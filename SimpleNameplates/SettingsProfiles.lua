-- Simple Nameplates: appearance Profile management.
local _, addon = ...
local UI, Widgets = addon.SettingsUI, addon.SettingsWidgets
local AddDescription, RefreshNameplates = UI.AddDescription, UI.RefreshNameplates

local function CancelProfileEdits()
    Widgets.CancelColorEdit()
    if addon.CancelAppearanceEdits then addon.CancelAppearanceEdits(true) end
end

local function DialogProfileIsCurrent(data)
    if not data.profileName or data.profileName == addon.GetActiveProfileName() then return true end
    print("|cff0cd29fSimple Nameplates:|r Selected profile changed. Reopen the profile dialog to continue.")
    return false
end

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
            if not DialogProfileIsCurrent(data) then return end
            local editBox = self.GetEditBox and self:GetEditBox() or self.editBox
            local ok, message = data.action(editBox:GetText())
            if not ok and message then print("|cff0cd29fSimple Nameplates:|r " .. message) end
            if ok then data.onChanged() end
        end,
        EditBoxOnEnterPressed = function(self)
            local dialog = self:GetParent()
            local button = dialog.GetButton1 and dialog:GetButton1() or dialog.button1
            if button and button:IsEnabled() then button:Click() end
        end,
        EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
        timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
    }
    StaticPopupDialogs["SNP_DELETE_PROFILE"] = {
        text = "Delete the profile |cffffffff%s|r? Characters using it will switch to Default.",
        button1 = DELETE or "Delete", button2 = CANCEL or "Cancel",
        OnAccept = function(_, data)
            if not DialogProfileIsCurrent(data) then return end
            local ok, message = addon.DeleteActiveProfile()
            if not ok and message then print("|cff0cd29fSimple Nameplates:|r " .. message) end
            if ok then data.onChanged() end
        end,
        timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
    }
    StaticPopupDialogs["SNP_RESTORE_BUNDLED_PROFILES"] = {
        text = "Restore factory settings for Default and High Contrast? Their changes will be lost; missing bundled profiles will be recreated.",
        button1 = "Restore", button2 = CANCEL or "Cancel",
        OnAccept = function(_, data)
            addon.RestoreBundledProfiles()
            data.onChanged()
        end,
        timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
    }
end

local function CreateProfileButtons(content, layout, changed)
    local function OpenNameDialog(action, initial, profileName)
        StaticPopup_Show("SNP_PROFILE_NAME", nil, nil,
            {action = action, initial = initial, profileName = profileName, onChanged = changed})
    end
    local function OpenActiveNameDialog(action, suffix)
        local name = addon.GetActiveProfileName()
        OpenNameDialog(action, name .. suffix, name)
    end
    local definitions = {
        {"Create", function() OpenNameDialog(addon.CreateProfile, "") end},
        {"Copy", function() OpenActiveNameDialog(addon.CopyActiveProfile, " Copy") end},
        {"Rename", function() OpenActiveNameDialog(addon.RenameActiveProfile, "") end},
        {"Delete", function()
            StaticPopup_Show("SNP_DELETE_PROFILE", addon.GetActiveProfileName(), nil,
                {profileName = addon.GetActiveProfileName(), onChanged = changed})
        end},
    }
    local row = CreateFrame("Frame", nil, content)
    row.LayoutFullWidth = true
    layout:Add(row, 24, 24, 8)
    local buttons = {}
    for index, definition in ipairs(definitions) do
        local button = Widgets.CreateButton(row, definition[1], definition[2], 88, 24)
        if index == 1 then button:SetPoint("LEFT", row, "LEFT", 0, 0)
        else button:SetPoint("LEFT", buttons[index - 1], "RIGHT", 8, 0) end
        buttons[index] = button
    end
    return buttons
end

-- Compact selector shared by the visual pages; management remains here.
local function AddProfileSelector(content, layout, refreshers, onChanged, controlX)
    local row, dropdown
    local function Refresh()
        dropdown:InvalidateOptions() -- Profile names may be created/renamed/deleted elsewhere.
        local active = addon.GetActiveProfileName()
        dropdown:SetValue(active, active)
    end
    row, dropdown = UI.CreateDropdownRow(content, layout, "Selected profile", function()
        local options = {}
        for _, name in ipairs(addon.GetProfileNames()) do
            options[#options + 1] = {value = name, label = name}
        end
        return options
    end, function(name)
        CancelProfileEdits()
        addon.SetActiveProfileName(name)
        Refresh()
        if onChanged then onChanged() end
        RefreshNameplates()
    end, controlX)
    refreshers[#refreshers + 1] = Refresh
    Refresh()
    return row, dropdown
end
addon.AddProfileSelector = AddProfileSelector

local function CreateProfilesPanel()
    RegisterProfileDialogs()
    local panel, content, layout = UI.CreateScrollablePanel("Profiles")
    UI.AddTitle(content, layout, "Profiles")
    AddDescription(content, layout,
        "Profiles are account-wide; each character remembers its selection.")
    local refreshers = {}
    local function Refresh() UI.RunRefreshers(refreshers) end
    local row, dropdown = AddProfileSelector(content, layout, refreshers, Refresh, 184)
    addon.AddStylingSwitch(row, dropdown, refreshers)
    AddDescription(content, layout, "Enables addon styling for all characters and profiles.")
    UI.AddSection(content, layout, "Manage profiles")
    AddDescription(content, layout,
        "Create uses factory defaults. Default cannot be renamed or deleted.")
    local function Changed() Refresh(); RefreshNameplates() end
    local buttons = CreateProfileButtons(content, layout, Changed)
    refreshers[#refreshers + 1] = function()
        local protected = addon.GetActiveProfileName() == addon.DEFAULT_PROFILE_NAME
        buttons[3]:SetEnabled(not protected)
        buttons[4]:SetEnabled(not protected)
    end
    UI.AddSection(content, layout, "Restore bundled profiles")
    AddDescription(content, layout,
        "Resets Default and High Contrast, recreating High Contrast if missing. Custom profiles are unchanged.")
    UI.AddPageAction(content, layout, "Restore bundled profiles", function()
        StaticPopup_Show("SNP_RESTORE_BUNDLED_PROFILES", nil, nil, {onChanged = Changed})
    end, 210)
    panel.Refresh = Refresh
    panel:SetScript("OnShow", panel.Refresh)
    Refresh()
    layout:Finish()
    return panel
end
addon.SettingsPanels.Profiles = CreateProfilesPanel

