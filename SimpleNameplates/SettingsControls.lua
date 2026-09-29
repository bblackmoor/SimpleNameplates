-- Simple Nameplates: shared settings controls and layout.
local _, ns = ...


local function RefreshNameplates()
    if ns.RefreshAll then ns.RefreshAll() end
end

-- Canvas settings pages are not scrollable on their own. Each page owns a
-- scroll frame and a content frame. The cursor makes vertical placement
-- sequential; explicit horizontal offsets and control heights remain useful.
local function CreateScrollablePanel(name)
    local panel = CreateFrame("Frame")
    panel.name = name
    local scroll = CreateFrame("ScrollFrame", nil, panel, "ScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT")
    scroll:SetPoint("BOTTOMRIGHT", -28, 0)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(640, 1)
    scroll:SetScrollChild(content)

    local desiredHeight = 1
    local function UpdateContentSize(_, width, height)
        width = width or scroll:GetWidth()
        height = height or scroll:GetHeight()
        if width and width > 4 then content:SetWidth(width - 4) end
        content:SetHeight(math.max(desiredHeight, height or 1, 1))
    end
    scroll:SetScript("OnSizeChanged", UpdateContentSize)
    scroll:SetScript("OnShow", function(self)
        UpdateContentSize(self, self:GetWidth(), self:GetHeight())
    end)

    local layout = { parent = content, offset = 18 }
    function layout:Add(region, x, height, gap)
        if height and region.SetHeight then region:SetHeight(height) end
        region:SetPoint("TOPLEFT", self.parent, "TOPLEFT", x or 20, -self.offset)
        self.offset = self.offset + (height or 20) + (gap or 0)
        return region
    end
    function layout:Space(height) self.offset = self.offset + height end
    function layout:Finish(bottomPadding)
        desiredHeight = self.offset + (bottomPadding or 20)
        UpdateContentSize(scroll, scroll:GetWidth(), scroll:GetHeight())
    end
    return panel, content, layout
end

local function AddTitle(content, layout, text)
    local title = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetText(text)
    return layout:Add(title, 20, 24, 4)
end

local function AddDescription(content, layout, text, height)
    local description = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    description:SetPoint("RIGHT", content, "RIGHT", -20, 0)
    description:SetJustifyH("LEFT")
    description:SetText(text)
    return layout:Add(description, 20, height or 32, 4)
end

-- Visual switch with the same SetChecked/GetChecked contract as the former checkbox.
local function CreateSwitch(parent, onChanged)
    local switch = CreateFrame("Button", nil, parent)
    switch:SetSize(44, 20)
    local track = switch:CreateTexture(nil, "BACKGROUND")
    track:SetAllPoints()
    local thumb = switch:CreateTexture(nil, "ARTWORK")
    thumb:SetSize(18, 16)
    function switch:SetChecked(checked)
        self.checked = checked == true
        thumb:ClearAllPoints()
        if self.checked then
            track:SetColorTexture(0.19, 0.42, 0.31, self:IsEnabled() and 1 or 0.5)
            thumb:SetPoint("RIGHT", self, "RIGHT", -2, 0)
        else
            track:SetColorTexture(0.25, 0.25, 0.26, self:IsEnabled() and 1 or 0.5)
            thumb:SetPoint("LEFT", self, "LEFT", 2, 0)
        end
        thumb:SetColorTexture(0.72, 0.72, 0.73, self:IsEnabled() and 1 or 0.5)
    end
    function switch:GetChecked() return self.checked end
    switch:SetScript("OnEnable", function(self) self:SetChecked(self.checked) end)
    switch:SetScript("OnDisable", function(self) self:SetChecked(self.checked) end)
    switch:SetScript("OnClick", function(self)
        self:SetChecked(not self:GetChecked())
        onChanged(self:GetChecked())
    end)
    switch:SetChecked(false)
    return switch
end

local function AddInfoLink(parent, anchor, popupKey)
    local link = CreateFrame("Button", nil, parent)
    link:SetSize(24, 26)
    link:SetPoint("LEFT", anchor, "RIGHT", 10, 0)
    local circle = link:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    circle:SetPoint("CENTER")
    circle:SetText("O")
    local letter = link:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    letter:SetPoint("CENTER")
    letter:SetText("i")
    link:SetSize(math.ceil(math.max(circle:GetStringWidth(), letter:GetStringWidth()) + 6),
        math.ceil(math.max(circle:GetStringHeight(), letter:GetStringHeight()) + 4))
    link:SetScript("OnClick", function() StaticPopup_Show(popupKey) end)
    return link
end


local function AddSectionResetButton(content, layout, title, buttonText, onClick)
    local row = CreateFrame("Frame", nil, content)
    row:SetPoint("RIGHT", content, "RIGHT", -24, 0)
    layout:Add(row, 24, 26, 8)
    local heading = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    heading:SetPoint("LEFT", 0, 0)
    heading:SetText(title)
    local reset = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    reset:SetSize(150, 24)
    reset:SetPoint("LEFT", heading, "RIGHT", 12, 0)
    reset:SetText(buttonText)
    reset:SetScript("OnClick", onClick)
end


local function AddSection(content, layout, text)
    local label = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetText(text)
    layout:Add(label, 24, 20, 2)
end

local function RunRefreshers(refreshers)
    for _, refresh in ipairs(refreshers) do refresh() end
end


ns.SettingsUI = {
    CreateScrollablePanel = CreateScrollablePanel,
    AddTitle = AddTitle,
    AddDescription = AddDescription,
    CreateSwitch = CreateSwitch,
    AddInfoLink = AddInfoLink,
    AddSectionResetButton = AddSectionResetButton,
    AddSection = AddSection,
    RunRefreshers = RunRefreshers,
    RefreshNameplates = RefreshNameplates,
}
ns.SettingsPanels = {}
