--- STEAMODDED CORE
--- MODULE API

function loadAPIs()
    -------------------------------------------------------------------------------------------------
    --- API CODE GameObject
    -------------------------------------------------------------------------------------------------

    --- GameObject base class. You should always use the appropriate subclass to register your object.
    SMODS.GameObject = Object:extend()
    SMODS.GameObject.subclasses = {}
    function SMODS.GameObject:extend(o)
        local cls = Object.extend(self)
        for k, v in pairs(o or {}) do
            cls[k] = v
        end
        self.subclasses[#self.subclasses + 1] = cls
        cls.subclasses = {}
        return cls
    end

    function SMODS.GameObject:__call(o)
        o = o or {}
        assert(o.mod == nil)
        o.mod = SMODS.current_mod
        setmetatable(o, self)
        for _, v in ipairs(o.required_params or {}) do
            assert(not (o[v] == nil), ('Missing required parameter for %s declaration: %s'):format(o.set, v))
        end
        if o:check_duplicate_register() then return end
        -- also updates o.prefix_config
        SMODS.add_prefixes(self, o)
        if o:check_duplicate_key() then return end
        o:register()
        return o
    end

    function SMODS.modify_key(obj, prefix, condition, key)
        key = key or 'key'
        -- condition == nil counts as true
        if condition ~= false and obj[key] and prefix then
            if string.sub(obj[key], 1, #prefix + 1) == prefix..'_' then
                -- this happens within steamodded itself and I don't want to spam the logs with warnings, leaving this disabled for now
                -- sendWarnMessage(("Attempted to prefix field %s=%s on object %s, already prefixed"):format(key, obj[key], obj.key), obj.set)
                return
            end
            obj[key] = prefix .. '_' .. obj[key]
        end
    end

    function SMODS.add_prefixes(cls, obj, from_take_ownership)
        if obj.prefix_config == false then return end
        obj.prefix_config = obj.prefix_config or {}
        if obj.raw_key then
            sendWarnMessage(([[The field `raw_key` on %s is deprecated.
Set `prefix_config.key = false` on your object instead.]]):format(obj.key), obj.set)
            obj.prefix_config.key = false
        end
        -- keep class defaults for unmodified keys in prefix_config
        obj.prefix_config = SMODS.merge_defaults(obj.prefix_config, cls.prefix_config)
        local mod = SMODS.current_mod
        obj.prefix_config = SMODS.merge_defaults(obj.prefix_config, mod and mod.prefix_config)
        obj.original_key = obj.key
        local key_cfg = obj.prefix_config.key
        if key_cfg ~= false then
            if type(key_cfg) ~= 'table' then key_cfg = {} end
            if not from_take_ownership then
                SMODS.modify_key(obj, mod and mod.prefix, key_cfg.mod)
            end
            SMODS.modify_key(obj, cls.class_prefix, key_cfg.class)
        end
        local atlas_cfg = obj.prefix_config.atlas
        if atlas_cfg ~= false then
            if type(atlas_cfg) ~= 'table' then atlas_cfg = {} end
            for _, v in ipairs({ 'atlas', 'hc_atlas', 'lc_atlas', 'hc_ui_atlas', 'lc_ui_atlas', 'sticker_atlas' }) do
                if rawget(obj, v) then SMODS.modify_key(obj, mod and mod.prefix, atlas_cfg[v], v) end
            end
        end
        local shader_cfg = obj.prefix_config.shader
        SMODS.modify_key(obj, mod and mod.prefix, shader_cfg, 'shader')
        local card_key_cfg = obj.prefix_config.card_key
        SMODS.modify_key(obj, mod and mod.prefix, card_key_cfg, 'card_key')
        local above_stake_cfg = obj.prefix_config.above_stake
        if above_stake_cfg ~= false then
            if type(above_stake_cfg) ~= 'table' then above_stake_cfg = {} end
            SMODS.modify_key(obj, mod and mod.prefix, above_stake_cfg.mod, 'above_stake')
            SMODS.modify_key(obj, cls.class_prefix, above_stake_cfg.class, 'above_stake') 
        end
        local applied_stakes_cfg = obj.prefix_config.applied_stakes
        if applied_stakes_cfg ~= false and obj.applied_stakes then
            if type(applied_stakes_cfg) ~= 'table' then applied_stakes_cfg = {} end
            for k,v in pairs(obj.applied_stakes) do
                SMODS.modify_key(obj.applied_stakes, mod and mod.prefix, (applied_stakes_cfg[k] or {}).mod or applied_stakes_cfg.mod, k)
                SMODS.modify_key(obj.applied_stakes, cls.class_prefix, (applied_stakes_cfg[k] or {}).class or applied_stakes_cfg.class, k)
            end
        end
        local unlocked_stake_cfg = obj.prefix_config.unlocked_stake
        if unlocked_stake_cfg ~= false then
            if type(unlocked_stake_cfg) ~= 'table' then unlocked_stake_cfg = {} end
            SMODS.modify_key(obj, mod and mod.prefix, unlocked_stake_cfg.mod, 'unlocked_stake')
            SMODS.modify_key(obj, cls.class_prefix, unlocked_stake_cfg.class, 'unlocked_stake') 
        end
    end

    function SMODS.GameObject:check_duplicate_register()
        if self.registered then
            sendWarnMessage(('Detected duplicate register call on object %s'):format(self.key), self.set)
            return true
        end
        return false
    end

    -- Checked on __call but not take_ownership. For take_ownership, the key must exist
    function SMODS.GameObject:check_duplicate_key()
        if self.obj_table[self.key] or (self.get_obj and self:get_obj(self.key)) then
            sendWarnMessage(('Object %s has the same key as an existing object, not registering.'):format(self.key), self.set)
            sendWarnMessage('If you want to modify an existing object, use take_ownership()', self.set)
            return true
        end
        return false
    end

    function SMODS.GameObject:register()
        if self:check_dependencies() then
            self.obj_table[self.key] = self
            self.obj_buffer[#self.obj_buffer + 1] = self.key
            self.registered = true
        end
    end

    function SMODS.GameObject:check_dependencies()
        local keep = true
        if self.dependencies then
            -- ensure dependencies are a table
            if type(self.dependencies) == 'string' then self.dependencies = { self.dependencies } end
            for _, v in ipairs(self.dependencies) do
                self.mod.optional_dependencies[v] = true
                if not SMODS.Mods[v] or not SMODS.Mods[v].can_load then keep = false end
            end
        end
        return keep
    end

    function SMODS.GameObject:process_loc_text()
        SMODS.process_loc_text(G.localization.descriptions[self.set], self.key, self.loc_txt)
    end
    
    --- Starting from this class, recursively searches for 
    --- functions with the given key on all subordinate classes
    --- and run all found functions with the given arguments
    function SMODS.GameObject:send_to_subclasses(func, ...)
        if rawget(self, func) and type(self[func]) == 'function' then self[func](self, ...) end
        for _, cls in ipairs(self.subclasses) do
            cls:send_to_subclasses(func, ...)
        end
    end


    -- Inject all direct instances `o` of the class by calling `o:inject()`.
    -- Also inject anything necessary for the class itself.
    function SMODS.GameObject:inject_class()
        local inject_time = 0
        local start_time = love.timer.getTime()
        self:send_to_subclasses('pre_inject_class')
        local end_time = love.timer.getTime()
        inject_time = end_time - start_time
        start_time = end_time
        local o = nil
        for i, key in ipairs(self.obj_buffer) do
            o = self.obj_table[key]
            o.atlas = o.atlas or o.set

            if o._discovered_unlocked_overwritten then
                assert(o._saved_d_u)
                o.discovered, o.unlocked = o._d, o._u
                o._discovered_unlocked_overwritten = false
            else
                SMODS._save_d_u(o)
            end

            -- Add centers to pools
            o:inject(i)

            -- Setup Localize text
            o:process_loc_text()
            if self.log_interval and i%(self.log_interval) == 0 then
                end_time = love.timer.getTime()
                inject_time = inject_time + end_time - start_time
                start_time = end_time
                local alert = ('[%s] Injecting %s: %.3f ms'):format(string.rep('0', 4-#tostring(i))..i, self.set, inject_time*1000)
                sendTraceMessage(alert, 'TIMER')
                boot_print_stage(alert)
            end
        end
        self:send_to_subclasses('post_inject_class')
        end_time = love.timer.getTime()
        inject_time = inject_time + end_time - start_time
        local n = #self.obj_buffer
        local alert = ('[%s] Injected %s in %.3f ms'):format(string.rep('0',4-#tostring(n))..n, self.set, inject_time*1000)
        sendInfoMessage(alert, 'TIMER')
        boot_print_stage(alert)
    end

    --- Takes control of vanilla objects. Child class must implement get_obj for this to function.
    function SMODS.GameObject:take_ownership(key, obj, silent)
        if self.check_duplicate_register(obj) then return end
        obj.key = key
        obj.mod = nil
        SMODS.add_prefixes(self, obj, true)
        key = obj.key
        local orig_o = self.obj_table[key] or (self.get_obj and self:get_obj(key))
        if not orig_o then
            sendWarnMessage(
                ('Cannot take ownership of %s: Does not exist.'):format(key), self.set
            )
            return
        end
        local is_loc_modified = obj.loc_txt or obj.loc_vars or obj.generate_ui
        if is_loc_modified then orig_o.is_loc_modified = true end
        if not orig_o.is_loc_modified then
            -- Setting generate_ui to this sentinel value
            -- makes vanilla localization code run instead of SMODS's code
            orig_o.generate_ui = 0
		else
			-- reset the value if otherwise, in case when the object was taken over before and this value was already set to 0
			if orig_o.generate_ui == 0 then
				orig_o.generate_ui = nil
			end
        end
        -- TODO
        -- it's unclear how much we should modify `obj` on a failed take_ownership call.
        -- do we make sure the metatable is set early, or wait until the end?
        setmetatable(orig_o, self)
        if orig_o.mod then
            orig_o.dependencies = orig_o.dependencies or {}
            if not silent then table.insert(orig_o.dependencies, SMODS.current_mod.id) end
        else
            if not silent then orig_o.mod = SMODS.current_mod end
            orig_o.rarity_original = orig_o.rarity
        end
        if orig_o._saved_d_u then
            orig_o.discovered, orig_o.unlocked = orig_o._d, orig_o._u
            orig_o._saved_d_u = false
            orig_o._discovered_unlocked_overwritten = false
        end
        for k, v in pairs(obj) do orig_o[k] = v end
        SMODS._save_d_u(orig_o)
        orig_o.taken_ownership = true
        orig_o:register()
        return orig_o
    end

    -- Inject all SMODS Objects that are part of this class or a subclass.
    function SMODS.injectObjects(class)
        if class.obj_table and class.obj_buffer then
            class:inject_class()
        else
            for _, subclass in ipairs(class.subclasses) do SMODS.injectObjects(subclass) end
        end
    end

    -- Internal function
    -- Creates a list of objects from a list of keys.
    -- Currently used for a special case when selecting a random suit/rank.
    function SMODS.GameObject:obj_list(reversed)
        local lb, ub, step = 1, #self.obj_buffer, 1
        if reversed then lb, ub, step = ub, lb, -1 end
        local res = {}
        for i = lb, ub, step do
          res[#res+1] = self.obj_table[self.obj_buffer[i]]
        end
        return res
    end

    -------------------------------------------------------------------------------------------------
    ----- API CODE GameObject.Language
    -------------------------------------------------------------------------------------------------

    SMODS.Languages = {}
    SMODS.Language = SMODS.GameObject:extend {
        obj_table = SMODS.Languages,
        set = 'Language',
        obj_buffer = {},
        required_params = {
            'key',
            'label',
        },
        prefix_config = { key = false },
        process_loc_text = function() end,
        inject = function(self)
            self.font = self.font or 1
            if type(self.font) == 'table' and not self.font.FONT and self.font.file and self.font.render_scale then
                local data = assert(NFS.newFileData(self.mod.path .. 'assets/fonts/' .. self.font.file), ('Failed to collect file data for font of language %s'):format(self.key))
                self.font.FONT = love.graphics.newFont(data, self.font.render_scale)
            elseif type(self.font) ~= 'table' then
                self.font = G.FONTS[type(self.font) == 'number' and self.font or 1] or G.FONTS[1]
            end
            G.LANGUAGES[self.key] = self
            if self.key == (G.SETTINGS.real_language or G.SETTINGS.language) then G.LANG = self end
        end,
    }

    -------------------------------------------------------------------------------------------------
    ----- INTERNAL API CODE GameObject._Loc_Pre
    -------------------------------------------------------------------------------------------------

    SMODS._Loc_Pre = SMODS.GameObject:extend {
        obj_table = {},
        obj_buffer = {},
        silent = true,
        set = '[INTERNAL]',
        register = function() error('INTERNAL CLASS, DO NOT CALL') end,
        pre_inject_class = function()
            SMODS.handle_loc_file(SMODS.path)
            if SMODS.dump_loc then SMODS.dump_loc.pre_inject = copy_table(G.localization) end
            for _, mod in ipairs(SMODS.mod_list) do
                if mod.process_loc_text and type(mod.process_loc_text) == 'function' then
                    mod.process_loc_text()
                end
            end
        end
    }

    -------------------------------------------------------------------------------------------------
    ----- API CODE GameObject.Atlas
    -------------------------------------------------------------------------------------------------

    SMODS.Atlases = {}
    SMODS.Atlas = SMODS.GameObject:extend {
        obj_table = SMODS.Atlases,
        obj_buffer = {},
        disable_mipmap = false,
        required_params = {
            'key',
            'path',
            'px',
            'py'
        },
        atlas_table = 'ASSET_ATLAS',
        set = 'Atlas',
        register = function(self)
            if self.registered then
                sendWarnMessage(('Detected duplicate register call on object %s'):format(self.key), self.set)
                return
            end
            if self.language then
                self.key_noloc = self.key
                self.key = ('%s_%s'):format(self.key, self.language)
            end
            -- needed for changing high contrast settings, apparently
            self.name = self.key
            SMODS.Atlas.super.register(self)
        end,
        inject = function(self)
            local file_path = type(self.path) == 'table' and
                ((G.SETTINGS.real_language and self.path[G.SETTINGS.real_language]) or self.path[G.SETTINGS.language] or self.path['default'] or self.path['en-us']) or self.path
            if file_path == 'DEFAULT' then return end
            -- language specific sprites override fully defined sprites only if that language is set
            if self.language and G.SETTINGS.language ~= self.language and G.SETTINGS.real_language ~= self.language then return end
            if not self.language and (self.obj_table[('%s_%s'):format(self.key, G.SETTINGS.language)] or self.obj_table[('%s_%s'):format(self.key, G.SETTINGS.real_language)]) then return end
            self.full_path = (self.mod and self.mod.path or SMODS.path) ..
                'assets/' .. G.SETTINGS.GRAPHICS.texture_scaling .. 'x/' .. file_path
            local file_data = assert(NFS.newFileData(self.full_path),
                ('Failed to collect file data for Atlas %s'):format(self.key))
            self.image_data = assert(love.image.newImageData(file_data),
                ('Failed to initialize image data for Atlas %s'):format(self.key))
            self.image = love.graphics.newImage(self.image_data,
                { mipmaps = true, dpiscale = G.SETTINGS.GRAPHICS.texture_scaling })
            G[self.atlas_table][self.key_noloc or self.key] = self

            local mipmap_level = SMODS.config.graphics_mipmap_level_options[SMODS.config.graphics_mipmap_level]
            if not self.disable_mipmap and mipmap_level and mipmap_level > 0 then
                self.image:setMipmapFilter('linear', mipmap_level)
            end
        end,
        process_loc_text = function() end,
        pre_inject_class = function(self) 
            G:set_render_settings() -- restore originals first in case a texture pack was disabled
        end
    }

    SMODS.Atlas {
        key = 'mod_tags',
        path = 'mod_tags.png',
        px = 34,
        py = 34,
    }
    SMODS.Atlas {
        key = 'achievements',
        path = 'default_achievements.png',
        px = 66,
        py = 66,
    }

    -------------------------------------------------------------------------------------------------
    ----- API CODE GameObject.Sound
    -------------------------------------------------------------------------------------------------

    SMODS.Sounds = {}
    SMODS.Sound = SMODS.GameObject:extend {
        obj_buffer = {},
        set = 'Sound',
        obj_table = SMODS.Sounds,
        stop_sounds = {},
        replace_sounds = {},
        required_params = {
            'key',
            'path'
        },
        process_loc_text = function() end,
        register = function(self)
            if self.registered then
                sendWarnMessage(('Detected duplicate register call on object %s'):format(self.key), self.set)
                return
            end
            self.sound_code = self.key
            if self.replace then
                local replace, times, args
                if type(self.replace) == 'table' then
                    replace, times, args = self.replace.key, self.replace.times or -1, self.replace.args
                else
                    replace, times = self.replace, -1
                end
                self.replace_sounds[replace] = { key = self.key, times = times, args = args }
            end 
            -- TODO detect music state based on if select_music_track exists
            assert(not self.select_music_track or self.key:find('music'))
            SMODS.Sound.super.register(self)
        end,
        inject = function(self)
            local file_path = type(self.path) == 'table' and
                ((G.SETTINGS.real_language and self.path[G.SETTINGS.real_language]) or self.path[G.SETTINGS.language] or self.path['default'] or self.path['en-us']) or self.path
            if file_path == 'DEFAULT' then return end
            local prev_path = self.full_path
            self.full_path = (self.mod and self.mod.path or SMODS.path) ..
                'assets/sounds/' .. file_path
            if prev_path == self.full_path then return end
            self.data = NFS.read('data', self.full_path)
            --self.decoder = love.sound.newDecoder(self.data)
            self.should_stream = string.find(self.key, 'music') or string.find(self.key, 'stream') or string.find(self.key, 'ambient')
            --self.sound = love.audio.newSource(self.decoder, self.should_stream and 'stream' or 'static')
            if prev_path then G.SOUND_MANAGER.channel:push({ type = 'stop' }) end
            G.SOUND_MANAGER.channel:push({ type = 'sound_source', sound_code = self.sound_code, data = self.data, should_stream = self.should_stream, per = self.pitch, vol = self.volume })
        end,
        register_global = function(self)
            local mod = SMODS.current_mod
            if not mod then return end
            for _, filename in ipairs(NFS.getDirectoryItems(mod.path .. 'assets/sounds/')) do
                local extension = string.sub(filename, -4)
                if extension == '.ogg' or extension == '.mp3' or extension == '.wav' then -- please use .ogg or .wav files
                    local sound_code = string.sub(filename, 1, -5)
                    self {
                        key = sound_code,
                        path = filename,
                    }
                end
            end
        end,
        -- retaining this function for mod compat
        play = function(self, pitch, volume, stop_previous_instance, key)
            return play_sound(key or self.sound_code, pitch, volume)
        end,
        create_stop_sound = function(self, key, times)
            times = times or -1
            self.stop_sounds[key] = times
        end,
        create_replace_sound = function(self, replace_sound)
            self.replace = replace_sound
            local replace, times, args
            if type(self.replace) == 'table' then
                replace, times, args = self.replace.key, self.replace.times or -1, self.replace.args
            else
                replace, times = self.replace, -1
            end
            self.replace_sounds[replace] = { key = self.key, times = times, args = args }
        end,
        get_current_music = function(self)
            local track
            local maxp = -math.huge
            for _, v in ipairs(self.obj_buffer) do
                local s = self.obj_table[v]
                if type(s.select_music_track) == 'function' then
                    local res = s:select_music_track()
                    if res then
                        if type(res) ~= 'number' then res = 0 end
                        if res > maxp then track, maxp = v, res end
                    end
                end
            end
            return track
        end
    }

    local play_sound_ref = play_sound
    function play_sound(sound_code, per, vol)
        local replace_sound = SMODS.Sound.replace_sounds[sound_code]
        if replace_sound then
            local sound = SMODS.Sounds[replace_sound.key]
            local rt
            if replace_sound.args then
                local args = replace_sound.args
                if type(args) == 'function' then args = args(sound, { pitch = per, volume = vol }) end
                play_sound(sound.sound_code, args.pitch, args.volume)
                if not args.continue_base_sound then rt = true end
            else
                play_sound(sound.sound_code, per, vol)
                rt = true
            end
            if replace_sound.times > 0 then replace_sound.times = replace_sound.times - 1 end
            if replace_sound.times == 0 then SMODS.Sound.replace_sounds[sound_code] = nil end
            if rt then return end
        end
        local stop_sound = SMODS.Sound.stop_sounds[sound_code]
        if stop_sound then
            if stop_sound > 0 then
                SMODS.Sound.stop_sounds[sound_code] = stop_sound - 1
            end
            return
        end

        return play_sound_ref(sound_code, per, vol)
    end

    -------------------------------------------------------------------------------------------------
    ----- API CODE GameObject.Stake
    -------------------------------------------------------------------------------------------------

    SMODS.Stakes = {}
    SMODS.Stake = SMODS.GameObject:extend {
        obj_table = SMODS.Stakes,
        obj_buffer = {},
        class_prefix = 'stake',
        unlocked = false,
        set = 'Stake',
        atlas = 'chips',
        pos = { x = 0, y = 0 },
        injected = false,
        required_params = {
            'key',
            'pos',
            'applied_stakes'
        },
        pre_inject_class = function(self)
            G.P_CENTER_POOLS[self.set] = {}
            G.P_STAKES = {}
        end,
        inject = function(self)
            if not self.injected then
                -- Inject stake in the correct spot
                self.count = #G.P_CENTER_POOLS[self.set] + 1
                self.order = self.count
                if self.above_stake and G.P_STAKES[self.above_stake] then
                    self.order = G.P_STAKES[self.above_stake].order + 1
                end
                for _, v in pairs(G.P_STAKES) do
                    if v.order >= self.order then
                        v.order = v.order + 1
                    end
                end
                G.P_STAKES[self.key] = self
                table.insert(G.P_CENTER_POOLS.Stake, self)
                -- Sticker sprites (stake_ prefix is removed for vanilla compatiblity)
                if self.sticker_pos ~= nil then
                    G.shared_stickers[self.key:sub(7)] = Sprite(0, 0, G.CARD_W, G.CARD_H,
                    G.ASSET_ATLAS[self.sticker_atlas] or G.ASSET_ATLAS["stickers"], self.sticker_pos)
                    G.sticker_map[self.key] = self.key:sub(7)
                else
                    G.sticker_map[self.key] = nil
                end
            else
                G.P_STAKES[self.key] = self
                SMODS.insert_pool(G.P_CENTER_POOLS.Stake, self)
            end
            self.injected = true
            -- should only need to do this once per injection routine
        end,
        post_inject_class = function(self)
            table.sort(G.P_CENTER_POOLS[self.set], function(a, b) return a.order < b.order end)
            for _,stake in pairs(G.P_CENTER_POOLS.Stake) do
                local applied = SMODS.build_stake_chain(stake)
                stake.stake_level = 0
                for i,_ in ipairs(G.P_CENTER_POOLS.Stake) do
                    if applied[i] then stake.stake_level = stake.stake_level+1 end
                end
            end
            G.C.STAKES = {}
            for i = 1, #G.P_CENTER_POOLS[self.set] do
                G.C.STAKES[i] = G.P_CENTER_POOLS[self.set][i].colour or G.C.WHITE
            end
        end,
        process_loc_text = function(self)
            -- empty loc_txt indicates there are existing values that shouldn't be changed or it isn't necessary
            if not self.loc_txt or not next(self.loc_txt) then return end
            local target = (G.SETTINGS.real_language and self.loc_txt[G.SETTINGS.real_language]) or self.loc_txt[G.SETTINGS.language] or self.loc_txt['default'] or self.loc_txt['en-us'] or
                self.loc_txt
            local applied_text = "{s:0.8}" .. localize('b_applies_stakes_1')
            local any_applied
            for _, v in pairs(self.applied_stakes) do
                any_applied = true
                applied_text = applied_text ..
                    localize { set = self.set, key = v, type = 'name_text' } .. ', '
            end
            applied_text = applied_text:sub(1, -3)
            if not any_applied then
                applied_text = "{s:0.8}"
            else
                applied_text = applied_text .. localize('b_applies_stakes_2')
            end
            local desc_target = copy_table(target)
            table.insert(desc_target.text, applied_text)
            G.localization.descriptions[self.set][self.key] = desc_target
            SMODS.process_loc_text(G.localization.descriptions["Other"], self.key:sub(7) .. "_sticker", self.loc_txt,
                'sticker')
        end,
        get_obj = function(self, key) return G.P_STAKES[key] end
    }

    function SMODS.build_stake_chain(stake, applied)
        if not applied then applied = {} end
        if not stake or applied[stake.order] then return end
        applied[stake.order] = stake.order
        if not stake.applied_stakes then
            return applied
        end
        for _, s in pairs(stake.applied_stakes) do
            SMODS.build_stake_chain(G.P_STAKES[s], applied)
        end
        return applied
    end 

    function SMODS.setup_stake(i)
        local applied_stakes = SMODS.build_stake_chain(G.P_CENTER_POOLS.Stake[i])
        for stake, _ in pairs(applied_stakes) do
            if G.P_CENTER_POOLS['Stake'][stake].modifiers then
                G.P_CENTER_POOLS['Stake'][stake].modifiers()
            end
        end
    end

    --Register vanilla stakes
    G.P_STAKES = {}
    SMODS.Stake {
        name = "White Stake",
        key = "white",
        unlocked_stake = "red",
        unlocked = true,
        applied_stakes = {},
        pos = { x = 0, y = 0 },
        sticker_pos = { x = 1, y = 0 },
        colour = G.C.WHITE,
        loc_txt = {}
    }
    SMODS.Stake {
        name = "Red Stake",
        key = "red",
        unlocked_stake = "green",
        applied_stakes = { "white" },
        pos = { x = 1, y = 0 },
        sticker_pos = { x = 2, y = 0 },
        modifiers = function()
            G.GAME.modifiers.no_blind_reward = G.GAME.modifiers.no_blind_reward or {}
            G.GAME.modifiers.no_blind_reward.Small = true
        end,
        colour = G.C.RED,
        loc_txt = {}
    }
    SMODS.Stake {
        name = "Green Stake",
        key = "green",
        unlocked_stake = "black",
        applied_stakes = { "red" },
        pos = { x = 2, y = 0 },
        sticker_pos = { x = 3, y = 0 },
        modifiers = function()
            G.GAME.modifiers.scaling = (G.GAME.modifiers.scaling or 1) + 1
        end,
        colour = G.C.GREEN,
        loc_txt = {}
    }
    SMODS.Stake {
        name = "Black Stake",
        key = "black",
        unlocked_stake = "blue",
        applied_stakes = { "green" },
        pos = { x = 4, y = 0 },
        sticker_pos = { x = 0, y = 1 },
        modifiers = function()
            G.GAME.modifiers.enable_eternals_in_shop = true
        end,
        colour = G.C.BLACK,
        loc_txt = {}
    }
    SMODS.Stake {
        name = "Blue Stake",
        key = "blue",
        unlocked_stake = "purple",
        applied_stakes = { "black" },
        pos = { x = 3, y = 0 },
        sticker_pos = { x = 4, y = 0 },
        modifiers = function()
            G.GAME.starting_params.discards = G.GAME.starting_params.discards - 1
        end,
        colour = G.C.BLUE,
        loc_txt = {}
    }
    SMODS.Stake {
        name = "Purple Stake",
        key = "purple",
        unlocked_stake = "orange",
        applied_stakes = { "blue" },
        pos = { x = 0, y = 1 },
        sticker_pos = { x = 1, y = 1 },
        modifiers = function()
            G.GAME.modifiers.scaling = (G.GAME.modifiers.scaling or 1) + 1
        end,
        colour = G.C.PURPLE,
        loc_txt = {}
    }
    SMODS.Stake {
        name = "Orange Stake",
        key = "orange",
        unlocked_stake = "gold",
        applied_stakes = { "purple" },
        pos = { x = 1, y = 1 },
        sticker_pos = { x = 2, y = 1 },
        modifiers = function()
            G.GAME.modifiers.enable_perishables_in_shop = true
        end,
        colour = G.C.ORANGE,
        loc_txt = {}
    }
    SMODS.Stake {
        name = "Gold Stake",
        key = "gold",
        applied_stakes = { "orange" },
        pos = { x = 2, y = 1 },
        sticker_pos = { x = 3, y = 1 },
        modifiers = function()
            G.GAME.modifiers.enable_rentals_in_shop = true
        end,
        colour = G.C.GOLD,
        shiny = true,
        loc_txt = {}
    }

    -------------------------------------------------------------------------------------------------
    ------- API CODE GameObject.Rarity
    -------------------------------------------------------------------------------------------------

    SMODS.Rarities = {}
    SMODS.Rarity = SMODS.GameObject:extend {
        obj_table = SMODS.Rarities,
        obj_buffer = {},
        set = 'Rarity',
        required_params = {
            'key',
        },
        badge_colour = HEX 'FFFFFF',
        default_weight = 0,
        inject = function(self)
            G.P_JOKER_RARITY_POOLS[self.key] = {}
            G.C.RARITY[self.key] = self.badge_colour
        end,
        process_loc_text = function(self)
            SMODS.process_loc_text(G.localization.misc.labels, "k_"..self.key:lower(), self.loc_txt, 'name')
            SMODS.process_loc_text(G.localization.misc.dictionary, "k_"..self.key:lower(), self.loc_txt, 'name')
        end,
        get_rarity_badge = function(self, rarity)
            local vanilla_rarity_keys = {localize('k_common'), localize('k_uncommon'), localize('k_rare'), localize('k_legendary')}
            if (vanilla_rarity_keys)[rarity] then 
                return vanilla_rarity_keys[rarity] --compat layer in case function gets the int of the rarity
            else 
                return localize("k_"..rarity:lower())
            end 
        end,
    }

    function SMODS.inject_rarity(object_type, rarity)
        if not object_type.rarities then 
            object_type.rarities = {}
            object_type.rarity_pools = {}
        end
        object_type.rarities[#object_type.rarities+1] = {
            key = rarity.key, 
            weight = type(rarity.pools[object_type.key]) == "table" and rarity.pools[object_type.key].weight or rarity.default_weight
        }
        for _, vv in ipairs(object_type.rarities) do
            local default_rarity_check = {["Common"] = 1, ["Uncommon"] = 2, ["Rare"] = 3, ["Legendary"] = 4}
            if default_rarity_check[vv.key] then
                object_type.rarity_pools[default_rarity_check[vv.key]] = {}
            else
                object_type.rarity_pools[vv.key] = {}
            end
        end
    end

    local game_init_game_object_ref = Game.init_game_object
    function Game:init_game_object()
        local t = game_init_game_object_ref(self)
        for _, v in pairs(SMODS.Rarities) do
            local key = v.key:lower() .. '_mod'
            t[key] = t[key] or 1
        end
        return t
    end

    SMODS.Rarity{
        key = "Common",
        loc_txt = {},
        default_weight = 0.7,
        badge_colour = HEX('009dff'),
        get_weight = function(self, weight, object_type)
            return weight
        end,
    }

    SMODS.Rarity{
        key = "Uncommon",
        loc_txt = {},
        default_weight = 0.25,
        badge_colour = HEX("4BC292"),
        get_weight = function(self, weight, object_type)
            return weight
        end,
    }

    SMODS.Rarity{
        key = "Rare",
        loc_txt = {},
        default_weight = 0.05,
        badge_colour = HEX('fe5f55'),
        get_weight = function(self, weight, object_type)
            return weight
        end,
    }

    SMODS.Rarity{
        key = "Legendary",
        loc_txt = {},
        default_weight = 0,
        badge_colour = HEX("b26cbb"),
        get_weight = function(self, weight, object_type)
            return weight
        end,
    }

    -------------------------------------------------------------------------------------------------
    ------- API CODE GameObject.ObjectType
    -------------------------------------------------------------------------------------------------

    SMODS.ObjectTypes = {}
    SMODS.ObjectType = SMODS.GameObject:extend {
        obj_table = SMODS.ObjectTypes,
        obj_buffer = {},
        set = 'ObjectType',
        required_params = {
            'key',
        },
        prefix_config = { key = false }, 
        inject = function(self)
            G.P_CENTER_POOLS[self.key] = G.P_CENTER_POOLS[self.key] or {}
            local injected_rarities = {}
            if self.rarities then
                self.rarity_pools = {}
                for _, v in ipairs(self.rarities) do
                    if not v.weight then v.weight = SMODS.Rarities[v.key].default_weight end
                    local default_rarity_check = {["Common"] = 1, ["Uncommon"] = 2, ["Rare"] = 3, ["Legendary"] = 4}
                    if default_rarity_check[v.key] then
                        self.rarity_pools[default_rarity_check[v.key]] = {}
                    else
                        self.rarity_pools[v.key] = {}
                    end
                    injected_rarities[v.key] = true
                end
            end
            for _, v in pairs(SMODS.Rarities) do
                if v.pools and v.pools[self.key] and not injected_rarities[v.key] then SMODS.inject_rarity(self, v) end
            end
        end,
        inject_card = function(self, center)
            if center.set ~= self.key then SMODS.insert_pool(G.P_CENTER_POOLS[self.key], center) end
            local default_rarity_check = {["Common"] = 1, ["Uncommon"] = 2, ["Rare"] = 3, ["Legendary"] = 4}
            if self.rarities and center.rarity and self.rarity_pools[default_rarity_check[center.rarity] or center.rarity] then
                SMODS.insert_pool(self.rarity_pools[default_rarity_check[center.rarity] or center.rarity], center)
            end
        end,
        delete_card = function(self, center)
            if center.set ~= self.key then SMODS.remove_pool(G.P_CENTER_POOLS[self.key], center.key) end
            local default_rarity_check = {["Common"] = 1, ["Uncommon"] = 2, ["Rare"] = 3, ["Legendary"] = 4}
            if self.rarities and center.rarity and self.rarity_pools[default_rarity_check[center.rarity] or center.rarity] then
                SMODS.remove_pool(self.rarity_pools[default_rarity_check[center.rarity] or center.rarity], center.key)
            end
        end,
    }

    SMODS.ObjectType{
        key = "Joker",
        rarities = {
            { key = "Common" },
            { key = "Uncommon" },
            { key = "Rare" },
        },
    }

    -------------------------------------------------------------------------------------------------
    ------- API CODE GameObject.ConsumableType
    -------------------------------------------------------------------------------------------------

    SMODS.ConsumableTypes = {}
    SMODS.ConsumableType = SMODS.ObjectType:extend {
        ctype_buffer = {},
        set = 'ConsumableType',
        required_params = {
            'key',
            'primary_colour',
            'secondary_colour',
        },
        prefix_config = { key = false },
        collection_rows = { 6, 6 },
        create_UIBox_your_collection = function(self)
            local type_buf = {}
            for _, v in ipairs(SMODS.ConsumableType.ctype_buffer) do
                if not v.no_collection and (not G.ACTIVE_MOD_UI or modsCollectionTally(G.P_CENTER_POOLS[v]).of > 0) then type_buf[#type_buf + 1] = v end
            end
            return SMODS.card_collection_UIBox(G.P_CENTER_POOLS[self.key], self.collection_rows, { back_func = #type_buf>3 and 'your_collection_consumables' or nil })
        end,
        register = function(self)
            SMODS.ConsumableType.super.register(self)
            if self:check_dependencies() then
                SMODS.ConsumableType.ctype_buffer[#SMODS.ConsumableType.ctype_buffer+1] = self.key
            end
        end,
        inject = function(self)
            SMODS.ObjectType.inject(self)
            SMODS.ConsumableTypes[self.key] = self
            G.localization.descriptions[self.key] = G.localization.descriptions[self.key] or {}
            G.C.SET[self.key] = self.primary_colour
            G.C.SECONDARY_SET[self.key] = self.secondary_colour
            G.FUNCS['your_collection_' .. string.lower(self.key) .. 's'] = function(e)
                G.SETTINGS.paused = true
                G.FUNCS.overlay_menu {
                    definition = self:create_UIBox_your_collection(),
                }
            end
        end,
        process_loc_text = function(self)
            SMODS.process_loc_text(G.localization.misc.dictionary, 'k_' .. string.lower(self.key), self.loc_txt, 'name')
            SMODS.process_loc_text(G.localization.misc.dictionary, 'b_' .. string.lower(self.key) .. '_cards',
                self.loc_txt, 'collection')
            SMODS.process_loc_text(G.localization.descriptions.Other, 'undiscovered_' .. string.lower(self.key),
                self.loc_txt, 'undiscovered')
        end,
    }

    SMODS.ConsumableType {
        key = 'Tarot',
        collection_rows = { 5, 6 },
        primary_colour = G.C.SET.Tarot,
        secondary_colour = G.C.SECONDARY_SET.Tarot,
        inject_card = function(self, center)
            SMODS.ObjectType.inject_card(self, center)
            SMODS.insert_pool(G.P_CENTER_POOLS['Tarot_Planet'], center)
        end,
        delete_card = function(self, center)
            SMODS.ObjectType.delete_card(self, center)
            SMODS.remove_pool(G.P_CENTER_POOLS['Tarot_Planet'], center.key)
        end,
        loc_txt = {},
    }
    SMODS.ConsumableType {
        key = 'Planet',
        collection_rows = { 6, 6 },
        primary_colour = G.C.SET.Planet,
        secondary_colour = G.C.SECONDARY_SET.Planet,
        inject_card = function(self, center)
            SMODS.ObjectType.inject_card(self, center)
            SMODS.insert_pool(G.P_CENTER_POOLS['Tarot_Planet'], center)
        end,
        delete_card = function(self, center)
            SMODS.ObjectType.delete_card(self, center)
            SMODS.remove_pool(G.P_CENTER_POOLS['Tarot_Planet'], center.key)
        end,
        loc_txt = {},
    }
    SMODS.ConsumableType {
        key = 'Spectral',
        collection_rows = { 4, 5 },
        primary_colour = G.C.SET.Spectral,
        secondary_colour = G.C.SECONDARY_SET.Spectral,
        loc_txt = {},
    }

    local game_init_game_object_ref = Game.init_game_object
    function Game:init_game_object()
        local t = game_init_game_object_ref(self)
        for _, v in pairs(SMODS.ConsumableTypes) do
            local key = v.key:lower() .. '_rate'
            t[key] = v.shop_rate or t[key] or 0
        end
        return t
    end

    -------------------------------------------------------------------------------------------------
    ----- API CODE GameObject.Center
    -------------------------------------------------------------------------------------------------

    SMODS.Centers = {}
    --- Shared class for center objects. Holds no default values; only register an object directly using this if it doesn't fit any subclass, creating one isn't justified and you know what you're doing.
    SMODS.Center = SMODS.GameObject:extend {
        obj_table = SMODS.Centers,
        obj_buffer = {},
        set = 'Center', -- For logging purposes | Subclasses should change this
        get_obj = function(self, key) return G.P_CENTERS[key] end,
        register = function(self)
            -- 0.9.8 defense
            self.name = self.name or self.key
            SMODS.Center.super.register(self)
        end,
        inject = function(self)
            G.P_CENTERS[self.key] = self
            if not self.omit then SMODS.insert_pool(G.P_CENTER_POOLS[self.set], self) end
            for k, v in pairs(SMODS.ObjectTypes) do
                -- Should "cards" be formatted as `{[<center key>] = true}` or {<center key>}?
                -- Changing "cards" and "pools" wouldn't be hard to do, just depends on preferred format
                if ((self.pools and self.pools[k]) or (v.cards and v.cards[self.key])) then
                    SMODS.ObjectTypes[k]:inject_card(self)
                end
            end
        end,
        delete = function(self)
            G.P_CENTERS[self.key] = nil
            SMODS.remove_pool(G.P_CENTER_POOLS[self.set], self.key)
            for k, v in pairs(SMODS.ObjectTypes) do
                if ((self.pools and self.pools[k]) or (v.cards and v.cards[self.key])) then
                    SMODS.ObjectTypes[k]:remove_card(self)
                end
            end
            local j
            for i, v in ipairs(self.obj_buffer) do
                if v == self.key then j = i end
            end
            if j then table.remove(self.obj_buffer, j) end
            self = nil
            return true
        end,
        generate_ui = function(self, info_queue, card, desc_nodes, specific_vars, full_UI_table)
            local target = {
                type = 'descriptions',
                key = self.key,
                set = self.set,
                nodes = desc_nodes,
                vars =
                    specific_vars or {}
            }
            local res = {}
            if self.loc_vars and type(self.loc_vars) == 'function' then
                res = self:loc_vars(info_queue, card) or {}
                target.vars = res.vars or target.vars
                target.key = res.key or target.key
                target.set = res.set or target.set
                target.scale = res.scale
                target.text_colour = res.text_colour
            end
            if desc_nodes == full_UI_table.main and not full_UI_table.name then
                full_UI_table.name = self.set == 'Enhanced' and 'temp_value' or localize { type = 'name', set = target.set, key = target.key, nodes = full_UI_table.name }
            elseif desc_nodes ~= full_UI_table.main and not desc_nodes.name and self.set ~= 'Enhanced' then
                desc_nodes.name = localize{type = 'name_text', key = target.key, set = target.set } 
            end
            if specific_vars and specific_vars.debuffed and not res.replace_debuff then
                target = { type = 'other', key = 'debuffed_' ..
                (specific_vars.playing_card and 'playing_card' or 'default'), nodes = desc_nodes }
            end
            if res.main_start then
                desc_nodes[#desc_nodes + 1] = res.main_start
            end
            localize(target)
            if res.main_end then
                desc_nodes[#desc_nodes + 1] = res.main_end
            end
            desc_nodes.background_colour = res.background_colour
        end
    }

    -------------------------------------------------------------------------------------------------
    ------- API CODE GameObject.Center.Joker
    -------------------------------------------------------------------------------------------------

    SMODS.Joker = SMODS.Center:extend {
        rarity = 1,
        unlocked = true,
        discovered = false,
        blueprint_compat = false,
        perishable_compat = true,
        eternal_compat = true,
        pos = { x = 0, y = 0 },
        cost = 3,
        config = {},
        set = 'Joker',
        atlas = 'Joker',
        class_prefix = 'j',
        required_params = {
            'key',
        },
        inject = function(self)
            -- call the parent function to ensure all pools are set
            SMODS.Center.inject(self)
            if self.taken_ownership and self.rarity_original == self.rarity then
                SMODS.remove_pool(G.P_JOKER_RARITY_POOLS[self.rarity_original], self.key)
                SMODS.insert_pool(G.P_JOKER_RARITY_POOLS[self.rarity], self, false)
            else
                SMODS.insert_pool(G.P_JOKER_RARITY_POOLS[self.rarity], self)
                local vanilla_rarities = {["Common"] = 1, ["Uncommon"] = 2, ["Rare"] = 3, ["Legendary"] = 4}
                if vanilla_rarities[self.rarity] then
                    SMODS.insert_pool(G.P_JOKER_RARITY_POOLS[vanilla_rarities[self.rarity]], self)
                end
            end
        end
    }

    -------------------------------------------------------------------------------------------------
    ------- API CODE GameObject.Center.Consumable
    -------------------------------------------------------------------------------------------------

    SMODS.Consumable = SMODS.Center:extend {
        unlocked = true,
        discovered = false,
        consumeable = true,
        pos = { x = 0, y = 0 },
        atlas = 'Tarot',
        legendaries = {},
        cost = 3,
        config = {},
        class_prefix = 'c',
        required_params = {
            'set',
            'key',
        },
        inject = function(self)
            SMODS.Center.inject(self)
            SMODS.insert_pool(G.P_CENTER_POOLS['Consumeables'], self)
            self.type = SMODS.ConsumableTypes[self.set]
            if self.hidden then
                self.soul_set = self.soul_set or 'Spectral'
                self.soul_rate = self.soul_rate or 0.003
                table.insert(self.legendaries, self)
            end
            if self.type and self.type.inject_card and type(self.type.inject_card) == 'function' then
                self.type:inject_card(self)
            end
        end,
        delete = function(self)
            if self.type and self.type.delete_card and type(self.type.delete_card) == 'function' then
                self.type:delete_card(self)
            end
            SMODS.remove_pool(G.P_CENTER_POOLS['Consumeables'], self.key)
            SMODS.Consumable.super.delete(self)
        end,
        loc_vars = function(self, info_queue)
            return {}
        end
    }
    
    SMODS.Tarot = SMODS.Consumable:extend {
        set = 'Tarot',
    }
    SMODS.Planet = SMODS.Consumable:extend {
        set = 'Planet',
        atlas = 'Planet',
    }
    SMODS.Spectral = SMODS.Consumable:extend {
        set = 'Spectral',
        atlas = 'Spectral',
        cost = 4,
    }


    -------------------------------------------------------------------------------------------------
    ------- API CODE GameObject.Center.Voucher
    -------------------------------------------------------------------------------------------------

    SMODS.Voucher = SMODS.Center:extend {
        set = 'Voucher',
        cost = 10,
        atlas = 'Voucher',
        discovered = false,
        unlocked = true,
        available = true,
        pos = { x = 0, y = 0 },
        config = {},
        class_prefix = 'v',
        required_params = {
            'key',
        }
    }

    -------------------------------------------------------------------------------------------------
    ------- API CODE GameObject.Center.Back
    -------------------------------------------------------------------------------------------------

    SMODS.Back = SMODS.Center:extend {
        set = 'Back',
        discovered = false,
        unlocked = true,
        atlas = 'centers',
        pos = { x = 0, y = 0 },
        config = {},
        omit = false,
        unlock_condition = {},
        stake = 1,
        class_prefix = 'b',
        required_params = {
            'key',
        },
        register = function(self)
            -- game expects a name, so ensure it's set
            self.name = self.name or self.key
            SMODS.Back.super.register(self)
        end
    }

    -- set the correct stake level for unlocks when injected (spares me from completely overwriting the unlock checks)
    local function stake_mod(stake)
        return {
            inject = function(self)
                self.unlock_condition.stake = SMODS.Stakes[stake].stake_level
                SMODS.Back.inject(self)
            end
        }
    end
    SMODS.Back:take_ownership('zodiac', stake_mod('stake_red'))
    SMODS.Back:take_ownership('painted', stake_mod('stake_green'))
    SMODS.Back:take_ownership('anaglyph', stake_mod('stake_black'))
    SMODS.Back:take_ownership('plasma', stake_mod('stake_blue'))
    SMODS.Back:take_ownership('erratic', stake_mod('stake_orange'))

    -------------------------------------------------------------------------------------------------
    ----- API CODE GameObject.Center.Booster
    -------------------------------------------------------------------------------------------------

    SMODS.OPENED_BOOSTER = nil
    SMODS.Booster = SMODS.Center:extend {
        required_params = {
            'key',
        },
        class_prefix = 'p',
        set = "Booster",
        atlas = "Booster",
        pos = {x = 0, y = 0},
        loc_txt = {},
        discovered = false,
        weight = 1,
        cost = 4,
        config = {extra = 3, choose = 1},
        process_loc_text = function(self)
            SMODS.process_loc_text(G.localization.descriptions.Other, self.key, self.loc_txt)
            SMODS.process_loc_text(G.localization.misc.dictionary, 'k_booster_group_'..self.key, self.loc_txt, 'group_name')
        end,
        loc_vars = function(self, info_queue, card)
            return { vars = {card.ability.choose, card.ability.extra} }
        end,
        generate_ui = function(self, info_queue, card, desc_nodes, specific_vars, full_UI_table)
            local target = {
                type = 'other',
                key = self.key,
                nodes = desc_nodes,
                vars = {}
            }
            local res = {}
            if self.loc_vars and type(self.loc_vars) == 'function' then
                res = self:loc_vars(info_queue, card) or {}
                target.vars = res.vars or target.vars
                target.key = res.key or target.key
                target.scale = res.scale
                target.text_colour = res.text_colour
            end
            if desc_nodes == full_UI_table.main and not full_UI_table.name then
                full_UI_table.name = localize{type = 'name', set = 'Other', key = target.key, nodes = full_UI_table.name}
            elseif desc_nodes ~= full_UI_table.main and not desc_nodes.name then
                desc_nodes.name = localize{type = 'name_text', key = target.key, set = 'Other' } 
            end
            localize(target)
            desc_nodes.background_colour = res.background_colour
        end,
        --[[
        create_card = function(self, card)
            -- Example
            -- return {set = "Joker", area = G.pack_cards, skip_materialize = true, soulable = true, key_append = "buf"}
        end,
        --]]
        update_pack = function(self, dt)
            if G.buttons then G.buttons:remove(); G.buttons = nil end
            if G.shop then G.shop.alignment.offset.y = G.ROOM.T.y+11 end
        
            if not G.STATE_COMPLETE then
                G.STATE_COMPLETE = true
                G.CONTROLLER.interrupt.focus = true
                G.E_MANAGER:add_event(Event({
                    trigger = 'immediate',
                    func = function()
                        if self.particles and type(self.particles) == "function" then self:particles() end
                        G.booster_pack = UIBox{
                            definition = self:create_UIBox(),
                            config = {align="tmi", offset = {x=0,y=G.ROOM.T.y + 9}, major = G.hand, bond = 'Weak'}
                        }
                        G.booster_pack.alignment.offset.y = -2.2
                        G.ROOM.jiggle = G.ROOM.jiggle + 3
                        self:ease_background_colour()
                        G.E_MANAGER:add_event(Event({
                            trigger = 'immediate',
                            func = function()
                                if self.draw_hand == true then G.FUNCS.draw_from_deck_to_hand() end
        
                                G.E_MANAGER:add_event(Event({
                                    trigger = 'after',
                                    delay = 0.5,
                                    func = function()
                                        G.CONTROLLER:recall_cardarea_focus('pack_cards')
                                        return true
                                    end}))
                                return true
                            end
                        }))  
                        return true
                    end
                }))  
            end
        end,
        ease_background_colour = function(self)
            ease_colour(G.C.DYN_UI.MAIN, G.C.FILTER)
            ease_background_colour{new_colour = G.C.FILTER, special_colour = G.C.BLACK, contrast = 2}
        end,
        create_UIBox = function(self)
            local _size = SMODS.OPENED_BOOSTER.ability.extra
            G.pack_cards = CardArea(
                G.ROOM.T.x + 9 + G.hand.T.x, G.hand.T.y,
                math.max(1,math.min(_size,5))*G.CARD_W*1.1,
                1.05*G.CARD_H, 
                {card_limit = _size, type = 'consumeable', highlight_limit = 1})

            local t = {n=G.UIT.ROOT, config = {align = 'tm', r = 0.15, colour = G.C.CLEAR, padding = 0.15}, nodes={
                {n=G.UIT.R, config={align = "cl", colour = G.C.CLEAR,r=0.15, padding = 0.1, minh = 2, shadow = true}, nodes={
                    {n=G.UIT.R, config={align = "cm"}, nodes={
                    {n=G.UIT.C, config={align = "cm", padding = 0.1}, nodes={
                        {n=G.UIT.C, config={align = "cm", r=0.2, colour = G.C.CLEAR, shadow = true}, nodes={
                            {n=G.UIT.O, config={object = G.pack_cards}},}}}}}},
                {n=G.UIT.R, config={align = "cm"}, nodes={}},
                {n=G.UIT.R, config={align = "tm"}, nodes={
                    {n=G.UIT.C,config={align = "tm", padding = 0.05, minw = 2.4}, nodes={}},
                    {n=G.UIT.C,config={align = "tm", padding = 0.05}, nodes={
                        UIBox_dyn_container({
                            {n=G.UIT.C, config={align = "cm", padding = 0.05, minw = 4}, nodes={
                                {n=G.UIT.R,config={align = "bm", padding = 0.05}, nodes={
                                    {n=G.UIT.O, config={object = DynaText({string = localize(self.group_key or ('k_booster_group_'..self.key)), colours = {G.C.WHITE},shadow = true, rotate = true, bump = true, spacing =2, scale = 0.7, maxw = 4, pop_in = 0.5})}}}},
                                {n=G.UIT.R,config={align = "bm", padding = 0.05}, nodes={
                                    {n=G.UIT.O, config={object = DynaText({string = {localize('k_choose')..' '}, colours = {G.C.WHITE},shadow = true, rotate = true, bump = true, spacing =2, scale = 0.5, pop_in = 0.7})}},
                                    {n=G.UIT.O, config={object = DynaText({string = {{ref_table = G.GAME, ref_value = 'pack_choices'}}, colours = {G.C.WHITE},shadow = true, rotate = true, bump = true, spacing =2, scale = 0.5, pop_in = 0.7})}}}},}}
                        }),}},
                    {n=G.UIT.C,config={align = "tm", padding = 0.05, minw = 2.4}, nodes={
                        {n=G.UIT.R,config={minh =0.2}, nodes={}},
                        {n=G.UIT.R,config={align = "tm",padding = 0.2, minh = 1.2, minw = 1.8, r=0.15,colour = G.C.GREY, one_press = true, button = 'skip_booster', hover = true,shadow = true, func = 'can_skip_booster'}, nodes = {
                            {n=G.UIT.T, config={text = localize('b_skip'), scale = 0.5, colour = G.C.WHITE, shadow = true, focus_args = {button = 'y', orientation = 'bm'}, func = 'set_button_pip'}}}}}}}}}}}}
            return t
        end,
        take_ownership_by_kind = function(self, kind, obj, silent)
            for k, v in ipairs(G.P_CENTER_POOLS.Booster) do
                if v.set == self.set and v.kind and v.kind == kind then
                    self:take_ownership(v.key, obj, silent)
                end
            end
        end
    }

    local pack_loc_vars = function(self, info_queue, card)
        local cfg = (card and card.ability) or self.config
        return {
            vars = { cfg.choose, cfg.extra },
            key = self.key:sub(1, -3),
        }
    end
    SMODS.Booster:take_ownership_by_kind('Arcana', {
        group_key = "k_arcana_pack",
        draw_hand = true,
        update_pack = SMODS.Booster.update_pack,
        ease_background_colour = function(self) ease_background_colour_blind(G.STATES.TAROT_PACK) end,
        create_UIBox = function(self) return create_UIBox_arcana_pack() end,
        particles = function(self)
            G.booster_pack_sparkles = Particles(1, 1, 0,0, {
                timer = 0.015,
                scale = 0.2,
                initialize = true,
                lifespan = 1,
                speed = 1.1,
                padding = -1,
                attach = G.ROOM_ATTACH,
                colours = {G.C.WHITE, lighten(G.C.PURPLE, 0.4), lighten(G.C.PURPLE, 0.2), lighten(G.C.GOLD, 0.2)},
                fill = true
            })
            G.booster_pack_sparkles.fade_alpha = 1
            G.booster_pack_sparkles:fade(1, 0)
        end,
        create_card = function(self, card, i)
            local _card
            if G.GAME.used_vouchers.v_omen_globe and pseudorandom('omen_globe') > 0.8 then
                _card = {set = "Spectral", area = G.pack_cards, skip_materialize = true, soulable = true, key_append = "ar2"}
            else
                _card = {set = "Tarot", area = G.pack_cards, skip_materialize = true, soulable = true, key_append = "ar1"}
            end
            return _card
        end,
        loc_vars = pack_loc_vars,
    })

    SMODS.Booster:take_ownership_by_kind('Celestial', {
        group_key = "k_celestial_pack",
        update_pack = SMODS.Booster.update_pack,
        ease_background_colour = function(self) ease_background_colour_blind(G.STATES.PLANET_PACK) end,
        create_UIBox = function(self) return create_UIBox_celestial_pack() end,
        particles = function(self)
            G.booster_pack_stars = Particles(1, 1, 0,0, {
                timer = 0.07,
                scale = 0.1,
                initialize = true,
                lifespan = 15,
                speed = 0.1,
                padding = -4,
                attach = G.ROOM_ATTACH,
                colours = {G.C.WHITE, HEX('a7d6e0'), HEX('fddca0')},
                fill = true
            })
            G.booster_pack_meteors = Particles(1, 1, 0,0, {
                timer = 2,
                scale = 0.05,
                lifespan = 1.5,
                speed = 4,
                attach = G.ROOM_ATTACH,
                colours = {G.C.WHITE},
                fill = true
            })
        end,
        create_card = function(self, card, i)
            local _card
            if G.GAME.used_vouchers.v_telescope and i == 1 then
                local _planet, _hand, _tally = nil, nil, 0
                for k, v in ipairs(G.handlist) do
                    if G.GAME.hands[v].visible and G.GAME.hands[v].played > _tally then
                        _hand = v
                        _tally = G.GAME.hands[v].played
                    end
                end
                if _hand then
                    for k, v in pairs(G.P_CENTER_POOLS.Planet) do
                        if v.config.hand_type == _hand then
                            _planet = v.key
                        end
                    end
                end
                _card = {set = "Planet", area = G.pack_cards, skip_materialize = true, soulable = true, key = _planet, key_append = "pl1"}
            else
                _card = {set = "Planet", area = G.pack_cards, skip_materialize = true, soulable = true, key_append = "pl1"}
            end
            return _card
        end,
        loc_vars = pack_loc_vars,
    })

    SMODS.Booster:take_ownership_by_kind('Spectral', {
        group_key = "k_spectral_pack",
        draw_hand = true,
        update_pack = SMODS.Booster.update_pack,
        ease_background_colour = function(self) ease_background_colour_blind(G.STATES.SPECTRAL_PACK) end,
        create_UIBox = function(self) return create_UIBox_spectral_pack() end,
        particles = function(self)
            G.booster_pack_sparkles = Particles(1, 1, 0,0, {
                timer = 0.015,
                scale = 0.1,
                initialize = true,
                lifespan = 3,
                speed = 0.2,
                padding = -1,
                attach = G.ROOM_ATTACH,
                colours = {G.C.WHITE, lighten(G.C.GOLD, 0.2)},
                fill = true
            })
            G.booster_pack_sparkles.fade_alpha = 1
            G.booster_pack_sparkles:fade(1, 0)
        end,
        create_card = function(self, card, i)
            return {set = "Spectral", area = G.pack_cards, skip_materialize = true, soulable = true, key_append = "spe"}
        end,
        loc_vars = pack_loc_vars,
    })

    SMODS.Booster:take_ownership_by_kind('Standard', {
        group_key = "k_standard_pack",
        update_pack = SMODS.Booster.update_pack,
        ease_background_colour = function(self) ease_background_colour_blind(G.STATES.STANDARD_PACK) end,
        create_UIBox = function(self) return create_UIBox_standard_pack() end,
        particles = function(self)
            G.booster_pack_sparkles = Particles(1, 1, 0,0, {
                timer = 0.015,
                scale = 0.3,
                initialize = true,
                lifespan = 3,
                speed = 0.2,
                padding = -1,
                attach = G.ROOM_ATTACH,
                colours = {G.C.BLACK, G.C.RED},
                fill = true
            })
            G.booster_pack_sparkles.fade_alpha = 1
            G.booster_pack_sparkles:fade(1, 0)
        end,
        create_card = function(self, card, i)
            local _edition = poll_edition('standard_edition'..G.GAME.round_resets.ante, 2, true)
            local _seal = SMODS.poll_seal({mod = 10})
            return {set = (pseudorandom(pseudoseed('stdset'..G.GAME.round_resets.ante)) > 0.6) and "Enhanced" or "Base", edition = _edition, seal = _seal, area = G.pack_cards, skip_materialize = true, soulable = true, key_append = "sta"}
        end,
        loc_vars = pack_loc_vars,
    })

    SMODS.Booster:take_ownership_by_kind('Buffoon', {
        group_key = "k_buffoon_pack",
        update_pack = SMODS.Booster.update_pack,
        ease_background_colour = function(self) ease_background_colour_blind(G.STATES.BUFFOON_PACK) end,
        create_UIBox = function(self) return create_UIBox_buffoon_pack() end,
        create_card = function(self, card)
            return {set = "Joker", area = G.pack_cards, skip_materialize = true, soulable = true, key_append = "buf"}
        end,
        loc_vars = pack_loc_vars,
    })

    -------------------------------------------------------------------------------------------------
    ----- API CODE GameObject.UndiscoveredSprite
    -------------------------------------------------------------------------------------------------

    SMODS.UndiscoveredSprites = {}
    SMODS.UndiscoveredSprite = SMODS.GameObject:extend {
        obj_buffer = {},
        obj_table = SMODS.UndiscoveredSprites,
        set = 'Undiscovered Sprite',
        -- this is more consistent and allows for extension
        process_loc_text = function() end,
        inject = function() end,
        prefix_config = { key = false },
        required_params = {
            'key',
            'atlas',
            'pos',
        }
    }
    SMODS.UndiscoveredSprite { key = 'Joker', atlas = 'Joker', pos = G.j_undiscovered.pos }
    SMODS.UndiscoveredSprite { key = 'Edition', atlas = 'Joker', pos = G.j_undiscovered.pos }
    SMODS.UndiscoveredSprite { key = 'Tarot', atlas = 'Tarot', pos = G.t_undiscovered.pos }
    SMODS.UndiscoveredSprite { key = 'Planet', atlas = 'Tarot', pos = G.p_undiscovered.pos }
    SMODS.UndiscoveredSprite { key = 'Spectral', atlas = 'Tarot', pos = G.s_undiscovered.pos }
    SMODS.UndiscoveredSprite { key = 'Voucher', atlas = 'Voucher', pos = G.v_undiscovered.pos }
    SMODS.UndiscoveredSprite { key = 'Booster', atlas = 'Booster', pos = G.booster_undiscovered.pos }

    -------------------------------------------------------------------------------------------------
    ----- API CODE GameObject.Blind
    -------------------------------------------------------------------------------------------------

    SMODS.Blinds = {}
    SMODS.Blind = SMODS.GameObject:extend {
        obj_table = SMODS.Blinds,
        obj_buffer = {},
        class_prefix = 'bl',
        debuff = {},
        vars = {},
        dollars = 5,
        mult = 2,
        atlas = 'blind_chips',
        discovered = false,
        pos = { x = 0, y = 0 },
        required_params = {
            'key',
        },
        set = 'Blind',
        get_obj = function(self, key) return G.P_BLINDS[key] end,
        register = function(self)
            self.name = self.name or self.key
            SMODS.Blind.super.register(self)
        end,
        inject = function(self, i)
            -- no pools to query length of, so we assign order manually
            if not self.taken_ownership then
                self.order = 30 + i
            end
            G.P_BLINDS[self.key] = self
        end
    }
    SMODS.Blind:take_ownership('eye', {
        set_blind = function(self, reset, silent)
            if not reset then
                G.GAME.blind.hands = {}
                for _, v in ipairs(G.handlist) do
                    G.GAME.blind.hands[v] = false
                end
            end
        end
    })
    SMODS.Blind:take_ownership('wheel', {
        loc_vars = function(self)
            return { vars = { G.GAME.probabilities.normal } }
        end,
        collection_loc_vars = function(self)
            return { vars = { '1' }}
        end,
        process_loc_text = function(self)
            local text = G.localization.descriptions.Blind[self.key].text[1]
            if string.sub(text, 1, 3) ~= '#1#' then
                G.localization.descriptions.Blind[self.key].text[1] = "#1#"..text
            end
            SMODS.Blind.process_loc_text(self)
        end,
        get_loc_debuff_text = function() return G.GAME.blind.loc_debuff_text end,
    })

    -------------------------------------------------------------------------------------------------
    ----- API CODE GameObject.Seal
    -------------------------------------------------------------------------------------------------

    SMODS.Seals = {}
    SMODS.Seal = SMODS.GameObject:extend {
        obj_table = SMODS.Seals,
        obj_buffer = {},
        rng_buffer = { 'Purple', 'Gold', 'Blue', 'Red' },
        badge_to_key = {},
        set = 'Seal',
        atlas = 'centers',
        pos = { x = 0, y = 0 },
        discovered = false,
        badge_colour = HEX('FFFFFF'),
        required_params = {
            'key',
            'pos',
        },
        inject = function(self)
            G.P_SEALS[self.key] = self
            G.shared_seals[self.key] = Sprite(0, 0, G.CARD_W, G.CARD_H,
                G.ASSET_ATLAS[self.atlas] or G.ASSET_ATLAS['centers'], self.pos)
            self.badge_to_key[self.key:lower() .. '_seal'] = self.key
            SMODS.insert_pool(G.P_CENTER_POOLS[self.set], self)
            self.rng_buffer[#self.rng_buffer + 1] = self.key
        end,
        process_loc_text = function(self)
            SMODS.process_loc_text(G.localization.descriptions.Other, self.key:lower() .. '_seal', self.loc_txt)
            SMODS.process_loc_text(G.localization.misc.labels, self.key:lower() .. '_seal', self.loc_txt, 'label')
        end,
        get_obj = function(self, key) return G.P_SEALS[key] end
    }

    -------------------------------------------------------------------------------------------------
    ----- API CODE GameObject.Suit
    -------------------------------------------------------------------------------------------------

    SMODS.inject_p_card = function(suit, rank)
        G.P_CARDS[suit.card_key .. '_' .. rank.card_key] = {
            name = rank.key .. ' of ' .. suit.key,
            value = rank.key,
            suit = suit.key,
            pos = { x = rank.pos.x, y = rank.suit_map[suit.key] or suit.pos.y },
            lc_atlas = rank.suit_map[suit.key] and rank.lc_atlas or suit.lc_atlas,
            hc_atlas = rank.suit_map[suit.key] and rank.hc_atlas or suit.hc_atlas,
        }
    end
    SMODS.remove_p_card = function(suit, rank)
        G.P_CARDS[suit.card_key .. '_' .. rank.card_key] =  nil
    end

    SMODS.Suits = {}
    SMODS.Suit = SMODS.GameObject:extend {
        obj_table = SMODS.Suits,
        obj_buffer = {},
        used_card_keys = {},
        set = 'Suit',
        required_params = {
            'key',
            'card_key',
            'pos',
            'ui_pos',
        },
        hc_atlas = 'cards_2',
        lc_atlas = 'cards_1',
        hc_ui_atlas = 'ui_2',
        lc_ui_atlas = 'ui_1',
        hc_colour = HEX '000000',
        lc_colour = HEX '000000',
        max_nominal = {
            value = 0,
        },
        register = function(self)
            -- 0.9.8 compat
            self.name = self.name or self.key
            if self.used_card_keys[self.card_key] then
                sendWarnMessage(('Tried to use duplicate card key %s, aborting registration'):format(self.card_key), self.set)
                return
            end
            self.used_card_keys[self.card_key] = true
            self.max_nominal.value = self.max_nominal.value + 0.01
            self.suit_nominal = self.max_nominal.value
            SMODS.Suit.super.register(self)
        end,
        inject = function(self)
            for _, rank in pairs(SMODS.Ranks) do
                SMODS.inject_p_card(self, rank)
            end
        end,
        delete = function(self)
            local i
            for j, v in ipairs(self.obj_buffer) do
                if v == self.key then i = j end
            end
            for _, rank in pairs(SMODS.Ranks) do
                SMODS.remove_p_card(self, rank)
            end
            self.used_card_keys[self.card_key] = nil
            table.remove(self.obj_buffer, i)
        end,
        process_loc_text = function(self)
            -- empty loc_txt indicates there are existing values that shouldn't be changed
            SMODS.process_loc_text(G.localization.misc.suits_plural, self.key, self.loc_txt, 'plural')
            SMODS.process_loc_text(G.localization.misc.suits_singular, self.key, self.loc_txt, 'singular')
            if not self.keep_base_colours then
                if type(self.lc_colour) == 'string' then self.lc_colour = HEX(self.lc_colour) end
                if type(self.hc_colour) == 'string' then self.hc_colour = HEX(self.hc_colour) end
                G.C.SO_1[self.key] = self.lc_colour
                G.C.SO_2[self.key] = self.hc_colour
                G.C.SUITS[self.key] = G.C["SO_" .. (G.SETTINGS.colourblind_option and 2 or 1)][self.key]
            end
        end,
    }
    SMODS.Suit {
        key = 'Diamonds',
        card_key = 'D',
        pos = { y = 2 },
        ui_pos = { x = 1, y = 1 },
        keep_base_colours = true,
    }
    SMODS.Suit {
        key = 'Clubs',
        card_key = 'C',
        pos = { y = 1 },
        ui_pos = { x = 2, y = 1 },
        keep_base_colours = true,
    }
    SMODS.Suit {
        key = 'Hearts',
        card_key = 'H',
        pos = { y = 0 },
        ui_pos = { x = 0, y = 1 },
        keep_base_colours = true,
    }
    SMODS.Suit {
        key = 'Spades',
        card_key = 'S',
        pos = { y = 3 },
        ui_pos = { x = 3, y = 1 },
        keep_base_colours = true,
    }
    -------------------------------------------------------------------------------------------------
    ----- API CODE GameObject.Rank
    -------------------------------------------------------------------------------------------------

    SMODS.Ranks = {}
    SMODS.Rank = SMODS.GameObject:extend {
        obj_table = SMODS.Ranks,
        obj_buffer = {},
        used_card_keys = {},
        set = 'Rank',
        required_params = {
            'key',
            'pos',
            'nominal',
        },
        hc_atlas = 'cards_2',
        lc_atlas = 'cards_1',
        strength_effect = {
            fixed = 1,
            random = false,
            ignore = false
        },
        next = {},
        straight_edge = false,
        -- TODO we need a better system for what this is doing.
        -- We should allow setting a playing card's atlas and position to any values,
        -- and we should also ensure that it's easy to create an atlas with a standard
        -- arrangement: x and y set according to rank and suit.

        -- Currently suit_map does the following:
        -- suit_map forces a playing card's atlas to be rank.hc_atlas/lc_atlas,
        -- and not the atlas defined on the suit of the playing card;
        -- additionally pos.y is set according to the corresponding value in the
        -- suit_map
        suit_map = {
            Hearts = 0,
            Clubs = 1,
            Diamonds = 2,
            Spades = 3,
        },
        max_id = {
            value = 1,
        },
        register = function(self)
            if self.used_card_keys[self.card_key] then
                sendWarnMessage(('Tried to use duplicate card key %s, aborting registration'):format(self.card_key), self.set)
                return
            end
            self.used_card_keys[self.card_key] = true
            self.max_id.value = self.max_id.value + 1
            self.id = self.max_id.value
            self.shorthand = self.shorthand or self.key
            self.sort_nominal = self.nominal + (self.face_nominal or 0)
            if self:check_dependencies() and not self.obj_table[self.key] then
                self.obj_table[self.key] = self
                local j
                -- keep buffer sorted in ascending nominal order
                for i = 1, #self.obj_buffer - 1 do
                    if self.obj_table[self.obj_buffer[i]].sort_nominal > self.sort_nominal then
                        j = i
                        break
                    end
                end
                if j then
                    table.insert(self.obj_buffer, j, self.key)
                else
                    table.insert(self.obj_buffer, self.key)
                end
            end
        end,
        process_loc_text = function(self)
            SMODS.process_loc_text(G.localization.misc.ranks, self.key, self.loc_txt, 'name')
        end,
        inject = function(self)
            for _, suit in pairs(SMODS.Suits) do
                SMODS.inject_p_card(suit, self)
            end
        end,
        delete = function(self)
            local i
            for j, v in ipairs(self.obj_buffer) do
                if v == self.key then i = j end
            end
            for _, suit in pairs(SMODS.Suits) do
                SMODS.remove_p_card(suit, self)
            end
            self.used_card_keys[self.card_key] = nil
            table.remove(self.obj_buffer, i)
        end
    }
    for _, v in ipairs({ 2, 3, 4, 5, 6, 7, 8, 9 }) do
        SMODS.Rank {
            key = v .. '',
            card_key = v .. '',
            pos = { x = v - 2 },
            nominal = v,
            next = { (v + 1) .. '' },
        }
    end
    SMODS.Rank {
        key = '10',
        card_key = 'T',
        pos = { x = 8 },
        nominal = 10,
        next = { 'Jack' },
    }
    SMODS.Rank {
        key = 'Jack',
        card_key = 'J',
        pos = { x = 9 },
        nominal = 10,
        face_nominal = 0.1,
        face = true,
        shorthand = 'J',
        next = { 'Queen' },
    }
    SMODS.Rank {
        key = 'Queen',
        card_key = 'Q',
        pos = { x = 10 },
        nominal = 10,
        face_nominal = 0.2,
        face = true,
        shorthand = 'Q',
        next = { 'King' },
    }
    SMODS.Rank {
        key = 'King',
        card_key = 'K',
        pos = { x = 11 },
        nominal = 10,
        face_nominal = 0.3,
        face = true,
        shorthand = 'K',
        next = { 'Ace' },
    }
    SMODS.Rank {
        key = 'Ace',
        card_key = 'A',
        pos = { x = 12 },
        nominal = 11,
        face_nominal = 0.4,
        shorthand = 'A',
        straight_edge = true,
        next = { '2' },
    }
    -- make consumable effects compatible with added suits
    -- TODO put this in utils.lua
    local function juice_flip(used_tarot)
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.4,
            func = function()
                play_sound('tarot1')
                used_tarot:juice_up(0.3, 0.5)
                return true
            end
        }))
        for i = 1, #G.hand.cards do
            local percent = 1.15 - (i - 0.999) / (#G.hand.cards - 0.998) * 0.3
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.15,
                func = function()
                    G.hand.cards[i]:flip(); play_sound('card1', percent); G.hand.cards[i]:juice_up(0.3, 0.3); return true
                end
            }))
        end
    end
    SMODS.Consumable:take_ownership('strength', {
        use = function(self, card, area, copier)
            local used_tarot = copier or card
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.4,
                func = function()
                    play_sound('tarot1')
                    used_tarot:juice_up(0.3, 0.5)
                    return true
                end
            }))
            for i = 1, #G.hand.highlighted do
                local percent = 1.15 - (i - 0.999) / (#G.hand.highlighted - 0.998) * 0.3
                G.E_MANAGER:add_event(Event({
                    trigger = 'after',
                    delay = 0.15,
                    func = function()
                        G.hand.highlighted[i]:flip(); play_sound('card1', percent); G.hand.highlighted[i]:juice_up(0.3,
                            0.3); return true
                    end
                }))
            end
            delay(0.2)
            for i = 1, #G.hand.highlighted do
                G.E_MANAGER:add_event(Event({
                    trigger = 'after',
                    delay = 0.1,
                    func = function()
                        local _card = G.hand.highlighted[i]
                        local rank_data = SMODS.Ranks[_card.base.value]
                        local behavior = rank_data.strength_effect or { fixed = 1, ignore = false, random = false }
                        local new_rank
                        if behavior.ignore or not next(rank_data.next) then
                            return true
                        elseif behavior.random then
                            -- TODO doesn't respect in_pool
                            new_rank = pseudorandom_element(rank_data.next, pseudoseed('strength'))
                        else
                            local ii = (behavior.fixed and rank_data.next[behavior.fixed]) and behavior.fixed or 1
                            new_rank = rank_data.next[ii]
                        end
                        assert(SMODS.change_base(_card, nil, new_rank))
                        return true
                    end
                }))
            end
            for i = 1, #G.hand.highlighted do
                local percent = 0.85 + (i - 0.999) / (#G.hand.highlighted - 0.998) * 0.3
                G.E_MANAGER:add_event(Event({
                    trigger = 'after',
                    delay = 0.15,
                    func = function()
                        G.hand.highlighted[i]:flip(); play_sound('tarot2', percent, 0.6); G.hand.highlighted[i]
                            :juice_up(
                                0.3, 0.3); return true
                    end
                }))
            end
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.2,
                func = function()
                    G.hand:unhighlight_all(); return true
                end
            }))
            delay(0.5)
        end,
    })
    SMODS.Consumable:take_ownership('sigil', {
        use = function(self, card, area, copier)
            local used_tarot = copier or card
            juice_flip(used_tarot)
            local _suit = pseudorandom_element(SMODS.Suits, pseudoseed('sigil'))
            for i = 1, #G.hand.cards do
                G.E_MANAGER:add_event(Event({
                    func = function()
                        local _card = G.hand.cards[i]
                        assert(SMODS.change_base(_card, _suit.key))
                        return true
                    end
                }))
            end
            for i = 1, #G.hand.cards do
                local percent = 0.85 + (i - 0.999) / (#G.hand.cards - 0.998) * 0.3
                G.E_MANAGER:add_event(Event({
                    trigger = 'after',
                    delay = 0.15,
                    func = function()
                        G.hand.cards[i]:flip(); play_sound('tarot2', percent, 0.6); G.hand.cards[i]:juice_up(0.3, 0.3); return true
                    end
                }))
            end
            delay(0.5)
        end,
    })
    SMODS.Consumable:take_ownership('ouija', {
        use = function(self, card, area, copier)
            local used_tarot = copier or card
            juice_flip(used_tarot)
            local _rank = pseudorandom_element(SMODS.Ranks, pseudoseed('ouija'))
            for i = 1, #G.hand.cards do
                G.E_MANAGER:add_event(Event({
                    func = function()
                        local _card = G.hand.cards[i]
                        assert(SMODS.change_base(_card, nil, _rank.key))
                        return true
                    end
                }))
            end
            G.hand:change_size(-1)
            for i = 1, #G.hand.cards do
                local percent = 0.85 + (i - 0.999) / (#G.hand.cards - 0.998) * 0.3
                G.E_MANAGER:add_event(Event({
                    trigger = 'after',
                    delay = 0.15,
                    func = function()
                        G.hand.cards[i]:flip(); play_sound('tarot2', percent, 0.6); G.hand.cards[i]:juice_up(0.3, 0.3); return true
                    end
                }))
            end
            delay(0.5)
        end,
    })
    local function random_destroy(used_tarot)
        local destroyed_cards = {}
        destroyed_cards[#destroyed_cards + 1] = pseudorandom_element(G.hand.cards, pseudoseed('random_destroy'))
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.4,
            func = function()
                play_sound('tarot1')
                used_tarot:juice_up(0.3, 0.5)
                return true
            end
        }))
        G.E_MANAGER:add_event(Event({
            trigger = 'after',
            delay = 0.1,
            func = function()
                for i = #destroyed_cards, 1, -1 do
                    local card = destroyed_cards[i]
                    if card.ability.name == 'Glass Card' then
                        card:shatter()
                    else
                        card:start_dissolve(nil, i ~= #destroyed_cards)
                    end
                end
                return true
            end
        }))
        return destroyed_cards
    end
    SMODS.Consumable:take_ownership('grim', {
        use = function(self, card, area, copier)
            local used_tarot = copier or card
            local destroyed_cards = random_destroy(used_tarot)
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.7,
                func = function()
                    local cards = {}
                    for i = 1, card.ability.extra do
                        cards[i] = true
                        -- TODO preserve suit vanilla RNG
                        local _suit, _rank =
                            pseudorandom_element(SMODS.Suits, pseudoseed('grim_create')).card_key, 'A'
                        local cen_pool = {}
                        for k, v in pairs(G.P_CENTER_POOLS["Enhanced"]) do
                            if v.key ~= 'm_stone' and not v.overrides_base_rank then
                                cen_pool[#cen_pool + 1] = v
                            end
                        end
                        create_playing_card({
                            front = G.P_CARDS[_suit .. '_' .. _rank],
                            center = pseudorandom_element(cen_pool, pseudoseed('spe_card'))
                        }, G.hand, nil, i ~= 1, { G.C.SECONDARY_SET.Spectral })
                    end
                    playing_card_joker_effects(cards)
                    return true
                end
            }))
            delay(0.3)
            for i = 1, #G.jokers.cards do
                G.jokers.cards[i]:calculate_joker({ remove_playing_cards = true, removed = destroyed_cards })
            end
        end,
    })
    SMODS.Consumable:take_ownership('familiar', {
        use = function(self, card, area, copier)
            local used_tarot = copier or card
            local destroyed_cards = random_destroy(used_tarot)
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.7,
                func = function()
                    local cards = {}
                    for i = 1, card.ability.extra do
                        cards[i] = true
                        -- TODO preserve suit vanilla RNG
                        local faces = {}
                        for _, v in ipairs(SMODS.Rank.obj_buffer) do
                            local r = SMODS.Ranks[v]
                            if r.face then table.insert(faces, r) end
                        end
                        local _suit, _rank =
                            pseudorandom_element(SMODS.Suits, pseudoseed('familiar_create')).card_key,
                            pseudorandom_element(faces, pseudoseed('familiar_create')).card_key
                        local cen_pool = {}
                        for k, v in pairs(G.P_CENTER_POOLS["Enhanced"]) do
                            if v.key ~= 'm_stone' and not v.overrides_base_rank then
                                cen_pool[#cen_pool + 1] = v
                            end
                        end
                        create_playing_card({
                            front = G.P_CARDS[_suit .. '_' .. _rank],
                            center = pseudorandom_element(cen_pool, pseudoseed('spe_card'))
                        }, G.hand, nil, i ~= 1, { G.C.SECONDARY_SET.Spectral })
                    end
                    playing_card_joker_effects(cards)
                    return true
                end
            }))
            delay(0.3)
            for i = 1, #G.jokers.cards do
                G.jokers.cards[i]:calculate_joker({ remove_playing_cards = true, removed = destroyed_cards })
            end
        end,
    })
    SMODS.Consumable:take_ownership('incantation', {
        use = function(self, card, area, copier)
            local used_tarot = copier or card
            local destroyed_cards = random_destroy(used_tarot)
            G.E_MANAGER:add_event(Event({
                trigger = 'after',
                delay = 0.7,
                func = function()
                    local cards = {}
                    for i = 1, card.ability.extra do
                        cards[i] = true
                        -- TODO preserve suit vanilla RNG
                        local numbers = {}
                        for _, v in ipairs(SMODS.Rank.obj_buffer) do
                            local r = SMODS.Ranks[v]
                            if v ~= 'Ace' and not r.face then table.insert(numbers, r) end
                        end
                        local _suit, _rank =
                            pseudorandom_element(SMODS.Suits, pseudoseed('incantation_create')).card_key,
                            pseudorandom_element(numbers, pseudoseed('incantation_create')).card_key
                        local cen_pool = {}
                        for k, v in pairs(G.P_CENTER_POOLS["Enhanced"]) do
                            if v.key ~= 'm_stone' and not v.overrides_base_rank then
                                cen_pool[#cen_pool + 1] = v
                            end
                        end
                        create_playing_card({
                            front = G.P_CARDS[_suit .. '_' .. _rank],
                            center = pseudorandom_element(cen_pool, pseudoseed('spe_card'))
                        }, G.hand, nil, i ~= 1, { G.C.SECONDARY_SET.Spectral })
                    end
                    playing_card_joker_effects(cards)
                    return true
                end
            }))
            delay(0.3)
            for i = 1, #G.jokers.cards do
                G.jokers.cards[i]:calculate_joker({ remove_playing_cards = true, removed = destroyed_cards })
            end
        end,
    })
    -------------------------------------------------------------------------------------------------
    ----- API CODE GameObject.DeckSkin
    -------------------------------------------------------------------------------------------------

    local deck_skin_count_by_suit = {}
    SMODS.DeckSkins = {}
    SMODS.DeckSkin =SMODS.GameObject:extend {
        obj_table = SMODS.DeckSkins,
        obj_buffer = {},
        required_params = {
            'key',
            'suit',
            'ranks',
            'lc_atlas',
        },
        posStyle = 'deck',
        set = 'DeckSkin',
        process_loc_text = function(self)
            if G.localization.misc.collabs[self.suit] == nil then
                G.localization.misc.collabs[self.suit] = {["1"] = 'Default'}
            end
            if not self.loc_txt then
                G.localization.misc.collabs[self.suit][self.suit_index .. ''] = G.localization.misc.collabs[self.suit][self.suit_index .. ''] or self.key
                return
            end
            SMODS.process_loc_text(G.localization.misc.collabs[self.suit], self.suit_index..'', self.loc_txt)
        end,
        register = function (self)
            if self.registered then
                sendWarnMessage(('Detected duplicate register call on DeckSkin %s'):format(self.key), self.set)
                return
            end
            if self:check_dependencies() then
                self.hc_atlas = self.hc_atlas or self.lc_atlas

                if not (self.posStyle == 'collab' or self.posStyle == 'suit' or self.posStyle == 'deck') then
                    sendWarnMessage(('%s is not a valid posStyle on DeckSkin %s. Supported posStyle values are \'collab\', \'suit\' and \'deck\''):format(self.posStyle, self.key), self.set)
                end

                self.obj_table[self.key] = self

                if deck_skin_count_by_suit[self.suit] then
                    self.suit_index  = deck_skin_count_by_suit[self.suit] + 1
                else
                    --start at 2 for default
                    self.suit_index = 2
                end
                deck_skin_count_by_suit[self.suit] = self.suit_index

                self.obj_buffer[#self.obj_buffer + 1] = self.key
                self.registered = true
            end
        end,
        inject = function (self)
            if G.COLLABS.options[self.suit] == nil then
                G.COLLABS.options[self.suit] = {'default'}
            end

            local options = G.COLLABS.options[self.suit]
            options[#options + 1] = self.key
        end
    }

    for suitName, options in pairs(G.COLLABS.options) do
        --start at 2 to skip default
        for i = 2, #options do
            SMODS.DeckSkin{
                key = options[i],
                suit = suitName,
                ranks = {'Jack', 'Queen', 'King'},
                lc_atlas = options[i] .. '_1',
                hc_atlas = options[i] .. '_2',
                posStyle = 'collab'
            }
        end
    end

    --Clear 'Friends of Jimbo' skins so they can be handled via the same pipeline
    G.COLLABS.options = {}

    -------------------------------------------------------------------------------------------------
    ----- API CODE GameObject.PokerHand
    -------------------------------------------------------------------------------------------------

    SMODS.PokerHandParts = {}
    SMODS.PokerHandPart = SMODS.GameObject:extend {
        obj_table = SMODS.PokerHandParts,
        obj_buffer = {},
        required_params = {
            'key',
            'func',
        },
        inject_class = function() end,
    }
    local handlist = G.handlist
    G.handlist = {}
    SMODS.PokerHands = {}
    SMODS.PokerHand = SMODS.GameObject:extend {
        obj_table = SMODS.PokerHands,
        obj_buffer = G.handlist,
        required_params = {
            'key',
            'mult',
            'chips',
            'l_mult',
            'l_chips',
            'example',
            'evaluate'
        },
        visible = true,
        played = 0,
        played_this_round = 0,
        level = 1,
        set = 'PokerHand',
        process_loc_text = function(self)
            SMODS.process_loc_text(G.localization.misc.poker_hands, self.key, self.loc_txt, 'name')
            SMODS.process_loc_text(G.localization.misc.poker_hand_descriptions, self.key, self.loc_txt, 'description')
        end,
        register = function(self)
            if self:check_dependencies() and not self.obj_table[self.key] then
                self.s_mult = self.mult
                self.s_chips = self.chips
                self.visible = self.visible
                self.level = self.level
                self.played = self.played
                self.played_this_round = self.played_this_round
                self.obj_table[self.key] = self
                self.obj_buffer[#self.obj_buffer + 1] = self.key
            end
        end,
        inject = function(self) end,
        post_inject_class = function(self)
            table.sort(
                self.obj_buffer,
                function(a, b)
                    local x, y = self.obj_table[a], self.obj_table[b]
                    local x_above = self.obj_table[x.above_hand or {}]
                    local y_above = self.obj_table[y.above_hand or {}]
                    local function eval(h) return h.mult*h.chips + (h.order_offset or 0) end
                    return (x_above and (1e-6*eval(x) + eval(x_above)) or eval(x)) > (y_above and (1e-6*eval(y) + eval(y_above)) or eval(y))
                end
            )
            for i, v in ipairs(self.obj_buffer) do self.obj_table[v].order = i end
        end
    }

    SMODS.PokerHandPart {
        key = '_highest',
        func = function(hand) return get_highest(hand) end
    }
    SMODS.PokerHandPart {
        key = '_straight',
        func = function(hand) return get_straight(hand) end
    }
    SMODS.PokerHandPart {
        key = '_flush',
        func = function(hand) return get_flush(hand) end,
    }
    -- all sets of 2 or more cards of same rank
    SMODS.PokerHandPart {
        key = '_all_pairs',
        func = function(hand)
            local _2 = get_X_same(2, hand, true)
            if not next(_2) then return {} end
            return {SMODS.merge_lists(_2)}
        end
    }
    for i = 2, 5 do
        SMODS.PokerHandPart {
            key = '_'..i,
            func = function(hand) return get_X_same(i, hand, true) end
        }
    end

    local hands = G:init_game_object().hands
    local eval_functions = {
        ['Flush Five'] = function(parts)
            if not next(parts._5) or not next(parts._flush) then return {} end
            return { SMODS.merge_lists(parts._5, parts._flush) }
        end,
        ['Flush House'] = function(parts)
            if #parts._3 < 1 or #parts._2 < 2 or not next(parts._flush) then return {} end
            return { SMODS.merge_lists(parts._all_pairs, parts._flush) }
        end, 
        ['Five of a Kind'] = function(parts) return parts._5 end,
        ['Straight Flush'] = function(parts)
            if not next(parts._straight) or not next(parts._flush) then return end
            return { SMODS.merge_lists(parts._straight, parts._flush) }
        end, 
        ['Four of a Kind'] = function(parts) return parts._4 end, 
        ['Full House'] = function(parts)
            if #parts._3 < 1 or #parts._2 < 2 then return {} end
            return parts._all_pairs
        end,
        ['Flush'] = function(parts) return parts._flush end,
        ['Straight'] = function(parts) return parts._straight end,
        ['Three of a Kind'] = function(parts) return parts._3 end, 
        ['Two Pair'] = function(parts)
            if #parts._2 < 2 then return {} end
            return parts._all_pairs
        end, 
        ['Pair'] = function(parts) return parts._2 end, 
        ['High Card'] = function(parts) return parts._highest end, 
    }
    for _, v in ipairs(handlist) do
        local hand = copy_table(hands[v])
        hand.key = v
        hand.evaluate = eval_functions[v]
        SMODS.PokerHand(hand)
    end
    -------------------------------------------------------------------------------------------------
    ----- API CODE GameObject.Challenge
    -------------------------------------------------------------------------------------------------

    SMODS.Challenges = {}
    SMODS.Challenge = SMODS.GameObject:extend {
        obj_table = SMODS.Challenges,
        obj_buffer = {},
        get_obj = function(self, key)
            for _, v in ipairs(G.CHALLENGES) do
                if v.id == key then return v end
            end
        end,
        set = "Challenge",
        required_params = {
            'key',
        },
        deck = { type = "Challenge Deck" },
        rules = { custom = {}, modifiers = {} },
        jokers = {},
        consumeables = {},
        vouchers = {},
        restrictions = { banned_cards = {}, banned_tags = {}, banned_other = {} },
        unlocked = function(self) return true end,
        class_prefix = 'c',
        process_loc_text = function(self)
            SMODS.process_loc_text(G.localization.misc.challenge_names, self.key, self.loc_txt, 'name')
        end,
        register = function(self)
            if self.registered then
                sendWarnMessage(('Detected duplicate register call on object %s'):format(self.key), self.set)
                return
            end
            self.id = self.key
            -- only needs to be called once
            SMODS.insert_pool(G.CHALLENGES, self)
            SMODS.Challenge.super.register(self)
        end,
        inject = function(self) end,
    }
    for k, v in ipairs {
        'omelette_1',
        'city_1',
        'rich_1',
        'knife_1',
        'xray_1',
        'mad_world_1',
        'luxury_1',
        'non_perishable_1',
        'medusa_1',
        'double_nothing_1',
        'typecast_1',
        'inflation_1',
        'bram_poker_1',
        'fragile_1',
        'monolith_1',
        'blast_off_1',
        'five_card_1',
        'golden_needle_1',
        'cruelty_1',
        'jokerless_1',
    } do
        SMODS.Challenge:take_ownership(v, {
            unlocked = function(self)
                return G.PROFILES[G.SETTINGS.profile].challenges_unlocked and
                (G.PROFILES[G.SETTINGS.profile].challenges_unlocked >= k)
            end,
        })
    end

    -------------------------------------------------------------------------------------------------
    ----- API CODE GameObject.Tag
    -------------------------------------------------------------------------------------------------

    SMODS.Tags = {}
    SMODS.Tag = SMODS.GameObject:extend {
        obj_table = SMODS.Tags,
        obj_buffer = {},
        required_params = {
            'key',
        },
        discovered = false,
        min_ante = nil,
        atlas = 'tags',
        class_prefix = 'tag',
        set = 'Tag',
        pos = { x = 0, y = 0 },
        config = {},
        get_obj = function(self, key) return G.P_TAGS[key] end,
        process_loc_text = function(self)
            SMODS.process_loc_text(G.localization.descriptions.Tag, self.key, self.loc_txt)
        end,
        inject = function(self)
            G.P_TAGS[self.key] = self
            SMODS.insert_pool(G.P_CENTER_POOLS[self.set], self)
        end,
        generate_ui = function(self, info_queue, card, desc_nodes, specific_vars, full_UI_table)
            local target = {
                type = 'descriptions',
                key = self.key,
                set = self.set,
                nodes = desc_nodes,
                vars = specific_vars
            }
            local res = {}
            if self.loc_vars and type(self.loc_vars) == 'function' then
                -- card is actually a `Tag` here
                res = self:loc_vars(info_queue, card) or {}
                target.vars = res.vars or target.vars
                target.key = res.key or target.key
                target.set = res.set or target.set
                target.scale = res.scale
                target.text_colour = res.text_colour
            end
            if desc_nodes == full_UI_table.main and not full_UI_table.name then
                full_UI_table.name = localize { type = 'name', set = target.set, key = target.key, nodes = full_UI_table.name }
            elseif desc_nodes ~= full_UI_table.main and not desc_nodes.name then
                desc_nodes.name = localize{type = 'name_text', key = target.key, set = target.set } 
            end
            if res.main_start then
                desc_nodes[#desc_nodes + 1] = res.main_start
            end
            localize(target)
            if res.main_end then
                desc_nodes[#desc_nodes + 1] = res.main_end
            end
            desc_nodes.background_colour = res.background_colour
        end
    }

    -------------------------------------------------------------------------------------------------
    ----- API CODE GameObject.Sticker
    -------------------------------------------------------------------------------------------------

    SMODS.Stickers = {}
    SMODS.Sticker = SMODS.GameObject:extend {
        obj_table = SMODS.Stickers,
        obj_buffer = {},
        set = 'Sticker',
        required_params = {
            'key',
        },
        rate = 0.3,
        atlas = 'stickers',
        pos = { x = 0, y = 0 },
        badge_colour = HEX 'FFFFFF',
        default_compat = true,
        compat_exceptions = {},
        sets = { Joker = true },
        needs_enable_flag = true,
        process_loc_text = function(self)
            SMODS.process_loc_text(G.localization.descriptions.Other, self.key, self.loc_txt)
            SMODS.process_loc_text(G.localization.misc.labels, self.key, self.loc_txt, 'label')
        end,
        register = function(self)
            if self.registered then
                sendWarnMessage(('Detected duplicate register call on object %s'):format(self.key), self.set)
                return
            end
            SMODS.Sticker.super.register(self)
            self.order = #self.obj_buffer
        end,
        inject = function(self)
            self.sticker_sprite = Sprite(0, 0, G.CARD_W, G.CARD_H, G.ASSET_ATLAS[self.atlas], self.pos)
            G.shared_stickers[self.key] = self.sticker_sprite
        end,
        -- relocating sticker checks to here, so if the sticker has different checks than default
        -- they can be handled without hooking/injecting into create_card
        -- or handling it in apply
        -- TODO: rename
        should_apply = function(self, card, center, area, bypass_roll)
            if 
                ( not self.sets or self.sets[center.set or {}]) and
                (
                    center[self.key..'_compat'] or -- explicit marker
                    (self.default_compat and not self.compat_exceptions[center.key]) or -- default yes with no exception
                    (not self.default_compat and self.compat_exceptions[center.key]) -- default no with exception
                ) and 
                (not self.needs_enable_flag or G.GAME.modifiers['enable_'..self.key])
            then
                self.last_roll = pseudorandom((area == G.pack_cards and 'packssj' or 'shopssj')..self.key..G.GAME.round_resets.ante)
                return (bypass_roll ~= nil) and bypass_roll or self.last_roll > (1-self.rate)
            end
        end,
        apply = function(self, card, val)
            card.ability[self.key] = val
        end
    }

    -- Create base game stickers
    -- eternal and perishable follow shared checks for sticker application, therefore omitted 
    SMODS.Sticker{
        key = "eternal",
        badge_colour = HEX 'c75985',
        prefix_config = {key = false},
        pos = { x = 0, y = 0 },
        hide_badge = true,
        order = 1,
        should_apply = false,
        inject = function(self)
            SMODS.Sticker.inject(self)
            G.shared_sticker_eternal = self.sticker_sprite
        end
    }

    SMODS.Sticker{
        key = "perishable",
        badge_colour = HEX '4f5da1',
        prefix_config = {key = false},
        pos = { x = 0, y = 2 },
        hide_badge = true,
        order = 2,
        should_apply = false,
        apply = function(self, card, val)
            card.ability[self.key] = val
            if card.ability[self.key] then card.ability.perish_tally = G.GAME.perishable_rounds end
        end,
        loc_vars = function(self, info_queue, card)
            return {vars = {card.ability.perishable_rounds or 5, card.ability.perish_tally or G.GAME.perishable_rounds}}
        end,
        inject = function(self)
            SMODS.Sticker.inject(self)
            G.shared_sticker_perishable = self.sticker_sprite
        end
    }

    SMODS.Sticker{
        key = "rental",
        badge_colour = HEX 'b18f43',
        prefix_config = {key = false},
        pos = { x = 1, y = 2 },
        hide_badge = true,
        order = 3,
        should_apply = false,
        apply = function(self, card, val)
            card.ability[self.key] = val
            if card.ability[self.key] then card:set_cost() end
        end,
        loc_vars = function(self, info_queue, card)
            return {vars = {G.GAME.rental_rate or 1}}
        end,
        inject = function(self)
            SMODS.Sticker.inject(self)
            G.shared_sticker_rental = self.sticker_sprite
        end
    }

    SMODS.Sticker{
        key = "pinned",
        badge_colour = HEX 'fda200',
        prefix_config = {key = false},
        pos = { x = 10, y = 10 }, -- Base game has no art, and I haven't made any yet to represent Pinned with
        rate = 0,
        should_apply = false, 
        order = 4,
        apply = function(self, card, val)
            card[self.key] = val
        end
    }

    -------------------------------------------------------------------------------------------------
    ----- API CODE GameObject.Enhancement
    -------------------------------------------------------------------------------------------------

    SMODS.Enhancement = SMODS.Center:extend {
        set = 'Enhanced',
        class_prefix = 'm',
        atlas = 'centers',
        pos = { x = 0, y = 0 },
        required_params = {
            'key',
            -- table with keys `name` and `text`
        },
        -- other fields:
        -- replace_base_card
        -- if true, don't draw base card sprite and don't give base card's chips
        -- no_suit
        -- if true, enhanced card has no suit
        -- no_rank
        -- if true, enhanced card has no rank
        -- overrides_base_rank
        -- Set to true if your enhancement overrides the base card's rank.
        -- This prevents rank generators like Familiar creating cards
        -- whose rank is overridden.
        -- any_suit
        -- if true, enhanced card is any suit
        -- always_scores
        -- if true, card always scores
        -- loc_subtract_extra_chips
        -- During tooltip generation, number of chips to subtract from displayed extra chips.
        -- Use if enhancement already displays its own chips.
        -- Future work: use ranks() and suits() for better control
        register = function(self)
            self.config = self.config or {}
            assert(not (self.no_suit and self.any_suit))
            if self.no_rank then self.overrides_base_rank = true end
            SMODS.Enhancement.super.register(self)
        end,
        -- Produces the description of the whole playing card
        -- (including chips from the rank of the card and permanent bonus chips).
        -- You will probably want to override this if your enhancement interacts with
        -- those parts of the base card.
        generate_ui = function(self, info_queue, card, desc_nodes, specific_vars, full_UI_table)
            if specific_vars and specific_vars.nominal_chips and not self.replace_base_card then
                localize { type = 'other', key = 'card_chips', nodes = desc_nodes, vars = { specific_vars.nominal_chips } }
            end
            SMODS.Enhancement.super.generate_ui(self, info_queue, card, desc_nodes, specific_vars, full_UI_table)
            if specific_vars and specific_vars.bonus_chips then
                local remaining_bonus_chips = specific_vars.bonus_chips - (self.config.bonus or 0)
                if remaining_bonus_chips > 0 then
                    localize { type = 'other', key = 'card_extra_chips', nodes = desc_nodes, vars = { specific_vars.bonus_chips - (self.config.bonus or 0) } }
                end
            end
        end,
        -- other methods:
        -- calculate(self, context, effect)
    }
    -- Note: `name`, `effect`, and `label` all serve the same purpose as
    -- the name of the enhancement. In theory, `effect` serves to allow reusing
    -- similar effects (ex. the Sinful jokers). But Balatro just uses them all
    -- indiscriminately for enhancements.
    -- `name` and `effect` are technically different for Bonus and Mult
    -- cards but this never matters in practice; also `label` is a red herring,
    -- I can't even find a single use of `label`.

    -- It would be nice if the relevant functions for modding each class of object
    -- would be documented.
    -- For example, Card:set_ability sets the card's enhancement, which is not immediately
    -- obvious.

    -- local stone_card = SMODS.Enhancement:take_ownership('m_stone', {
    --     replace_base_card = true,
    --     no_suit = true,
    --     no_rank = true,
    --     always_scores = true,
    --     loc_txt = {
    --         name = "Stone Card",
    --         text = {
    --             "{C:chips}+#1#{} Chips",
    --             "no rank or suit"
    --         }
    --     },
    --     loc_vars = function(self)
    --         return {
    --             vars = { self.config.bonus }
    --         }
    --     end
    -- })

    -------------------------------------------------------------------------------------------------
    ----- API CODE GameObject.Shader
    -------------------------------------------------------------------------------------------------

    SMODS.Shaders = {}
    SMODS.Shader = SMODS.GameObject:extend {
        obj_table = SMODS.Shaders,
        obj_buffer = {},
        required_params = {
            'key',
            'path',
        },
        set = 'Shader',
        send_vars = nil, -- function (sprite) - get custom externs to send to shader.
        inject = function(self)
            self.full_path = (self.mod and self.mod.path or SMODS.path) ..
                'assets/shaders/' .. self.path
            local file = NFS.read(self.full_path)
            love.filesystem.write(self.key .. "-temp.fs", file)
            G.SHADERS[self.key] = love.graphics.newShader(self.key .. "-temp.fs")
            love.filesystem.remove(self.key .. "-temp.fs")
            -- G.SHADERS[self.key] = love.graphics.newShader(self.full_path)
        end,
        process_loc_text = function() end
    }

    -------------------------------------------------------------------------------------------------
    ----- API CODE GameObject.Edition
    -------------------------------------------------------------------------------------------------

    SMODS.Edition = SMODS.Center:extend {
        set = 'Edition',
        -- atlas only matters for displaying editions in the collection
        atlas = 'Joker',
        pos = { x = 0, y = 0 },
        class_prefix = 'e',
        discovered = false,
        unlocked = true,
        apply_to_float = false,
        in_shop = false,
        weight = 0,
        badge_colour = G.C.DARK_EDITION,
        -- default sound is foil sound
        sound = { sound = "foil1", per = 1.2, vol = 0.4 },
        required_params = {
            'key',
            'shader' -- can be set to `false` for shaderless edition
        },
        -- optional fields:
        extra_cost = nil,
        
        -- TODO badge colours. need to check how Steamodded already does badge colors
        -- other methods:
        calculate = nil, -- function (self)
        on_apply = nil,  -- function (card) - modify card when edition is applied
        on_remove = nil, -- function (card) - modify card when edition is removed
        on_load = nil,   -- function (card) - modify card when it is loaded from the save file
        register = function(self)
            self.config = self.config or {}
            SMODS.Edition.super.register(self)
        end,
        process_loc_text = function(self)
            SMODS.process_loc_text(G.localization.misc.labels, self.key:sub(3), self.loc_txt, 'label')
            SMODS.Edition.super.process_loc_text(self)
        end,
        -- apply_modifier = true when G.GAME.edition_rate is to be applied
        get_weight = function(self, apply_modifier)
            return self.weight
        end
    }

    -- TODO also, this should probably be a utility method in core
    -- card_area = pass the card area
    -- edition = boolean value
    function SMODS.Edition:get_edition_cards(card_area, edition)
        local cards = {}
        for _, v in ipairs(card_area.cards) do
            if (not v.edition and edition) or (v.edition and not edition) then
                table.insert(cards, v)
            end
        end
        return cards
    end

    SMODS.Edition:take_ownership('foil', {
        shader = 'foil',
        config = setmetatable({ chips = 50 }, {
            __index = function(t, k)
                if k == 'extra' then return t.chips end
                return rawget(t, k)
            end,
            __newindex = function(t, k, v)
                if k == 'extra' then
                    t.chips = v; return
                end
                rawset(t, k, v)
            end,
        }),
        sound = { sound = "foil1", per = 1.2, vol = 0.4 },
        weight = 20,
        extra_cost = 2,
        get_weight = function(self)
            return G.GAME.edition_rate * self.weight
        end,
        loc_vars = function(self)
            return { vars = { self.config.chips } }
        end
    })
    SMODS.Edition:take_ownership('holo', {
        shader = 'holo',
        config = setmetatable({ mult = 10 }, {
            __index = function(t, k)
                if k == 'extra' then return t.mult end
                return rawget(t, k)
            end,
            __newindex = function(t, k, v)
                if k == 'extra' then
                    t.mult = v; return
                end
                rawset(t, k, v)
            end,
        }),
        sound = { sound = "holo1", per = 1.2 * 1.58, vol = 0.4 },
        weight = 14,
        extra_cost = 3,
        get_weight = function(self)
            return G.GAME.edition_rate * self.weight
        end,
        loc_vars = function(self)
            return { vars = { self.config.mult } }
        end
    })
    SMODS.Edition:take_ownership('polychrome', {
        shader = 'polychrome',
        config = setmetatable({ x_mult = 1.5 }, {
            __index = function(t, k)
                if k == 'extra' then return t.x_mult end
                return rawget(t, k)
            end,
            __newindex = function(t, k, v)
                if k == 'extra' then
                    t.x_mult = v; return
                end
                rawset(t, k, v)
            end,
        }),
        sound = { sound = "polychrome1", per = 1.2, vol = 0.7 },
        weight = 3,
        extra_cost = 5,
        get_weight = function(self)
            return (G.GAME.edition_rate - 1) * G.P_CENTERS["e_negative"].weight + G.GAME.edition_rate * self.weight
        end,
        loc_vars = function(self)
            return { vars = { self.config.x_mult } }
        end
    })
    SMODS.Edition:take_ownership('negative', {
        shader = 'negative',
        config = setmetatable({ card_limit = 1 }, {
            __index = function(t, k)
                if k == 'extra' then return t.card_limit end
                return rawget(t, k)
            end,
            __newindex = function(t, k, v)
                if k == 'extra' then
                    t.card_limit = v; return
                end
                rawset(t, k, v)
            end,
        }),
        sound = { sound = "negative", per = 1.5, vol = 0.4 },
        weight = 3,
        extra_cost = 5,
        get_weight = function(self)
            return self.weight
        end,
        loc_vars = function(self)
            return { vars = { self.config.card_limit } }
        end,
    })

    -------------------------------------------------------------------------------------------------
    ------- API CODE GameObject.Keybind
    -------------------------------------------------------------------------------------------------
    SMODS.Keybinds = {}
    SMODS.Keybind = SMODS.GameObject:extend {
        obj_table = SMODS.Keybinds,
        obj_buffer = {},

        -- key_pressed = 'x',
        held_keys = {}, -- other key(s) that need to be held
        -- action = function(controller)
        --     print("Keybind pressed")
        -- end,

        event = 'pressed',
        held_duration = 1,

        required_params = {
            'key_pressed',
            'action',
        },
        set = 'Keybind',
        class_prefix = 'keybind',
        register = function(self)
            self.key = self.key or (#self.obj_buffer..'')
            SMODS.Keybind.super.register(self)
        end,
        inject = function(_) end
    }
    
    SMODS.Keybind {
        key_pressed = 'm',
        event = 'held',
        held_duration = 1.1,
        action = function(self)
            SMODS.save_all_config()
		    SMODS.restart_game()
        end
    }

    -------------------------------------------------------------------------------------------------
    ------- API CODE GameObject.Achievements
    -------------------------------------------------------------------------------------------------

    SMODS.Achievements = {}
    SMODS.Achievement = SMODS.GameObject:extend{
        obj_table = SMODS.Achievements,
        obj_buffer = {},
        required_params = {
            'key',
            'unlock_condition',
        },
        set = 'Achievement',
        class_prefix = "ach",
        atlas = "achievements",
        pos = {x=1, y=0},
        hidden_pos = {x=0, y=0},
        bypass_all_unlocked = false,
        hidden_name = true,
        steamid = "STEAMODDED",
        pre_inject_class = fetch_achievements,
        inject = function(self)
            G.ACHIEVEMENTS[self.key] = self
            if self.reset_on_startup then
                if G.SETTINGS.ACHIEVEMENTS_EARNED[self.key] then G.SETTINGS.ACHIEVEMENTS_EARNED[self.key] = nil end
                if G.ACHIEVEMENTS[self.key].earned then G.ACHIEVEMENTS[self.key].earned = nil end
            end
        end,
        process_loc_text = function(self)
            SMODS.process_loc_text(G.localization.misc.achievement_names, self.key, self.loc_txt, "name")
            SMODS.process_loc_text(G.localization.misc.achievement_descriptions, self.key, self.loc_txt, "description")
        end,
    }

    -------------------------------------------------------------------------------------------------
    ----- INTERNAL API CODE GameObject._Loc_Post
    -------------------------------------------------------------------------------------------------

    SMODS._Loc_Post = SMODS.GameObject:extend {
        obj_table = {},
        obj_buffer = {},
        set = '[INTERNAL]',
        silent = true,
        register = function() error('INTERNAL CLASS, DO NOT CALL') end,
        pre_inject_class = function()
            for _, mod in ipairs(SMODS.mod_list) do
                if mod.can_load then
                    SMODS.handle_loc_file(mod.path)
                end
            end
        end
    }
end
