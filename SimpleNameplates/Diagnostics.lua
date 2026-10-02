-- Simple Nameplates: targeted-unit relationship and presentation diagnostics.
local _, ns = ...
local UnitExists, UnitName = UnitExists, UnitName
local AccessibleBoolean, AccessibleValue = ns.AccessibleBoolean, ns.AccessibleValue
local StateForUnit = ns.NameplateClassification.StateForUnit
local Resolve = ns.PresentationRules.Resolve
local Capabilities = ns.PresentationCapabilities
local GetContext = ns.WorldContext.Get
local GetStylingEnabled = ns.GetStylingEnabled
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

local function ReadUnitAPI(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, ...)
    if ok then return AccessibleValue(value) end
end

local function SameUnit(candidate, unit)
    if type(candidate) ~= "string" then return nil end
    local same = AccessibleBoolean(ReadUnitAPI(UnitIsUnit, candidate, unit))
    if same ~= nil then return same end
    -- Never use displayed names for identity; readable GUIDs are a fallback.
    local a, b = ReadUnitAPI(UnitGUID, candidate), ReadUnitAPI(UnitGUID, unit)
    if type(a) == "string" and a ~= "" and type(b) == "string" and b ~= "" then
        return a == b
    end
end

local function FindDiagnosticPlates(unit, context)
    local matches, seen, candidates = {}, {}, {}
    local direct = Capabilities.InspectUnit(unit, context)
    if direct.frame then
        matches[#matches + 1] = {assessment = direct, source = "direct lookup"}
        seen[direct.frame] = true
    end
    local plates = ReadUnitAPI(C_NamePlate and C_NamePlate.GetNamePlates)
    local scanned, unknown = 0, 0
    if type(plates) == "table" then
        for _, plate in pairs(plates) do
            scanned = scanned + 1
            local frame = Capabilities.SafeField(plate, "UnitFrame", context)
            local token = Capabilities.SafeField(frame, "unit", context)
            local same = SameUnit(token, unit)
            local assessment = Capabilities.InspectFrame(frame, context)
            candidates[#candidates + 1] = {assessment = assessment, token = token,
                targetMatch = same, plateStatus = Capabilities.ObjectStatus(plate, context),
                plateShown = Capabilities.ReadRegion(plate, "IsShown", context),
                plateVisible = Capabilities.ReadRegion(plate, "IsVisible", context)}
            if same == true and not seen[frame] then
                matches[#matches + 1] = {assessment = assessment,
                    source = "enumerated unit match", token = token}
                seen[frame] = true
            elseif same == nil then unknown = unknown + 1 end
        end
    end
    return matches, direct, scanned, unknown, type(plates) == "table", candidates
end

local function DebugAddonText(assessment, context)
    local frame = assessment.frame
    local function Field(object, key) return Capabilities.SafeField(object, key, context) end
    local cached = Field(frame, "SNPNameStyle")
    local decision = Field(frame, "SNPPresentation")
    print("  Simple Nameplates markers: state " .. DebugValue(Field(frame, "SNPState"))
        .. "; frame unit: " .. DebugValue(Field(frame, "unit"))
        .. "; original unit: " .. DebugValue(Field(frame, "SNPOriginalUnit"))
        .. "; restoring: " .. DebugBoolean(Field(frame, "SNPRestoring")))
    print("  Cached name style: " .. (cached and "found" or "not found")
        .. "; text: " .. DebugValue(Field(cached, "text"))
        .. "; name-only: " .. DebugBoolean(Field(cached, "nameOnly"))
        .. "; inside bar: " .. DebugBoolean(Field(cached, "inside")))
    print("  Cached presentation: action " .. DebugValue(Field(decision, "action"))
        .. "; color: " .. DebugValue(Field(decision, "colorState"))
        .. "; revision: " .. DebugValue(Field(decision, "contextRevision"))
        .. "; current revision: " .. context.revision)
    for _, key in ipairs({"SNPInsideName", "SNPFullTitleText"}) do
        local region = Field(frame, key)
        print("  " .. key .. ": " .. (region and "found" or "not found")
            .. "; text: " .. DebugRegionValue(region, "GetText", nil, context)
            .. "; shown: " .. DebugRegionValue(region, "IsShown", "boolean", context)
            .. "; visible: " .. DebugRegionValue(region, "IsVisible", "boolean", context))
    end
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

local function DebugClassification(state, rule, assessment, context, facts)
    local hasNameplate = assessment.canAccess
    local decision = Resolve(context, facts, state, assessment, GetStylingEnabled(), GetCategoryMode(state))
    local enabled, mode = GetStylingEnabled(), GetCategoryMode(state)
    local display, colorHex
    if not hasNameplate then
        display, colorHex = "no accessible nameplate; world-name display unknown", "unavailable"
    elseif decision.action == "restore" then
        display, colorHex = "Blizzard presentation", "Blizzard-controlled"
    else
        local r, g, b = PriorityColorForState(decision.colorState)
        colorHex = string.format("#%02X%02X%02X", math.floor(r * 255 + 0.5),
            math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5))
        display = decision.nameOnly and "colored name only" or "white name with colored health bar"
    end
    print("  Styling enabled: " .. (enabled and "yes" or "no")
        .. "; detected state: " .. state .. "; winning rule: " .. rule .. "; mode: " .. mode
        .. "; configured display: " .. display .. "; configured color: " .. colorHex)
    print("  Presentation rule: " .. decision.ruleID .. "; action: " .. decision.action
        .. "; reason: " .. decision.reason .. "; health bar requested: " .. DebugBoolean(decision.showHealthBar)
        .. "; full title permitted: " .. DebugBoolean(decision.showFullTitle))
