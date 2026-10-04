-- Simple Nameplates: uniform presentation for accessible Active plates.
local _, ns = ...
local function Resolve(context, facts, state, capabilities, enabled, mode)
    local result = {ruleID = "uniform", contextRevision = context.revision,
        state = state, colorState = state}
    if not capabilities.canAccess then
        result.action, result.reason = "skip", capabilities.status
    elseif not enabled or mode == "inactive" then
        result.action, result.reason = "restore", "Blizzard presentation"
    elseif facts.widgetsOnly == true then
        -- This is a widget anchor, not another actor label. Preserve its widgets.
        result.action, result.reason = "style", "widget-only plate: suppress text"
        result.suppressText, result.nameOnly, result.showFullTitle = true, true, false
    else
        result.action, result.reason = "style", "uniform Active plate"
        result.showHealthBar = capabilities.hasHealthBar == true
        result.showCastBar = capabilities.hasCastBar == true
        result.showCombatIndicators = true
        result.nameOnly = not result.showHealthBar
        result.showFullTitle = true
    end
    return result
end
ns.PresentationRules = {Resolve = Resolve}
