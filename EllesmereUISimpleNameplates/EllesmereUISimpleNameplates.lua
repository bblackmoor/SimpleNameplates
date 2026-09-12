-- EllesmereUI Simple Nameplates
-- Four colors, one meaning each:
--   green  = friendly / cannot fight
--   yellow = neutral / attackable but non-aggressive
--   orange = hostile / not currently on you
--   red    = aggro on you

if EUI_CLIENT_BLOCKED then return end
local addon, ns = ...
if not EllesmereUI then return end
if EllesmereUI._ModuleNS then EllesmereUI._ModuleNS[addon] = ns end
local ESNP = EllesmereUI.Lite and EllesmereUI.Lite.NewAddon and EllesmereUI.Lite.NewAddon("EllesmereUISimpleNameplates")

local C_NamePlate = C_NamePlate
local UnitCanAttack, UnitReaction = UnitCanAttack, UnitReaction
local UnitThreatSituation = UnitThreatSituation
local UnitHealth, UnitHealthMax = UnitHealth, UnitHealthMax
local UnitName, UnitExists, UnitIsUnit = UnitName, UnitExists, UnitIsUnit
local UnitCastingInfo, UnitChannelInfo = UnitCastingInfo, UnitChannelInfo
local GetTime = GetTime
local issecretvalue = issecretvalue or function() return false end

local COLORS = {
    friendly = { 0.20, 0.85, 0.25 },
    neutral  = { 1.00, 0.82, 0.12 },
    hostile  = { 1.00, 0.48, 0.08 },
    angry    = { 1.00, 0.12, 0.10 },
    cast     = { 0.95, 0.75, 0.20 },
    shield   = { 0.65, 0.65, 0.65 },
}

local defaults = {
    width = 150,
    height = 13,
    castHeight = 8,
    nameSize = 11,
    valueSize = 10,
    showHealthPercent = true,
    showThreatPercent = true,
}

local db
local plates = {}
local hiddenParent
local STANDARD_NAMEPLATES = "EllesmereUINameplates"

local function StandardNameplatesEnabled()
    if not C_AddOns then return false end
    if C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded(STANDARD_NAMEPLATES) then
        return true
    end
    if C_AddOns.GetAddOnEnableState then
        local player = UnitName("player")
        return (C_AddOns.GetAddOnEnableState(STANDARD_NAMEPLATES, player) or 0) > 0
    end
    return false
end

local function ShowNameplateConflictWarning()
    if not StandardNameplatesEnabled() then return end

    StaticPopupDialogs["ESNP_ELLESMERE_NAMEPLATE_CONFLICT"] = {
        text = "|cff0cd29fEllesmereUI Simple Nameplates|r\n\nThe standard |cff0cd29fEllesmereUI Nameplates|r addon is also enabled. The two nameplate modules should not run together.\n\nDisable standard EllesmereUI Nameplates and reload the UI?",
        button1 = "Disable & Reload",
        button2 = "Ignore",
        OnAccept = function()
            if C_AddOns and C_AddOns.DisableAddOn then
                C_AddOns.DisableAddOn(STANDARD_NAMEPLATES)
            end
            ReloadUI()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = false,
        preferredIndex = 3,
    }
    StaticPopup_Show("ESNP_ELLESMERE_NAMEPLATE_CONFLICT")
end

local function FontPath()
    if EllesmereUI.GetFontPath then return EllesmereUI.GetFontPath("nameplates") end
    return "Fonts\\FRIZQT__.TTF"
end

local function FontFlags()
    if EllesmereUI.GetFontOutlineFlag then return EllesmereUI.GetFontOutlineFlag("nameplates") end
    return "OUTLINE"
end

local function SetFont(fs, size)
    if not fs then return end
    if EllesmereUI.PrimeFontShadow then EllesmereUI.PrimeFontShadow(fs, false) end
    fs:SetFont(FontPath(), size, FontFlags())
end

local function SafeNumber(v)
    if v == nil or issecretvalue(v) then return nil end
    if type(v) ~= "number" then return nil end
    return v
end

local function ColorForUnit(unit)
    -- Friendly is deliberately defined first: if we cannot attack it, it is green.
    if not UnitCanAttack("player", unit) then
        return COLORS.friendly
    end

    -- Reaction 4 is WoW's neutral reaction. The second test covers attackable units
    -- whose reaction API is temporarily unavailable during nameplate setup.
    local reaction = UnitReaction(unit, "player")
    if reaction and not issecretvalue(reaction) and reaction == 4 then
        return COLORS.neutral
    end

    -- Threat situation 3 = securely tanking / has aggro. For this addon that has
    -- one intentionally simple visual meaning: this hostile unit is RED.
    local threat = UnitThreatSituation("player", unit)
    if threat and not issecretvalue(threat) and threat >= 3 then
        return COLORS.angry
    end

    return COLORS.hostile
end

local function SuppressBlizzard(np)
    local uf = np and np.UnitFrame
    if not uf then return end
    uf:SetAlpha(0)
