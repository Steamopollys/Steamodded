--- SOURCE: https://github.com/anton-kl/lua-hot-reload
-- This code requires major refactoring.
-- Also see TODOs
local module = {}

-- if "inspect.lua" is accessible - load it
local exists, inspect = pcall( require, "inspect" )
if not exists then inspect = nil end

-- original function are set in the Inject() function
local setfenvOriginal
local loadfileOriginal
local requireOriginal

local fileCache = {}
local fileIndexCounter = 1

local traverseRegistry = true
local traverseGlobals = true
local trackGlobals = false
local globalsAccessed = {}
local handleGlobalModules = false

-- logging related flags
local log = true
local logCacheAccess = true
local logReferencesSteps = false
local storeReferencePath = false
local logUpvalues = false
local logGlobalAccess = true
local logTrace = false

-- if error happened during loading of the file,
-- but the old working version of the file is available, use it
local useOldFileOnError = true
local retrieveUpvaluesFromNestedFunctions = true
-- getinfo as an additional source of information about functions, is used only
-- for Lua5.2+ where we can't set ENV for every function (functions which
-- doesn't use globals doesn't have ENVs)
local useGetInfo = _ENV ~= nil
-- In vanilla Lua, if a chunk creates a function, which doesn't have any upvalues
-- (e.g. just return a result of some calculations), then even if execute this
-- chunk several times, we may get exactly the same function, down to its address.
-- This make it practically impossible to determine if two functions are coming
-- from different versions of the file, or not. Thus each time we are about
-- to execute the chunk, we should make it from scratch first. Example of the issue:
--[[
    function Func()
        return function() return 100 end
    end
    print(Func() == Func()) -- true on vanilla Lua
]]
local loadFileFromSource = type(jit) ~= 'table'
-- set to false to always assume file has been changed when loading/reloading
local enableTimestampCheck = true
-- set to false to always load file from the disk ignoring cache
local useCache = true

local Reload -- defined below
local reloading = false
local toBeReload = {}
local loadedFilesList = {}
local returnValuesMt = { __mode = "v" }
local customErrorHandler = nil
local functionSource = setmetatable({}, { __mode = "k" })

local visitedGlobal = {}
local queuePreallocationSize = 40000
local visitedPreallocationSize = 40000

local debug = debug
local getinfo = debug.getinfo
local getlocal = debug.getlocal
local getupvalue = debug.getupvalue
local upvalueid = debug.upvalueid
local setlocal = debug.setlocal
local setupvalue = debug.setupvalue
local upvaluejoin = debug.upvaluejoin

-- default handler just prints the error message, but you may want
-- to abort executing if isReloading is set to false, which means
-- that this is the first time we load this file, so we can't use
-- an older version of it
local function HandleLoadError(fileName, errorMessage, isReloading)
    if customErrorHandler then
        customErrorHandler(fileName, errorMessage, isReloading)
    else
        print("ERROR during loading of the " .. fileName .. ": " .. errorMessage .. ". " .. debug.traceback())
    end
end

local reloadTimes = 0
local function Log(...)
    local num = select("#", ...)
    local arg = {...}
    local prefix = "[LUAR]" .. (reloading and "[#" .. reloadTimes .. "]" or "") .. " "
    local msg = prefix
    for i = 1, num do
        msg = msg .. tostring(arg[i]) .. " "
    end
    print( (msg:gsub("\n", "\n" .. prefix)) )
end
local function Error(...)
    local num = select("#", ...)
    local arg = {...}
    local msg = ""
    for i = 1, num do
        msg = msg .. tostring(arg[i]) .. " "
    end
    error(msg)
end

local _GOriginal = _G
local envMetatable = {
    __index = function(t, k)
        if trackGlobals then
            globalsAccessed[k] = true
            if log and logGlobalAccess then Log("  get global", k, "value: [", _GOriginal[k], "]") end
        end
        return _GOriginal[k]
    end,
    __newindex = function(t, k, v)
        if trackGlobals then
            globalsAccessed[k] = true
            if log and logGlobalAccess then Log("  set global", k, "from: [", _GOriginal[k], "] to: [", v, "]") end
        end
        _GOriginal[k] = v
    end
}

local function GetFuncDesc(func)
    local info = getinfo(func)
    return info.func, "defined in", info.short_src, "at", info.linedefined, "-", info.lastlinedefined
end

-- see https://leafo.net/guides/setfenv-in-lua52-and-above.html
local setfenv = setfenv or function(func, env)
    local i = 1
    while true do
        local name = getupvalue(func, i)
        if name == "_ENV" then
            upvaluejoin(func, i, function() return env end, 1)
            break
        elseif not name then
            break
        end
        i = i + 1
    end
    return func
end

local getfenv = getfenv or function(func)
    local i = 1
    while true do
        local name, val = getupvalue(func, i)
        if name == "_ENV" then
            return val
        elseif not name then
            break
        end
        i = i + 1
    end
end

local setfenvNew = function(target, env)
    local oldEnv = getfenv(target)
    local _sourceFileIndex = rawget(oldEnv, "_sourceFileIndex")
    local _sourceFileName = rawget(oldEnv, "_sourceFileName")
    local _sourceFileIndex_current = rawget(env, "_sourceFileIndex")
    local _sourceFileName_current = rawget(env, "_sourceFileName")
    if (_sourceFileIndex_current ~= nil and _sourceFileIndex_current ~= _sourceFileIndex)
        or (_sourceFileName_current ~= nil and _sourceFileName_current ~= _sourceFileName)
    then
        -- TODO add a test case for this
        error("You set the environment of two functions defined in a different files to the same table.\n" ..
            "Unfortunately, this is not supported. In the environment of a functions, we store file name\n" ..
            "and file index - and without this information it is impossible to update a function properly.\n" ..
            "we could use getinfo().short_src, but it is slower, pollutes stacktraces, and more trickier\n" ..
            "to include \"file index\" in. Consider doing shallow-copy of the table, and use it as an environment.")
    end
    rawset(env, "_sourceFileIndex", _sourceFileIndex)
    rawset(env, "_sourceFileName", _sourceFileName)
    setfenvOriginal(target, env)
end

local function StoreReturnValues(file, fileIndex, ...)
    local number = select("#", ...)
    for i = 1, number do
        local value = select(i, ...)
        local vtype = type(value)
        if vtype == "table" or vtype == "function" then
            file.returnValues[ {
                fileIndex = fileIndex,
                valueIndex = i
            } ] = value
        end
    end
    return ...
end

