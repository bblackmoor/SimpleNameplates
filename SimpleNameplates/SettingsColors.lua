-- Simple Nameplates: profile colors and global category activation.
local _, ns = ...
local U = ns.SettingsUI
local AddSection, AddDescription, RunRefreshers, RefreshNameplates =
    U.AddSection, U.AddDescription, U.RunRefreshers, U.RefreshNameplates
local PriorityColorForState, SetPriorityColor, ResetPriorityColor =
    ns.PriorityColorForState, ns.SetPriorityColor, ns.ResetPriorityColor
local EffectColor, SetEffectColor, ResetEffectColor = ns.EffectColor, ns.SetEffectColor, ns.ResetEffectColor

local function OpenColorPicker(getColor, setColor, updateSwatch)
    local oldR, oldG, oldB = getColor()
    local function ApplyPickerColor()
        local r, g, b = ColorPickerFrame:GetColorRGB()
        setColor(r, g, b)
        updateSwatch()
        RefreshNameplates()
    end
    ColorPickerFrame:SetupColorPickerAndShow({
        r = oldR, g = oldG, b = oldB, hasOpacity = false,
        swatchFunc = ApplyPickerColor,
        cancelFunc = function()
            setColor(oldR, oldG, oldB)
            updateSwatch()
            RefreshNameplates()
        end,
    })
end

local function CreateColorRow(context, text, displayText, getColor, setColor, resetColor, activation)
    local row = U.CreateSettingRow(context.content, context.layout, text)
    local swatch = CreateFrame("Button", nil, row, "BackdropTemplate")
    swatch:SetSize(26, 26)
    swatch:SetPoint("LEFT", row, "LEFT", U.CONTROL_X, 0)
    swatch:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
    swatch:SetBackdropColor(0.04, 0.04, 0.04, 1)
    swatch:SetBackdropBorderColor(0.45, 0.45, 0.45, 1)
    local fill = swatch:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("TOPLEFT", 3, -3)
    fill:SetPoint("BOTTOMRIGHT", -3, 3)
    local function UpdateSwatch() fill:SetColorTexture(getColor()) end
    context.swatchRefreshers[#context.swatchRefreshers + 1] = UpdateSwatch
    UpdateSwatch()
    swatch:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(1, 1, 1, 1)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(text)
        GameTooltip:AddLine("Click to choose a color.", 1, 1, 1)
        GameTooltip:Show()
    end)
    swatch:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.45, 0.45, 0.45, 1)
        GameTooltip:Hide()
    end)
    local function RefreshSwatches() RunRefreshers(context.swatchRefreshers) end
    swatch:SetScript("OnClick", function() OpenColorPicker(getColor, setColor, RefreshSwatches) end)
    local resetAnchor = swatch
    if activation then
        local toggle = U.CreateSwitch(row, function(checked)
            activation.set(checked)
            ns.DisableFriendlyClassColors()
            RunRefreshers(context.refreshers)
            RefreshNameplates()
        end)
        toggle:SetPoint("LEFT", swatch, "RIGHT", 8, 0)
        local status = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        status:SetPoint("LEFT", toggle, "RIGHT", 8, 0)
        status:SetWidth(56)
        status:SetJustifyH("LEFT")
        local function RefreshMode()
            local active = activation.get()
            toggle:SetChecked(active)
            status:SetText(active and "Active" or "Inactive")
        end
        context.refreshers[#context.refreshers + 1] = RefreshMode
        RefreshMode()
        resetAnchor = status
    end
    local reset = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    reset:SetSize(54, 22)
    reset:SetPoint("LEFT", resetAnchor, "RIGHT", 8, 0)
    reset:SetText("Reset")
    reset:SetScript("OnClick", function()
        resetColor()
        RefreshSwatches()
        RefreshNameplates()
    end)
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

local function CreateColorsPanel()
    local panel, content, layout = U.CreateScrollablePanel("Colors")
    U.AddTitle(content, layout, "Colors")
    local context = {content = content, layout = layout, swatchRefreshers = {}, refreshers = {}}
    local function Refresh()
        RunRefreshers(context.refreshers)
        RunRefreshers(context.swatchRefreshers)
    end
    ns.AddProfileSelector(content, layout, context.refreshers, Refresh)
    U.AddActionButton(content, layout, "Reset all colors", function()
        ns.ResetAllColors()
        ns.DisableFriendlyClassColors()
        Refresh()
        RefreshNameplates()
    end)
    AddDescription(content, layout,
        "Restores High Contrast defaults for that profile, Default for all others. " ..
        "Resets global priority switches to Active and this profile's cast highlight to Inactive.")
    AddPriorityColorControls(context)
    AddSection(content, layout, "Cast highlight color")
    CreateColorRow(context, "Interruptible cast highlight",
        "Pulses the cast-bar border for interruptible casts and channels. This switch applies only to the selected profile.",
        function() return EffectColor("interruptible") end,
        function(r, g, b) SetEffectColor("interruptible", r, g, b) end,
        function() ResetEffectColor("interruptible") end, {
            get = ns.GetInterruptibleHighlightEnabled,
            set = ns.SetInterruptibleHighlightEnabled,
        })
    panel:SetScript("OnShow", Refresh)
    Refresh()
    layout:Finish()
    return panel
end
ns.SettingsPanels.Colors = CreateColorsPanel

