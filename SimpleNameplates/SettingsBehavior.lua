-- Simple Nameplates: shared global styling switch and Appearance visibility controls.
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

ns.AddStylingSwitch = AddStylingSwitch
