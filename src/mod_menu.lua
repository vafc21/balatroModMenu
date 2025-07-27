-- balatroModMenu: in-game mod manager for Balatro
--
-- This script implements a Lua based mod manager and downloader.
-- It uses LuaSocket for HTTP requests, dkjson for JSON parsing, and
-- executes git commands to download and update mods.
-- The UI is built with ImGui.
--
-- NOTE: This file is a simplified example implementation. Actual
-- integration with Balatro and its modding framework may require
-- additional setup not shown here.

local json = require('dkjson')
local socket_http = require('socket.http')
local lfs = require('lfs')

local ModMenu = {}

-- location of mod directory within the Balatro installation
ModMenu.mods_path = 'Mods'

-- URL of remote index listing available mods
ModMenu.index_url = 'https://example.com/balatro/mod_index.json'

-- optional local fallback index file
-- default path is relative to this script's location
local script_dir = (debug.getinfo(1, 'S').source:gsub('^@', '')):match('(.*/)' ) or './'
ModMenu.index_file = script_dir .. 'mod_index.json'

-- table populated with data from mod_index.json
ModMenu.available_mods = {}

-- table of installed mods with version info
ModMenu.installed_mods = {}

-- whether the UI window is currently visible
ModMenu.visible = false

function ModMenu.toggle()
    ModMenu.visible = not ModMenu.visible
end

------------------------------------------------------
-- Utility functions
------------------------------------------------------

local function file_exists(path)
    local f = io.open(path, 'r')
    if f then f:close() return true end
    return false
end

local function run_git_command(cmd)
    local result = os.execute(cmd)
    return result == 0
end

local function load_index_file(path)
    if not file_exists(path) then
        return nil, 'index file not found: ' .. path
    end
    local f = io.open(path, 'r')
    local contents = f:read('*a')
    f:close()
    local index, pos, err = json.decode(contents, 1, nil)
    if err then
        return nil, 'failed to parse index file: ' .. err
    end
    ModMenu.available_mods = index.mods or {}
    return true
end

------------------------------------------------------
-- Index fetching and installed mod scanning
------------------------------------------------------

-- Download mod_index.json from the internet
function ModMenu.fetch_index()
    if ModMenu.index_url and ModMenu.index_url ~= '' then
        local body, status = socket_http.request(ModMenu.index_url)
        if body and status == 200 then
            local index, pos, err = json.decode(body, 1, nil)
            if not err then
                ModMenu.available_mods = index.mods or {}
                return true
            end
        end
    end
    return load_index_file(ModMenu.index_file)
end

-- Scan Mods folder for installed mods and read mod.json
function ModMenu.scan_installed()
    ModMenu.installed_mods = {}
    for entry in lfs.dir(ModMenu.mods_path) do
        if entry ~= '.' and entry ~= '..' then
            local info = lfs.attributes(ModMenu.mods_path .. '/' .. entry)
            if info and info.mode == 'directory' then
                local manifest_path = ModMenu.mods_path .. '/' .. entry .. '/mod.json'
                if file_exists(manifest_path) then
                    local f = io.open(manifest_path, 'r')
                    local contents = f:read('*a')
                    f:close()
                    local mod_data = json.decode(contents)
                    if mod_data then
                        ModMenu.installed_mods[entry] = mod_data
                    end
                end
            end
        end
    end
end

------------------------------------------------------
-- Git operations
------------------------------------------------------

local function mod_folder(mod)
    return ModMenu.mods_path .. '/' .. mod.folder
end

function ModMenu.is_installed(mod)
    return file_exists(mod_folder(mod) .. '/mod.json')
end

function ModMenu.clone_mod(mod)
    local cmd = string.format('git clone %s %s', mod.repo_url, mod_folder(mod))
    return run_git_command(cmd)
end

function ModMenu.update_mod(mod)
    local cmd = string.format('git -C %s pull', mod_folder(mod))
    return run_git_command(cmd)
end

------------------------------------------------------
-- ImGui rendering
------------------------------------------------------

function ModMenu.draw()
    if not ModMenu.visible then return end
    if imgui.Begin('Balatro Mod Menu') then
        if imgui.Button('Refresh Mod List') then
            ModMenu.fetch_index()
            ModMenu.scan_installed()
        end
        imgui.Separator()
        for _, mod in ipairs(ModMenu.available_mods) do
            imgui.Text(mod.name)
            imgui.SameLine(200)
            local installed = ModMenu.installed_mods[mod.folder]
            if installed and installed.version then
                imgui.Text('Installed: ' .. installed.version)
            else
                imgui.Text('Not installed')
            end
            imgui.SameLine(400)
            if imgui.Button(installed and 'Update' or 'Install') then
                if installed then
                    ModMenu.update_mod(mod)
                else
                    ModMenu.clone_mod(mod)
                end
                ModMenu.scan_installed()
            end
            imgui.TextWrapped(mod.description or '')
            imgui.Separator()
        end
        imgui.End()
    end
end

return ModMenu

