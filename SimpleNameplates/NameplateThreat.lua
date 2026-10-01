-- Simple Nameplates: optional readable threat percentage on health bars.
local _, ns = ...
local UnitDetailedThreatSituation = UnitDetailedThreatSituation
local AccessibleNumber, FontPath = ns.AccessibleNumber, ns.FontPath
local GetAppearanceSetting, GetThreatEnabled = ns.GetAppearanceSetting, ns.GetThreatEnabled
local IsNameOnlyState = ns.NameplateClassification.IsNameOnlyState
local GetHealthBar = ns.NameplateFrames.GetHealthBar

local function EnsureThreatText(frame)
    if frame.SNPThreatText then return frame.SNPThreatText end
    local bar = GetHealthBar(frame)
    if not bar then return nil end
    local threatText = bar:CreateFontString(nil, "OVERLAY")
    threatText:SetPoint("RIGHT", bar, "RIGHT", -3, 0)
    threatText:SetJustifyH("RIGHT")
    threatText:SetTextColor(1, 1, 1, 1)
    frame.SNPThreatText = threatText
    return threatText
end

local function UpdateThreatText(frame, state)
    local threatText = EnsureThreatText(frame)
    if not threatText then return end
    local threatSize = 9
    if GetAppearanceSetting("namePlacement") == "INSIDE" then
        local baseNameSize = GetAppearanceSetting("nameSize") or 12
        threatSize = math.min(threatSize, math.floor(baseNameSize * 0.8 + 0.5))
    end
    threatText:SetFont(FontPath(GetAppearanceSetting("threatFont")), threatSize, "OUTLINE")
    if not GetThreatEnabled() then threatText:SetText(""); return end
    if IsNameOnlyState(state) then threatText:SetText(""); return end
    local _, _, scaled, raw = UnitDetailedThreatSituation("player", frame.unit)
    local percent = AccessibleNumber(raw) or AccessibleNumber(scaled)
    if percent then threatText:SetFormattedText("%.0f%%", percent) else threatText:SetText("") end
end


ns.NameplateThreat = {
    UpdateThreatText = UpdateThreatText,
}
