-- Simple Nameplates: About settings page.
local _, ns = ...
local U = ns.SettingsUI
local CreateScrollablePanel, AddTitle, AddDescription =
    U.CreateScrollablePanel, U.AddTitle, U.AddDescription
local VERSION, SOURCE_URL = ns.VERSION, ns.SOURCE_URL

-- Record entity types and observed world contexts, not individual names.
-- Mirror the register in the README without generalizing to untested contexts.
local PRESENTATION_LIMITS = {
    { "Opposite-faction PCs, nonattackable in either direction",
      "Sanctuary; observed in Silvermoon City / The Bazaar with an Alliance viewer and Horde PCs" },
}

local function CreateAboutPanel()
    local panel, content, layout = CreateScrollablePanel("About")
    StaticPopupDialogs["SNP_COPY_SOURCE"] = {
        text = "Press Ctrl+C to copy the source URL.", button1 = CLOSE or "Close",
        hasEditBox = true, maxLetters = 255, editBoxWidth = 340,
        OnShow = function(self, url)
            local editBox = self.GetEditBox and self:GetEditBox() or self.editBox
            editBox:SetText(url or self.data or SOURCE_URL)
            editBox:SetFocus()
            editBox:HighlightText()
        end,
        EditBoxOnEnterPressed = function(self) self:GetParent():Hide() end,
        EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
        timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
    }

    AddTitle(content, layout, "Simple Nameplates — About")
    AddDescription(content, layout,
        "A deliberately simple standalone nameplate-color addon. It recolors addon-accessible " ..
        "Blizzard Midnight nameplates with customizable Priority Colors and an optional " ..
        "interruptible cast highlight.")

    local details = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    details:SetPoint("RIGHT", content, "RIGHT", -20, 0)
    details:SetJustifyH("LEFT")
    details:SetText("Version " .. VERSION .. "\nAuthor    Brandon Blackmoor\nCategory  Unit Frames")
    layout:Add(details, 20, 48, 2)

    local sourceRow = CreateFrame("Frame", nil, content)
    sourceRow:SetPoint("RIGHT", content, "RIGHT", -20, 0)
    layout:Add(sourceRow, 20, 18, 2)
    local sourceLabel = sourceRow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sourceLabel:SetPoint("LEFT")
    sourceLabel:SetText("Source    ")
    local sourceLink = CreateFrame("Button", nil, sourceRow)
    sourceLink:SetPoint("LEFT", sourceLabel, "RIGHT")
    local sourceText = sourceLink:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sourceText:SetPoint("LEFT")
    sourceText:SetText(SOURCE_URL)
    sourceText:SetTextColor(0.35, 0.7, 1, 1)
    sourceLink:SetSize(sourceText:GetStringWidth(), 16)
    sourceLink:SetScript("OnEnter", function() sourceText:SetTextColor(0.65, 0.85, 1, 1) end)
    sourceLink:SetScript("OnLeave", function() sourceText:SetTextColor(0.35, 0.7, 1, 1) end)
    sourceLink:SetScript("OnClick", function() StaticPopup_Show("SNP_COPY_SOURCE", nil, nil, SOURCE_URL) end)

    local information = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    information:SetPoint("RIGHT", content, "RIGHT", -20, 0)
    information:SetJustifyH("LEFT")
    information:SetText(
        "License   GPL-3.0\n\nSlash commands\n" ..
        "    /snp - Open the behavior settings.\n" ..
        "    /snp behavior - Open the behavior settings.\n" ..
        "    /snp appearance (or colors) - Open the appearance settings.\n" ..
        "    /snp trp3 - Open the TRP3 settings.\n" ..
        "    /snp debug - Explain the current target and cast-highlight state.\n" ..
        "    /snp about - Open this About page.")
    layout:Add(information, 20, 145)
    layout:Space(12)
    U.AddSection(content, layout, "KNOWN PRESENTATION LIMITS")
    AddDescription(content, layout,
        "These observed entity/context combinations have native overhead names but no matching addon-accessible " ..
        "plate. Simple Nameplates currently cannot change their name color, font, size, titles, or layout. " ..
        "Visibility settings were enabled; no supported workaround was found.", 76)
    for _, case in ipairs(PRESENTATION_LIMITS) do
        AddDescription(content, layout, case[1] .. " — " .. case[2], 58)
    end
    AddDescription(content, layout,
        "Recorded 2026-10-02. This is an observed limitation, not proof that every opposite-faction " ..
        "PC is inaccessible in every context. Duplicate actor text on widget-only NPC plates was " ..
        "resolved in v1.0.117; ordinary NPC names and service titles can be styled.", 70)
    layout:Finish()
    return panel
end
ns.SettingsPanels.About = CreateAboutPanel
