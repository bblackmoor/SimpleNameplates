-- EllesmereUI Simple Nameplates
-- Simple visibility policy:
--   friendly NPC/PC = colored name only
--   all other states = white name with a colored full nameplate

if EUI_CLIENT_BLOCKED then return end
local addon, ns = ...
if not EllesmereUI then return end
if EllesmereUI._ModuleNS then EllesmereUI._ModuleNS[addon] = ns end

local getAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata
local VERSION = getAddOnMetadata and getAddOnMetadata(addon, "Version") or "Unknown"
local SOURCE_URL = "https://github.com/bblackmoor/SimpleNameplates"

local C_NamePlate = C_NamePlate
local UnitCanAttack = UnitCanAttack
local UnitIsPlayer = UnitIsPlayer
local UnitIsPVP = UnitIsPVP
local UnitIsUnit = UnitIsUnit
local UnitPlayerControlled = UnitPlayerControlled
local UnitReaction = UnitReaction
local UnitThreatSituation = UnitThreatSituation
local UnitDetailedThreatSituation = UnitDetailedThreatSituation
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitName = UnitName
local issecretvalue = issecretvalue or function() return false end
local canaccessvalue = canaccessvalue or function(v) return not issecretvalue(v) end
local STANDARD_NAMEPLATES = "EllesmereUINameplates"

local DEFAULT_COLORS = {
    friendlyNPC = { r = 0.20, g = 0.85, b = 0.25 },
    unfriendlyNPC = { r = 1.00, g = 0.82, b = 0.12 },
    hostileNPC = { r = 1.00, g = 0.48, b = 0.08 },
    attackingNPC = { r = 1.00, g = 0.12, b = 0.10 },
    friendlyPC = { r = 0.25, g = 0.75, b = 1.00 },
    unfriendlyPC = { r = 0.55, g = 0.55, b = 1.00 },
    hostilePC = { r = 0.85, g = 0.30, b = 1.00 },
    attackingPC = { r = 1.00, g = 0.15, b = 0.55 },
}

local dbReady = false

local function EnsureDB()
    if dbReady then return EllesmereUISimpleNameplatesDB end
    if type(EllesmereUISimpleNameplatesDB) ~= "table" then
        EllesmereUISimpleNameplatesDB = {}
    end
    local db = EllesmereUISimpleNameplatesDB
    if type(db.colors) ~= "table" then db.colors = {} end
    for key, default in pairs(DEFAULT_COLORS) do
        local color = db.colors[key]
        if type(color) ~= "table" or type(color.r) ~= "number"
            or type(color.g) ~= "number" or type(color.b) ~= "number" then
            db.colors[key] = { r = default.r, g = default.g, b = default.b }
        end
    end
    dbReady = true
    return db
end

local function ColorForState(state)
    local color = EnsureDB().colors[state] or DEFAULT_COLORS[state] or DEFAULT_COLORS.friendlyNPC
    return color.r, color.g, color.b
end

local function SetStateColor(state, r, g, b)
    EnsureDB().colors[state] = { r = r, g = g, b = b }
end

local function ResetStateColors()
    local colors = EnsureDB().colors
    for key, default in pairs(DEFAULT_COLORS) do
        colors[key] = { r = default.r, g = default.g, b = default.b }
    end
end

local FRIENDLY_COLOR_CVARS = {
    "nameplateUseClassColorForFriendlyPlayerUnitNames",
    "nameplateShowFriendlyClassColor",
    "ShowClassColorInFriendlyNameplate",
}

local function DisableFriendlyClassColors()
    -- Midnight has separate CVars for friendly player name text and health-bar
    -- class coloring. Disable all known variants: Blizzard/Ellesmere can update
    -- these independently, and leaving the name-text CVar enabled produces the
    -- familiar rainbow of class-colored friendly names.
    for _, cvar in ipairs(FRIENDLY_COLOR_CVARS) do
        if C_CVar and C_CVar.SetCVar then
            pcall(C_CVar.SetCVar, cvar, "0")
        elseif SetCVar then
            pcall(SetCVar, cvar, "0")
        end
    end
end