local function UpdateReturnValues(file, fileIndex, ...)
    -- Tables created in new versions of a file never get references in the game,
    -- instead of copying references to tables - we just transfer the data from
    -- new tables to respective old tables (we match them based on return values
    -- order and some other factors). But new functions are obviously get
    -- referenced in the game, and we update references everywhere in the game,
    -- we don't do this for returnValues tables (we explicitly skip them while
    -- searching for references, this is why we have to manually remove old
    -- functions references in the returnValues table)
    local returnValues = file.returnValues
    for data, value in pairs(returnValues) do
        if log then Log("Analyze return value no.", data.valueIndex, "for fileIndex", fileIndex) end
        if data.fileIndex == fileIndex
            and type(value) == "function"
        then
            local newValue = select(data.valueIndex, ...)
            if log then Log("  Update this old function from", returnValues[data], "to", newValue) end
            returnValues[data] = newValue
        end
    end
    return ...
end

local function Pack(...)
    return { n = select("#", ...), ... }
end

local function SetupChunkEnv(chunk, fileName, fileIndex)
    local env = {
        _sourceFileIndex = fileIndex,
        _sourceFileName = fileName
    }
    setfenvOriginal(chunk, setmetatable(env, envMetatable))
end

local function ScheduleReload(fileName)
    local trace = logTrace and debug.traceback() or ""
    if not toBeReload[fileName] then
        if log then Log("SCHEDULE", fileName, "to be reloaded", trace) end
        toBeReload[fileName] = true
    else
        if log then Log(fileName, "is already scheduled to be reloaded", trace) end
    end
end

local function ReloadFile(fileName)
    if reloading then
        ScheduleReload(fileName)
        return false
    end
    local file = fileCache[fileName]
    assert(file, "DEV ERROR: Reloading a file which doesn't exist in the cache")

    local chunk, errorMessage = loadfileOriginal(fileName)

    if not chunk then
        HandleLoadError(fileName, errorMessage, true)
        return false, errorMessage
    end

    reloading = true
    Reload(fileName, file.chunk, chunk, file.returnValues)
    reloading = false

    file.chunk = chunk
    file.timestamp = module.FileGetTimestamp(fileName)

    return true
end

local function ReloadScheduledFiles(files)
    if reloading then return end

    -- reload all pending files
    while next(toBeReload) do
        local fileName, _ = next(toBeReload)
        toBeReload[fileName] = nil

        ReloadFile(fileName)
    end
end

local loadfileInternal = function(fileName)
    local file = fileCache[fileName]
    local errorMessage
    local timestamp = module.FileGetTimestamp(fileName)

    if file and (not enableTimestampCheck or timestamp > file.timestamp) and module.ShouldReload(fileName) then
        if reloading then
            -- schedule to reload
            ScheduleReload(fileName)
        else
            -- reload
            local _
            _, errorMessage = ReloadFile(fileName)
            -- reload any files that may have been scheduled for reloading
            -- during reloading of the above file
            ReloadScheduledFiles()
        end
    elseif file and enableTimestampCheck and useCache and timestamp == file.timestamp then
        -- load from cache (if timestamp check is disabled always load from the file)
        if logCacheAccess then Log("Loading", fileName, "from cache") end
    else
        -- load from file
        if log then
            local trace = logTrace and debug.traceback() or ""
            Log("Loading", fileName, trace)
        end
        table.insert(loadedFilesList, fileName)
        local chunk
        chunk, errorMessage = loadfileOriginal(fileName)
        if not chunk then
            HandleLoadError(fileName, errorMessage, false)
        else
            file = {
                chunk = chunk,
                timestamp = timestamp,
                returnValues = setmetatable({}, returnValuesMt)
            }
            fileCache[fileName] = file
        end
    end

    return file, errorMessage
end

local loadfileNew = function(fileName)
    -- load the file into the cache (or get from the cache)
    -- also reload it automatically if it has changed
    local file, errorMessage = loadfileInternal(fileName)

    if file and (not errorMessage or useOldFileOnError) then
        -- we do not return chunk directly, since each time it is executed,
        -- we want to setup a new ENV for it, so we return a function which
        -- does exactly that: executes the chunk, and setups the proper ENV
        return function(...)
            local fileIndex = fileIndexCounter
            fileIndexCounter = fileIndexCounter + 1

            local chunk = file.chunk
            if loadFileFromSource then
                if errorMessage then
                    local fileNameTmp = fileName .. "RELOADTMP"
                    os.rename(fileName, fileNameTmp)

                    local handle = io.open(fileName, "w+")
                    handle:write(string.dump(file.chunk, false))
                    io.close(handle)

                    chunk = loadfileOriginal(fileName)

                    os.remove(fileName)
                    os.rename(fileNameTmp, fileName)
                else
                    -- TODO if file is scheduled to reload, we may load a newer
                    -- version of the file here, so the file will exists in
                    -- different versions in the system, which is wrong
                    chunk = loadfileOriginal(fileName)
                end
            end
            SetupChunkEnv(chunk, fileName, fileIndex)
            if reloading then
                -- during reloading we are may load files, but their return
                -- values should not be referenced in the game, so we avoid
                -- storing them because they won't be used
                -- TODO return values may still be written into global variables
                -- how should we handle this?
                return chunk(...)
            else
                return StoreReturnValues(file, fileIndex, chunk(...))
            end
        end
    else
        -- if file loading failed, and we didn't abort yet,
        -- assume user code will handle nil and error message properly
        return nil, errorMessage
    end
end

local function dofileNew(fileName)
    local func, msg = loadfileNew(fileName)
    assert(func, msg)
    return func()
end

local function requireNew(modname)
    local function DoesFileExist(fileName)
        local file = io.open(fileName, "r")
        if file ~= nil then
            io.close(file)
            return true
        else
            return false
        end
    end

    local fileName = modname:gsub("%.", "/") .. ".lua"
    if DoesFileExist(fileName) and not fileCache[fileName] then
        local func, msg = loadfileNew(fileName)
        assert(func, msg)
        local result = func(modname, fileName)
        package.loaded[modname] = result
        return result
    else
        return requireOriginal(modname)
    end
end

