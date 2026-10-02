-- Simple Nameplates: factory settings and validation ranges.
local _, ns = ...

local function RGB8(r, g, b)
    return { r = r / 255, g = g / 255, b = b / 255 }
end

local DEFAULT_PRIORITY_COLORS = {
    attacking = RGB8(255, 0, 0),
    hostile = RGB8(255, 102, 0),
    neutral = RGB8(255, 204, 0),
    friendly = RGB8(51, 204, 51),
    useful = RGB8(211, 211, 211),
    useless = RGB8(153, 153, 153),
    sanctuaryFriendly = RGB8(135, 206, 235),
}
local DEFAULT_CATEGORY_MODES = {
    attacking = "active",
    hostile = "active",
    neutral = "active",
    friendly = "active",
    useful = "active",
    useless = "active",
}
local DEFAULT_EFFECT_COLORS = {
    interruptible = RGB8(0, 255, 255),
}
local COLOR_PRESETS = {
    highContrast = {
        priorityColors = {
            attacking = RGB8(255, 0, 255),
            hostile = RGB8(255, 102, 0),
            neutral = RGB8(255, 255, 0),
            friendly = RGB8(0, 255, 255),
            useful = RGB8(0, 102, 255),
            useless = RGB8(255, 255, 255),
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
    nameFont = "FRIZQT",
    matchSanctuaryFont = true,
    nameSize = 21,
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
local DEFAULT_HIDE_CRITTER_COMPANION_NAMES = false

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
    hideCritterCompanionNames = DEFAULT_HIDE_CRITTER_COMPANION_NAMES,
}
