-- Simple Nameplates: register settings pages and slash routes.
local _, ns = ...
local CreateAboutPanel, CreateBehaviorPanel = ns.SettingsPanels.About, ns.SettingsPanels.Behavior
local CreateAppearancePanel, CreateTRP3Panel = ns.SettingsPanels.Appearance, ns.SettingsPanels.TRP3
local settingsCategory, behaviorSettingsCategory, appearanceSettingsCategory, trp3SettingsCategory

local function RegisterSettingsPanel()
    if settingsCategory or not Settings or not Settings.RegisterCanvasLayoutCategory
        or not Settings.RegisterCanvasLayoutSubcategory then return end
    local aboutPanel = CreateAboutPanel()
    settingsCategory = Settings.RegisterCanvasLayoutCategory(aboutPanel, "Simple Nameplates")
    Settings.RegisterAddOnCategory(settingsCategory)
    behaviorSettingsCategory = Settings.RegisterCanvasLayoutSubcategory(settingsCategory, CreateBehaviorPanel(), "Behavior")
    appearanceSettingsCategory = Settings.RegisterCanvasLayoutSubcategory(settingsCategory, CreateAppearancePanel(), "Appearance")
    trp3SettingsCategory = Settings.RegisterCanvasLayoutSubcategory(settingsCategory, CreateTRP3Panel(), "TRP3")

    SLASH_SNP1 = "/snp"
    SlashCmdList.SNP = function(message)
        local command = string.lower(strtrim(message or ""))
        if command == "debug" or command == "diagnose" then
            if ns.DebugUnit then ns.DebugUnit("target") end
            return
        end
        if InCombatLockdown and InCombatLockdown() then
            print("|cff0cd29fSimple Nameplates:|r Settings cannot be opened during combat.")
            return
        end
        if command == "about" then
            Settings.OpenToCategory(settingsCategory:GetID())
        elseif command == "text" or command == "font" or command == "fonts"
            or command == "appearance" then
            Settings.OpenToCategory(appearanceSettingsCategory:GetID())
        elseif command == "colors" or command == "color" then
            Settings.OpenToCategory(appearanceSettingsCategory:GetID())
        elseif command == "trp3" or command == "rp" then
            Settings.OpenToCategory(trp3SettingsCategory:GetID())
        elseif command == "" or command == "behavior" or command == "general" or command == "config"
            or command == "options" or command == "settings" then
            Settings.OpenToCategory(behaviorSettingsCategory:GetID())
        else
            print("|cff0cd29fSimple Nameplates:|r /snp, /snp behavior, /snp appearance, /snp colors, /snp trp3, /snp debug, /snp about")
        end
    end
end

ns.RegisterSettingsPanel = RegisterSettingsPanel
