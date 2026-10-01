-- Pure context/entity rule selection and capability-dependent bar decisions.
-- Run: lua tests/presentation-rules-smoke.lua (or luatex --luaonly).
local ns = {}
assert(loadfile("SimpleNameplates/PresentationRules.lua"))("SimpleNameplates", ns)
local Resolve = ns.PresentationRules.Resolve
local function equal(actual, expected, label)
    assert(actual == expected, label .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local cap = {canAccess = true, hasHealthBar = true, hasCastBar = true}
for _, state in ipairs({"attacking", "hostile", "neutral", "friendly", "useful", "useless"}) do
    local out = Resolve({revision = 1, inCombat = false}, {}, state, cap, true, "active")
    local danger = state == "attacking" or state == "hostile" or state == "neutral"
    equal(out.showHealthBar, danger, "out of combat: " .. state)
    equal(out.showFullTitle, not danger, "title policy: " .. state)
    local combat = Resolve({revision = 2, inCombat = true}, {}, state, cap, true, "active")
    equal(combat.showHealthBar, true, "in combat: " .. state)
    equal(combat.nameOnly, false, "combat bar name: " .. state)
    equal(combat.showFullTitle, false, "combat title: " .. state)
    local missing = Resolve({inCombat = true}, {}, state, {canAccess = true}, true, "active")
    equal(missing.showHealthBar, false, "no bar support: " .. state)
    equal(missing.nameOnly, true, "missing bar uses colored name: " .. state)
    equal(missing.showFullTitle, true, "missing bar permits title: " .. state)
    equal(Resolve({inCombat = true}, {}, state, cap, true, "inactive").action, "restore", "inactive: " .. state)
end
local facts = {isPlayer = true, oppositeFaction = true, eligiblePvPOpponent = false}
local sanctuary = Resolve({sanctuary = true, inCombat = false}, facts, "friendly", cap, true, "active")
equal(sanctuary.ruleID, "oppositePlayerSanctuary", "sanctuary rule")
equal(sanctuary.showHealthBar, false, "sanctuary out-of-combat name")
equal(Resolve({sanctuary = true, inCombat = true}, facts, "friendly", cap, true, "active").showHealthBar,
    true, "sanctuary combat bar")
facts.eligiblePvPOpponent = true
local pvp = Resolve({sanctuary = false, inCombat = false}, facts, "hostile", cap, true, "active")
equal(pvp.ruleID, "oppositePlayerPvP", "eligible opponent rule")
equal(pvp.showHealthBar, true, "eligible opponent bar")
facts.oppositeFaction = false
equal(Resolve({sanctuary = true, inCombat = false}, facts, "friendly", cap, true, "active").ruleID,
    "default", "same-faction rule independent")
equal(Resolve({inCombat = false}, {isNPC = true}, "useful", cap, true, "active").ruleID,
    "default", "NPC rule independent")
equal(Resolve({}, {}, "hostile", cap, true, "active").action, "restore", "unknown combat preserves Blizzard")
equal(Resolve({inCombat = true}, {}, "hostile", cap, false, "active").action, "restore", "disabled")
equal(Resolve({inCombat = true}, {}, "hostile", {canAccess = false, status = "forbidden"}, true, "active").action,
    "skip", "forbidden")
print("Presentation rules smoke: passed")
