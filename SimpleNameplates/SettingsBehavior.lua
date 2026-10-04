-- Simple Nameplates: shared global styling switch and Appearance visibility controls.
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

-- Matches the Colors-page switch/status layout; activation remains global.
local function AddStylingSwitch(row, anchor, refreshers)
    local toggle, status
    local function Refresh()
        local active = GetStylingEnabled()
        toggle:SetChecked(active)
        status:SetText(active and "Active" or "Inactive")
    end
    toggle = U.CreateSwitch(row, function(checked)
        SetStylingEnabled(checked)
        HandleStylingChanged(checked)
        -- Compatibility checks may pause styling while their dialog is open.
        Refresh()
    end)
    toggle:SetPoint("LEFT", anchor, "RIGHT", 8, 0)
    status = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    status:SetPoint("LEFT", toggle, "RIGHT", 8, 0)
    status:SetWidth(56)
    status:SetJustifyH("LEFT")
    refreshers[#refreshers + 1] = Refresh
    Refresh()
    return toggle
end

local function AddGlobalAppearanceControls(content, layout, refreshers)
    U.AddSection(content, layout, "Global visibility")
    U.AddDescription(content, layout,
        "This setting applies to every character and profile. Reset settings also restores it to its default.")
    U.AddToggle(content, layout, refreshers, "Hide critter and companion names",
        ns.GetHideCritterCompanionNames, ns.SetHideCritterCompanionNames)
    U.AddDescription(content, layout, "Hides native world names for noncombat critters and companions.")
end
ns.AddStylingSwitch = AddStylingSwitch
ns.AddGlobalAppearanceControls = AddGlobalAppearanceControls
