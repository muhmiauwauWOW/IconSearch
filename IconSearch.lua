local addonName, ns = ...
IconSearchAddon = LibStub("AceAddon-3.0"):NewAddon("IconSearch", "AceEvent-3.0")
local _ = LibStub("LibLodash-1"):Get()

-- Hilfsfunktion für sicheres Frame-Handling
local function safeCreateFrame(parent, accountBank)
    if not parent then
        return nil
    end
    local ok, frame = pcall(CreateFrame, "Frame", nil, parent, "IconSearchFrame")
    if not ok or not frame then
        return nil
    end
    frame:SetPoint("TOPLEFT", 0, accountBank and -170 or -75)
    frame:SetPoint("BOTTOMRIGHT", 0, 7)
    return frame
end

function IconSearchAddon:OnEnable()
    if not ns or not ns.buildIcons then
        return
    end
    ns.buildIcons()
    safeCreateFrame(GearManagerPopupFrame)
    safeCreateFrame(AccountBankPanel and AccountBankPanel.TabSettingsMenu, true)
    self:RegisterEvent("ADDON_LOADED", "OnAddonLoaded")
end

function IconSearchAddon:OnAddonLoaded(event, name)
    local frameMap = {
        ["Blizzard_MacroUI"] = MacroPopupFrame,
        ["Blizzard_GuildBankUI"] = GuildBankPopupFrame
    }
    if frameMap[name] then
        safeCreateFrame(frameMap[name])
    end
    if name == "LargerMacroIconSelection" and LargerMacroIconSelection then
        hooksecurefunc(LargerMacroIconSelection, "SetSearchData", function()
            IconSearchAddon:SendMessage("tabchange", "Icons")
        end)
    end
end

IconSearchMixin = {}
function IconSearchMixin:OnLoad()
    TabSystemOwnerMixin.OnLoad(self)
	self.searchStr = ""
    self:SetTabSystem(self.TabSystem)
    self.mainView = self:AddNamedTab("Icon Search", self.IconSearchViewFrame)
    self.Blizz = self:AddNamedTab("Icons", self.IconSearchBlizzadViewFrame)
    self:SetTab(self.mainView)
    self:GetParent().BorderBox.IconTypeDropdown:SetParent(self.IconSearchBlizzadViewFrame)
    self:GetParent().IconSelector:SetParent(self.IconSearchBlizzadViewFrame)
    IconSearchAddon:RegisterMessage("tabchange", function(_, type, arg)
        self:SetTab(arg == "Icons" and self.Blizz or self.mainView)
    end, self)
end

function IconSearchMixin:OnShow()
    -- self:reset()
    self:SetTab(self.mainView)
end

