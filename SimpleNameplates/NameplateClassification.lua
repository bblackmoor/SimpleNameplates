-- Simple Nameplates: priority classification for addon-accessible units.
local _, ns = ...

local UnitCanAttack = UnitCanAttack
local UnitFactionGroup = UnitFactionGroup
local UnitIsPlayer = UnitIsPlayer
local UnitIsOwnerOrControllerOfUnit = UnitIsOwnerOrControllerOfUnit
local UnitIsPVP = UnitIsPVP
local UnitIsUnit = UnitIsUnit
local UnitPlayerControlled = UnitPlayerControlled
local UnitReaction = UnitReaction
local UnitThreatSituation = UnitThreatSituation
local AccessibleNumber, AccessibleBoolean, AccessibleValue =
    ns.AccessibleNumber, ns.AccessibleBoolean, ns.AccessibleValue

local function UnitHasAggro(unitToken, hostileUnit)
    local threat = UnitThreatSituation(unitToken, hostileUnit)
    threat = AccessibleNumber(threat)
    return threat ~= nil and threat >= 2
end

local function HasAggroOnPlayerOrPet(unit)
    if UnitHasAggro("player", unit) or UnitHasAggro("pet", unit) then return true end
    return false
end

local function UnitMatches(unit1, unit2)
    return AccessibleBoolean(UnitIsUnit(unit1, unit2)) == true
end

local function TargetsPlayerControlledUnit(unit)
    local target = unit .. "target"
    if UnitMatches(target, "player") or UnitMatches(target, "pet") then return true end
    if UnitIsOwnerOrControllerOfUnit then
        return AccessibleBoolean(UnitIsOwnerOrControllerOfUnit("player", target)) == true
    end
    return false
end

local function IsAttackingPlayerControlledUnit(unit)
    return HasAggroOnPlayerOrPet(unit) or TargetsPlayerControlledUnit(unit)
end

local function IsPlayerControlledUnit(unit)
    if AccessibleBoolean(UnitIsPlayer(unit)) == true then return true end
    return AccessibleBoolean(UnitPlayerControlled(unit)) == true
end

local function UnitCombatAvailable(unit)
    local canAttackThem = AccessibleBoolean(UnitCanAttack("player", unit))
    local canAttackUs = AccessibleBoolean(UnitCanAttack(unit, "player"))
    return canAttackThem == true or canAttackUs == true
end

local function OpposingPlayerState(unit)
    if UnitCombatAvailable(unit) then
        if IsAttackingPlayerControlledUnit(unit) then return "attacking" end
        return "hostile"
    end

    -- A readable false/false result is the ordinary sanctuary/non-PvP case.
    -- Restricted attackability also falls back to the opposing-PC category
    -- unless WoW exposes a usable PvP signal.
    local pvp = AccessibleBoolean(UnitIsPVP(unit))
    if pvp == true and IsAttackingPlayerControlledUnit(unit) then return "attacking" end
    if pvp == true then return "hostile" end
    return "unfriendlyPC"
end

local function PlayerState(unit, reaction)
    local playerFaction = AccessibleValue(UnitFactionGroup("player"))
    local unitFaction = AccessibleValue(UnitFactionGroup(unit))
    if playerFaction and unitFaction then
        if playerFaction ~= unitFaction then return OpposingPlayerState(unit) end
        -- Duels and other same-faction combat still obey the higher combat
        -- priorities instead of being flattened into My-faction PC.
        if UnitCombatAvailable(unit) then
            if IsAttackingPlayerControlledUnit(unit) then return "attacking" end
            return "hostile"
        end
        return "friendlyPC"
    end

    if reaction and reaction >= 5 and not UnitCombatAvailable(unit) then
        return "friendlyPC"
    end
    return OpposingPlayerState(unit)
end

local function PlayerControlledUnitState(unit)
    -- Player-controlled pets, guardians, totems, and minions are category 6,
    -- except while attackability or active combat promotes them to 1 or 2.
    if UnitCombatAvailable(unit) then
        if IsAttackingPlayerControlledUnit(unit) then return "attacking" end
        return "hostile"
    end
    return "other"
end

local function NonPlayerState(unit, reaction)
    if reaction and reaction >= 5 then return "other" end
    if IsAttackingPlayerControlledUnit(unit) then return "attacking" end
    if reaction == 4 then return "unfriendlyNPC" end
    if reaction then return "hostile" end

    local attackable = AccessibleBoolean(UnitCanAttack("player", unit))
    if attackable == true then return "hostile" end
    return "other"
end

local function StateForUnit(unit, context)
    local reaction = AccessibleNumber(UnitReaction(unit, "player"))
    if AccessibleBoolean(UnitIsPlayer(unit)) == true then return PlayerState(unit, reaction) end
    if IsPlayerControlledUnit(unit) then return PlayerControlledUnitState(unit) end
    return NonPlayerState(unit, reaction)
end

local function IsNameOnlyState(state)
    return state == "friendlyPC" or state == "unfriendlyPC" or state == "other"
end


ns.NameplateClassification = {
    StateForUnit = StateForUnit,
    TargetsPlayerControlledUnit = TargetsPlayerControlledUnit,
    IsNameOnlyState = IsNameOnlyState,
}