local function FindReferences(fileName)
    local references = {}

    if log then Log("[ref_search]  Searching for references started") end

    -- debug/performance flags
    -- storePath - store full path for every value as a string, involves
    -- a lot of string allocations, should be used for debugging purposes only
    local storePath = false
    local calculateMaxDepth = false
    local traverseLocals = true
    local traverseEnvs = true
    local traverseGlobals = traverseGlobals == nil and true or traverseGlobals
    local traverseRegistry = traverseRegistry == nil and true or traverseRegistry

    -- initialization
    local preallocateTable = module.PreallocateTable
    local queueValue = preallocateTable and preallocateTable(queuePreallocationSize, 0) or {}
    local queuePrevious = preallocateTable and preallocateTable(queuePreallocationSize, 0) or {}
    local queueName = preallocateTable and preallocateTable(queuePreallocationSize, 0) or {}
    local queueType = preallocateTable and preallocateTable(queuePreallocationSize, 0) or {}
    -- to store info about the local variable, for locals only
    -- TODO refactor it to not consist of tables, check GC usage
    local queueLink = preallocateTable and preallocateTable(queuePreallocationSize, 0) or {}
    local queuePath = {} -- for debug purposes only
    local size = 0
    local visited = preallocateTable and preallocateTable(0, visitedPreallocationSize) or {}
    visited[fileCache] = true
    visited[fileCache[fileName]] = true
    visited[functionSource] = true
    visited[FindReferences] = true
    if not traverseGlobals then
        visited[_G] = true
        visited[_GOriginal] = true
    end
    for k, v in pairs(visitedGlobal) do
        visited[k] = v
    end

    local function GetReferencePath(ptr)
        local path = {}
        local prev = ptr
        local length = 0
        while prev do
            table.insert(path, prev)
            prev = queuePrevious[prev]
            length = length + 1
        end

        local pathText = {}
        for i = length, 1, -1 do
            if i ~= 1 and type(queueValue[path[i]]) == "function" then
                local source = getinfo(queueValue[path[i]], "S").source
                table.insert(pathText, tostring(queueName[path[i]]) .. "->[upvalues in " .. tostring(source) .. "]")
            else
                table.insert(pathText, tostring(queueName[path[i]]))
            end
        end
        return table.concat(pathText, "/")
    end

    -- capture locals
    local stackLevel = 4 -- ignore getLocals(1), FindReferences(2) and Reload(3)
    while traverseLocals do
        local info = getinfo(stackLevel, "S")
        if not info then break end
        local localId = 1
        while true do
            local ln, lv = getlocal(stackLevel, localId)
            if ln ~= nil then
                size = size + 1
                queueValue[size] = lv
                queuePrevious[size] = nil
                queueName[size] = "[locals in " .. info.short_src .. "]/" .. tostring(ln)
                queueType[size] = type(lv)
                queueLink[size] = {
                    stackLevel = stackLevel - 2, -- TODO fix this magic value
                    localId = localId
                }
                if storePath then queuePath[size] = queueName[size] end
            else
                break
            end
            localId = localId + 1
        end
        stackLevel = stackLevel + 1
    end

    -- capture globals
    if traverseGlobals then
        size = size + 1
        queueValue[size] = _G
        queuePrevious[size] = nil
        queueName[size] = "globals(_G)"
        queueType[size] = type(_G)
        if storePath then queuePath[size] = queueName[size] end
    end

    if traverseRegistry then
        local registry = debug.getregistry()
        size = size + 1
        queueValue[size] = registry
        queuePrevious[size] = nil
        queueName[size] = "lua_registry"
        queueType[size] = type(registry)
        if storePath then queuePath[size] = queueName[size] end
    end

    -- loop
    local depthMax = calculateMaxDepth and 0 or nil
    local ptr = 0
    while ptr < size do
        ptr = ptr + 1
        local currentValue = queueValue[ptr]
        local currentType = type(currentValue)
        local currentPath = storePath and queuePath[ptr]

        if calculateMaxDepth then
            local depthCurrent = 0
            local prev = ptr
            while prev do
                depthCurrent = depthCurrent + 1
                prev = queuePrevious[prev]
            end
            depthMax = math.max(depthCurrent, depthMax)
        end

        if logReferencesSteps then
            local pathText = GetReferencePath(ptr)
            local definedIn = ""
            if currentType == "function" then
                local fileName
                if useGetInfo then
                    local info = functionSource[currentValue]
                    if not info then
                        info = getinfo(currentValue, "S")
                        functionSource[currentValue] = info
                    end
                    fileName = info.short_src
                else
                    fileName = getfenv(currentValue)._sourceFileName
                end
                if fileName then
                    definedIn = "defined in " .. tostring(fileName)
                end
            end
            Log("[ref_search]    step", tostring(ptr), pathText, "=", tostring(currentValue), definedIn)
        end
        if currentType == "table" and not visited[currentValue] then
            visited[currentValue] = true
            local i = 0
            for k, v2 in pairs(currentValue) do
                local t = type(v2)
                if t == "table" or t == "function" then
                    i = i + 1
                    size = size + 1
                    queueValue[size] = v2
                    queuePrevious[size] = ptr
                    queueName[size] = k
                    queueLink[size] = {
                        owner = currentValue,
                        key = k
                    }
                    if storePath then queuePath[size] = currentPath .. "/" .. tostring(k) end
                end
                local t = type(k)
                if t == "table" or t == "function" then
                    i = i + 1
                    size = size + 1
                    queueValue[size] = k
                    queuePrevious[size] = ptr
                    queueName[size] = k
                    queueLink[size] = {
                        owner = currentValue
                    }
                    if storePath then queuePath[size] = currentPath .. "/" .. tostring(k) end
                end
            end
            local mt = getmetatable(currentValue)
            if mt then
                size = size + 1
                queueValue[size] = mt
                queuePrevious[size] = ptr
                queueName[size] = "mt"
                if storePath then queuePath[size] = currentPath .. "/mt" end
            end
        elseif currentType == "function" then
            local target = false
            local env = getfenv(currentValue)
            target = env and env._sourceFileName == fileName
            if not env and useGetInfo then
                local info = functionSource[currentValue]
                if not info then
                    info = getinfo(currentValue, "S")
                    functionSource[currentValue] = info
                end
                target = info.short_src == fileName
            end
            if target then
                local index = env and env._sourceFileIndex or 0
                local list = references[index] or {}
                table.insert(list, {
                    path = storePath and currentPath or (storeReferencePath and GetReferencePath(ptr)),
                    value = currentValue,
                    link = queueLink[ptr]
                })
                references[index] = list
            end

            if not visited[currentValue] then
                if traverseEnvs and env ~= _GOriginal and env ~= envMetatable then
                    size = size + 1
                    queueValue[size] = env
                    queuePrevious[size] = ptr
                    queueName[size] = "ENV"
                    if storePath then queuePath[size] = currentPath .. "/" .. queueName[size] end
                end

                visited[currentValue] = true
                local i = 1
                while true do
                    local ln, lv = getupvalue(currentValue, i)
                    if ln ~= nil then
                        local t = type(lv)
                        if t == "table" or t == "function" then
                            size = size + 1
                            queueValue[size] = lv
                            queuePrevious[size] = ptr
                            queueName[size] = ln
                            queueLink[size] = {
                                owner = currentValue,
                                upvalueId = i
                            }
                            if storePath then queuePath[size] = currentPath .. "/" .. tostring(ln) end
                        end
                    else
                        break
                    end
                    i = i + 1
                end
            end
        end
        if log and ptr % 100000 == 0 then
            Log("[ref_search] did ", ptr, " steps")
        end
    end

    if log then Log("[ref_search]  Finished in", ptr, "steps") end

    return references, visited
end

