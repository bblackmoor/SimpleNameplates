-- Simple Nameplates: profile colors and global category activation.
local _, ns = ...
local U = ns.SettingsUI
local AddSection, AddDescription, RunRefreshers, RefreshNameplates =
    U.AddSection, U.AddDescription, U.RunRefreshers, U.RefreshNameplates
local PriorityColorForState, SetPriorityColor, ResetPriorityColor =
    ns.PriorityColorForState, ns.SetPriorityColor, ns.ResetPriorityColor
local EffectColor, SetEffectColor, ResetEffectColor = ns.EffectColor, ns.SetEffectColor, ns.ResetEffectColor

local W = ns.SettingsWidgets

local function RefreshContext(context)
    RunRefreshers(context.refreshers)
end

local function AddActivation(context, row, swatch, activation)
    local _, status = U.AddSwitchStatus(row, swatch, context.refreshers, activation.get, function(checked)
        activation.set(checked)
        RefreshContext(context)
        RefreshNameplates()
    end)
    return status
end

local function CreateColorRow(context, text, displayText, getColor, setColor, resetColor, activation)
    local row = U.CreateSettingRow(context.content, context.layout, text)
    local swatch = W.CreateColorPicker(row, function(r, g, b)
        setColor(r, g, b)
        RefreshContext(context)
        RefreshNameplates()
    end)
    swatch:SetPoint("LEFT", row, "LEFT", U.CONTROL_X, 0)
    context.refreshers[#context.refreshers + 1] = function() swatch:SetColor(getColor()) end
    local frame = swatch:GetFrame()
    frame:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(text)
        GameTooltip:AddLine("Click to choose a color.", 1, 1, 1)
        GameTooltip:Show()
    end)
    frame:HookScript("OnLeave", function() GameTooltip:Hide() end)
    local resetAnchor = activation and AddActivation(context, row, swatch, activation) or frame
    local reset = W.CreateButton(row, "Reset", function()
        W.CancelColorEdit()
        resetColor()
        RefreshContext(context)
        RefreshNameplates()
    end, 54, 22)
    reset:SetPoint("LEFT", resetAnchor, "RIGHT", 8, 0)
    if displayText then AddDescription(context.content, context.layout, displayText) end
end

local function CreatePriorityColorRow(context, text, state, displayText)
    CreateColorRow(context, text, displayText,
        function() return PriorityColorForState(state) end,
        function(r, g, b) SetPriorityColor(state, r, g, b) end,
        function() ResetPriorityColor(state) end, {
            get = function() return ns.GetCategoryMode(state) == "active" end,
            set = function(checked) ns.SetCategoryMode(state, checked and "active" or "inactive") end,
        })
end

local function AddPriorityColorControls(context)
    AddSection(context.content, context.layout, "Priority colors")
    AddDescription(context.content, context.layout,
        "First matching category wins. These switches apply globally; Inactive keeps Blizzard's display.")
    CreatePriorityColorRow(context, "1. Attacking me", "attacking",
        "Includes attacks on your controlled units.")
    CreatePriorityColorRow(context, "2. Will attack me — Hostile", "hostile",
        "Includes eligible PvP opponents.")
    CreatePriorityColorRow(context, "3. Can attack me — Neutral", "neutral")
    CreatePriorityColorRow(context, "4. Player - Friendly", "friendly")
    CreatePriorityColorRow(context, "5. NPC - Interactive", "useful")
    CreatePriorityColorRow(context, "6. NPC - Background", "useless",
        "Fallback for unmatched entities.")
end

local function AddCastEffectSelector(context)
    local options = {
        {value = "NONE", label = "None"},
        {value = "PIXEL", label = "Moving dashes"},
        {value = "AUTOCAST", label = "Autocast Shine"},
        {value = "BUTTON", label = "Action Button Glow"},
        {value = "PROC", label = "Proc Glow"},
    }
    local _, dropdown = U.CreateDropdownRow(context.content, context.layout, "Effect", function() return options end, function(value)
        ns.SetInterruptibleCastStyle(value)
        RefreshContext(context)
        RefreshNameplates()
    end)
    context.refreshers[#context.refreshers + 1] = function()
        dropdown:SetValue(ns.GetInterruptibleCastStyle())
    end
end

local function CreateColorsPanel()
    local panel, content, layout = U.CreateScrollablePanel("Colors")
    U.AddTitle(content, layout, "Colors")
    local context = {content = content, layout = layout, refreshers = {}}
    local function Refresh()
        RefreshContext(context)
    end
    ns.AddProfileSelector(content, layout, context.refreshers, Refresh)
    U.AddPageAction(content, layout, "Reset all colors", function()
        W.CancelColorEdit()
        ns.ResetAllColors()
        Refresh()
        RefreshNameplates()
    end)
    AddDescription(content, layout,
        "Restores High Contrast defaults for that profile, Default for all others. " ..
        "Resets global priority switches to Active and this profile's cast highlight to None.")
    AddPriorityColorControls(context)
    AddSection(content, layout, "Cast highlight color")
    CreateColorRow(context, "Interruptible cast highlight",
        "Highlights interruptible casts and channels. Applies to the selected profile.",
        function() return EffectColor("interruptible") end,
        function(r, g, b) SetEffectColor("interruptible", r, g, b) end,
        function() ResetEffectColor("interruptible") end)
    AddCastEffectSelector(context)
    panel:SetScript("OnShow", Refresh)
    panel:SetScript("OnHide", W.CancelColorEdit)
    Refresh()
    layout:Finish()
    return panel
end
ns.SettingsPanels.Colors = CreateColorsPanel

