-- Simple Nameplates: Behavior settings page.
local _, ns = ...
local U = ns.SettingsUI
local CreateScrollablePanel, AddTitle, AddDescription, CreateSwitch =
    U.CreateScrollablePanel, U.AddTitle, U.AddDescription, U.CreateSwitch
local AddSection, RunRefreshers, RefreshNameplates =
    U.AddSection, U.RunRefreshers, U.RefreshNameplates
local GetCategoryMode, SetCategoryMode = ns.GetCategoryMode, ns.SetCategoryMode
local GetStylingEnabled, SetStylingEnabled = ns.GetStylingEnabled, ns.SetStylingEnabled
local GetHideCritterCompanionNames, SetHideCritterCompanionNames =
    ns.GetHideCritterCompanionNames, ns.SetHideCritterCompanionNames

local CATEGORY_ROWS = {
    { "1. Attacking me", "attacking", "Includes attacks on pets, guardians, and minions; overrides 2–6" },
    { "2. Will attack me — Hostile", "hostile", "Aggressive NPCs and eligible PvP opponents" },
    { "3. Can attack me — Neutral", "neutral", "Can attack you without meeting a higher priority" },
    { "4. Player — Friendly", "friendly", "Any player not meeting a higher priority; faction remains a separate fact" },
    { "5. Interactive NPC — Useful", "useful", "Readable interaction evidence; hostile interaction targets use higher priorities" },
    { "6. Otherwise — Useless", "useless", "Fallback for remaining entities; unknown facts are reported in diagnostics" },
}

local function CreateBehaviorToggle(context, labelText, noteText, getter, setter, onChanged)
    local content, layout = context.content, context.layout
    local row = CreateFrame("Frame", nil, content)
    row:SetPoint("RIGHT", content, "RIGHT", -20, 0)
    layout:Add(row, 24, 30, 0)
    local label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("LEFT")
    label:SetText(labelText)
    local toggle
    toggle = CreateSwitch(row, function(checked)
        setter(checked)
        if onChanged then onChanged(checked) end
        toggle:SetChecked(getter())
    end)
    toggle:SetPoint("LEFT", label, "RIGHT", 12, 0)
    if noteText then
        local note = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
        note:SetPoint("RIGHT", content, "RIGHT", -20, 0)
        note:SetJustifyH("LEFT")
        note:SetText(noteText)
        layout:Add(note, 24, 34, 8)
    else
        layout:Space(6)
    end

    local function Refresh() toggle:SetChecked(getter()) end
    context.refreshers[#context.refreshers + 1] = Refresh
    Refresh()
end

local function HandleStylingChanged(enabled)
    if enabled then
        ns.DisableFriendlyClassColors()
        ns.ApplyManagedNameSettings()
        RefreshNameplates()
    else
        ns.RestoreManagedNameSettings()
        ns.RestoreFriendlyClassColors()
        if ns.RestoreAll then ns.RestoreAll() end
    end
end

local CATEGORY_MODES = {
    { value = "active", label = "Active" },
    { value = "inactive", label = "Inactive" },
}

local function CreateCategoryModeRow(context, rowData)
    local content, layout = context.content, context.layout
    local labelText, state, noteText = rowData[1], rowData[2], rowData[3]
    local row = CreateFrame("Frame", nil, content)
    row:SetPoint("RIGHT", content, "RIGHT", -24, 0)
    layout:Add(row, 24, 44, 2)
    local label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("TOPLEFT", 4, -3)
    label:SetWidth(375)
    label:SetJustifyH("LEFT")
    label:SetText(labelText)
    local dropdown = CreateFrame("Frame", nil, row, "UIDropDownMenuTemplate")
    dropdown:SetPoint("LEFT", label, "RIGHT", -4, -9)
    UIDropDownMenu_SetWidth(dropdown, 82)
    local note = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    note:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -4)
    note:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    note:SetJustifyH("LEFT")
    note:SetText(noteText)

    local function Refresh()
        local mode = GetCategoryMode(state)
        UIDropDownMenu_SetSelectedValue(dropdown, mode)
        for _, option in ipairs(CATEGORY_MODES) do
            if option.value == mode then UIDropDownMenu_SetText(dropdown, option.label) end
        end
    end
    UIDropDownMenu_Initialize(dropdown, function(_, level)
        for _, option in ipairs(CATEGORY_MODES) do
            local value, optionLabel = option.value, option.label
            local info = UIDropDownMenu_CreateInfo()
            info.text, info.value = optionLabel, value
            info.checked = GetCategoryMode(state) == value
            info.func = function()
                SetCategoryMode(state, value)
                ns.DisableFriendlyClassColors()
                Refresh()
                RefreshNameplates()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    context.refreshers[#context.refreshers + 1] = Refresh
    Refresh()
end

local function AddBehaviorCategoryControls(context)
    AddSection(context.content, context.layout, "CATEGORY HANDLING")
    AddDescription(context.content, context.layout,
        "Active lets Simple Nameplates style the category. Inactive leaves Blizzard's display unchanged.")
    for _, rowData in ipairs(CATEGORY_ROWS) do CreateCategoryModeRow(context, rowData) end
end

local function AddBehaviorOverheadNameControls(context)
    context.layout:Space(6)
    AddSection(context.content, context.layout, "BLIZZARD OVERHEAD NAMES")
    CreateBehaviorToggle(context, "Hide critter and companion names",
        "Hides Blizzard overhead names for noncombat critters and companions.",
        GetHideCritterCompanionNames, SetHideCritterCompanionNames)
end

local function CreateBehaviorPanel()
    local panel, content, layout = CreateScrollablePanel("Behavior")
    AddTitle(content, layout, "Simple Nameplates — Behavior")
    AddDescription(content, layout,
        "Global addon behavior and user preferences. These settings do not change with the appearance profile.")

    local context = { content = content, layout = layout, refreshers = {} }
    AddSection(content, layout, "ADDON")
    CreateBehaviorToggle(context, "Enable Simple Nameplates styling", nil,
        GetStylingEnabled, SetStylingEnabled, HandleStylingChanged)
    AddBehaviorCategoryControls(context)
    AddBehaviorOverheadNameControls(context)

    panel:SetScript("OnShow", function() RunRefreshers(context.refreshers) end)
    layout:Finish()
    return panel
end

ns.SettingsPanels.Behavior = CreateBehaviorPanel
