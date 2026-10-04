-- Simple Nameplates: About settings page.
local _, ns = ...
local U, W = ns.SettingsUI, ns.SettingsWidgets
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
        text = "In the sanctuary contexts listed here, nonattackable opposite-faction PCs have native overhead names without an accessible nameplate. The addon cannot style those names.\n\nPet, guardian, totem and minion world labels are also separate; their accessible nameplates can still be styled.",
        button1 = OKAY or "Okay", timeout = 0, whileDead = true,
        hideOnEscape = true, preferredIndex = 3,
    }
    StaticPopupDialogs["SNP_BLIZZARD_INTERACTIVE_INFO"] = {
        text = "Native world labels use Blizzard's colors. Enable Friendly NPC Nameplates to allow styling of separate accessible plates and verified service titles.",
        button1 = OKAY or "Okay", timeout = 0, whileDead = true,
        hideOnEscape = true, preferredIndex = 3,
    }
    StaticPopupDialogs["SNP_BLIZZARD_VENDOR_INFO"] = {
        text = "Native vendor world labels use Blizzard's colors. Enable Friendly NPC Nameplates to allow styling of separate accessible plates and verified service titles.",
        button1 = OKAY or "Okay", timeout = 0, whileDead = true,
        hideOnEscape = true, preferredIndex = 3,
    }
end

local function CreateLockedColorRow(context, text, r, g, b, popupKey)
    local content, layout = context.content, context.layout
    local row = U.CreateSettingRow(content, layout, text)
    local swatch = W.CreateColorDisplay(row, r, g, b)
    swatch:SetPoint("LEFT", row, "LEFT", U.CONTROL_X, 0)
    U.AddInfoLink(row, swatch:GetFrame(), popupKey)
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
        "Customizes accessible Blizzard nameplates with priority colors, text styling and selectable interruptible-cast highlights.")

    AddDescription(content, layout, "Version " .. VERSION .. "\nAuthor: Brandon Blackmoor\nCategory: Unit Frames\nLicense: GPL-3.0")

    local sourceRow = CreateFrame("Frame", nil, content)
    sourceRow.SNPLayoutFullWidth = true
    layout:Add(sourceRow, 24, 24, 8)
    local sourceLabel = sourceRow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    sourceLabel:SetPoint("LEFT")
    sourceLabel:SetText("Source    ")
    local sourceLink = W.CreateLink(sourceRow, SOURCE_URL, function()
        StaticPopup_Show("SNP_COPY_SOURCE", nil, nil, SOURCE_URL)
    end)
    sourceLink:SetPoint("LEFT", sourceLabel, "RIGHT", 0, 0)

    U.AddSection(content, layout, "Commands")
    AddDescription(content, layout,
        "/snp or /snp appearance — Appearance settings\n" ..
        "/snp profiles — Manage appearance profiles\n" ..
        "/snp colors — Color settings\n" ..
        "/snp trp3 — TRP3 settings\n" ..
        "/snp debug — Explain the current target\n" ..
        "/snp debug mouseover — Inspect without targeting\n" ..
        "/snp about — This page")
    U.AddSection(content, layout, "Presentation limits")
    AddDescription(content, layout,
        "No accessible nameplate was found in these contexts despite enabled visibility settings; " ..
        "the addon cannot change the native name, font, size, color, titles or position.")
    for _, case in ipairs(PRESENTATION_LIMITS) do
        AddDescription(content, layout, case[1] .. " — " .. case[2])
    end
    AddDescription(content, layout,
        "Observed 2026-10-02; other contexts may differ. Duplicate NPC widget labels were fixed in v1.0.117; " ..
        "ordinary NPC names and service titles can be styled.")
    U.AddSection(content, layout, "Native world-label examples")
    AddDescription(content, layout,
        "Read-only examples of Blizzard's separate world labels. Accessible NPC and minion nameplates can still be styled.")
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