-- TODO use queueName instead of storing the whole path
local function traverse(data, fileName, visitedDuringSearch)
    if log then Log("-> traverse", fileName) end
    local storePath = log
    local logContent = log and false
    local logPush = log and false

    local functions = {}
    local upvalues = {}
    local tables = {}

    local queue = {}
    local queuePrevious = {}
    local queueLink = {}
    local queuePath = {}
    local visited = {
        [_G] = true, -- do not traverse _G which is found in ENVs of the functions
        [_GOriginal] = true
    }
    for k, v in pairs(visitedGlobal) do
        visited[k] = v
    end
    local size = 0
    local function push(obj, name, previous, link)
        size = size + 1
        queue[size] = obj
        queuePrevious[size] = previous
        queueLink[size] = link
        if storePath then queuePath[size] = (queuePath[previous] or "") .. "/[" .. tostring(name) .. "]" end
        if logPush then Log("  push [", obj, "] at", size) end
        if type(obj) == "table" then
            visited[obj] = true
        end
    end
    push(data, "data")

    local ptr = 0
    while ptr < size do
        ptr = ptr + 1
        local currentValue = queue[ptr]
        local currentType = type(currentValue)
        if storePath then Log(ptr .. ".", queuePath[ptr], "= [", currentValue, "]") end

        if currentType == "function" then
            -- For LuaJIT:
            -- Do not traverse a function, if it was defined before the file was
            -- loaded, cause it 100% doesn't come from the file we loaded
            -- For vanilla Lua:
            -- Remember that function with no ENV may have exactly the same
            -- address in vanilla Lua, so we have to traverse a function even if
            -- it seems like it existed before we loaded the file
            if not visitedDuringSearch[currentValue]
                or (useGetInfo and not getfenv(currentValue))
            then
                local target = false
                local env = getfenv(currentValue)
                if useGetInfo then
                    local info = functionSource[currentValue]
                    if not info then
                        info = getinfo(currentValue, "S")
                        functionSource[currentValue] = info
                    end
                    target = info.short_src == fileName
                else
                    target = env and env._sourceFileName == fileName
                end
                if target then
                    local info = functionSource[currentValue]
                    if not info then
                        info = getinfo(currentValue, "S")
                        functionSource[currentValue] = info
                    end
                    local linedefined = info.linedefined
                    if functions[linedefined] then
                        -- TODO print warning if two functions are defined at the same line
                        table.insert(functions[linedefined], ptr)
                    else
                        functions[linedefined] = { ptr }
                    end

                    -- Note: unlike tables, we push functions even _if they were
                    -- visited_, in order to store all routes to them (see above code)
                    -- this is why we have to check here if we didn't already
                    -- visited this functions, and only then mark it as visited
                    if not visited[currentValue] then
                        visited[currentValue] = true
                        local i = 1
                        while true do
                            local ln, lv = getupvalue(currentValue, i)
                            if ln ~= nil then
                                local upvalueid = upvalueid(currentValue, i)
                                if upvalues[ln] and upvalues[ln].id ~= upvalueid then
                                    Error("Two different upvalues with the same name found, please rename one of them. Upvalue `"
                                        .. tostring(ln) .. "` referenced in", GetFuncDesc(upvalues[ln].func),
                                        "and", GetFuncDesc(currentValue))
                                end
                                if logContent then Log("  - upvalue [", ln, "] = [", lv, "]") end
                                upvalues[ln] = {
                                    id = upvalueid,
                                    func = currentValue,
                                    index = i,
                                    value = lv
                                }
                                local vtype = type(lv)
                                if vtype == "function" or (vtype == "table" and not visited[lv]) then
                                    -- TODO optimize out the string concatenation
                                    push(lv, "upvalue " .. ln, ptr, { upvalueName = ln, upvalueIndex = i })
                                end
                            else
                                break
                            end
                            i = i + 1
                        end
                    end
                end
                if not visited[env] and env ~= envMetatable then
                    push(env, "env", ptr, { env = currentValue })
                end
            end
        elseif currentType == "table" then
            tables[currentValue] = ptr
            -- TODO traverse keys?
            for k, v in pairs(currentValue) do
                if logContent then Log("  - pair [", k, "] = [", v, "]") end
                local vtype = type(v)
                if vtype == "function" or (vtype == "table" and not visited[v]) then
                    push(v, k, ptr, { key = k })
                end
            end
            -- loading a file should create any tables with metatables, because if it is,
            -- then file executes "setmetable", which isn't nice
            local mt = getmetatable(currentValue)
            if mt and not visited[mt] then
                if logContent then Log("  - metatable", mt) end
                push(mt, "metatable", ptr, { metatable = true })
            end
        end
    end

    if log then Log("traverse completed in", size, "steps") end

    if log and inspect then
        Log("Upvalues data:")
        Log(inspect(upvalues))
    end

    return {
        queue = queue,
        queueLink = queueLink,
        queuePath = storePath and queuePath or nil,
        queuePrevious = queuePrevious,
        functions = functions,
        upvalues = upvalues,
        tables = tables
    }
end

local function SeparateReferencesByUpvalues(references, returnValuesByIndex)
    local upvalueidToFunc = {}
    local functionToIndex = {}

    if log then Log("Creating a map [function : fileIndex] based on captured return values") end
    for index, _returnValues in pairs(returnValuesByIndex) do
        if not references[index] then
            if log then Log("  Traverse return values for fileIndex no.", index, "in order to look for functions") end
            local queue = { _returnValues }
            local size = 1
            local visited = {
                [_G] = true,
                [_GOriginal] = true,
                [_returnValues] = true,
            }
            local validType = {
                ["table"] = true,
                ["function"] = true
            }
            local ptr = 0
            while ptr < size do
                ptr = ptr + 1
                local value = queue[ptr]
                local vtype = type(value)
                if vtype == "table" then
                    for k, v in pairs(value) do
                        if validType[type(k)] and not visited[k] then
                            size = size + 1
                            queue[size] = k
                            visited[k] = true
                        end
                        if validType[type(v)] and not visited[v] then
                            size = size + 1
                            queue[size] = v
                            visited[v] = true
                        end
                    end
                elseif vtype == "function" then
                    if log then Log("   ", GetFuncDesc(value), "is associated with fileIndex", index) end
                    functionToIndex[value] = index
                    visited[value] = true

                    local i = 1
                    while true do
                        local name, v = getupvalue(value, i)
                        if name == nil then break end

                        local id = upvalueid(value, i)
                        upvalueidToFunc[id] = value

                        if validType[type(v)] and not visited[v] then
                            size = size + 1
                            queue[size] = v
                            visited[v] = true
                        end
                        i = i + 1
                    end
                end
            end
        end
    end

    if log then Log("Separating functions into buckets based on their upvalues") end
    local refList = references[0]
    references[0] = nil
    local index = 0

    for fileIndex, list in pairs(references) do
        for _, ref in ipairs(list) do
            local func = ref.value
            functionToIndex[func] = fileIndex

            if log then Log(" ", GetFuncDesc(func), "is associated with file index", fileIndex) end

            local i = 1
            while true do
                if getupvalue(func, i) == nil then
                    break
                end
                local id = upvalueid(func, i)
                upvalueidToFunc[id] = func
                i = i + 1
            end
        end
    end

    for _, ref in ipairs(refList) do
        local func = ref.value
        local myIndexes = {}

        if log then Log("  Analyzing", GetFuncDesc(func)) end

        local myIndex = functionToIndex[func]
        if myIndex then
            myIndexes[myIndex] = true
            if log then Log("    This function's fileIndex was deduced based on captured return values, and it is", myIndex) end
        else
            -- no deduced index for this function, try to find shared upvalues
            -- with other functions which do have fileIndex associated
            local i = 1
            while true do
                if getupvalue(func, i) == nil then
                    break
                end

                local id = upvalueid(func, i)
                if upvalueidToFunc[id] then
                    local myIndex = functionToIndex[upvalueidToFunc[id]]
                    myIndexes[myIndex] = true
                    if log then Log("    Upvalue with id", id, "is referred to the bucket no.", myIndex) end
                else
                    upvalueidToFunc[id] = func
                    if log then Log("    Upvalue with id", id, "seems to be new") end
                end
                i = i + 1
            end

            local myFirstIndex = next(myIndexes)
            if myFirstIndex == nil then
                -- negative file indexes are used for these temporal buckets, to avoid a conflict with real fileIndexes
                index = index - 1
                myIndex = index
                if log then Log("    All upvalues were new, introducing a new bucket with id", myIndex) end
            else
                myIndex = myFirstIndex
                if log then Log("    This function shared upvalues with functions in the bucket no.", myIndex) end
                for i, _ in pairs(myIndexes) do
                    if i ~= myIndex then
                        for _, ref in ipairs(references[i]) do
                            table.insert(references[myIndex], ref)
                        end
                        if log then Log("    Moving all functions from bucket no.", i, "to above bucket,",
                            "since those functions are sharing upvalues") end
                        references[i] = nil
                    end
                end
            end
        end
        functionToIndex[func] = myIndex
        references[myIndex] = references[myIndex] or {}
        table.insert(references[myIndex], ref)
    end
