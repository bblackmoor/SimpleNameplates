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
local Capabilities = ns.PresentationCapabilities
local GetContext = ns.WorldContext.Get
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

local function DebugRegionValue(region, methodName, valueType, context)
    if not region then return "not found" end
    local value = Capabilities.ReadRegion(region, methodName, context)
    if valueType == "boolean" then return DebugBoolean(value) end
    return DebugValue(value)
end

local function DebugContext(context)
    print("|cff0cd29fSimple Nameplates context:|r revision " .. context.revision
        .. "; initialized: " .. DebugBoolean(context.initialized))
    print("  Zone: " .. DebugValue(context.zone) .. "; subzone: " .. DebugValue(context.subzone)
        .. "; map: " .. DebugValue(context.mapID) .. "; territory: " .. DebugValue(context.territory)
        .. "; sanctuary: " .. DebugBoolean(context.sanctuary)
        .. "; territory faction: " .. DebugValue(context.territoryFaction)
        .. "; subzone PvP: " .. DebugBoolean(context.subzonePvP))
    print("  Instance: " .. DebugBoolean(context.inInstance) .. "; type: " .. DebugValue(context.instanceType)
        .. "; name: " .. DebugValue(context.instanceName) .. "; player faction: " .. DebugValue(context.playerFaction))
    print("  War Mode desired: " .. DebugBoolean(context.warModeDesired)
        .. "; active: " .. DebugBoolean(context.warModeActive)
        .. "; player PvP: " .. DebugBoolean(context.playerPvP)
        .. "; free-for-all: " .. DebugBoolean(context.freeForAll)
        .. "; player combat: " .. DebugBoolean(context.inCombat)
        .. "; combat lockdown: " .. DebugBoolean(context.combatLockdown))
end

local function DebugClassification(unit, state, hasNameplate)
    local display, colorHex
    if not hasNameplate then
        display = "no accessible nameplate; world-name display unknown"
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

local function DebugNameRegion(assessment, context)
    local nameRegion = assessment.canAccess and assessment.name or nil
    local nameParent = Capabilities.ReadRegion(nameRegion, "GetParent", context)
    print("  Name region: " .. (nameRegion and "found" or "not found")
        .. "; text: " .. DebugRegionValue(nameRegion, "GetText", nil, context)
        .. "; shown: " .. DebugRegionValue(nameRegion, "IsShown", "boolean", context)
        .. "; visible: " .. DebugRegionValue(nameRegion, "IsVisible", "boolean", context)
        .. "; alpha: " .. DebugRegionValue(nameRegion, "GetAlpha", nil, context))
    print("  Name parent shown: " .. DebugRegionValue(nameParent, "IsShown", "boolean", context)
        .. "; visible: " .. DebugRegionValue(nameParent, "IsVisible", "boolean", context))
end

local function DebugPresentation(assessment, context)
    print("  Presentation access: " .. assessment.status .. "; blocked region: " .. DebugValue(assessment.reason)
        .. "; name: " .. DebugBoolean(assessment.hasName)
        .. "; health bar: " .. DebugBoolean(assessment.hasHealthBar)
        .. "; cast bar: " .. DebugBoolean(assessment.hasCastBar))
    local bar = assessment.canAccess and assessment.healthBar or nil
    print("  Health bar shown: " .. DebugRegionValue(bar, "IsShown", "boolean", context)
        .. "; visible: " .. DebugRegionValue(bar, "IsVisible", "boolean", context))
    local castBar = assessment.canAccess and assessment.castBar or nil
    local icon = Capabilities.SafeField(castBar, "Icon", context)
    local highlight = Capabilities.SafeField(assessment.frame, "SNPInterruptibleHighlight", context)
    local overlay = Capabilities.SafeField(highlight, "frame", context)
    local hookedIcon = Capabilities.SafeField(highlight, "hookedIcon", context)
    print("  Interruptible highlight: enabled "
        .. (GetInterruptibleHighlightEnabled() and "yes" or "no")
        .. "; cast icon found " .. (icon and "yes" or "no")
        .. "; hook installed " .. (icon and hookedIcon == icon and "yes" or "no")
        .. "; highlight shown " .. DebugRegionValue(overlay, "IsShown", "boolean", context))
end

local function DebugUnit(unit, context)
    context = context or GetContext()
    DebugContext(context)
    if AccessibleBoolean(UnitExists(unit)) ~= true then
        print("|cff0cd29fSimple Nameplates:|r No target selected.")
        return
    end

    local name = DebugValue(UnitName(unit))
    local state = StateForUnit(unit, context)
    local reaction = AccessibleNumber(UnitReaction(unit, "player"))
    local assessment = Capabilities.InspectUnit(unit, context)
    print("|cff0cd29fSimple Nameplates debug:|r " .. name)
    DebugClassification(unit, state, assessment.canAccess)
    DebugUnitRelationships(unit, reaction)
    DebugNameRegion(assessment, context)
    DebugPresentation(assessment, context)
end


ns.DebugUnit = DebugUnit
