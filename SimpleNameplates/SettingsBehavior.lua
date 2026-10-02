-- Simple Nameplates: global behavior controls embedded on Appearance.
local _, ns = ...
local U = ns.SettingsUI
local GetStylingEnabled, SetStylingEnabled = ns.GetStylingEnabled, ns.SetStylingEnabled

local function HandleStylingChanged(enabled)
    if enabled then
        if ns.CheckNameplateSetup and not ns.CheckNameplateSetup() then return end
        ns.DisableFriendlyClassColors()
        ns.ApplyManagedNameSettings()
        U.RefreshNameplates()
    else
        ns.RestoreManagedNameSettings()
        ns.RestoreFriendlyClassColors()
        if ns.RestoreAll then ns.RestoreAll() end
    end
end

local function AddGlobalAppearanceControls(content, layout, refreshers)
    U.AddSection(content, layout, "Global behavior")
    U.AddDescription(content, layout,
        "These switches apply to every character and profile. Text/layout and color resets do not change them.")
    local toggle = U.AddToggle(content, layout, refreshers, "Enable Simple Nameplates styling",
        GetStylingEnabled, SetStylingEnabled, HandleStylingChanged)
    -- Compatibility checks can pause styling, so reread the effective value.
    local click = toggle:GetScript("OnClick")
    toggle:SetScript("OnClick", function(self)
        click(self)
        self:SetChecked(GetStylingEnabled())
    end)
    U.AddToggle(content, layout, refreshers, "Hide critter and companion names",
        ns.GetHideCritterCompanionNames, ns.SetHideCritterCompanionNames)
    U.AddDescription(content, layout, "Hides native world names for noncombat critters and companions.")
end
ns.AddGlobalAppearanceControls = AddGlobalAppearanceControls
