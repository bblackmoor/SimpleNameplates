-- Simple Nameplates: factory settings and validation ranges.
local _, ns = ...

local function RGB8(r, g, b)
    return { r = r / 255, g = g / 255, b = b / 255 }
end

local DEFAULT_PRIORITY_COLORS = {
    attacking = RGB8(255, 0, 0),
    hostile = RGB8(255, 102, 0),
    neutral = RGB8(255, 204, 0),
    friendly = RGB8(0, 0, 255),
    useful = RGB8(0, 255, 0),
    useless = RGB8(153, 153, 153),
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
        gradients = false,
        appearance = {namePlacement = "ABOVE"},
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
    useSlugRendering = true,
    nameSize = 18,
    threatFont = "ARIALN",
    namePlacement = "INSIDE",
    healthBarWidth = 120,
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
ns.MIN_HEALTH_BAR_WIDTH = 80
ns.MAX_HEALTH_BAR_WIDTH = 150
ns.Defaults = {
    priorityColors = DEFAULT_PRIORITY_COLORS,
    categoryModes = DEFAULT_CATEGORY_MODES,
    healthBars = {attacking = true, hostile = true, neutral = true, friendly = true, useful = true, useless = false},
    dimBackgroundNames = true,
    gradients = true,
    effectColors = DEFAULT_EFFECT_COLORS,
    colorPresets = COLOR_PRESETS,
    fontByValue = FONT_BY_VALUE,
    appearance = DEFAULT_APPEARANCE,
    trp3 = DEFAULT_TRP3,
    stylingEnabled = DEFAULT_STYLING_ENABLED,
    showThreat = DEFAULT_SHOW_THREAT,
    interruptibleHighlight = false,
    interruptibleEffect = "PULSE",
    hideCritterCompanionNames = DEFAULT_HIDE_CRITTER_COMPANION_NAMES,
}

-- Saved per-profile experimental render controls. Database validation and
-- Advanced UI both read these definitions to avoid divergent defaults.
ns.CAST_ADVANCED_CONTROLS = {
 PULSE = {
  {key="thickness",label="Pulse thickness",min=1,max=12,step=1,default=4,suffix=" px"},
  {key="inset",label="Pulse inset",min=0,max=8,step=1,default=2,suffix=" px"},
  {key="lowAlpha",label="Minimum opacity",min=0,max=1,step=0.05,default=0.35},
  {key="highAlpha",label="Maximum opacity",min=0,max=1,step=0.05,default=1},
  {key="fadeOut",label="Fade-out time",min=0.1,max=2,step=0.05,default=0.55,suffix=" s"},
  {key="fadeIn",label="Fade-in time",min=0.1,max=2,step=0.05,default=0.55,suffix=" s"},
 },
 SOLID = {
  {key="thickness",label="Solid thickness",min=1,max=10,step=1,default=2,suffix=" px"},
  {key="minPixels",label="Minimum physical pixels",min=1,max=5,step=1,default=2,suffix=" px"},
  {key="upward",label="Upper extension",min=0,max=12,step=1,default=2,suffix=" px"},
  {key="upwardMin",label="Upper minimum pixels",min=0,max=5,step=1,default=2,suffix=" px"},
  {key="distance",label="Border distance",min=0,max=12,step=1,default=0,suffix=" px"},
 },
 SOFT = {
  {key="thickness",label="Soft layer thickness",min=1,max=8,step=1,default=2,suffix=" px"},
  {key="spread",label="Soft border spread",min=0,max=12,step=1,default=0,suffix=" px"},
  {key="alpha1",label="Inner layer opacity",min=0,max=1,step=0.05,default=1},
  {key="alpha2",label="Middle layer opacity",min=0,max=1,step=0.05,default=0.55},
  {key="alpha3",label="Outer layer opacity",min=0,max=1,step=0.05,default=0.2},
  {key="layer1",label="Show inner layer",kind="switch",default=true},
  {key="layer2",label="Show middle layer",kind="switch",default=true},
  {key="layer3",label="Show outer layer",kind="switch",default=true},
 },
 ANTS = {
  {key="frameTime",label="Marching frame interval",min=0.01,max=0.15,step=0.005,default=0.025,suffix=" s"},
  {key="distance",label="Marching distance",min=0,max=14,step=1,default=3,suffix=" px"},
  {key="opacity",label="Marching opacity",min=0,max=1,step=0.05,default=1},
  {key="frames",label="Animation frames",min=1,max=22,step=1,default=22},
 },
 GLOW = {
  {key="expandX",label="Horizontal glow extent",min=0,max=32,step=1,default=8,suffix=" px"},
  {key="expandY",label="Vertical glow extent",min=0,max=32,step=1,default=8,suffix=" px"},
  {key="offsetX",label="Horizontal glow offset",min=-20,max=20,step=1,default=0,suffix=" px"},
  {key="offsetY",label="Vertical glow offset",min=-20,max=20,step=1,default=0,suffix=" px"},
  {key="antsAlpha",label="Inner animation opacity",min=0,max=1,step=0.05,default=1},
  {key="glowAlpha",label="Outer glow opacity",min=0,max=1,step=0.05,default=1},
 },
}

ns.CAST_EFFECT_OPTIONS = {
    {value = "PULSE", label = "Pulsing border"},
    {value = "SOLID", label = "Solid border"},
    {value = "SOFT", label = "Soft border"},
    {value = "ANTS", label = "Marching ants"},
    {value = "GLOW", label = "Spell-alert glow"},
}
ns.CAST_EFFECT_BY_VALUE = {}
for _, option in ipairs(ns.CAST_EFFECT_OPTIONS) do ns.CAST_EFFECT_BY_VALUE[option.value] = option.label end

