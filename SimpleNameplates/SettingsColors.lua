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

local function CreateColorRow(context, text, displayText, getColor, setColor, resetColor, modeKey)
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
    if modeKey then
        local toggle = U.CreateSwitch(row, function(checked)
            ns.SetCategoryMode(modeKey, checked and "active" or "inactive")
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
            local active = ns.GetCategoryMode(modeKey) == "active"
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
        function() ResetPriorityColor(state) end, state == "sanctuaryFriendly" and "friendly" or state)
end

local function AddPriorityColorControls(context)
    AddSection(context.content, context.layout, "Priority colors")
    AddDescription(context.content, context.layout,
        "The switch beside each color is global: Active applies addon styling; Inactive leaves Blizzard presentation. " ..
        "Colors remain profile settings and can be edited while inactive.")
    CreatePriorityColorRow(context, "1. Attacking me", "attacking",
        "Health bar; includes attacks on your controlled units; overrides 2–6")
    CreatePriorityColorRow(context, "2. Will attack me — Hostile", "hostile",
        "Health bar for aggressive NPCs and eligible PvP opponents")
    CreatePriorityColorRow(context, "3. Can attack me — Neutral", "neutral",
        "Health bar for entities that can attack you without a higher priority")
    CreatePriorityColorRow(context, "4. Player — Friendly", "friendly",
        "Colored name out of combat; colored health bar in combat when supported")
    CreatePriorityColorRow(context, "5. Interactive NPC — Useful", "useful",
        "Interactive NPC: colored name out of combat; health bar in combat when supported")
    CreatePriorityColorRow(context, "6. Otherwise — Useless", "useless",
        "Remaining entity: colored name out of combat; health bar in combat when supported")

    U.AddActionButton(context.content, context.layout, "Reset priority colors", function()
        for _, state in ipairs({"attacking", "hostile", "neutral", "friendly", "useful", "useless"}) do
            ResetPriorityColor(state)
        end
        RunRefreshers(context.swatchRefreshers)
        RefreshNameplates()
    end)

    AddSection(context.content, context.layout, "Sanctuary colors")
    AddDescription(context.content, context.layout,
        "These switches share the global Player, Useful, and Useless category settings above. " ..
        "The player switch affects the whole Player category, not just sanctuary players.")
    CreatePriorityColorRow(context, "Same-faction player", "sanctuaryFriendly",
        "Sanctuary only; higher combat priorities keep their normal colors")
    CreatePriorityColorRow(context, "Interactive NPC — Useful", "useful",
        "Shared with Priority colors; higher danger priorities keep their own colors")
    CreatePriorityColorRow(context, "Other NPC — Useless", "useless",
        "Shared with Priority colors; applies to NPCs in the Otherwise category")
end

local function CreateColorsPanel()
    local panel, content, layout = U.CreateScrollablePanel("Colors")
    U.AddTitle(content, layout, "Colors")
    AddDescription(content, layout, "Appearance-profile colors apply to accessible names and bars in both combat states.")
    local context = {content = content, layout = layout, swatchRefreshers = {}, refreshers = {}}
    local function Refresh()
        RunRefreshers(context.refreshers)
        RunRefreshers(context.swatchRefreshers)
    end
    ns.AddProfileSelector(content, layout, context.refreshers, Refresh)
    AddPriorityColorControls(context)
    AddSection(content, layout, "Cast highlight color")
    CreateColorRow(context, "Interruptible cast highlight",
        "The pulsing border is enabled on Appearance. This setting changes its color.",
        function() return EffectColor("interruptible") end,
        function(r, g, b) SetEffectColor("interruptible", r, g, b) end,
        function() ResetEffectColor("interruptible") end)
    AddSection(content, layout, "Reset colors")
    AddDescription(content, layout, "Resets every color in this profile: Priority colors, the sanctuary player color, and the cast highlight color.")
    U.AddActionButton(content, layout, "Reset all profile colors", function()
        ns.ResetAllColors()
        Refresh()
        RefreshNameplates()
    end)
    panel:SetScript("OnShow", Refresh)
    Refresh()
    layout:Finish()
    return panel
end
ns.SettingsPanels.Colors = CreateColorsPanel