end

local function GetValueByRoute(routeStart, fileData1, traverseStartingPoint)
    -- build route for this reference
    local route = {}
    local prev = routeStart
    while prev do
        table.insert(route, fileData1.queueLink[prev])
        prev = fileData1.queuePrevious[prev]
    end

    -- print route
    if log then
        Log("  route:", #route, "steps")
        for i = #route, 1, -1 do
            local step = route[i]
            local msg = "    " .. tostring(#route - i + 1) .. "."
            for k,v in pairs(step) do
                msg = msg .. " " .. tostring(k) .. " = " .. tostring(v)
            end
            Log(msg)
        end
    end

    -- find a new value using above route
    local newValueFound = true
    local currentValue = traverseStartingPoint
    local lastValue
    for stepNumber = #route, 1, -1 do
        lastValue = currentValue
        local step = route[stepNumber]
        local currentType = type(currentValue)
        if currentType == "function" then
            assert(step.upvalueName or step.env)
            if step.upvalueName then
                local i = 1
                local found = false
                while true do
                    local name, value = getupvalue(currentValue, i)
                    if name == nil then
                        break
                    elseif name == step.upvalueName then
                        currentValue = value
                        found = true
                        break
                    end
                    i = i + 1
                end
                if not found then
                    if log then
                        Log("  wasn't able to take step no.", #route - stepNumber + 1,
                            "in the new file, missing upvalue", step.upvalueName,
                            "(originally at index", tostring(step.upvalueIndex) .. ")")
                    end
                    newValueFound = false
                    break
                end
            elseif step.env then
                currentValue = getfenv(currentValue)
            end
        elseif currentType == "table" then
            assert(step.key or step.metatable)
            if step.key then
                currentValue = currentValue[step.key]
            else
                currentValue = getmetatable(currentValue)
            end
        end
    end
    return newValueFound, currentValue, lastValue
end

Reload = function(fileName, chunkOriginal, chunkNew, returnValues)
    reloadTimes = reloadTimes + 1
    if log then Log("*** Reloading", fileName, "***") end

    if log then Log("\n*** LOOKING FOR REFERENCES ***") end
    local references, visitedDuringSearch = FindReferences(fileName)


    if log then Log("\n*** PREPARE RETURN VALUES BY INDEX  ***") end
    -- We store return values for all versions of the file in a one big table
    -- cause we want them to be automatically removed by gc (see returnValuesMt)
    -- It's okay if we load file once in applications lifetime, use it,
    -- remove all references and the entry in the table is still present
    -- Worse if entries for each version of the file are present.
    local returnValuesByIndex = {}
    for k, v in pairs(returnValues) do
        local t = returnValuesByIndex[k.fileIndex]
        if not t then
            t = {}
            returnValuesByIndex[k.fileIndex] = t
        end
        t[k.valueIndex] = v
        if log then Log("return value for file with index [", k.fileIndex, "] no.", k.valueIndex, "is", v) end
    end

    -- If we don't have information about file indexes for functions,
    -- they all go into the bucket with id=0 in `references`,
    -- and we have to separate function into several buckets based on their
    -- upvalues, i.e. if two functions share an upvalue, we place them in the
    -- same bucket. So essentially it is the same as having file indexes for
    -- those functions, but with additional work required.
    if useGetInfo and references[0] then
        SeparateReferencesByUpvalues(references, returnValuesByIndex)
    end

    -- Update return values. If a file returns a table with data without functions,
    -- there will be no references, but we should update return values anyway.
    for index, _ in pairs(returnValuesByIndex) do
        if not references[index] then
            references[index] = {}
            if log then
                Log("adding empty reference list based on return values",
                    "for file index", index)
            end
        end
    end

    local versions = 0
    for _, _ in pairs(references) do
        versions = versions + 1
    end
    if log then Log("FOUND", versions, "VERSIONS OF THE", fileName, ":") end

    if log then
        local version = 1
        for index, list in pairs(references) do
            Log(version .. ". ", fileName, "with index [", index, "]")
            for i, ref in ipairs(list) do
                Log("  ref#" .. i, "at [", ref.path, "] to", GetFuncDesc(ref.value))
            end
            version = version + 1
        end
    end

    if log then Log("\n*** BUILDING ROUTES TO FUNCTIONS IN ORIGINAL FILE ***") end

    globalsAccessed = {}
    if handleGlobalModules then
        if log then Log("tracking globals...") end
        trackGlobals = true
        _G = setmetatable({}, envMetatable)
    end
    -- When traversing the original file, we can get to the references (e.g. via
    -- following upvalues), and we shouldn't confuse them with new functions,
    -- but we can't rely on fileIndex on Lua5.2 (some functions may not have it),
    -- so instead we maintain the list of references, and check if a given
    -- function isn't is this list
    SetupChunkEnv(chunkOriginal, fileName, 0) -- fileIndex is irrelevant here
    local returnValuesOriginal = Pack(chunkOriginal())
    if trackGlobals then
        trackGlobals = false
        _G = _GOriginal
    end
    local data = {
        ["return_values"] = returnValuesOriginal
    }
    for name, _ in pairs(globalsAccessed) do
        data["global_" .. name] = _G[name]
        if log then Log("  schedule global [", name , "] to be traversed") end
    end

    local fileData1 = traverse(data, fileName, visitedDuringSearch)

    local file = fileCache[fileName]
    for fileIndex, list in pairs(references) do
        if log then Log("\n*** UPDATING FILE WITH INDEX", fileIndex, "***") end
        -- set env for newly loaded file to ensure that new functions has correct fileName and the fileIndex of the old file
        SetupChunkEnv(chunkNew, fileName, fileIndex)
        local returnValuesNew = Pack(UpdateReturnValues(file, fileIndex, chunkNew()))
        local data = {
            ["return_values"] = returnValuesNew
        }
        for name, _ in pairs(globalsAccessed) do
            data["global_" .. name] = _G[name]
        end
        local fileData2 = traverse(data, fileName, visitedDuringSearch)
        local detectedTables = {}

        if log then Log("\n*** UPDATING REFERENCES && SET ENVS OF THE NEW FUNCs TO ENV OF OLD ONES ***") end
        if log and #list == 0 then Log("There are no references for this file index - no functions to update.") end

        for refIndex, ref in ipairs(list) do
            local linedefined = getinfo(ref.value, "S").linedefined
            local functionPtrList = fileData1.functions[linedefined]
            if not functionPtrList then
                if log then Log(refIndex .. ".", ref.value, "- wasn't able to find this one, probably it's a function made in another function"
                    .. "\n  It was defined at line", linedefined) end
            else
                for routeIndex, routeStart in ipairs(functionPtrList) do
                    if log then
                        Log("ref#" .. refIndex, ref.value, "found in",
                            fileData1.queuePath and fileData1.queuePath[routeStart] or "<path of reference isn't stored>",
                            "(route#" .. routeIndex .. ")")
                    end

                    local newValueFound, currentValue, lastValue = GetValueByRoute(routeStart, fileData1, data)

                    if not newValueFound then
                        if log then Log("  wasn't able to retrieve new value") end
                    else
                        if log then Log("  found new value", currentValue) end
                        -- skip nil values unless it is a last route, and we found nothing besides nil
                        -- then assume this function just got removed and we have to remove it.
                        if currentValue == nil and routeIndex ~= #functionPtrList then
                            if log then Log("  but is is a nil value, so first we should check other routes - maybe we will find non-nil value") end
                        else
                            -- update the reference
                            if ref.link.localId then
                                -- if it is a local variable
                                local stackLevel = ref.link.stackLevel + 1
                                local localId = ref.link.localId
                                if log then
                                    local name, value = getlocal(stackLevel, localId)
                                    Log("  set local [", name, "] at stack level", stackLevel, "at index", localId, "from [", value, "] to [", currentValue, "]")
                                end
                                setlocal(stackLevel, localId, currentValue)
                            elseif type(ref.link.owner) == "function" then
                                if log then
                                    local name, _ = getupvalue(ref.link.owner, ref.link.upvalueId)
                                    Log("  set upvalue [", ref.link.upvalueId, "] called [", name, "] in", ref.link.owner, "to [", currentValue, "]")
                                end
                                setupvalue(ref.link.owner, ref.link.upvalueId, currentValue)
                            elseif type(ref.link.owner) == "table" then
                                if lastValue then
                                    detectedTables[lastValue] = {
                                        current = ref.link.owner, -- in fact it is "current", but we wand to override
                                                                  -- values in the original table, since this is what may be referenced
                                        new = lastValue, -- new
                                        original = fileData1.queue[fileData1.queuePrevious[routeStart]] -- original
                                    }
                                end
                                if ref.link.key ~= nil then
                                    ref.link.owner[ref.link.key] = currentValue
                                    if log then Log("  set value [", ref.link.key, "] in", ref.link.owner, "to [", currentValue, "]") end
                                else
                                    if currentValue then
                                        ref.link.owner[currentValue] = ref.link.owner[ref.value]
                                        if log then Log("  set key [", currentValue, "] in", ref.link.owner, "to [", ref.link.owner[ref.value], "]") end
                                    else
                                        if log then Log("  remove key [", ref.value, "] in", ref.link.owner) end
                                    end
                                    ref.link.owner[ref.value] = nil
                                end
                            else
                                error("DEV ERROR: invalid owner type in the reference, probably code gathering references is broken")
                            end

                            -- stop going through the routes, if we a found a new non-nil value for this reference
                            break
                        end
                    end
                end
            end
        end

        if log then Log("\n*** BUILDING CURRENT UPVALUES LIST ***") end
        local upvaluesOriginal = fileData1.upvalues
        local upvaluesNew = fileData2.upvalues
        local upvaluesCurrent = {}

        local function IsFileScopeFunction(func, linedefined)
            linedefined = linedefined or getinfo(func, "S").linedefined
            return fileData1.functions[linedefined] ~= nil
        end

        local ignoreUpvalues = {}
        local visited = {}
        for _, ref in ipairs(list) do
            local currentValue = ref.value
            local linedefined = getinfo(currentValue, "S").linedefined
            if not visited[linedefined] then
                visited[linedefined] = true
                local upvalues = upvaluesCurrent
                local isFileScopeFunction = IsFileScopeFunction(currentValue, linedefined)
                if isFileScopeFunction or retrieveUpvaluesFromNestedFunctions then
                    local i = 1
                    while true do
                        local ln, lv = getupvalue(currentValue, i)
                        if ln ~= nil then
                            -- ignore upvalues that aren't present in the original file - they are probably local variables in functions,
                            -- which are references in nested functions
                            if upvaluesOriginal[ln] then
                                local write = true
                                local upvalueid = upvalueid(currentValue, i)
                                if upvalues[ln] and upvalues[ln].id ~= upvalueid then
                                    local isFileScopeFunction_old = IsFileScopeFunction(upvalues[ln].func)
                                    if not isFileScopeFunction and not isFileScopeFunction_old then
                                        if log then Log("Note: Two different upvalues with the same names, referenced in two different nested functions\n",
                                            "with name [", ln, "] will be ignored for safety. Because they probably aren't file-scoped upvalues.\n",
                                            "There seems to be a file-scoped upvalue with the name, which may not be referenced in any accessible file-scoped func,\n",
                                            "But we can't use those upvalues, because we can't tell which one (if there is one) is the file-scoped upvalue.")
                                        end
                                        ignoreUpvalues[ln] = true
                                    elseif isFileScopeFunction and isFileScopeFunction_old then
                                        error("DEV ERROR: something went wrong... Two different file-scoped functions with two different upvalues with the same name?.\n"
                                            .. "We check for this case when we load original file, so this shouldn't happen.")
                                    else
                                        -- at this point we know, that one upvalue is from a nested func, and another one from the file-scoped func
                                        if log then Log("Note: There are at least two upvalues with the same name [", ln, "],\n",
                                            "but one of them is referenced in nested function, why another one is referenced in the file-scoped func,\n",
                                            "so we are gonna use this one from the file-scoped func.")
                                        end
                                        if isFileScopeFunction then
                                            -- below we override an upvalue from nested function with this upvalue from file-scoped function
                                            ignoreUpvalues[ln] = nil
                                        else
                                            -- do not override upvalue, since we already have one from the file-scoped function
                                            write = false
                                        end
                                    end
                                end
                                if write then
                                    upvalues[ln] = {
                                        id = upvalueid,
                                        func = currentValue,
                                        index = i,
                                        value = lv
                                    }
                                end
                            end
                        else
                            break
                        end
                        i = i + 1
                    end
                else
                    if log then Log(GetFuncDesc(currentValue), "is seems to be a nested function, so we ignore its upvalues.\n",
                        "If this functions references upvalues from the file which aren't referenced in other accesible functions -\n",
                        "they won't be taken into account. New functions won't use them. Their values won't be updated, if they are const.")
                    end
                end
            end
        end

        for k in pairs(ignoreUpvalues) do
            -- remove any upvalues that weren't sure are file-scope upvalues
            upvaluesCurrent[k] = nil
            if log then Log("Note: removing upvalue [", k, "] from the list, because we aren't sure if it's a file-scoped upvalue or not.") end
        end

        if logUpvalues and inspect then
            local function LogUpvalues(message, upvalues)
                Log(message)
                Log(inspect(upvalues))
            end

            LogUpvalues("Current upvalues:", upvaluesCurrent)
            LogUpvalues("Original upvalues:", upvaluesOriginal)
            LogUpvalues("New upvalues:", upvaluesNew)
        end


        if log then Log("\n*** UPDATING OLD CONST UPVALUES TO NEW VALUES ***") end

        local queue = {}
        local queueLink = {}
        local visited = {}
        for k, v in pairs(visitedGlobal) do
            visited[k] = v
        end
        local size = 0

        local function push(obj, link)
            size = size + 1
            queue[size] = obj
            queueLink[size] = link
        end

        for _, v in pairs(detectedTables) do
            push(v, { debugName = "detected_table" })
        end

        for k, _ in pairs(upvaluesCurrent) do
            if upvaluesOriginal[k] then
                if not upvaluesNew[k] then
                    if log then Log("  Note: upvalue [", k, "] seems to be removed from the new version of the file.") end
                end
                push({
                    current = upvaluesCurrent[k].value,
                    new = upvaluesNew[k] and upvaluesNew[k].value, -- do not add `or nil` here because it will replace `false` `value` by `nil`
                    original = upvaluesOriginal[k].value
                }, {
                    func = upvaluesCurrent[k].func,
                    upvalueIndex = upvaluesCurrent[k].index,
                    debugName = k
                })
            else
                if log then Log("  Note: upvalue [", k, "] isn't present in the original file, so it is probably an upvalue of a nested function.") end
            end
        end

        if log then Log("  Current fileIndex is", fileIndex) end
        local returnedTables = returnValuesByIndex[fileIndex]
        if returnedTables then
            for i, v in pairs(returnedTables) do
                local newValue = returnValuesNew[i]
                if type(newValue) == "table" then
                    local original = returnValuesOriginal[i]
                    assert(type(original) == "table",
                        "DEV ERROR: type of return value in original file is different from the one stored in returnValues")
                    push({
                        current = v,
                        new = newValue,
                        original = original
                    }, {
                        debugName = "return value no. " .. i
                    })
                else
                    if log and type(v) == "table" then
                        Log("  Note: return value no. [", i, "] from the original file, which was a table, is", type(newValue))
                    end
                end
            end
        else
            if log then Log("  Note: old version of the file didn't return any tables, no special handling of the returned values is required.") end
        end

        local ptr = 0
        local tableNewValue = {}
        while ptr < size do
            ptr = ptr + 1
            local obj = queue[ptr]
            if log then Log(ptr .. ". stored in: [", queueLink[ptr].key or queueLink[ptr].debugName, "] current: [", obj.current, "] original: [", obj.original, "] new: [", obj.new, "]") end
            -- if there is a difference
            if obj.current ~= obj.new then
                local currentType = type(obj.current)
                if currentType == "table" and type(obj.original) == "table" and type(obj.new) == "table" then
                    if not visited[obj.current] then
                        visited[obj.current] = true
                        tableNewValue[obj.new] = obj.current
                        -- TODO take metatables into consideration
                        local isArray = true
                        local count1 = 0
                        local count2 = 0
                        local isStatic = true
                        for k, v in pairs(obj.current) do
                            count1 = count1 + 1
                        end
                        isArray = count1 == #obj.current
                        if isArray then
                            for k, v in pairs(obj.original) do
                                count2 = count2 + 1
                            end
                            isArray = count2 == #obj.original
                            if isArray then
                                for i, v in ipairs(obj.current) do
                                    -- TODO maybe a deep comparison? how about a static array of tables?
                                    if v ~= obj.original[i] then
                                        isStatic = false
                                        break
                                    end
                                end
                            end
                        end
                        if not isArray or isStatic then
                            if log then Log("  it's a table value, and we are gonna traverse it further either because it's a dynamic array or not an array at all.") end
                            -- traverse further
                            for k, _ in pairs(obj.current) do
                                push({
                                    current = obj.current[k],
                                    new = obj.new[k],
                                    original = obj.original[k]
                                }, { table = obj.current, key = k })
                            end

                            for k, _ in pairs(obj.new) do
                                if obj.current[k] == nil and obj.original[k] == nil then
                                    push({
                                        current = nil,
                                        new = obj.new[k],
                                        original = nil
                                    }, { table = obj.current, key = k })
                                end
                            end
                        else
                            if log then Log("  it's a table value, but we aren't gonna traverse it, because it's a static array.") end
                        end
                    end
                elseif currentType ~= "function " and currentType ~= "thread" and currentType ~= "userdata" then
                    local isConst = obj.original == obj.current
                    if isConst then
                        if log then Log("  it's a POD value") end
                    end

                    local isTableToPOD = type(obj.current) == "table" and type(obj.original) == "table"
                    if isTableToPOD then
                        if log then Log("  it's a table, which is a POD value in the new version of the file\n"
                            .. "  So we just change this value into a new POD, but if there are anonymous functions from old file using this value, they may broke.") end
                    end

                    if isConst or isTableToPOD then
                        -- it is a const value -- update old upvalue
                        local ref = queueLink[ptr]
                        if log then Log("  it's a CONST value") end
                        -- update the reference
                        if ref.func then
                            setupvalue(ref.func, ref.upvalueIndex, obj.new)
                            local ln, _ = getupvalue(ref.func, ref.upvalueIndex)
                            if log then Log("  set upvalue [", ln, "] in", ref.func, "from [", obj.current, "] to [", obj.new, "]") end
                        elseif ref.table then
                            ref.table[ref.key] = obj.new
                            if log then Log("  set value [", ref.key, "] in", ref.table, "from [", obj.current, "] to [", obj.new, "]") end
                        else
                            error("DEV ERROR: we try to update a value which isn't stored anywhere, either this the link is broken, or we are updating a return value.")
                        end
                    else
                        if log then Log("  it's NOT a CONST value") end
                    end
                else
                    if log then Log("  it's a", currentType, "value - ignored") end
                end
            end
        end

        if log then Log("\n*** MERGING UPVALUES OF NEW FUNCTIONS TO OLD ONES ***") end
        for _, ptrList in pairs(fileData2.functions) do
            local ptr = ptrList[1]
            local func = fileData2.queue[ptr]
            if log then Log("- processing function", func, "in ptr", ptr) end
            local i = 1
            while true do
                local ln, lv = getupvalue(func, i)
                if ln ~= nil then
                    local upvalue_new = upvaluesCurrent[ln]
                    if upvalue_new then
                        upvaluejoin(func, i, upvalue_new.func, upvalue_new.index)
                        if log then
                            Log("  link upvalue [", ln, "] to upvalue no.", upvalue_new.index, "from", upvalue_new.func,
                                "(was [", lv, "] now [", select(2, getupvalue(upvalue_new.func, upvalue_new.index)), "])")
                        end
                    else
                        if log then Log("  wasn't able to find upvalue [", ln, "] in the old version of the file") end
                        local newValue = tableNewValue[lv]
                        if newValue then
                            setupvalue(func, i, newValue)
                            if log then Log("  set upvalue [", ln, "] to table [", newValue, "] which was found during comparison of the data beetwen the original and new files") end
                        end
                    end
                else
                    if log and i == 1 then
                        Log("  no upvalues")
                    end
                    break
                end
                i = i + 1
            end
        end
    end

    if log then Log("\n*** RELOADING FINISHED ***") end
end

function module.SetPrintReloadingLogs(enable)
    log = enable
end

function module.SetLogCacheAccess(enable)
    logCacheAccess = enable
end

function module.SetLogReferencesSteps(enable)
    logReferencesSteps = enable
end

function module.SetStoreReferencePath(enable)
    storeReferencePath = enable
end

function module.SetLogUpvalues(enable)
    logUpvalues = enable
end

function module.SetTraverseGlobals(enable)
    traverseGlobals = enable
end

function module.SetTraverseRegistry(enable)
    traverseRegistry = enable
end

function module.SetHandleGlobalModules(enable)
    handleGlobalModules = enable
end

function module.SetErrorHandler(errorHandler)
    customErrorHandler = errorHandler
end

function module.GetFileCache()
    return fileCache
end

function module.ClearFileCache()
    fileCache = {}
end

function module.SetUseCache(enable)
    useCache = enable
end

function module.SetUseOldFileOnError(enable)
    useOldFileOnError = enable
end


function module.SetUseGetInfo(enable)
    useGetInfo = enable
end

function module.SetQueuePreallocationSize(value)
    queuePreallocationSize = value
end

function module.SetVisitedPreallocationSize(value)
    visitedPreallocationSize = value
end

-- a game is expected to provide getTimestamp function
local staticTimestamp = 0
function module.FileGetTimestamp(fileName)
    if lfs then
        return lfs.attributes(fileName, "modification")
    elseif love and love.filesystem.getInfo then
        return love.filesystem.getInfo(fileName).modtime
    elseif love and love.filesystem.getLastModified then
        return love.filesystem.getLastModified(fileName)
    else
        staticTimestamp = staticTimestamp + 1
        return staticTimestamp
    end
end

function module.SetEnableTimestampCheck(enable)
    enableTimestampCheck = enable
end

local function GetTime()
    if chronos then
        return chronos.nanotime()
    elseif love then
        return love.timer.getTime()
    end
    return 0
end

local monitorPtr = 1
function module.Monitor(step, log)
    local momentStart = GetTime()
    local filesNumber = #loadedFilesList
    local filesToMonitor = step and math.min(filesNumber - 1, step) or filesNumber - 1
    local target = monitorPtr + filesToMonitor
    local reloading = false
    for i = monitorPtr, target do
        local filename = loadedFilesList[i % filesNumber + 1]
        local cached = fileCache[filename]
        if cached then
            local timestamp = module.FileGetTimestamp(filename)
            if timestamp and timestamp > cached.timestamp then
                local file = io.open(filename, "r")
                if file then
                    local success = true
                    if lfs then
                        success = lfs.lock(file, "r")
                        if success then
                            lfs.unlock(file)
                        end
                    end
                    io.close(file)

                    if success then
                        if log then Log("Reloading", filename, "old timestamp:", cached.timestamp, "new timestamp:", timestamp) end
                        ScheduleReload(filename)
                        reloading = true
                    else
                        if log then Log("Failed to retrieve lock on a file") end
                    end
                end
            end
        end
    end
    monitorPtr = target + 1
    if log then
        local duration = GetTime() - momentStart
        local timeinfo = ""
        if duration > 0 then
            timeinfo = "Monitoring took " .. string.format("%.3f", duration * 1000) .. "ms, "
        end
        Log(timeinfo .. "monitored", (filesToMonitor + 1) .. "/" .. filesNumber, "files")
    end
    if reloading then
        momentStart = GetTime()
    end
    ReloadScheduledFiles()
    if reloading then
        local duration = GetTime() - momentStart
        if duration > 0 then
            Log("Reloading took", string.format("%.3f", duration * 1000) .. "ms" )
        end
    end
end

-- this function is expected to be overridden by the game
function module.ShouldReload(fileName)
    return true
end

function module.ReloadFile(fileName, ignoreTimestamp)
    if ignoreTimestamp == nil then
        ignoreTimestamp = not enableTimestampCheck
    end
    -- check if this was loaded at least once (otherwise there is nothing to reload)
    local file = fileCache[fileName]
    if file and module.ShouldReload(fileName) then
        local timestamp = module.FileGetTimestamp(fileName)
        if timestamp > file.timestamp or ignoreTimestamp then
            ScheduleReload(fileName)
            ReloadScheduledFiles()
            return true
        end
    end
    return false
end

function module.ReloadScheduledFiles()
    ReloadScheduledFiles()
end

function module.SetVisited(k, v)
    visitedGlobal[k] = v
end

function module.Inject()
    -- if setfenv isn't accessible, assume we are dealing wih lua5.2+
    setfenvOriginal = setfenv
    loadfileOriginal = loadfile
    requireOriginal = require

    -- avoid overriding global setfenv if it wasn't defined
    setfenv = setfenv and setfenvNew or setfenv
    loadfile = loadfileNew
    dofile = dofileNew
    require = require and requireNew
end

return module