end

local function DebugUnitRelationships(facts)
    print("  Player: " .. DebugBoolean(facts.isPlayer)
        .. "; player-controlled: " .. DebugBoolean(facts.playerControlled)
        .. "; owned/controlled by you: " .. DebugBoolean(facts.ownedByPlayer)
        .. "; NPC: " .. DebugBoolean(facts.isNPC))
    print("  Reaction: " .. DebugValue(facts.reaction)
        .. "; faction: " .. DebugValue(facts.faction)
        .. "; opposite faction: " .. DebugBoolean(facts.oppositeFaction)
        .. "; you can attack: " .. DebugBoolean(facts.canAttackThem)
        .. "; it can attack you: " .. DebugBoolean(facts.canAttackYou)
        .. "; PvP flagged: " .. DebugBoolean(facts.pvpFlagged)
        .. "; eligible PvP opponent: " .. DebugBoolean(facts.eligiblePvPOpponent))
    print("  Threat on you: " .. DebugValue(facts.playerThreat)
        .. "; threat on pet: " .. DebugValue(facts.petThreat)
        .. "; targeting your controlled unit: " .. DebugBoolean(facts.targetsYourControlledUnit)
        .. "; attacking: " .. DebugBoolean(facts.attacking))
    print("  Aggressive NPC: " .. DebugBoolean(facts.aggressiveNPC)
        .. "; interactable: " .. DebugBoolean(facts.interactable)
        .. "; useful NPC: " .. DebugBoolean(facts.usefulNPC)
        .. "; facts context revision: " .. DebugValue(facts.contextRevision))
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

local function DebugScannedPlates(candidates, context)
    for index, candidate in ipairs(candidates) do
        local assessment, token = candidate.assessment, candidate.token
        local unitName
        if type(token) == "string" then unitName = ReadUnitAPI(UnitName, token) end
        print("  Scanned nameplate " .. index .. ": token " .. DebugValue(token)
            .. "; unit name: " .. DebugValue(unitName)
            .. "; matches target: " .. DebugBoolean(candidate.targetMatch))
        local subtitle
        if type(token) == "string" then
            local _, _, facts = StateForUnit(token, context)
            subtitle = ns.NPCTitles.GetTitle(token, facts)
        end
        print("  NPC nameplate tooltip subtitle: " .. DebugValue(subtitle))
        print("  Base plate access: " .. candidate.plateStatus
            .. "; shown: " .. DebugBoolean(candidate.plateShown)
            .. "; visible: " .. DebugBoolean(candidate.plateVisible)
            .. "; unit frame access: " .. assessment.status
            .. "; blocked region: " .. DebugValue(assessment.reason))
        print("  Unit frame shown: " .. DebugRegionValue(assessment.frame, "IsShown", "boolean", context)
            .. "; visible: " .. DebugRegionValue(assessment.frame, "IsVisible", "boolean", context))
        DebugNameRegion(assessment, context)
        DebugAddonText(assessment, context)
    end
end

local function DebugUnit(unit, context)
    context = context or GetContext()
    DebugContext(context)
    if AccessibleBoolean(UnitExists(unit)) ~= true then
        print("|cff0cd29fSimple Nameplates:|r No target selected.")
        return
    end

    local name = DebugValue(UnitName(unit))
    local state, rule, facts = StateForUnit(unit, context)
    local matches, direct, scanned, unknown, enumerationAvailable, candidates = FindDiagnosticPlates(unit, context)
    local assessment = matches[1] and matches[1].assessment or direct
    print("|cff0cd29fSimple Nameplates debug:|r " .. name)
    print("  Nameplate lookup: direct " .. direct.status .. "; enumeration available: "
        .. DebugBoolean(enumerationAvailable) .. "; scanned: " .. scanned
        .. "; matching frames: " .. #matches .. "; identity unavailable: " .. unknown)
    DebugClassification(state, rule, assessment, context, facts)
    DebugUnitRelationships(facts)
    print("  NPC tooltip subtitle: " .. DebugValue(ns.NPCTitles.GetTitle(unit, facts)))
    if #matches == 0 then
        DebugNameRegion(assessment, context)
        DebugPresentation(assessment, context)
        print("  No matching nameplate identified; world-name source remains unknown.")
    else
        for index, match in ipairs(matches) do
            print("  Matching nameplate " .. index .. ": " .. match.source
                .. "; token: " .. DebugValue(match.token
                    or Capabilities.SafeField(match.assessment.frame, "unit", context)))
            DebugNameRegion(match.assessment, context)
            DebugPresentation(match.assessment, context)
            DebugAddonText(match.assessment, context)
        end
    end
    DebugScannedPlates(candidates, context)
end


ns.DebugUnit = DebugUnit