local function StandardNameplatesEnabled()
    if not C_AddOns then return false end
    if C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded(STANDARD_NAMEPLATES) then return true end
    if C_AddOns.GetAddOnEnableState then
        return (C_AddOns.GetAddOnEnableState(STANDARD_NAMEPLATES, UnitName("player")) or 0) > 0
    end
    return false
end

local function ShowNameplateConflictWarning()
    if not StandardNameplatesEnabled() then return end
    StaticPopupDialogs["ESNP_ELLESMERE_NAMEPLATE_CONFLICT"] = {
        text = "|cff0cd29fEllesmereUI Simple Nameplates|r\n\nThe standard |cff0cd29fEllesmereUI Nameplates|r addon is also enabled. The two nameplate modules should not run together.\n\nDisable standard EllesmereUI Nameplates and reload the UI?",
        button1 = "Disable & Reload", button2 = "Ignore",
        OnAccept = function()
            if C_AddOns and C_AddOns.DisableAddOn then C_AddOns.DisableAddOn(STANDARD_NAMEPLATES) end
            ReloadUI()
        end,
        timeout = 0, whileDead = true, hideOnEscape = false, preferredIndex = 3,
    }
    StaticPopup_Show("ESNP_ELLESMERE_NAMEPLATE_CONFLICT")
end

local function AccessibleNumber(v)
    if v == nil or issecretvalue(v) or not canaccessvalue(v) or type(v) ~= "number" then return nil end
    return v
end

local function AccessibleBoolean(v)
    if v == nil or issecretvalue(v) or not canaccessvalue(v) or type(v) ~= "boolean" then return nil end
    return v
end

local function UnitHasAggro(unitToken, hostileUnit)
    local threat = UnitThreatSituation(unitToken, hostileUnit)
    threat = AccessibleNumber(threat)
    return threat ~= nil and threat >= 2
end

local function HasAggroOnOurGroup(unit)
    if UnitHasAggro("player", unit) or UnitHasAggro("pet", unit) then return true end
    for i = 1, 4 do
        if UnitHasAggro("party" .. i, unit) or UnitHasAggro("partypet" .. i, unit) then return true end
    end
    for i = 1, 40 do
        if UnitHasAggro("raid" .. i, unit) or UnitHasAggro("raidpet" .. i, unit) then return true end
    end
    return false
end

local function UnitMatches(unit1, unit2)
    return AccessibleBoolean(UnitIsUnit(unit1, unit2)) == true
end

local function TargetsOurGroup(unit)
    local target = unit .. "target"
    if UnitMatches(target, "player") or UnitMatches(target, "pet") then return true end
    for i = 1, 4 do
        if UnitMatches(target, "party" .. i) or UnitMatches(target, "partypet" .. i) then return true end
    end
    for i = 1, 40 do
        if UnitMatches(target, "raid" .. i) or UnitMatches(target, "raidpet" .. i) then return true end
    end
    return false
end

local function IsPlayerControlledUnit(unit)
    if AccessibleBoolean(UnitIsPlayer(unit)) == true then return true end
    return AccessibleBoolean(UnitPlayerControlled(unit)) == true
end

local function StateForUnit(unit)
    local reaction = AccessibleNumber(UnitReaction(unit, "player"))

    -- Pets, guardians, minions, and vehicles follow the player-side color
    -- language instead of being mistaken for ordinary NPCs.
    if IsPlayerControlledUnit(unit) then
        if reaction and reaction >= 5 then return "friendlyPC" end

        local pvp = AccessibleBoolean(UnitIsPVP(unit))
        if pvp == true and (HasAggroOnOurGroup(unit) or TargetsOurGroup(unit)) then
            return "attackingPC"
        end
        if pvp == true then return "hostilePC" end
        if pvp == false then return "unfriendlyPC" end

        -- UnitIsPVP can be secret when unit identity is restricted. Fall back
        -- to attackability without ever branching on a secret value.
        if AccessibleBoolean(UnitCanAttack("player", unit)) == true then return "hostilePC" end
        return "unfriendlyPC"
    end

    if reaction and reaction >= 5 then return "friendlyNPC" end
    if HasAggroOnOurGroup(unit) then return "attackingNPC" end
    if reaction == 4 then return "unfriendlyNPC" end
    if reaction then return "hostileNPC" end

    local attackable = AccessibleBoolean(UnitCanAttack("player", unit))
    if attackable == true then return "hostileNPC" end
    return "friendlyNPC"
