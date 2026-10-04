-- Simple Nameplates: optional threat percentage rendered by WoW's text API.
local _, ns = ...
local CanAccessFrame = ns.PresentationCapabilities.CanAccessFrame
local GetContext = ns.WorldContext.Get
local UnitDetailedThreatSituation = UnitDetailedThreatSituation
local AccessibleNumber, FontPath = ns.AccessibleNumber, ns.FontPath
local GetAppearanceSetting, GetThreatEnabled = ns.GetAppearanceSetting, ns.GetThreatEnabled
local GetHealthBar = ns.NameplateFrames.GetHealthBar

local function ClearThreatText(frame, reason)
    frame.SNPThreatStatus = reason
    if frame.SNPThreatText then
        ns.TextUnderlayers.Hide(frame.SNPThreatText)
        frame.SNPThreatText:SetText("")
        frame.SNPThreatText:Hide()
    end
end

local function EnsureThreatText(frame, bar)
    if frame.SNPThreatText and frame.SNPThreatTextBar == bar then return frame.SNPThreatText end
    if frame.SNPThreatText then ns.TextUnderlayers.Hide(frame.SNPThreatText); frame.SNPThreatText:Hide() end
    local text = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetDrawLayer("OVERLAY", 7)
    text:SetPoint("RIGHT", bar, "RIGHT", -3, -0.5)
    text:SetJustifyH("RIGHT")
    text:SetWordWrap(false)
    text:SetMaxLines(1)
    frame.SNPThreatText, frame.SNPThreatTextBar = text, bar
    return text
end

local function RenderPercent(text, value)
    -- SetFormattedText accepts secret arguments. Pass them straight through:
    -- never compare, concatenate, or calculate with a secret percentage.
    if not (issecretvalue and issecretvalue(value)) then
        value = AccessibleNumber(value)
        if value == nil then return false end
    end
    return pcall(text.SetFormattedText, text, "%.0f%%", value)
end

local function UpdateThreatText(frame, state, context, decision)
    context = context or GetContext()
    if not CanAccessFrame(frame, context) then return end
    if not GetThreatEnabled() then ClearThreatText(frame, "disabled"); return end
    local bar = GetHealthBar(frame, context)
    if not decision or not decision.showHealthBar or not bar then
        ClearThreatText(frame, "no displayed health bar"); return
    end
    local text = EnsureThreatText(frame, bar)
    text:SetTextColor(1, 1, 1, 1)
    text:SetFont(FontPath(GetAppearanceSetting("threatFont")), GetAppearanceSetting("nameSize") or 12, ns.FontFlags(false))
    text:SetShadowColor(0, 0, 0, 0)
    text:SetShadowOffset(0, 0)
    local ok, _, _, scaled, raw = pcall(UnitDetailedThreatSituation, "player", frame.unit)
    if not ok then ClearThreatText(frame, "threat API unavailable"); return end
    if RenderPercent(text, raw) then frame.SNPThreatStatus = "displayed raw percentage"
    elseif RenderPercent(text, scaled) then frame.SNPThreatStatus = "displayed scaled percentage"
    else ClearThreatText(frame, "no displayable threat percentage"); return end
    text:Show()
    ns.TextUnderlayers.Update(text, bar)
end

ns.NameplateThreat = { UpdateThreatText = UpdateThreatText }
