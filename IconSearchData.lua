local addonName, ns = ...

local _ = LibStub("LibLodash-1"):Get()


ns.IconSearchData = {}
ns.IconSearchData.all = {}
ns.IconSearchData.sections = {}



local function getSpells()
	local tableObj = {}

	for skillLineIndex = 1, C_SpellBook.GetNumSpellBookSkillLines() do
		local skillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo(skillLineIndex);
		for i = 1, skillLineInfo.numSpellBookItems do
			local spellIndex = skillLineInfo.itemIndexOffset + i;
			local spellName = C_SpellBook.GetSpellBookItemName(spellIndex,  Enum.SpellBookSpellBank.Player)
			local spellType, ID = C_SpellBook.GetSpellBookItemType(spellIndex, Enum.SpellBookSpellBank.Player);
			if spellType ~= "FUTURESPELL" then
				local fileID = C_SpellBook.GetSpellBookItemTexture(spellIndex, Enum.SpellBookSpellBank.Player);
				if fileID ~= nil then
					table.insert(tableObj, {
						name = spellName,
						texture = fileID,
						type = "spell",
						search =  string.format("%s %s %s", spellName, fileID, ID)
					})
				end
			end

			if spellType == "FLYOUT" then
				local _, _, numSlots, isKnown = GetFlyoutInfo(ID);
				if isKnown and (numSlots > 0) then
					for k = 1, numSlots do
						local spellID, overrideSpellID, isSlotKnown, spellName  = GetFlyoutSlotInfo(ID, k)
						if isSlotKnown then
							local fileID = C_Spell.GetSpellTexture(spellID);
							if fileID ~= nil then
								table.insert(tableObj, {
									name = spellName,
									texture = fileID,
									type = "spell",
									search =  string.format("%s %s %s", spellName, fileID, spellID)
								})
							end
						end
					end
				end
			end
		end
	end

	return tableObj
end


local function getTalents()
	local tableObj = {}
	local isInspect = false;
	for specIndex = 1, GetNumSpecGroups(isInspect) do
		for tier = 1, MAX_TALENT_TIERS do
			for column = 1, NUM_TALENT_COLUMNS do
				local talentinfo = {GetTalentInfo(tier, column, specIndex)};
				if talentinfo[3] ~= nil then
					table.insert(tableObj, {
						name = talentinfo[2],
						texture = talentinfo[3],
						type = "talent",
						search =  string.format("%s %s %s %s", talentinfo[2], talentinfo[3], talentinfo[1], talentinfo[6])
					})
				end
			end
		end
	end

	local slotInfo = C_SpecializationInfo.GetPvpTalentSlotInfo(1);
	if slotInfo ~= nil then
		for i, pvpTalentID in ipairs(slotInfo.availableTalentIDs) do
			local talentinfo = {GetPvpTalentInfoByID(pvpTalentID)}
			if talentinfo[3]  ~= nil then
				table.insert(tableObj, {
					name = talentinfo[2],
					texture = talentinfo[3],
					type = "talent",
					search =  string.format("%s %s %s %s", talentinfo[2], talentinfo[3], talentinfo[1], talentinfo[6])
				})
			end
		end
	end
	return tableObj
end




local function getEquipment()
	local tableObj = {}
	for i = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
		local slotItem =  GetInventoryItemID("player", i)
		if slotItem then
			local info = {C_Item.GetItemInfo(slotItem)}
			local itemTexture = GetInventoryItemTexture("player", i);
			if itemTexture ~= nil then
				table.insert(tableObj, {
					name = info[1],
					texture = itemTexture,
					type = "equip",
					search =  string.format("%s %s", info[1], itemTexture)
				})
			end
		end
	end
	return tableObj
end
local function getBags()
	local itemcache = {}
	local tableObj = {}
	for i = Enum.BagIndex.Backpack, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
		for j = 1, C_Container.GetContainerNumSlots(i) do
			local cinfo = C_Container.GetContainerItemInfo(i, j)
			if cinfo then
				if not itemcache[cinfo.itemID] then
					itemcache[cinfo.itemID] = true
					local name = C_Item.GetItemInfo(cinfo.itemID)
					if name then
						table.insert(tableObj, {
							name = name,
							texture = cinfo.iconFileID,
							type = "bags",
							search =  string.format("%s %s %s",name,  cinfo.iconFileID, cinfo.itemID)
						})
					end
				end
			end
		end
	end
	return tableObj
end


 
local i = 0
local function addData(name, obj)
	i = i + 1
	ns.IconSearchData.sections[i] = {
		name =  name,
		obj = obj
	}

	tAppendAll(ns.IconSearchData.all, obj)
end




addData("Spells", getSpells())
addData("Talents", getTalents())
addData("Equipment", getEquipment())
addData("Bags", getBags())




--addData("Items", {})

--local itemcache = {}

-- local addon = CreateFrame("Frame")
-- addon:RegisterEvent("ITEM_DATA_LOAD_RESULT")
-- addon:SetScript("OnEvent", function(self, event, itemID)
-- 	if itemcache[itemID] then return end
-- 	DevTool:AddData(itemID, "ITEM_DATA_LOAD_RESULT")

-- 	itemcache[itemID] = true

-- 	local info = {C_Item.GetItemInfo(itemID)}
-- 	if info then
-- 		table.insert(ns.IconSearchData.sections[1].obj, {
-- 			name = info[1],
-- 			texture = info[10],
-- 			type = "items",
-- 			search =  string.format("%s %s %s",info[1], info[10], itemID)
-- 		})

-- 		table.insert(ns.IconSearchData.all, {
-- 			name = info[1],
-- 			texture = info[10],
-- 			type = "items",
-- 			search =  string.format("%s %s %s",info[1], info[10], itemID)
-- 		})
-- 	end
-- end)













-- local spells = getSpells()
-- for i = 1, 50, 1 do
-- 	addData("Spells"..i, spells)
-- end