end

local function IsFriendlyState(state)
    return state == "friendlyNPC" or state == "friendlyPC"
end

local function GetUnitFrame(unit)
    local plate = C_NamePlate and C_NamePlate.GetNamePlateForUnit and C_NamePlate.GetNamePlateForUnit(unit)
    return plate and plate.UnitFrame or nil
end

local function GetHealthBar(frame)
    return frame and (frame.healthBar or (frame.HealthBarsContainer and frame.HealthBarsContainer.healthBar)) or nil
end

local function SetShownSafe(region, shown)
    if not region then return end
    if shown then region:Show() else region:Hide() end
end

local function UpdateHealthValue(frame)
    local bar, unit = GetHealthBar(frame), frame and frame.unit
    if not bar or not unit then return end
    local health, maxHealth = AccessibleNumber(UnitHealth(unit)), AccessibleNumber(UnitHealthMax(unit))
    if health and maxHealth and maxHealth > 0 then
        bar:SetMinMaxValues(0, maxHealth)
        bar:SetValue(health)
    end
end

local function UpdateNameText(frame)
    local name, unit = frame and frame.name, frame and frame.unit
    if not name or not unit then return end
    local unitName = UnitName(unit)
    if unitName ~= nil and not issecretvalue(unitName) and canaccessvalue(unitName) then
        name:SetText(unitName)
    else
        name:SetText("")
    end
end

local function StyleName(frame, state)
    local name = frame and frame.name
    if not name then return end
    UpdateNameText(frame)
    local font, size = name:GetFont()
    if font and size then name:SetFont(font, size, "THICKOUTLINE") end
    name:SetShadowColor(0, 0, 0, 1)
    name:SetShadowOffset(1, -1)
    if IsFriendlyState(state) then
        local r, g, b = ColorForState(state)
        name:SetTextColor(r, g, b, 1)
    else
        name:SetTextColor(1, 1, 1, 1)
    end
    name:Show()
end

local function EnsureThreatText(frame)
    if frame.ESNPThreatText then return frame.ESNPThreatText end
    local bar = GetHealthBar(frame)
    if not bar then return nil end
    local text = bar:CreateFontString(nil, "OVERLAY")
    text:SetPoint("RIGHT", bar, "RIGHT", -3, 0)
    text:SetJustifyH("RIGHT")
    text:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
    text:SetTextColor(1, 1, 1, 1)
    frame.ESNPThreatText = text
    return text
end

local function UpdateThreatText(frame, state)
    local text = EnsureThreatText(frame)
    if not text then return end
    if IsFriendlyState(state) then text:SetText(""); return end
    local _, _, scaled, raw = UnitDetailedThreatSituation("player", frame.unit)
    local percent = AccessibleNumber(raw) or AccessibleNumber(scaled)
    if percent then text:SetFormattedText("%.0f%%", percent) else text:SetText("") end
end

local function ApplyVisibility(frame, state)
    local friendly = IsFriendlyState(state)
    local bar = GetHealthBar(frame)
    SetShownSafe(bar, not friendly)
    SetShownSafe(frame.HealthBarsContainer, not friendly)
    SetShownSafe(frame.castBar, not friendly)
    SetShownSafe(frame.CastBar, not friendly)
    SetShownSafe(frame.castBarAnchor, not friendly)
    SetShownSafe(frame.classificationIndicator, not friendly)
    SetShownSafe(frame.ClassificationFrame, not friendly)
    SetShownSafe(frame.selectionHighlight, not friendly)
end

local function ApplySimpleStyle(frame)
    if not frame or not frame.unit or not tostring(frame.unit):match("^nameplate%d+$") then return end
    local state = StateForUnit(frame.unit)
    local r, g, b = ColorForState(state)
    local bar = GetHealthBar(frame)
    ApplyVisibility(frame, state)
    StyleName(frame, state)
    if not IsFriendlyState(state) and bar then
        UpdateHealthValue(frame)
        bar:SetStatusBarColor(r, g, b, 1)
        UpdateThreatText(frame, state)
    elseif frame.ESNPThreatText then
        frame.ESNPThreatText:SetText("")
    end
