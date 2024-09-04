
IconSearchAddon = LibStub("AceAddon-3.0"):NewAddon("IconSearch", "AceEvent-3.0")
local _ = LibStub("LibLodash-1"):Get()




local defaultSearchMacroText = false

SearchMacroText = nil



IconSearchMixin = {}

function IconSearchMixin:OnLoad()
	TabSystemOwnerMixin.OnLoad(self);
    self:SetTabSystem(self.TabSystem);
    self.mainView = self:AddNamedTab("Icon Search", self.IconSearchViewFrame);
   	self.Blizz = self:AddNamedTab("Icons", self.IconSearchBlizzadViewFrame);

    self:SetTab(self.mainView);

	MacroPopupFrame.BorderBox.IconTypeDropdown:SetParent(self.IconSearchBlizzadViewFrame)
	MacroPopupFrame.IconSelector:SetParent(self.IconSearchBlizzadViewFrame)
end



IconSearchButtonMixin = {}



local lastActiveButton = nil

function IconSearchButtonMixin:OnClick()
	MacroPopupFrame.BorderBox.SelectedIconArea.SelectedIconButton:SetIconTexture(self.data.texture);

	if lastActiveButton then
		lastActiveButton.SelectedTexture:Hide()
	end
	self.SelectedTexture:Show();

	lastActiveButton = self
	
end

function IconSearchButtonMixin:OnEnter()
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:AddLine(self.data.name)
	GameTooltip:AddDoubleLine("Type:",self.data.type)
	GameTooltip:AddDoubleLine("texture:",self.data.texture)
	GameTooltip:AddLine(self.data.search)
	GameTooltip:Show()
end

function IconSearchButtonMixin:OnLeave()
	GameTooltip:Hide();
end




IconSectionSelectorMixin = {}


function IconSectionSelectorMixin:OnLoad()
	self.scrollBarHideable = false;
	ScrollFrame_OnLoad(self);	
	
	
	self.Data = ICONSEARCH_DATA


	self.pool = CreateFramePool("Frame", self.Contents, "IconSelectorSectionTemplate")



	IconSearchAddon:RegisterMessage("search", function(self, search, searchString)
		for widget in self.pool:EnumerateActive() do
			
			local data = _.filter(widget.IconSelector.data, function(icon) 
				return string.find(string.lower(icon.search), searchString)
			end)

			widget:SetShown(#data > 0)
			widget.IconSelector:renderIcons(data)
		end

		self:calcHeight()
	end, self)

	IconSearchAddon:RegisterMessage("reset", function(self, reset, searchString)
		for widget in self.pool:EnumerateActive() do
			widget.IconSelector:renderIcons(widget.IconSelector.data)
			widget:Show()
		end

		self:calcHeight()
	end, self)

end



function IconSectionSelectorMixin:buildSections()
	self.pool:ReleaseAll()
	_.forEach(self.Data.sections, function(section,idx)
		local pos = ((idx - 1) * (136)) *-1
		local frame = self.pool:Acquire();
		frame.name = section.name
		frame.height = 36
		frame.IconSelector.initialized = false
		print(section.name, #section.obj)
		frame.IconSelector.data = section.obj
		frame.Title:SetText(section.name);
		frame:SetShown(#section.obj > 0)

		-- frame.Texture = frame:CreateTexture()
		-- frame.Texture:SetAllPoints()
		-- frame.Texture:SetColorTexture(0,0, 0, 0.7)
	end)
end



function IconSectionSelectorMixin:OnShow()
	DevTool:AddData(ICONSEARCH_DATA, "ICONSEARCH_DATA")
	self.Data = ICONSEARCH_DATA
	self:buildSections()
end

function IconSectionSelectorMixin:calcHeight()
	local height = 0
	local children = {self.Contents:GetChildren()}
-- print("ddd calcHeight")
-- 	for widget in self.pool:EnumerateActive() do
-- 		print(widget.name)
-- 		widget:SetPoint("TOPLEFT", 0, height * -1)
-- 		height = height + widget.height
-- 	end


	table.foreach(children, function(idx, child)
		if not child:IsShown() then return end
		child:SetPoint("TOPLEFT", 0, height * -1)
		height = height + child.height
	end)


	self.Contents:SetHeight(height)
end






IconSelectorSectionMixin = {}


function IconSelectorSectionMixin:OnLoad()
end



function IconSelectorSectionMixin:setHeight(height)
	height = height + 40
	self.height = height
	self:SetHeight(height)
	
end



IconSelectorMixin = {}
function IconSelectorMixin:OnLoad()
	self.data = {}
	self.initialized = false;
	self.pool = CreateFramePool("FRAME", self, "IconSearchButtonTemplate")

end


function IconSelectorMixin:OnShow()
	if not self.initialized then
		print("init")
		self:Init();
	end
end

function IconSelectorMixin:Init()

	self.cols = 10
	self.padding = 45 + 1

	self.getPos = function(type, index)
		index = index -1
		local row = math.floor(index / self.cols) 
		if type == "y" then return row * self.padding end
		return (index - (row * self.cols)) *  self.padding
	end
	print(#self.data)

	self:renderIcons()
	self:GetParent():GetParent():GetParent():calcHeight()
	self.initialized = true;
end



function IconSelectorMixin:renderIcons(data)
	self.pool:ReleaseAll()
	data = data or self.data
	_.forEach(data, function(entry, idx)
		local x = 0
		local y = 0
		local frame = self.pool:Acquire();
		
		
		frame:SetPoint("TOPLEFT", self, "TOPLEFT", self.getPos("x", idx), 0 - self.getPos("y", idx))
		frame:SetHeight(45)
		frame:SetWidth(45)
		frame.data = entry
		frame.button.data = entry
		frame.button.Icon:SetTexture(entry.texture);
		frame:Show()
	end)

	local height = #data == 0 and 45 or ( math.ceil(#data / self.cols) * self.padding )
	self.NoSearchResultsText:SetShown(#data == 0)
	self:GetParent():setHeight(height)
end








IconSearchTitleTemplateTitleMixin = {}













IconSearchSearchBarMixin = {}

function IconSearchSearchBarMixin:OnLoad()
	SearchBoxTemplate_OnLoad(self);
	self.clearButton:HookScript("OnClick", function(btn)
	--	self:GetParent():reset()
		IconSearchAddon:SendMessage("reset", true)
		SearchBoxTemplateClearButton_OnClick(btn);
	end)
end
function IconSearchSearchBarMixin:search(text)
    if string.len(text) == 0 then
		--self:GetParent():reset()
		IconSearchAddon:SendMessage("reset", true)
	else
	--	self:GetParent():search(text)
		IconSearchAddon:SendMessage("search", text)
	end
end

function IconSearchSearchBarMixin:OnEnterPressed()
	EditBox_ClearFocus(self);
	self:search(self:GetText())
end

function IconSearchSearchBarMixin:OnKeyUp()
	self:search(self:GetText())
end

function IconSearchSearchBarMixin:Reset()
	self:SetText("");
end


