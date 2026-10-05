-- Simple Nameplates: register settings pages and slash routes.
local _, ns = ...
local settingsCategory
local categories = {}
local aliases = {
    [""] = "Appearance", general = "Appearance", config = "Appearance",
    options = "Appearance", settings = "Appearance", about = "About",
    profiles = "Profiles", profile = "Profiles",
    appearance = "Appearance", text = "Appearance", font = "Appearance", fonts = "Appearance",
    colors = "Colors", color = "Colors", trp3 = "TRP3", rp = "TRP3",
}
local function RegisterSettingsPanel()
    if settingsCategory or not Settings or not Settings.RegisterCanvasLayoutCategory
        or not Settings.RegisterCanvasLayoutSubcategory then return end
    settingsCategory = Settings.RegisterCanvasLayoutCategory(ns.SettingsPanels.About(), "Simple Nameplates")
    categories.About = settingsCategory
    Settings.RegisterAddOnCategory(settingsCategory)
    for _, name in ipairs({"Profiles", "Appearance", "Colors", "TRP3"}) do
        categories[name] = Settings.RegisterCanvasLayoutSubcategory(settingsCategory, ns.SettingsPanels[name](), name)
    end
    SLASH_SNP1 = "/snp"
    SlashCmdList.SNP = function(message)
        local command = string.lower(strtrim(message or ""))
        local verb, argument = command:match("^(%S+)%s*(.-)$")
        if verb == "perf" then ns.Profiler.Command(argument); return end
        if verb == "debug" or verb == "diagnose" then
            local unit = argument == "" and "target" or argument
            if unit ~= "target" and unit ~= "mouseover" then
                print("|cff0cd29fSimple Nameplates:|r /snp debug [target|mouseover]")
                return
            end
            if ns.DebugUnit then ns.DebugUnit(unit) end
            return
        end
        if InCombatLockdown and InCombatLockdown() then
            print("|cff0cd29fSimple Nameplates:|r Settings cannot be opened during combat.")
            return
        end
        local category = aliases[command] and categories[aliases[command]]
        if category then Settings.OpenToCategory(category:GetID())
        else print("|cff0cd29fSimple Nameplates:|r /snp, /snp profiles, /snp appearance, /snp colors, /snp trp3, /snp debug [target|mouseover], /snp perf [start|stop|report], /snp about") end
    end
end
ns.RegisterSettingsPanel = RegisterSettingsPanel

