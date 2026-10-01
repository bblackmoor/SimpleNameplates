-- Simple Nameplates: targeted-unit relationship and presentation diagnostics.
local _, ns = ...
local UnitExists, UnitName = UnitExists, UnitName
local UnitIsPlayer, UnitPlayerControlled = UnitIsPlayer, UnitPlayerControlled
local UnitIsOwnerOrControllerOfUnit = UnitIsOwnerOrControllerOfUnit
local UnitReaction, UnitFactionGroup = UnitReaction, UnitFactionGroup
local UnitCanAttack, UnitIsPVP, UnitThreatSituation = UnitCanAttack, UnitIsPVP, UnitThreatSituation
local AccessibleBoolean, AccessibleNumber, AccessibleValue =
    ns.AccessibleBoolean, ns.AccessibleNumber, ns.AccessibleValue
local StateForUnit, IsNameOnlyState =
    ns.NameplateClassification.StateForUnit, ns.NameplateClassification.IsNameOnlyState
local TargetsPlayerControlledUnit = ns.NameplateClassification.TargetsPlayerControlledUnit
local GetUnitFrame, GetCastBar = ns.NameplateFrames.GetUnitFrame, ns.NameplateFrames.GetCastBar
local EnsureInterruptibleHighlight = ns.CastHighlight.EnsureInterruptibleHighlight
local GetStylingEnabled, GetReplaceBlizzardOverheadNames =
    ns.GetStylingEnabled, ns.GetReplaceBlizzardOverheadNames
local PriorityColorForState, GetCategoryMode = ns.PriorityColorForState, ns.GetCategoryMode
local GetInterruptibleHighlightEnabled = ns.GetInterruptibleHighlightEnabled

local function DebugBoolean(value)
    value = AccessibleBoolean(value)
    if value == nil then return "restricted/unavailable" end
    return value and "yes" or "no"
end

local function DebugValue(value)
    value = AccessibleValue(value)
    return value == nil and "restricted/unavailable" or tostring(value)
end

local function DebugRegionValue(region, methodName, valueType)
    if not region then return "not found" end
    local method = region[methodName]
    if type(method) ~= "function" then return "unavailable" end
    local ok, value = pcall(method, region)
    if not ok then return "unavailable" end

    if valueType == "boolean" then
        value = AccessibleBoolean(value)
        if value == nil then return "restricted/unavailable" end
        return value and "yes" or "no"
    end

    return DebugValue(value)
end

local function DebugClassification(unit, state, hasNameplate)
    local display, colorHex
    if not hasNameplate and GetReplaceBlizzardOverheadNames() then
        display = "replacement requested; no nameplate frame"
        colorHex = "not displayed by Simple Nameplates"
    else
        local r, g, b = PriorityColorForState(state)
        colorHex = string.format("#%02X%02X%02X", math.floor(r * 255 + 0.5),
            math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
        display = IsNameOnlyState(state) and "colored name only" or "white name with colored health bar"
    end
    print("  Styling enabled: " .. (GetStylingEnabled() and "yes" or "no")
        .. "; overhead replacement: " .. (GetReplaceBlizzardOverheadNames() and "yes" or "no")
        .. "; nameplate frame: " .. (hasNameplate and "yes" or "no")
        .. "; detected state: " .. state .. "; mode: " .. GetCategoryMode(state)
        .. "; display: " .. display .. "; color: " .. colorHex)
end

local function DebugUnitRelationships(unit, reaction)
    print("  Player: " .. DebugBoolean(UnitIsPlayer(unit))
        .. "; player-controlled: " .. DebugBoolean(UnitPlayerControlled(unit))
        .. "; owned/controlled by you: " .. DebugBoolean(UnitIsOwnerOrControllerOfUnit and UnitIsOwnerOrControllerOfUnit("player", unit)))
    print("  Reaction: " .. (reaction and tostring(reaction) or "restricted/unavailable")
        .. "; faction: " .. DebugValue(UnitFactionGroup(unit))
        .. "; you can attack: " .. DebugBoolean(UnitCanAttack("player", unit))
        .. "; it can attack you: " .. DebugBoolean(UnitCanAttack(unit, "player"))
        .. "; PvP flagged: " .. DebugBoolean(UnitIsPVP(unit)))
    print("  Threat on you: " .. DebugValue(UnitThreatSituation("player", unit))
        .. "; threat on pet: " .. DebugValue(UnitThreatSituation("pet", unit))
        .. "; targeting your controlled unit: " .. (TargetsPlayerControlledUnit(unit) and "yes" or "no"))
end

local function DebugNameRegion(unitFrame)
    local nameRegion = unitFrame and unitFrame.name or nil
    local nameParent = nameRegion and nameRegion.GetParent and nameRegion:GetParent() or nil
    print("  Name region: " .. (nameRegion and "found" or "not found")
        .. "; text: " .. DebugRegionValue(nameRegion, "GetText")
        .. "; shown: " .. DebugRegionValue(nameRegion, "IsShown", "boolean")
        .. "; visible: " .. DebugRegionValue(nameRegion, "IsVisible", "boolean")
        .. "; alpha: " .. DebugRegionValue(nameRegion, "GetAlpha"))
    print("  Name parent: " .. (nameParent and "found" or "not found")
        .. "; shown: " .. DebugRegionValue(nameParent, "IsShown", "boolean")
        .. "; visible: " .. DebugRegionValue(nameParent, "IsVisible", "boolean")
        .. "; alpha: " .. DebugRegionValue(nameParent, "GetAlpha"))
end

local function DebugInterruptibleHighlight(unitFrame)
    local castBar = GetCastBar(unitFrame)
    local highlight = unitFrame and EnsureInterruptibleHighlight(unitFrame) or nil
    local icon = castBar and castBar.Icon or nil
    local highlightShown = false
    if highlight and highlight.frame then
        local ok, shown = pcall(highlight.frame.IsShown, highlight.frame)
        highlightShown = ok and shown == true
    end
    print("  Interruptible highlight: enabled "
        .. (GetInterruptibleHighlightEnabled() and "yes" or "no")
        .. "; cast bar found " .. (castBar and "yes" or "no")
        .. "; cast icon found " .. (icon and "yes" or "no")
        .. "; hook installed " .. (highlight and highlight.hookedIcon == icon and icon ~= nil and "yes" or "no")
        .. "; highlight shown " .. (highlightShown and "yes" or "no"))
end

local function DebugUnit(unit)
    if AccessibleBoolean(UnitExists(unit)) ~= true then
        print("|cff0cd29fSimple Nameplates:|r No target selected.")
        return
    end

    local name = DebugValue(UnitName(unit))
    local state = StateForUnit(unit)
    local reaction = AccessibleNumber(UnitReaction(unit, "player"))
    local unitFrame = GetUnitFrame(unit)
    print("|cff0cd29fSimple Nameplates debug:|r " .. name)
    DebugClassification(unit, state, unitFrame ~= nil)
    DebugUnitRelationships(unit, reaction)
    DebugNameRegion(unitFrame)
    DebugInterruptibleHighlight(unitFrame)
end


ns.DebugUnit = DebugUnit
