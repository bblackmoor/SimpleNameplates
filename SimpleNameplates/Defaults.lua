-- Simple Nameplates: factory settings and validation ranges.
local _, ns = ...

local function RGB8(r, g, b)
    return { r = r / 255, g = g / 255, b = b / 255 }
end

local DEFAULT_PRIORITY_COLORS = {
    attacking = RGB8(255, 0, 0),
    hostile = RGB8(255, 102, 0),
    unfriendlyNPC = RGB8(255, 204, 0),
    unfriendlyPC = RGB8(102, 102, 255),
    friendlyPC = RGB8(51, 204, 51),
    other = RGB8(51, 204, 255),
}
local DEFAULT_CATEGORY_MODES = {
    attacking = "active",
    hostile = "active",
    unfriendlyNPC = "active",
    unfriendlyPC = "active",
    friendlyPC = "active",
    other = "active",
}
local DEFAULT_EFFECT_COLORS = {
    interruptible = RGB8(0, 255, 255),
}
local COLOR_PRESETS = {
    highContrast = {
        priorityColors = {
            attacking = RGB8(255, 0, 255),
            hostile = RGB8(255, 102, 0),
            unfriendlyNPC = RGB8(255, 255, 0),
            unfriendlyPC = RGB8(0, 102, 255),
            friendlyPC = RGB8(0, 255, 255),
            other = RGB8(255, 255, 255),
        },
        effectColors = {
            interruptible = RGB8(0, 255, 0),
        },
    },
}
ns.DEFAULT_PRIORITY_COLORS = DEFAULT_PRIORITY_COLORS
ns.DEFAULT_EFFECT_COLORS = DEFAULT_EFFECT_COLORS

local FONT_OPTIONS = {
    { value = "ARIALN", label = "Arial Narrow", path = "Fonts\\ARIALN.TTF" },
    { value = "FRIZQT", label = "Friz Quadrata", path = "Fonts\\FRIZQT__.TTF" },
    { value = "MORPHEUS", label = "Morpheus", path = "Fonts\\MORPHEUS.TTF" },
    { value = "SKURRI", label = "Skurri", path = "Fonts\\skurri.ttf" },
    { value = "2002", label = "2002", path = "Fonts\\2002.TTF" },
    { value = "2002B", label = "2002 Bold", path = "Fonts\\2002B.TTF" },
}
local FONT_BY_VALUE = {}
for _, option in ipairs(FONT_OPTIONS) do FONT_BY_VALUE[option.value] = option end

local DEFAULT_APPEARANCE = {
    nameFont = "ARIALN",
    nameSize = 12,
    threatFont = "ARIALN",
    namePlacement = "ABOVE",
}
local MIN_NAME_SIZE = 8
local MAX_NAME_SIZE = 36

local DEFAULT_TRP3 = {
    enabled = false,
    useRoleplayingName = true,
    showShortTitle = true,
    showFullTitle = true,
    showOOC = true,
}

local DEFAULT_STYLING_ENABLED = true
local DEFAULT_SHOW_THREAT = true
local DEFAULT_HIDE_BLIZZARD_MINION_NAMES = false
local DEFAULT_HIDE_CRITTER_COMPANION_NAMES = false
local DEFAULT_REPLACE_BLIZZARD_OVERHEAD_NAMES = false

ns.FONT_OPTIONS = FONT_OPTIONS
ns.DEFAULT_APPEARANCE = DEFAULT_APPEARANCE
ns.MIN_NAME_SIZE = MIN_NAME_SIZE
ns.MAX_NAME_SIZE = MAX_NAME_SIZE
ns.Defaults = {
    priorityColors = DEFAULT_PRIORITY_COLORS,
    categoryModes = DEFAULT_CATEGORY_MODES,
    effectColors = DEFAULT_EFFECT_COLORS,
    colorPresets = COLOR_PRESETS,
    fontByValue = FONT_BY_VALUE,
    appearance = DEFAULT_APPEARANCE,
    trp3 = DEFAULT_TRP3,
    stylingEnabled = DEFAULT_STYLING_ENABLED,
    showThreat = DEFAULT_SHOW_THREAT,
    hideBlizzardMinionNames = DEFAULT_HIDE_BLIZZARD_MINION_NAMES,
    hideCritterCompanionNames = DEFAULT_HIDE_CRITTER_COMPANION_NAMES,
    replaceBlizzardOverheadNames = DEFAULT_REPLACE_BLIZZARD_OVERHEAD_NAMES,
}
