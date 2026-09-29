-- Simple Nameplates: appearance Profile management.
local _, ns = ...
local U = ns.SettingsUI
local AddDescription, RefreshNameplates = U.AddDescription, U.RefreshNameplates

local function RegisterProfileDialogs()
    StaticPopupDialogs["SNP_PROFILE_NAME"] = {
        text = "Enter a profile name.", button1 = ACCEPT or "Accept",
        button2 = CANCEL or "Cancel", hasEditBox = true, maxLetters = 64,
        editBoxWidth = 260,
        OnShow = function(self, data)
            local editBox = self.GetEditBox and self:GetEditBox() or self.editBox
            editBox:SetText(data and data.initial or "")
            editBox:SetFocus()
            editBox:HighlightText()
        end,
        OnAccept = function(self, data)
            local editBox = self.GetEditBox and self:GetEditBox() or self.editBox
            local ok, message = data.action(editBox:GetText())
            if not ok and message then print("|cff0cd29fSimple Nameplates:|r " .. message) end
            if ok then data.onChanged() end
        end,
        EditBoxOnEnterPressed = function(self)
            local dialog = self:GetParent()
            if dialog.button1 then dialog.button1:Click() end
        end,
        EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
        timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
    }
    StaticPopupDialogs["SNP_DELETE_PROFILE"] = {
        text = "Delete the profile |cffffffff%s|r? Characters using it will switch to Default.",
        button1 = DELETE or "Delete", button2 = CANCEL or "Cancel",
        OnAccept = function(_, data)
            local ok, message = ns.DeleteActiveProfile()
            if not ok and message then print("|cff0cd29fSimple Nameplates:|r " .. message) end
            if ok then data.onChanged() end
        end,
        timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
    }
    StaticPopupDialogs["SNP_RESTORE_BUNDLED_PROFILES"] = {
        text = "Restore the bundled Default and High Contrast profiles? This replaces their current appearance settings and recreates High Contrast if it was deleted or renamed.",
        button1 = "Restore", button2 = CANCEL or "Cancel",
        OnAccept = function(_, data)
            ns.RestoreBundledProfiles()
            data.onChanged()
        end,
        timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
    }
end

local function CreateProfileButtons(content, layout)
    local buttonRow = CreateFrame("Frame", nil, content)
    buttonRow:SetPoint("RIGHT", content, "RIGHT", -20, 0)
    layout:Add(buttonRow, 24, 24, 8)
    local buttons = {}
    for index, definition in ipairs({
        { "Create", 88 }, { "Copy", 88 }, { "Rename", 88 }, { "Delete", 88 },
    }) do
        local button = CreateFrame("Button", nil, buttonRow, "UIPanelButtonTemplate")
        button:SetSize(definition[2], 24)
        if index == 1 then button:SetPoint("LEFT")
        else button:SetPoint("LEFT", buttons[index - 1], "RIGHT", 8, 0) end
        button:SetText(definition[1])
        buttons[index] = button
    end
    return buttons
end

local function InstallProfileButtonScripts(buttons, changed)
    local create, copy, rename, delete =
        buttons[1], buttons[2], buttons[3], buttons[4]
    local function OpenNameDialog(action, initial)
        StaticPopup_Show("SNP_PROFILE_NAME", nil, nil,
            { action = action, initial = initial, onChanged = changed })
    end
    create:SetScript("OnClick", function() OpenNameDialog(ns.CreateProfile, "") end)
    copy:SetScript("OnClick", function()
        OpenNameDialog(ns.CopyActiveProfile, ns.GetActiveProfileName() .. " Copy")
    end)
    rename:SetScript("OnClick", function()
        OpenNameDialog(ns.RenameActiveProfile, ns.GetActiveProfileName())
    end)
    delete:SetScript("OnClick", function()
        StaticPopup_Show("SNP_DELETE_PROFILE", ns.GetActiveProfileName(), nil,
            { onChanged = changed })
    end)
end

local function AddProfileControls(content, layout, refreshers, onChanged)
    RegisterProfileDialogs()
    local section = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    section:SetText("PROFILES")
    layout:Add(section, 24, 20, 6)
    AddDescription(content, layout,
        "Profiles hold appearance settings and are shared account-wide. Each character remembers its selected profile.", 40)

    local profileRow = CreateFrame("Frame", nil, content)
    profileRow:SetPoint("RIGHT", content, "RIGHT", -20, 0)
    layout:Add(profileRow, 24, 42, 6)
    local label = profileRow:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("LEFT", 0, 0)
    label:SetText("Selected profile")
    local profileDropdown = CreateFrame("Frame", nil, profileRow, "UIDropDownMenuTemplate")
    profileDropdown:SetPoint("LEFT", label, "RIGHT", -4, 0)
    UIDropDownMenu_SetWidth(profileDropdown, 235)

    local buttons = CreateProfileButtons(content, layout)
    local rename, delete = buttons[3], buttons[4]
    local function Changed()
        onChanged()
        RefreshNameplates()
    end
    InstallProfileButtonScripts(buttons, Changed)

    local restore = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    restore:SetSize(172, 24)
    restore:SetText("Restore Bundled Profiles")
    layout:Add(restore, 24, 24, 6)
    restore:SetScript("OnClick", function()
        StaticPopup_Show("SNP_RESTORE_BUNDLED_PROFILES", nil, nil,
            { onChanged = Changed })
    end)
    AddDescription(content, layout,
        "Default can be edited and restored, but not renamed or deleted. Create starts with bundled defaults; Copy uses the selected profile. Restore replaces Default and High Contrast.", 48)

    local function Refresh()
        local active = ns.GetActiveProfileName()
        UIDropDownMenu_SetSelectedValue(profileDropdown, active)
        UIDropDownMenu_SetText(profileDropdown, active)
        local protected = active == ns.DEFAULT_PROFILE_NAME
        rename:SetEnabled(not protected)
        delete:SetEnabled(not protected)
    end
    UIDropDownMenu_Initialize(profileDropdown, function(_, level)
        for _, profileName in ipairs(ns.GetProfileNames()) do
            local name = profileName
            local info = UIDropDownMenu_CreateInfo()
            info.text, info.value = name, name
            info.checked = ns.GetActiveProfileName() == name
            info.func = function()
                ns.SetActiveProfileName(name)
                Changed()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)
    refreshers[#refreshers + 1] = Refresh
    Refresh()
end

ns.AddProfileControls = AddProfileControls
