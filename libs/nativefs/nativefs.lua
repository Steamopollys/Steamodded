--[[
Copyright 2020 megagrump@pm.me

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]--

-- module("nativefs", package.seeall)

local ffi, bit = require('ffi'), require('bit')
local C = ffi.C

local fopen, getcwd, chdir, unlink, mkdir, rmdir
local BUFFERMODE, MODEMAP
local ByteArray = ffi.typeof('unsigned char[?]')
local function _ptr(p) return p ~= nil and p or nil end -- NULL pointer to nil

local File = {
    getBuffer = function(self) return self._bufferMode, self._bufferSize end,
    getFilename = function(self) return self._name end,
    getMode = function(self) return self._mode end,
    isOpen = function(self) return self._mode ~= 'c' and self._handle ~= nil end,
}

function File:open(mode)
    if self._mode ~= 'c' then return false, "File " .. self._name .. " is already open" end
    if not MODEMAP[mode] then return false, "Invalid open mode for " .. self._name .. ": " .. mode end

    local handle = _ptr(fopen(self._name, MODEMAP[mode]))
    if not handle then return false, "Could not open " .. self._name .. " in mode " .. mode end

    self._handle, self._mode = ffi.gc(handle, C.fclose), mode
    self:setBuffer(self._bufferMode, self._bufferSize)

    return true
end

function File:close()
    if self._mode == 'c' then return false, "File is not open" end
    C.fclose(ffi.gc(self._handle, nil))
    self._handle, self._mode = nil, 'c'
    return true
end

function File:setBuffer(mode, size)
    local bufferMode = BUFFERMODE[mode]
    if not bufferMode then
        return false, "Invalid buffer mode " .. mode .. " (expected 'none', 'full', or 'line')"
    end

    if mode == 'none' then
        size = math.max(0, size or 0)
    else
        size = math.max(2, size or 2) -- Windows requires buffer to be at least 2 bytes
    end

    local success = self._mode == 'c' or C.setvbuf(self._handle, nil, bufferMode, size) == 0
    if not success then
        self._bufferMode, self._bufferSize = 'none', 0
        return false, "Could not set buffer mode"
    end

    self._bufferMode, self._bufferSize = mode, size
    return true
end

function File:getSize()
    -- NOTE: The correct way to do this would be a stat() call, which requires a
    -- lot more (system-specific) code. This is a shortcut that requires the file
    -- to be readable.
    local mustOpen = not self:isOpen()
    if mustOpen and not self:open('r') then return 0 end

    local pos = mustOpen and 0 or self:tell()
    C.fseek(self._handle, 0, 2)
    local size = self:tell()
    if mustOpen then
        self:close()
    else
        self:seek(pos)
    end
    return size
end

function File:read(containerOrBytes, bytes)
    if self._mode ~= 'r' then return nil, 0 end

    local container = bytes ~= nil and containerOrBytes or 'string'
    if container ~= 'string' and container ~= 'data' then
        error("Invalid container type: " .. container)
    end

    bytes = not bytes and containerOrBytes or 'all'
    bytes = bytes == 'all' and self:getSize() - self:tell() or math.min(self:getSize() - self:tell(), bytes)

    if bytes <= 0 then
        local data = container == 'string' and '' or love.data.newFileData('', self._name)
        return data, 0
    end

    local data = love.data.newByteData(bytes)
    local r = tonumber(C.fread(data:getFFIPointer(), 1, bytes, self._handle))

    if container == 'data' then
        -- FileData from ByteData requires LÖVE 11.4+
        local ok, fd = pcall(love.filesystem.newFileData, data, self._name)
        if ok then return fd end
    end

    local str = data:getString()
    data:release()
    data = container == 'data' and love.filesystem.newFileData(str, self._name) or str
    return data, r
end

local function lines(file, autoclose)
    local BUFFERSIZE = 4096
    local buffer, bufferPos = ByteArray(BUFFERSIZE), 0
    local bytesRead = tonumber(C.fread(buffer, 1, BUFFERSIZE, file._handle))

    local offset = file:tell()
    return function()
        file:seek(offset)

        local line = {}
        while bytesRead > 0 do
            for i = bufferPos, bytesRead - 1 do
                if buffer[i] == 10 then -- end of line
                    bufferPos = i + 1
                    return table.concat(line)
                end

                if buffer[i] ~= 13 then -- ignore CR
                    table.insert(line, string.char(buffer[i]))
                end
            end

            bytesRead = tonumber(C.fread(buffer, 1, BUFFERSIZE, file._handle))
            offset, bufferPos = offset + bytesRead, 0
        end

        if not line[1] then
            if autoclose then file:close() end
            return nil
        end
        return table.concat(line)
    end
end

function File:lines()
    if self._mode ~= 'r' then error("File is not opened for reading") end
    return lines(self)
end

function File:write(data, size)
    if self._mode ~= 'w' and self._mode ~= 'a' then
        return false, "File " .. self._name .. " not opened for writing"
    end

    local toWrite, writeSize
    if type(data) == 'string' then
        writeSize = (size == nil or size == 'all') and #data or size
        toWrite = data
    else
        writeSize = (size == nil or size == 'all') and data:getSize() or size
        toWrite = data:getFFIPointer()
    end

    if tonumber(C.fwrite(toWrite, 1, writeSize, self._handle)) ~= writeSize then
        return false, "Could not write data"
    end
    return true
end

function File:seek(pos)
    return self._handle and C.fseek(self._handle, pos, 0) == 0
end

function File:tell()
    if not self._handle then return nil, "Invalid position" end
    return tonumber(C.ftell(self._handle))
end

function File:flush()
    if self._mode ~= 'w' and self._mode ~= 'a' then
        return nil, "File is not opened for writing"
    end
    return C.fflush(self._handle) == 0
end

function File:isEOF()
    return not self:isOpen() or C.feof(self._handle) ~= 0 or self:tell() == self:getSize()
end

function File:release()
    if self._mode ~= 'c' then self:close() end
    self._handle = nil
end

function File:type() return 'File' end

function File:typeOf(t) return t == 'File' end

File.__index = File

-----------------------------------------------------------------------------

local nativefs = {}
local loveC = ffi.os == 'Windows' and ffi.load('love') or C

function nativefs.newFile(name)
    if type(name) ~= 'string' then
        error("bad argument #1 to 'newFile' (string expected, got " .. type(name) .. ")")
    end
    return setmetatable({
        _name = name,
        _mode = 'c',
        _handle = nil,
        _bufferSize = 0,
        _bufferMode = 'none'
    }, File)
end

function nativefs.newFileData(filepath)
    local f = nativefs.newFile(filepath)
    local ok, err = f:open('r')
    if not ok then return nil, err end

    local data, err = f:read('data', 'all')
    f:close()
    return data, err
end

function nativefs.mount(archive, mountPoint, appendToPath)
    return loveC.PHYSFS_mount(archive, mountPoint, appendToPath and 1 or 0) ~= 0
end

function nativefs.unmount(archive)
    return loveC.PHYSFS_unmount(archive) ~= 0
end

function nativefs.read(containerOrName, nameOrSize, sizeOrNil)
    local container, name, size
    if sizeOrNil then
        container, name, size = containerOrName, nameOrSize, sizeOrNil
    elseif not nameOrSize then
        container, name, size = 'string', containerOrName, 'all'
    else
        if type(nameOrSize) == 'number' or nameOrSize == 'all' then
            container, name, size = 'string', containerOrName, nameOrSize
        else
            container, name, size = containerOrName, nameOrSize, 'all'
        end
    end

    local file = nativefs.newFile(name)
    local ok, err = file:open('r')
    if not ok then return nil, err end

    local data, size = file:read(container, size)
    file:close()
    return data, size
end

local function writeFile(mode, name, data, size)
    local file = nativefs.newFile(name)
    local ok, err = file:open(mode)
    if not ok then return nil, err end

    ok, err = file:write(data, size or 'all')
    file:close()
    return ok, err
end

function nativefs.write(name, data, size)
    return writeFile('w', name, data, size)
end

function nativefs.append(name, data, size)
    return writeFile('a', name, data, size)
end

function nativefs.lines(name)
    local f = nativefs.newFile(name)
    local ok, err = f:open('r')
    if not ok then return nil, err end
    return lines(f, true)
end

function nativefs.load(name)
    local chunk, err = nativefs.read(name)
    if not chunk then return nil, err end
    return loadstring(chunk, name)
end

function nativefs.getWorkingDirectory()
    return getcwd()
end

function nativefs.setWorkingDirectory(path)
    if not chdir(path) then return false, "Could not set working directory" end
    return true
end

function nativefs.getDriveList()
    if ffi.os ~= 'Windows' then return { '/' } end
    local drives, bits = {}, C.GetLogicalDrives()
    for i = 0, 25 do
        if bit.band(bits, 2 ^ i) > 0 then
            table.insert(drives, string.char(65 + i) .. ':/')
        end
    end
    return drives
end

function nativefs.createDirectory(path)
    local current = path:sub(1, 1) == '/' and '/' or ''
    for dir in path:gmatch('[^/\\]+') do
        current = current .. dir .. '/'
        local info = nativefs.getInfo(current, 'directory')
        if not info and not mkdir(current) then return false, "Could not create directory " .. current end
    end
    return true
end

function nativefs.remove(name)
    local info = nativefs.getInfo(name)
    if not info then return false, "Could not remove " .. name end
    if info.type == 'directory' then
        if not rmdir(name) then return false, "Could not remove directory " .. name end
        return true
    end
    if not unlink(name) then return false, "Could not remove file " .. name end
    return true
end

local function withTempMount(dir, fn, ...)
    local mountPoint = _ptr(loveC.PHYSFS_getMountPoint(dir))
    if mountPoint then return fn(ffi.string(mountPoint), ...) end
    if not nativefs.mount(dir, '__nativefs__temp__') then return false, "Could not mount " .. dir end
    local a, b = fn('__nativefs__temp__', ...)
    nativefs.unmount(dir)
    return a, b
end

function nativefs.getDirectoryItems(dir)
    local result, err = withTempMount(dir, love.filesystem.getDirectoryItems)
    return result or {}
end

local function getDirectoryItemsInfo(path, filtertype)
    local items = {}
    local files = love.filesystem.getDirectoryItems(path)
    for i = 1, #files do
        local filepath = string.format('%s/%s', path, files[i])
        local info = love.filesystem.getInfo(filepath, filtertype)
        if info then
            info.name = files[i]
            table.insert(items, info)
        end
    end
    return items
end

function nativefs.getDirectoryItemsInfo(path, filtertype)
    local result, err = withTempMount(path, getDirectoryItemsInfo, filtertype)
    return result or {}
end

local function getInfo(path, file, filtertype)
    local filepath = string.format('%s/%s', path, file)
    return love.filesystem.getInfo(filepath, filtertype)
end

local function leaf(p)
    p = p:gsub('\\', '/')
    local last, a = p, 1
    while a do
        a = p:find('/', a + 1)
        if a then
            last = p:sub(a + 1)
        end
    end
    return last
end

function nativefs.getInfo(path, filtertype)
    local dir = path:match("(.*[\\/]).*$") or './'
    local file = leaf(path)
    local result, err = withTempMount(dir, getInfo, file, filtertype)
    return result or nil
end

-----------------------------------------------------------------------------

MODEMAP = { r = 'rb', w = 'wb', a = 'ab' }
local MAX_PATH = 4096

ffi.cdef([[
    int PHYSFS_mount(const char* dir, const char* mountPoint, int appendToPath);
    int PHYSFS_unmount(const char* dir);
    const char* PHYSFS_getMountPoint(const char* dir);

    typedef struct FILE FILE;

    FILE* fopen(const char* path, const char* mode);
    size_t fread(void* ptr, size_t size, size_t nmemb, FILE* stream);
    size_t fwrite(const void* ptr, size_t size, size_t nmemb, FILE* stream);
    int fclose(FILE* stream);
    int fflush(FILE* stream);
    size_t fseek(FILE* stream, size_t offset, int whence);
    size_t ftell(FILE* stream);
    int setvbuf(FILE* stream, char* buffer, int mode, size_t size);
    int feof(FILE* stream);
]])

if ffi.os == 'Windows' then
    ffi.cdef([[
        int MultiByteToWideChar(unsigned int cp, uint32_t flags, const char* mb, int cmb, const wchar_t* wc, int cwc);
        int WideCharToMultiByte(unsigned int cp, uint32_t flags, const wchar_t* wc, int cwc, const char* mb,
                                int cmb, const char* def, int* used);
        int GetLogicalDrives(void);
        int CreateDirectoryW(const wchar_t* path, void*);
        int _wchdir(const wchar_t* path);
        wchar_t* _wgetcwd(wchar_t* buffer, int maxlen);
        FILE* _wfopen(const wchar_t* path, const wchar_t* mode);
        int _wunlink(const wchar_t* path);
        int _wrmdir(const wchar_t* path);
    ]])

    BUFFERMODE = { full = 0, line = 64, none = 4 }

    local function towidestring(str)
        local size = C.MultiByteToWideChar(65001, 0, str, #str, nil, 0)
        local buf = ffi.new('wchar_t[?]', size + 1)
        C.MultiByteToWideChar(65001, 0, str, #str, buf, size)
        return buf
    end

    local function toutf8string(wstr)
        local size = C.WideCharToMultiByte(65001, 0, wstr, -1, nil, 0, nil, nil)
        local buf = ffi.new('char[?]', size + 1)
        C.WideCharToMultiByte(65001, 0, wstr, -1, buf, size, nil, nil)
        return ffi.string(buf)
    end

    local nameBuffer = ffi.new('wchar_t[?]', MAX_PATH + 1)

    fopen = function(path, mode) return C._wfopen(towidestring(path), towidestring(mode)) end
    getcwd = function() return toutf8string(C._wgetcwd(nameBuffer, MAX_PATH)) end
    chdir = function(path) return C._wchdir(towidestring(path)) == 0 end
    unlink = function(path) return C._wunlink(towidestring(path)) == 0 end
    mkdir = function(path) return C.CreateDirectoryW(towidestring(path), nil) ~= 0 end
    rmdir = function(path) return C._wrmdir(towidestring(path)) == 0 end
else
    BUFFERMODE = { full = 0, line = 1, none = 2 }

    ffi.cdef([[
        char* getcwd(char *buffer, int maxlen);
        int chdir(const char* path);
        int unlink(const char* path);
        int mkdir(const char* path, int mode);
        int rmdir(const char* path);
    ]])

    local nameBuffer = ByteArray(MAX_PATH)

    fopen = C.fopen
    unlink = function(path) return ffi.C.unlink(path) == 0 end
    chdir = function(path) return ffi.C.chdir(path) == 0 end
    mkdir = function(path) return ffi.C.mkdir(path, 0x1ed) == 0 end
    rmdir = function(path) return ffi.C.rmdir(path) == 0 end

    getcwd = function()
        local cwd = _ptr(C.getcwd(nameBuffer, MAX_PATH))
        return cwd and ffi.string(cwd) or nil
    end
end

return nativefs