function IconSearchMixin:search(searchString)
	C_Timer.After(.1, function()
		local frame = self.IconSearchViewFrame.IconSectionSelector
		for widget in frame.pool:EnumerateActive() do
			local data = _.filter(widget.IconSelector.data, function(icon)
				return string.find(string.lower(icon.search), searchString)
			end)
			widget:SetShown(#data > 0)
			widget.IconSelector:renderIcons(data)
		end
		frame:calcHeight() 
		self.searchStr = searchString

	end)
end

function IconSearchMixin:reset()
    self.IconSearchViewFrame.SearchBar:Reset()
    local frame = self.IconSearchViewFrame.IconSectionSelector
    for widget in frame.pool:EnumerateActive() do
        widget.IconSelector:renderIcons(widget.IconSelector.data)
        widget:Show()
    end
    frame:calcHeight()
	self.searchStr = ""
end

function IconSearchMixin:reSearch()
	self:search(self.searchStr)
end

IconSectionSelectorMixin = {}

function IconSectionSelectorMixin:OnLoad()
    self.scrollBarHideable = false
    ScrollFrame_OnLoad(self)
    self.firstTitle = CreateFrame("BUTTON", nil, self, "IconSelectorSectionTitleTemplate")
    self.firstTitle.height = 36
    self.Data = ns.IconSearchData
    self.pool = CreateFramePool("Frame", self.Contents, "IconSelectorSectionTemplate")
    self.titleIdx = 1
    self.heightTitleMap = {}
    self.lastScrollPos = 0
end

function IconSectionSelectorMixin:OnUpdate()
    local scrollPos = self:GetVerticalScroll()
    if self.lastScrollPos == scrollPos then return end
    local scrollDirection = self.lastScrollPos > scrollPos and "up" or "down"
    self.lastScrollPos = scrollPos
    if scrollDirection == "down" and scrollPos > self.heightTitleMap[self.titleIdx] then
        self.titleIdx = self.titleIdx + 1
        self.firstTitle:SetText(self.Data.sections[self.titleIdx].name)
    end
    if self.titleIdx == 1 then return end
    if scrollDirection == "up" and scrollPos < self.heightTitleMap[self.titleIdx - 1] then
        self.titleIdx = self.titleIdx - 1
        self.firstTitle:SetText(self.Data.sections[self.titleIdx].name)
    end
end

function IconSectionSelectorMixin:buildSections()
    self.pool:ReleaseAll()
    self.firstTitle:SetText(self.Data.sections[1].name)
    _.forEach(self.Data.sections, function(section)
        if #section.obj == 0 then return end
        local frame = self.pool:Acquire()
        frame.name = section.name
        frame.idx = section.idx
        frame.height = 36
        frame.IconSelector.initialized = false
        frame.IconSelector.data = section.obj
        frame.Title:SetText(section.name)
        frame:SetShown(#section.obj > 0)
    end)
end

function IconSectionSelectorMixin:OnShow()
    self.Data = ns.IconSearchData
    self:buildSections()
end

function IconSectionSelectorMixin:calcHeight()
    local height = 0
    local children = { self.Contents:GetChildren() }
    table.sort(children, function(a, b) return (a.idx or 0) < (b.idx or 0) end)
    self.heightTitleMap = {}
    _.forEach(children, function(child, idx)
        if not child:IsShown() then self.heightTitleMap[idx] = height; return end
        child:SetPoint("TOPLEFT", 0, -height)
        height = height + (child.height or 0)
        self.heightTitleMap[idx] = height
    end)
    self:GetParent().NoSearchResultsText:SetShown(height == 0)
    self.firstTitle:SetShown(height > 0)
    self.Contents:SetHeight(height)
end

IconSelectorSectionMixin = {}
function IconSelectorSectionMixin:OnLoad() end
function IconSelectorSectionMixin:setHeight(height)
    height = height + 40
    self.height = height
    self:SetHeight(height)
end

IconSelectorMixin = {}
function IconSelectorMixin:OnLoad()
    self.data = {}
    self.initialized = false
    self.pool = CreateFramePool("FRAME", self, "IconSearchButtonTemplate")
end

function IconSelectorMixin:OnShow()
    if not self.initialized then self:Init() end
end

function IconSelectorMixin:Init()
    self.cols = 10
    self.padding = 46
    self.getPos = function(type, index)
        index = index - 1
        local row = math.floor(index / self.cols)
        if type == "y" then return row * self.padding end
        return (index - (row * self.cols)) * self.padding
    end
    self:renderIcons()
    self.initialized = true
end

function IconSelectorMixin:renderIcons(data)
    self.pool:ReleaseAll()
    data = data or self.data
    _.forEach(data, function(entry, idx)
        local frame = self.pool:Acquire()
        frame:SetPoint("TOPLEFT", self, "TOPLEFT", self.getPos("x", idx), -self.getPos("y", idx))
        frame:SetHeight(45)
        frame:SetWidth(45)
        frame.button.parent = self:GetParent():GetParent():GetParent():GetParent():GetParent():GetParent()
        frame.data = entry
        frame.button.data = entry
        frame.button.Icon:SetTexture(entry.texture)
        frame:Show()
    end)
    local height = #data == 0 and 45 or (math.ceil(#data / self.cols) * self.padding)
    self.NoSearchResultsText:SetShown(#data == 0)
    self:GetParent():setHeight(height)
end

IconSearchSearchBarMixin = {}

function IconSearchSearchBarMixin:OnLoad()
    SearchBoxTemplate_OnLoad(self)

    self.clearButton:HookScript("OnClick", function(btn)
        self:GetParent():GetParent():reset()
        SearchBoxTemplateClearButton_OnClick(btn)
    end)
end
function IconSearchSearchBarMixin:search(text)
    if string.len(text) == 0 then
        self:GetParent():GetParent():reset()
    else
        self:GetParent():GetParent():search(text)
    end
end

function IconSearchSearchBarMixin:OnEnterPressed()
    EditBox_ClearFocus(self)
    self:search(self:GetText())
end
function IconSearchSearchBarMixin:OnKeyUp()
    self:search(self:GetText())
end
function IconSearchSearchBarMixin:Reset()
    self:SetText("")
end

IconSearchNoResultButtonMixin = {}
function IconSearchNoResultButtonMixin:OnClick()
    local frame = self:GetParent():GetParent():GetParent()
    frame:SetTab(frame.Blizz)
    frame:reset()
end

IconSearchButtonMixin = {}
local lastActiveButton = nil
function IconSearchButtonMixin:OnClick()
    self.parent.BorderBox.SelectedIconArea.SelectedIconButton:SetIconTexture(self.data.texture)
    if lastActiveButton then lastActiveButton.SelectedTexture:Hide() end
    self.SelectedTexture:Show()
    lastActiveButton = self
end
function IconSearchButtonMixin:OnEnter()
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine(self.data.name, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
    --@do-not-package@
    GameTooltip:AddDoubleLine("Type:", self.data.type)
    GameTooltip:AddDoubleLine("texture:", self.data.texture)
    GameTooltip:AddLine(self.data.search)
    --@end-do-not-package@
    GameTooltip:Show()
end
function IconSearchButtonMixin:OnLeave()
    GameTooltip:Hide()
end



IconSearchViewFrameMixin = {}
function IconSearchViewFrameMixin:OnShow()
	self:GetParent():reSearch()

end
