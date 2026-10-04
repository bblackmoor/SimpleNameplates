-- Simple Nameplates: global styling switch and its setup/restoration lifecycle.
local _, ns = ...
local U = ns.SettingsUI
local GetStylingEnabled, SetStylingEnabled = ns.GetStylingEnabled, ns.SetStylingEnabled

local function HandleStylingChanged(enabled)
    if enabled then
        if ns.CheckNameplateSetup and not ns.CheckNameplateSetup() then return end
        ns.ApplyManagedNameSettings()
        U.RefreshNameplates()
    else
        ns.RestoreManagedNameSettings()
        if ns.RestoreAll then ns.RestoreAll() end
    end
end

-- Matches the Colors-page switch/status layout; activation remains global.
local function AddStylingSwitch(row, anchor, refreshers)
    local toggle, _, refresh
    toggle, _, refresh = U.AddSwitchStatus(row, anchor, refreshers, GetStylingEnabled, function(checked)
        SetStylingEnabled(checked)
        HandleStylingChanged(checked)
        -- Compatibility checks may pause styling while their dialog is open.
        refresh()
    end)
    ns.RefreshStylingControl = refresh
    refresh()
    return toggle
end

ns.AddStylingSwitch = AddStylingSwitch