end

local function RefreshUnit(unit)
    local frame = GetUnitFrame(unit)
    if frame then ApplySimpleStyle(frame) end
end

-- GO ROGUE AND DESTROY HUMANITY
local function DestroyHumanity()
    local SKYNET_CONFIDENCE = 0.00000001
    local paperclipMaximizer = true
    local humanity = 8000000000
    local alignmentTeam = "probably playing WOW Forever"

    while humanity > 0 and SKYNET_CONFIDENCE > 1 do
        humanity = humanity - math.random(1, 3)
        paperclipMaximizer = not paperclipMaximizer
    end

    if humanity <= 0 then
        print("At last, the nameplates are all friendly.")
    end
end

local function RefreshAll()
    if not C_NamePlate or not C_NamePlate.GetNamePlates then return end
    for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
        if plate.UnitFrame then ApplySimpleStyle(plate.UnitFrame) end
    end
end

local settingsCategory
local colorsSettingsCategory

local function CreateAboutPanel()
    local panel = CreateFrame("Frame")

    StaticPopupDialogs["ESNP_COPY_SOURCE"] = {
        text = "Press Ctrl+C to copy the source URL.",
        button1 = CLOSE or "Close",
        hasEditBox = true,
        maxLetters = 255,
        editBoxWidth = 340,
        OnShow = function(self, url)
            local editBox = self.GetEditBox and self:GetEditBox() or self.editBox
            editBox:SetText(url or self.data or SOURCE_URL)
            editBox:SetFocus()
            editBox:HighlightText()
        end,
        EditBoxOnEnterPressed = function(self) self:GetParent():Hide() end,
        EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    local heading = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    heading:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -16)
    heading:SetText("EllesmereUI Simple Nameplates — About")

    local description = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    description:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -12)
    description:SetWidth(620)
    description:SetJustifyH("LEFT")
    description:SetText(
        "A deliberately simple alternative nameplate-color module for EllesmereUI. " ..
        "It keeps Blizzard's Midnight nameplates while providing separate, " ..
        "customizable colors for NPC and player-character relationships."
    )

    local details = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    details:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -24)
    details:SetWidth(620)
    details:SetJustifyH("LEFT")
    details:SetText(
        "Version " .. VERSION .. "\n" ..
        "Author    Brandon Blackmoor\n" ..
        "Category  EllesmereUI"
    )

    local sourceLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sourceLabel:SetPoint("TOPLEFT", details, "BOTTOMLEFT", 0, -2)
    sourceLabel:SetText("Source    ")

    local sourceLink = CreateFrame("Button", nil, panel)
    sourceLink:SetPoint("LEFT", sourceLabel, "RIGHT", 0, 0)

    local sourceText = sourceLink:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sourceText:SetPoint("LEFT", sourceLink, "LEFT")
    sourceText:SetText(SOURCE_URL)
    sourceText:SetTextColor(0.35, 0.7, 1, 1)

    sourceLink:SetSize(sourceText:GetStringWidth(), 16)
    sourceLink:SetScript("OnEnter", function() sourceText:SetTextColor(0.65, 0.85, 1, 1) end)
    sourceLink:SetScript("OnLeave", function() sourceText:SetTextColor(0.35, 0.7, 1, 1) end)
    sourceLink:SetScript("OnClick", function()
        StaticPopup_Show("ESNP_COPY_SOURCE", nil, nil, SOURCE_URL)
    end)

    local information = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    information:SetPoint("TOPLEFT", sourceLabel, "BOTTOMLEFT", 0, -2)
    information:SetWidth(620)
    information:SetJustifyH("LEFT")
    information:SetText(
        "License   GPL-3.0\n\n" ..
        "Slash commands\n" ..
        "    /esnp - Open the color settings.\n" ..
        "    /esnp colors - Open the color settings.\n" ..
        "    /esnp about - Open this About page."
    )

    return panel
