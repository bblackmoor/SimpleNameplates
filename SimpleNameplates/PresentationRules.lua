-- Simple Nameplates: context/entity rules and independent health-bar policy.
local _, ns = ...
local function Danger(state)
    return state == "attacking" or state == "hostile" or state == "neutral"
end

-- Each entry can be changed independently without changing another context/type.
local rules = {
    default = { outOfCombatBar = Danger },
    oppositePlayerSanctuary = { outOfCombatBar = Danger },
    oppositePlayerPvP = { outOfCombatBar = function() return true end },
    oppositePlayerNonPvP = { outOfCombatBar = Danger },
}
local function SelectRule(context, facts)
    if context.sanctuary == true then
        if facts.isPlayer == true and facts.oppositeFaction == true
            and facts.eligiblePvPOpponent ~= true then return "oppositePlayerSanctuary" end
    end
    if facts.isPlayer == true and facts.oppositeFaction == true then
        if facts.eligiblePvPOpponent == true then return "oppositePlayerPvP" end
        if facts.eligiblePvPOpponent == false then return "oppositePlayerNonPvP" end
    end
    return "default"
end

local function ColorState(context, facts, state)
    -- Keep combat priorities, opposite-faction players, and unknown identity
    -- on their normal category colors, even inside a sanctuary.
    if context.sanctuary == true then
        if state == "friendly" and facts.isPlayer == true and facts.oppositeFaction == false then
            return "sanctuaryFriendly"
        end
    end
    return state
end

local function Resolve(context, facts, state, capabilities, enabled, mode)
    local ruleID = SelectRule(context, facts)
    local result = {ruleID = ruleID, contextRevision = context.revision, state = state}
    result.colorState = ColorState(context, facts, state)
    if not capabilities.canAccess then
        result.action, result.reason = "skip", capabilities.status
    elseif not enabled or mode == "inactive" then
        result.action, result.reason = "restore", "Blizzard presentation"
    elseif facts.widgetsOnly == true then
        -- This is a widget anchor, not another actor label. Preserve its widgets.
        result.action, result.reason = "style", "widget-only plate: suppress text"
        result.suppressText, result.nameOnly, result.showFullTitle = true, true, false
    elseif context.inCombat == nil then
        result.action, result.reason = "restore", "player combat unavailable"
    else
        local combatPresentation = context.inCombat == true or rules[ruleID].outOfCombatBar(state)
        result.action = "style"
        result.showHealthBar = combatPresentation and capabilities.hasHealthBar == true
        result.showCastBar = combatPresentation and capabilities.hasCastBar == true
        result.showCombatIndicators = combatPresentation
        result.nameOnly = not result.showHealthBar
        result.showFullTitle = not result.showHealthBar
        result.reason = context.inCombat and "player in combat" or "out-of-combat rule"
    end
    return result
end
ns.PresentationRules = { Resolve = Resolve }
