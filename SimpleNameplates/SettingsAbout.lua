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

local function RegisterWorldLabelPopups()
    StaticPopupDialogs["SNP_BLIZZARD_OVERHEAD_INFO"] = {
        text = "Nonattackable opposite-faction PCs in sanctuary have been observed with native periwinkle overhead labels and no matching addon-accessible plate. That presentation remains outside the addon's control. The verified entity types and world contexts are listed in About.\n\nNative pet, guardian, totem, and minion world labels are also separate from nameplate text. Simple Nameplates styles those entities only where Blizzard supplies an accessible plate.",
        button1 = OKAY or "Okay", timeout = 0, whileDead = true,
        hideOnEscape = true, preferredIndex = 3,
    }
    StaticPopupDialogs["SNP_BLIZZARD_INTERACTIVE_INFO"] = {
        text = "Blizzard's native interactive-NPC world labels are separate from addon-accessible nameplates. Their native color is controlled by the game.\n\nInteractive NPCs can also have ordinary nameplates that Simple Nameplates styles, including service titles when verified. Enable Friendly NPC Nameplates for ordinary friendly NPC plates. A native world-label color does not establish whether a separate plate is available.",
        button1 = OKAY or "Okay", timeout = 0, whileDead = true,
        hideOnEscape = true, preferredIndex = 3,
    }
    StaticPopupDialogs["SNP_BLIZZARD_VENDOR_INFO"] = {
        text = "Blizzard's native vendor-NPC world labels are separate from addon-accessible nameplates. Their native color is controlled by the game.\n\nVendor NPCs can also have ordinary nameplates that Simple Nameplates styles, including service titles when verified. Enable Friendly NPC Nameplates for ordinary friendly NPC plates. Vendors are not a blanket unalterable entity category.",
        button1 = OKAY or "Okay", timeout = 0, whileDead = true,
        hideOnEscape = true, preferredIndex = 3,
    }
end

local function CreateLockedColorRow(context, text, r, g, b, popupKey)
    local content, layout = context.content, context.layout
    local row = U.CreateSettingRow(content, layout, text)
    local swatch = CreateFrame("Frame", nil, row, "BackdropTemplate")
    swatch:SetSize(26, 26)
    swatch:SetPoint("LEFT", row, "LEFT", U.CONTROL_X, 0)
    swatch:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    swatch:SetBackdropColor(0.04, 0.04, 0.04, 1)
    swatch:SetBackdropBorderColor(0.45, 0.45, 0.45, 1)
    local fill = swatch:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("TOPLEFT", 3, -3)
    fill:SetPoint("BOTTOMRIGHT", -3, 3)
    fill:SetColorTexture(r, g, b, 1)
    U.AddInfoLink(row, swatch, popupKey)
    row:EnableMouse(true)
    row:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(text)
        GameTooltip:AddLine("This color is chosen by Blizzard and cannot be edited.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

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

    AddTitle(content, layout, "About")
    RegisterWorldLabelPopups()
    AddDescription(content, layout,
        "A deliberately simple standalone nameplate-color addon. It recolors addon-accessible " ..
        "Blizzard Midnight nameplates with customizable Priority Colors and an optional " ..
        "interruptible cast highlight.")

    AddDescription(content, layout, "Version " .. VERSION .. "\nAuthor: Brandon Blackmoor\nCategory: Unit Frames\nLicense: GPL-3.0")

    local sourceRow = CreateFrame("Frame", nil, content)
    sourceRow.SNPLayoutFullWidth = true
    layout:Add(sourceRow, 24, 24, 8)
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

    U.AddSection(content, layout, "Commands")
    AddDescription(content, layout,
        "/snp or /snp appearance — Appearance settings\n" ..
        "/snp profiles — Manage appearance profiles\n" ..
        "/snp colors — Color settings\n" ..
        "/snp trp3 — TRP3 settings\n" ..
        "/snp debug — Explain the current target\n" ..
        "/snp about — This page")
    U.AddSection(content, layout, "Presentation limits")
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
    U.AddSection(content, layout, "Native world-label examples")
    AddDescription(content, layout,
        "These swatches describe Blizzard's separate world labels, not editable nameplate colors. " ..
        "An ordinary accessible NPC or minion plate can still be styled. Click an info link for details.")
    local context = {content = content, layout = layout}
    CreateLockedColorRow(context, "Opposite-faction PC labels in sanctuary",
        102 / 255, 102 / 255, 1, "SNP_BLIZZARD_OVERHEAD_INFO")
    CreateLockedColorRow(context, "Native interactive-NPC world labels",
        1, 1, 0, "SNP_BLIZZARD_INTERACTIVE_INFO")
    CreateLockedColorRow(context, "Native vendor-NPC world labels",
        0, 1, 0, "SNP_BLIZZARD_VENDOR_INFO")
    layout:Finish()
    return panel
end
ns.SettingsPanels.About = CreateAboutPanel