end

local function RestoreBlizzard(np)
    local uf = np and np.UnitFrame
    if not uf then return end
    uf:SetAlpha(1)
end

local function CreatePlate(np)
    local f = CreateFrame("Frame", nil, np)
    f:SetSize(db.width, db.height + db.castHeight + 22)
    f:SetPoint("CENTER", np, "CENTER", 0, 8)
    f:SetFrameLevel(np:GetFrameLevel() + 5)
    f:EnableMouse(false)

    f.health = CreateFrame("StatusBar", nil, f)
    f.health:SetPoint("TOP", f, "TOP", 0, -14)
    f.health:SetSize(db.width, db.height)
    f.health:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    f.health.bg = f.health:CreateTexture(nil, "BACKGROUND")
    f.health.bg:SetAllPoints()
    f.health.bg:SetColorTexture(0.06, 0.06, 0.06, 0.90)

    f.border = CreateFrame("Frame", nil, f.health, "BackdropTemplate")
    f.border:SetPoint("TOPLEFT", -1, 1)
    f.border:SetPoint("BOTTOMRIGHT", 1, -1)
    f.border:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    f.border:SetBackdropBorderColor(0, 0, 0, 1)

    f.name = f:CreateFontString(nil, "OVERLAY")
    f.name:SetPoint("BOTTOMLEFT", f.health, "TOPLEFT", 0, 2)
    f.name:SetPoint("RIGHT", f.health, "RIGHT", 0, 0)
    f.name:SetJustifyH("LEFT")
    SetFont(f.name, db.nameSize)

    f.healthText = f.health:CreateFontString(nil, "OVERLAY")
    f.healthText:SetPoint("CENTER", f.health, "CENTER", 0, 0)
    SetFont(f.healthText, db.valueSize)

    f.threatText = f.health:CreateFontString(nil, "OVERLAY")
    f.threatText:SetPoint("RIGHT", f.health, "RIGHT", -3, 0)
    SetFont(f.threatText, db.valueSize)

    f.cast = CreateFrame("StatusBar", nil, f)
    f.cast:SetPoint("TOPLEFT", f.health, "BOTTOMLEFT", 0, -2)
    f.cast:SetSize(db.width, db.castHeight)
    f.cast:SetStatusBarTexture("Interface\\Buttons\\WHITE8X8")
    f.cast:SetStatusBarColor(unpack(COLORS.cast))
    f.cast.bg = f.cast:CreateTexture(nil, "BACKGROUND")
    f.cast.bg:SetAllPoints()
    f.cast.bg:SetColorTexture(0.06, 0.06, 0.06, 0.90)
    f.cast:Hide()

    f.castName = f.cast:CreateFontString(nil, "OVERLAY")
    f.castName:SetPoint("LEFT", f.cast, "LEFT", 2, 0)
    f.castName:SetPoint("RIGHT", f.cast, "RIGHT", -2, 0)
    f.castName:SetJustifyH("LEFT")
    SetFont(f.castName, 9)

    f.target = f:CreateTexture(nil, "OVERLAY")
    f.target:SetTexture("Interface\\Buttons\\WHITE8X8")
    f.target:SetPoint("TOPLEFT", f.health, "TOPLEFT", -3, 3)
    f.target:SetPoint("BOTTOMRIGHT", f.health, "BOTTOMRIGHT", 3, -3)
    f.target:SetColorTexture(1, 1, 1, 0.16)
    f.target:Hide()

    return f
end

local function UpdateThreatText(f)
    if not db.showThreatPercent or not UnitCanAttack("player", f.unit) then
        f.threatText:SetText("")
        return
    end
    local _, _, scaled, raw = UnitDetailedThreatSituation("player", f.unit)
    local pct = SafeNumber(raw) or SafeNumber(scaled)
    if pct then
        f.threatText:SetFormattedText("%.0f%%", pct)
    else
        f.threatText:SetText("")
    end
end

local function UpdateColor(f)
    local c = ColorForUnit(f.unit)
    f.health:SetStatusBarColor(c[1], c[2], c[3], 1)
    f.name:SetTextColor(c[1], c[2], c[3], 1)
end

local function UpdateHealth(f)
    local hp, maxhp = SafeNumber(UnitHealth(f.unit)), SafeNumber(UnitHealthMax(f.unit))
    if hp and maxhp and maxhp > 0 then
        f.health:SetMinMaxValues(0, maxhp)
        f.health:SetValue(hp)
        if db.showHealthPercent then
            f.healthText:SetFormattedText("%.0f%%", hp / maxhp * 100)
        else
            f.healthText:SetText("")
        end
    else
        -- Midnight may redact some values. Do not inspect/branch on secret values.
        f.health:SetMinMaxValues(0, 1)
        f.health:SetValue(1)
        f.healthText:SetText("")
    end
end

local function UpdateTarget(f)
    f.target:SetShown(UnitExists("target") and UnitIsUnit(f.unit, "target"))
end

