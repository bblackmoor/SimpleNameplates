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

    local desiredHeight, finished = 1, false
    local layout = { parent = content, offset = 18, items = {} }
    local function Reflow()
        local offset = 18
        for _, item in ipairs(layout.items) do
            local height = item.height
            if item.region and item.region.SNPLayoutFullWidth then
                item.region:SetWidth(math.max(1, content:GetWidth() - item.x - 24))
            end
            if item.autoHeight then
                item.region:SetHeight(0) -- Measure wrapped text without its previous height cap.
                height = math.max(16, item.region:GetStringHeight() + 2)
            end
            if item.region then
                item.region:SetHeight(height)
                item.region:SetPoint("TOPLEFT", content, "TOPLEFT", item.x, -offset)
            end
            offset = offset + height + item.gap
        end
        layout.offset = offset
        desiredHeight = offset + 20
    end
    local function UpdateContentSize(_, width, height)
        width = width or scroll:GetWidth()
        height = height or scroll:GetHeight()
        if width and width > 4 then content:SetWidth(width - 4) end
        if finished then Reflow() end
        content:SetHeight(math.max(desiredHeight, height or 1, 1))
    end
    scroll:SetScript("OnSizeChanged", UpdateContentSize)
    scroll:SetScript("OnShow", function(self)
        UpdateContentSize(self, self:GetWidth(), self:GetHeight())
    end)
    function layout:Add(region, x, height, gap, autoHeight)
        self.items[#self.items + 1] = {region = region, x = x or 24,
            height = height or 20, gap = gap or 0, autoHeight = autoHeight}
        if region.SNPLayoutFullWidth then region:SetWidth(math.max(1, content:GetWidth() - (x or 24) - 24)) end
        region:SetHeight(height or 20)
        region:SetPoint("TOPLEFT", content, "TOPLEFT", x or 24, -self.offset)
        self.offset = self.offset + (height or 20) + (gap or 0)
        return region
    end
    function layout:Space(height)
        self.items[#self.items + 1] = {height = height, gap = 0}
        self.offset = self.offset + height
    end
    function layout:Finish()
        finished = true
        local onShow = panel:GetScript("OnShow")
        panel:SetScript("OnShow", function(self, ...)
            if onShow then onShow(self, ...) end
            UpdateContentSize(scroll, scroll:GetWidth(), scroll:GetHeight())
        end)
        UpdateContentSize(scroll, scroll:GetWidth(), scroll:GetHeight())
    end
    return panel, content, layout
end

local function AddTitle(content, layout, text)
    local title = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetText(text)
    return layout:Add(title, 24, 24, 8)
end

local function AddDescription(content, layout, text)
    local description = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    description.SNPLayoutFullWidth = true
    description:SetTextColor(0.72, 0.72, 0.72, 1)
    description:SetJustifyH("LEFT")
    description:SetText(text)
    return layout:Add(description, 24, 16, 8, true)
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


local CONTROL_X = 340
local function AddSection(content, layout, text)
    layout:Space(14)
    local label = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetText(text)
    return layout:Add(label, 24, 20, 6)
end

-- Headings contain no actions. Section actions follow their controls.
local function AddActionButton(content, layout, text, onClick, width)
    local button = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    button:SetSize(width or 190, 24)
    button:SetText(text)
    button:SetScript("OnClick", onClick)
    layout:Add(button, 24, 24, 8)
    return button
end

local function CreateSettingRow(content, layout, text)
    local row = CreateFrame("Frame", nil, content)
    row.SNPLayoutFullWidth = true
    local label = row:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    label:SetPoint("LEFT")
    label:SetWidth(CONTROL_X - 16)
    label:SetJustifyH("LEFT")
    label:SetText(text)
    layout:Add(row, 24, 32, 6)
    return row, label
end

local function AddToggle(content, layout, refreshers, text, getter, setter, onChanged)
    local row = CreateSettingRow(content, layout, text)
    local toggle = CreateSwitch(row, function(checked)
        setter(checked)
        if onChanged then onChanged(checked) end
    end)
    toggle:SetPoint("LEFT", row, "LEFT", CONTROL_X, 0)
    local function Refresh() toggle:SetChecked(getter()) end
    refreshers[#refreshers + 1] = Refresh
    Refresh()
    return toggle
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
    AddActionButton = AddActionButton,
    CreateSettingRow = CreateSettingRow,
    AddToggle = AddToggle,
    CONTROL_X = CONTROL_X,
    AddSection = AddSection,
    RunRefreshers = RunRefreshers,
    RefreshNameplates = RefreshNameplates,
}
ns.SettingsPanels = {}
