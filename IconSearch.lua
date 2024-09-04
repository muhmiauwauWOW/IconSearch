local _ = LibStub("LibLodash-1"):Get()




local defaultSearchMacroText = false

SearchMacroText = nil



IconSearchMixin = {}

function IconSearchMixin:OnLoad()
	
	if true then return true end

	self.Data = ICONSEARCH_DATA
	self.searchString = nil
	self.filterdIcons = {}
	--self.updateFN = MacroFrame.Update

	self.Icons = self.Data.all

	


	self.filterdIcons = self.Icons
	

	self.IconSelector:AdjustScrollBarOffsets(-14, -4, 6);

	self.IconSelector:SetCustomStride(10);
	-- self.IconSelector:SetCustomPadding(5, 5, 5, 5, 13, 13);
	
	local function InitIconButton(macroButton, selectionIndex, obj)
		macroButton:SetIconTexture(obj.texture);
		macroButton.Name:SetText(obj.name);
		macroButton.data = obj
	end
	
	self.IconSelector:SetSetupCallback(InitIconButton);



	local function SelectedCallback(selectionIndex, obj)
		local icon = obj.texture
		if type(icon) == "string" then
			icon = string.gsub(icon, [[INTERFACE\ICONS\]], "");
		end

		MacroPopupFrame.BorderBox.SelectedIconArea.SelectedIconButton:SetIconTexture(icon);
		-- Index is not yet set, but we know if an icon in IconSelector was selected it was in the list, so set directly.
		MacroPopupFrame.BorderBox.SelectedIconArea.SelectedIconText.SelectedIconDescription:SetText(ICON_SELECTION_CLICK);
		MacroPopupFrame.BorderBox.SelectedIconArea.SelectedIconText.SelectedIconDescription:SetFontObject(GameFontHighlightSmall);
	end

	self.IconSelector:SetSelectedCallback(SelectedCallback);



	local function GetIconInfo(selectionIndex)
		return self.filterdIcons[selectionIndex]
	end

	local function GetNumIcon()
		return #self.filterdIcons
	end

	self.IconSelector:SetSelectionsDataProvider(GetIconInfo, GetNumIcon);



	self.NoSearchResultsText:SetAllPoints(self.IconSelector)



end

function IconSearchMixin:setFindMode(bool)
	SearchMacroText = bool or defaultSearchMacroText
	self.findmode = bool and "extended" or  "default"
end
function IconSearchMixin:repeatSearch()
	if not self.searchString then return end
	self:search(self.searchString)
end

function IconSearchMixin:search(str)
	self.searchString = string.lower(str)
	self.filterdIcons = _.filter(self.Icons, function(icon) 
		return string.find(string.lower(icon.search), self.searchString)
	end)
	self.IconSelector:UpdateSelections();
	self.NoSearchResultsText:SetShown(#self.filterdIcons == 0)
end

function IconSearchMixin:reset()
	self.filterdIcons = self.Icons
	self.IconSelector:UpdateSelections();
	-- IconSearchFrame.Update = self.updateFN
	-- IconSearchFrame:Update()
	self.searchString = nil
	self.SearchBar:Reset()
end








IconSectionSelectorMixin = {}


function IconSectionSelectorMixin:OnLoad()
	self.scrollBarHideable = false;
	ScrollFrame_OnLoad(self);	
	
	
	self.Data = ICONSEARCH_DATA



	self.Contents:SetHeight(1111)


	self:Show()

	self.pool = CreateFramePool("Frame", self.Contents, "IconSelectorSectionTemplate")



	_.forEach(self.Data.sections, function(section,idx)
		print(section.name,idx)
		local pos = ((idx - 1) * (36 + 360)) *-1
		local frame = self.pool:Acquire();
		frame:SetHeight(100)
		frame.IconSelector.data = section.obj
		frame.Title:SetText(section.name);
		frame:SetPoint("TOPLEFT", self.Contents, "TOPLEFT", 0, pos)
		frame:Show()
	end)

	



	print("vvvv")
end




IconSelectorSectionMixin = {}


function IconSelectorSectionMixin:OnLoad()
	print("IconSelectorSectionMixin")
end




IconSelectorMixin = {}
function IconSelectorMixin:OnShow()
	if not self.initialized then
		self:Init();
	end

	print("IconSelectorMixin")
end




function IconSelectorMixin:Init()

	local view = CreateScrollBoxListGridView(10);

	local function InitializeGridSelectorScrollButton(button, selectionIndex)
		self:RunSetup(button, selectionIndex);
	end

	local templateType, buttonTemplate = self:GetButtonTemplate();
	view:SetElementInitializer(buttonTemplate, InitializeGridSelectorScrollButton);

end










IconSearchTitleTemplateTitleMixin = {}














IconSearchSearchBarMixin = {}

function IconSearchSearchBarMixin:OnLoad()
	SearchBoxTemplate_OnLoad(self);
	self.clearButton:HookScript("OnClick", function(btn)
		self:GetParent():reset()
		SearchBoxTemplateClearButton_OnClick(btn);
	end)
end
function IconSearchSearchBarMixin:search(text)
    if string.len(text) == 0 then
		self:GetParent():reset()
	else
		self:GetParent():search(text)
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


IconSearchButtonMixin = {}




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