local function StopCast(f)
    f.casting, f.channeling = nil, nil
    f.cast:Hide()
    f.cast:SetScript("OnUpdate", nil)
end

local function UpdateCast(f)
    local name, _, _, startMS, endMS, _, _, notInterruptible = UnitCastingInfo(f.unit)
    local channel = false
    if not name then
        name, _, _, startMS, endMS, _, notInterruptible = UnitChannelInfo(f.unit)
        channel = name ~= nil
    end
    if not name or issecretvalue(name) or issecretvalue(startMS) or issecretvalue(endMS) then
        StopCast(f)
        return
    end
    local startT, endT = startMS / 1000, endMS / 1000
    if endT <= startT then StopCast(f); return end
    f.castName:SetText(name)
    if notInterruptible and not issecretvalue(notInterruptible) then
        f.cast:SetStatusBarColor(unpack(COLORS.shield))
    else
        f.cast:SetStatusBarColor(unpack(COLORS.cast))
    end
    f.cast:SetMinMaxValues(startT, endT)
    f.casting, f.channeling = not channel, channel
    f.cast:Show()
    f.cast:SetScript("OnUpdate", function(bar)
        local now = GetTime()
        if f.channeling then
            bar:SetValue(endT - (now - startT)) -- overwritten below with matching range
            local remain = endT - now
            bar:SetMinMaxValues(0, endT - startT)
            bar:SetValue(math.max(0, remain))
        else
            bar:SetMinMaxValues(0, endT - startT)
            bar:SetValue(math.max(0, math.min(endT - startT, now - startT)))
        end
        if now >= endT then StopCast(f) end
    end)
end

local function AddUnit(unit)
    local np = C_NamePlate.GetNamePlateForUnit(unit)
    if not np then return end
    SuppressBlizzard(np)
    local f = CreatePlate(np)
    f.unit, f.nameplate = unit, np
    plates[unit] = f
    f.name:SetText(UnitName(unit) or "")
    UpdateHealth(f)
    UpdateColor(f)
    UpdateThreatText(f)
    UpdateTarget(f)
    UpdateCast(f)
end

local function RemoveUnit(unit)
    local f = plates[unit]
    if not f then return end
    StopCast(f)
    RestoreBlizzard(f.nameplate)
    f:Hide()
    f:SetParent(hiddenParent)
    plates[unit] = nil
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("NAME_PLATE_UNIT_ADDED")
events:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
events:RegisterEvent("PLAYER_TARGET_CHANGED")
events:RegisterEvent("UNIT_HEALTH")
events:RegisterEvent("UNIT_MAXHEALTH")
events:RegisterEvent("UNIT_NAME_UPDATE")
events:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
events:RegisterEvent("UNIT_FACTION")
events:RegisterEvent("UNIT_FLAGS")
events:RegisterEvent("UNIT_SPELLCAST_START")
events:RegisterEvent("UNIT_SPELLCAST_DELAYED")
events:RegisterEvent("UNIT_SPELLCAST_STOP")
events:RegisterEvent("UNIT_SPELLCAST_FAILED")
events:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
events:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
events:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
events:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
events:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE")
events:RegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE")

events:SetScript("OnEvent", function(_, event, unit)
    if event == "PLAYER_LOGIN" then
        EllesmereUISimpleNameplatesDB = EllesmereUISimpleNameplatesDB or {}
        db = setmetatable(EllesmereUISimpleNameplatesDB, { __index = defaults })
        hiddenParent = CreateFrame("Frame")
        hiddenParent:Hide()
        C_Timer.After(0.5, ShowNameplateConflictWarning)
        -- Ask Blizzard to provide both friendly and enemy plates; our four-state
        -- vocabulary is only useful when all nearby units use the same language.
        SetCVar("nameplateShowEnemies", 1)
        SetCVar("nameplateShowFriends", 1)
        return
    end

    if event == "NAME_PLATE_UNIT_ADDED" then AddUnit(unit); return end
    if event == "NAME_PLATE_UNIT_REMOVED" then RemoveUnit(unit); return end

    if event == "PLAYER_TARGET_CHANGED" then
        for _, f in pairs(plates) do UpdateTarget(f) end
        return
    end

    local f = unit and plates[unit]
    if not f then return end

    if event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" then
        UpdateHealth(f)
    elseif event == "UNIT_NAME_UPDATE" then
        f.name:SetText(UnitName(unit) or "")
    elseif event == "UNIT_THREAT_LIST_UPDATE" then
        UpdateColor(f)
        UpdateThreatText(f)
    elseif event == "UNIT_FACTION" or event == "UNIT_FLAGS" then
        UpdateColor(f)
        UpdateThreatText(f)
    elseif event:find("UNIT_SPELLCAST", 1, true) then
        UpdateCast(f)
    end
end)

-- Public refresh helper for testing from /run if desired.
function ns.RefreshAll()
    for _, f in pairs(plates) do
        UpdateHealth(f); UpdateColor(f); UpdateThreatText(f); UpdateTarget(f); UpdateCast(f)
    end
end
