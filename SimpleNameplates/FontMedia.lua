-- Simple Nameplates: built-in font compatibility and shared-media choices.
local _, ns = ...
local builtins = ns.Defaults.fontByValue
local media = LibStub and LibStub("LibSharedMedia-3.0", true)
local PREFIX = "LSM:"

local function SharedKey(value)
    if type(value) == "string" and #value > #PREFIX and #value <= 256
        and value:sub(1, #PREFIX) == PREFIX and not value:find("[%c]") then
        return value:sub(#PREFIX + 1)
    end
end

local function SharedPath(key)
    if not media or not key or not media:IsValid("font", key) then return end
    local path = media:Fetch("font", key, true)
    if type(path) == "string" and path ~= "" then return path end
end

-- Preserve a saved shared key even before its supplying addon has loaded.
local function IsSavedFontSelection(value)
    return type(value) == "string" and (builtins[value] ~= nil or SharedKey(value) ~= nil)
end

local function IsAvailableFontSelection(value)
    return type(value) == "string" and (builtins[value] ~= nil
        or (SharedKey(value) ~= nil and media and media:IsValid("font", SharedKey(value))
            and SharedPath(SharedKey(value)) ~= nil))
end

local function FontPath(value)
    local builtin = builtins[value]
    if builtin then return builtin.path end
    return SharedPath(SharedKey(value)) or builtins.ARIALN.path
end

local function GetFontOptions(selected)
    local options, paths, labels = {}, {}, {}
    for _, option in ipairs(ns.FONT_OPTIONS) do
        options[#options + 1] = option
        paths[option.path:lower()] = true
        labels[option.label] = true
    end
    local found = builtins[selected] ~= nil
    if media then
        local fonts = media:HashTable("font") or {}
        for _, key in ipairs(media:List("font") or {}) do
            local path = fonts[key]
            local value = PREFIX .. key
            if SharedKey(value) and type(path) == "string" and path ~= ""
                and (not paths[path:lower()] or value == selected) then
                local label = labels[key] and key .. " (shared)" or key
                options[#options + 1] = {value = value, label = label, path = path}
                paths[path:lower()] = true
                if value == selected then found = true end
            end
        end
    end
    if not found and SharedKey(selected) then
        options[#options + 1] = {value = selected, label = SharedKey(selected) .. " (unavailable)"}
    end
    table.sort(options, function(a, b)
        if a.label == b.label then return a.value < b.value end
        return a.label < b.label
    end)
    return options
end

if media then
    local function MediaChanged(_, mediatype)
        if mediatype ~= "font" then return end
        if ns.RefreshFontControls then ns.RefreshFontControls() end
        if ns.QueueNameplateRefresh then ns.QueueNameplateRefresh() end
    end
    media.RegisterCallback(ns, "LibSharedMedia_Registered", MediaChanged)
    media.RegisterCallback(ns, "LibSharedMedia_SetGlobal", MediaChanged)
end

ns.IsSavedFontSelection = IsSavedFontSelection
ns.IsAvailableFontSelection = IsAvailableFontSelection
ns.FontPath = FontPath
ns.GetFontOptions = GetFontOptions