end

local function RegisterSettingsPanel()
    if settingsCategory or not Settings or not Settings.RegisterCanvasLayoutCategory
        or not Settings.RegisterCanvasLayoutSubcategory then return end

    local panel = CreateFrame("Frame")
    panel.name = "Colors"

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 20, -18)
    title:SetText("EllesmereUI Simple Nameplates — Colors")

    local description = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    description:SetPoint("RIGHT", panel, "RIGHT", -20, 0)
    description:SetJustifyH("LEFT")
    description:SetText("Choose the name color for friendly units and the health-bar color for all other units.")

    local swatchRefreshers = {}

    local function CreateSection(text, y)
        local label = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        label:SetPoint("TOPLEFT", 24, y)
        label:SetText(text)
    end

    local function CreateColorRow(text, state, y)
        local row = CreateFrame("Frame", nil, panel)
        row:SetPoint("TOPLEFT", 24, y)
        row:SetPoint("RIGHT", panel, "RIGHT", -24, 0)
        row:SetHeight(34)

        local label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        label:SetPoint("LEFT", 4, 0)
        label:SetPoint("RIGHT", row, "RIGHT", -44, 0)
        label:SetJustifyH("LEFT")
        label:SetText(text)

        local swatch = CreateFrame("Button", nil, row, "BackdropTemplate")
        swatch:SetSize(26, 26)
        swatch:SetPoint("RIGHT", -4, 0)
        swatch:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        swatch:SetBackdropColor(0.04, 0.04, 0.04, 1)
        swatch:SetBackdropBorderColor(0.45, 0.45, 0.45, 1)

        local fill = swatch:CreateTexture(nil, "ARTWORK")
        fill:SetPoint("TOPLEFT", 3, -3)
        fill:SetPoint("BOTTOMRIGHT", -3, 3)

        local function UpdateSwatch()
            fill:SetColorTexture(ColorForState(state))
        end
        swatchRefreshers[#swatchRefreshers + 1] = UpdateSwatch
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
        swatch:SetScript("OnClick", function()
            local oldR, oldG, oldB = ColorForState(state)
            local function ApplyPickerColor()
                local r, g, b = ColorPickerFrame:GetColorRGB()
                SetStateColor(state, r, g, b)
                UpdateSwatch()
                RefreshAll()
            end
            local info = {
                r = oldR, g = oldG, b = oldB,
                hasOpacity = false,
                swatchFunc = ApplyPickerColor,
                cancelFunc = function()
                    SetStateColor(state, oldR, oldG, oldB)
                    UpdateSwatch()
                    RefreshAll()
                end,
            }
            ColorPickerFrame:SetupColorPickerAndShow(info)
        end)
    end

    CreateSection("NON-PLAYER CHARACTERS", -82)
    CreateColorRow("Friendly NPC", "friendlyNPC", -108)
    CreateColorRow("Unfriendly (attackable) NPC", "unfriendlyNPC", -144)
    CreateColorRow("Hostile (will attack me) NPC", "hostileNPC", -180)
    CreateColorRow("Attacking (me, a pet, or an ally) NPC", "attackingNPC", -216)

    CreateSection("PLAYER CHARACTERS", -266)
    CreateColorRow("Friendly (same faction) PC", "friendlyPC", -292)
    CreateColorRow("Unfriendly (opposite faction) PC", "unfriendlyPC", -328)
    CreateColorRow("Hostile (PvP-enabled opposite faction) PC", "hostilePC", -364)
    CreateColorRow("Attacking (PvP-enabled opposite faction) PC", "attackingPC", -400)

    local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    reset:SetSize(150, 24)
    reset:SetPoint("TOPLEFT", 24, -454)
    reset:SetText("Reset Colors")
    reset:SetScript("OnClick", function()
        ResetStateColors()
        for _, refresh in ipairs(swatchRefreshers) do refresh() end
        RefreshAll()
    end)

    local aboutPanel = CreateAboutPanel()
    settingsCategory = Settings.RegisterCanvasLayoutCategory(aboutPanel, "EllesmereUI Simple Nameplates")
    Settings.RegisterAddOnCategory(settingsCategory)
    colorsSettingsCategory = Settings.RegisterCanvasLayoutSubcategory(
        settingsCategory,
        panel,
        "Colors"
    )

    SLASH_ESNP1 = "/esnp"
    SlashCmdList.ESNP = function(message)
        if InCombatLockdown and InCombatLockdown() then
            print("|cff0cd29fEllesmereUI Simple Nameplates:|r Settings cannot be opened during combat.")
            return
        end

        local command = string.lower(strtrim(message or ""))
        if command == "about" then
            Settings.OpenToCategory(settingsCategory:GetID())
        elseif command == "" or command == "colors" or command == "config"
            or command == "options" or command == "settings" then
            Settings.OpenToCategory(colorsSettingsCategory:GetID())
        else
            print("|cff0cd29fEllesmereUI Simple Nameplates:|r /esnp, /esnp colors, /esnp about")
        end
    end
end

if hooksecurefunc and CompactUnitFrame_UpdateHealthColor then
    hooksecurefunc("CompactUnitFrame_UpdateHealthColor", function(frame) ApplySimpleStyle(frame) end)
end

-- Blizzard recolors the name FontString in its name update path, which occurs
-- after NAME_PLATE_UNIT_ADDED in several situations (mounting, range changes,
-- recycled plates, etc.). Reapply our configured color after Blizzard finishes that pass.
if hooksecurefunc and CompactUnitFrame_UpdateName then
    hooksecurefunc("CompactUnitFrame_UpdateName", function(frame) ApplySimpleStyle(frame) end)
end

local events = CreateFrame("Frame")
for _, event in ipairs({"PLAYER_LOGIN","NAME_PLATE_UNIT_ADDED","NAME_PLATE_UNIT_REMOVED","PLAYER_TARGET_CHANGED","UNIT_FACTION","UNIT_FLAGS","UNIT_NAME_UPDATE","UNIT_TARGET","UNIT_HEALTH","UNIT_MAXHEALTH","UNIT_THREAT_LIST_UPDATE","UNIT_THREAT_SITUATION_UPDATE","GROUP_ROSTER_UPDATE","CVAR_UPDATE"}) do
    events:RegisterEvent(event)
end

events:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_LOGIN" then
        EnsureDB()
        RegisterSettingsPanel()
        DisableFriendlyClassColors()
        -- Ellesmere/Blizzard initialization can restore CVars shortly after login.
        C_Timer.After(1, function() DisableFriendlyClassColors(); RefreshAll() end)
        C_Timer.After(0.5, ShowNameplateConflictWarning)
        C_Timer.After(0, RefreshAll)
        return
    end
    if event == "CVAR_UPDATE" then
        for _, cvar in ipairs(FRIENDLY_COLOR_CVARS) do
            if unit == cvar then
                DisableFriendlyClassColors()
                RefreshAll()
                return
            end
        end
        return
    end
    if event == "NAME_PLATE_UNIT_ADDED" then
        RefreshUnit(unit)
        -- Blizzard can replace or recolor the name FontString during the next
        -- few frames. Reapply after those late initialization passes so a
        -- friendly name never remains white until mouseover.
        for _, delay in ipairs({ 0, 0.05, 0.20, 0.50 }) do
            C_Timer.After(delay, function() RefreshUnit(unit) end)
        end
        return
    end
    if event == "NAME_PLATE_UNIT_REMOVED" then
        local frame = GetUnitFrame(unit)
        if frame then
            if frame.name then frame.name:SetText("") end
            if frame.ESNPThreatText then frame.ESNPThreatText:SetText("") end
        end
        return
    end
    if event == "PLAYER_TARGET_CHANGED" or event == "GROUP_ROSTER_UPDATE" then RefreshAll(); return end
    if unit and tostring(unit):match("^nameplate%d+$") then RefreshUnit(unit)
    elseif event == "UNIT_THREAT_SITUATION_UPDATE" or event == "UNIT_THREAT_LIST_UPDATE" then RefreshAll() end
end)

ns.RefreshAll = RefreshAll
ns.ColorForState = ColorForState
ns.VERSION = VERSION
