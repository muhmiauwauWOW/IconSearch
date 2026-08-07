-- IconSearchData: Vollständig refactored, konsistent mit Lodash, robust und erweiterbar
local addonName, ns = ...
local _ = LibStub("LibLodash-1"):Get()

ns.IconSearchData = {}
ns.IconSearchData.sections = {}

-- Hilfsfunktion für sichere API-Aufrufe
local function safeCall(fn, ...)
    local ok, result = pcall(fn, ...)
    if ok then return result end
    return nil
end

-- Hilfsfunktion für nil-sichere string.format
local function safeFormat(fmt, ...)
    local args = {...}
    local needed = select(2, fmt:gsub("%%s", ""))
    while #args < needed do
        table.insert(args, "")
    end
    _.forEach(args, function(v, i)
        if v == nil then args[i] = "" end
    end)
    return string.format(fmt, unpack(args))
end

-- SPELLS
local function addSpell(tableObj, seen, name, texture, id, typ)
    local key = (name or "")..(texture or "")
    if texture and name and not seen[key] then
        _.push(tableObj, {
            name = name or "",
            texture = texture or "",
            type = typ or "spell",
            search = safeFormat("%s %s %s", name, texture, id)
        })
        seen[key] = true
    end
end

local function addFlyoutSpells(tableObj, seen, ID)
    local _, _, numSlots, isKnown = safeCall(GetFlyoutInfo, ID)
    if isKnown and (numSlots and numSlots > 0) then
        _.forEach(_.range(1, numSlots), function(k)
            local spellID, _, isSlotKnown, flyoutSpellName = safeCall(GetFlyoutSlotInfo, ID, k)
            if isSlotKnown then
                local fileID = safeCall(C_Spell.GetSpellTexture, spellID)
                addSpell(tableObj, seen, flyoutSpellName, fileID, spellID, "spell")
            end
        end)
    end
end

local function getSpells()
    local tableObj, seen = {}, {}
    _.forEach(_.range(1, C_SpellBook.GetNumSpellBookSkillLines()), function(skillLineIndex)
        local skillLineInfo = safeCall(C_SpellBook.GetSpellBookSkillLineInfo, skillLineIndex)
        if skillLineInfo and skillLineInfo.numSpellBookItems then
            _.forEach(_.range(1, skillLineInfo.numSpellBookItems), function(i)
                local spellIndex = skillLineInfo.itemIndexOffset + i
                local spellName = safeCall(C_SpellBook.GetSpellBookItemName, spellIndex, Enum.SpellBookSpellBank.Player)
                local spellType, ID = safeCall(C_SpellBook.GetSpellBookItemType, spellIndex, Enum.SpellBookSpellBank.Player)
                if spellType ~= "FUTURESPELL" then
                    local fileID = safeCall(C_SpellBook.GetSpellBookItemTexture, spellIndex, Enum.SpellBookSpellBank.Player)
                    addSpell(tableObj, seen, spellName, fileID, ID, "spell")
                end
                if spellType == "FLYOUT" then
                    addFlyoutSpells(tableObj, seen, ID)
                end
            end)
        end
    end)
    return tableObj
end

-- TALENTS
local function addTalent(tableObj, seen, t)
    local key = (t[2] or "")..(t[3] or "")
    if t[3] and not seen[key] then
        _.push(tableObj, {
            name = t[2] or "",
            texture = t[3] or "",
            type = "talent",
            search = safeFormat("%s %s %s %s", t[2], t[3], t[1], t[6])
        })
        seen[key] = true
    end
end

local function addPvPTalents(tableObj, seen, availableTalentIDs)
    _.forEach(availableTalentIDs, function(pvpTalentID)
        local t = {GetPvpTalentInfoByID(pvpTalentID)}
        addTalent(tableObj, seen, t)
    end)
end

local function getTalents()
    local tableObj, seen = {}, {}
    local isInspect = false
    _.forEach(_.range(1, GetNumSpecGroups(isInspect)), function(specIndex)
        _.forEach(_.range(1, MAX_TALENT_TIERS), function(tier)
            _.forEach(_.range(1, NUM_TALENT_COLUMNS), function(column)
                local t = {GetTalentInfo(tier, column, specIndex)}
                addTalent(tableObj, seen, t)
            end)
        end)
    end)
    local slotInfo = safeCall(C_SpecializationInfo.GetPvpTalentSlotInfo, 1)
    if slotInfo and slotInfo.availableTalentIDs then
        addPvPTalents(tableObj, seen, slotInfo.availableTalentIDs)
    end
    return tableObj
end

-- EQUIPMENT
local function addEquip(tableObj, seen, info, itemTexture, slotItem)
    if itemTexture and info[1] and not seen[slotItem] then
        _.push(tableObj, {
            name = info[1] or "",
            texture = itemTexture or "",
            type = "equip",
            search = safeFormat("%s %s", info[1], itemTexture)
        })
        seen[slotItem] = true
    end
end

local function getEquipment()
    local tableObj, seen = {}, {}
    _.forEach(_.range(INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED), function(i)
        local slotItem = GetInventoryItemID("player", i)
        if slotItem and not seen[slotItem] then
            local info = {C_Item.GetItemInfo(slotItem)}
            local itemTexture = GetInventoryItemTexture("player", i)
            addEquip(tableObj, seen, info, itemTexture, slotItem)
        end
    end)
    return tableObj
end

-- BAGS
local function addBagItem(tableObj, itemcache, cinfo, name)
    if name and cinfo and not itemcache[cinfo.itemID] then
        itemcache[cinfo.itemID] = true
        _.push(tableObj, {
            name = name or "",
            texture = cinfo.iconFileID or "",
            type = "bags",
            search = safeFormat("%s %s %s", name, cinfo.iconFileID, cinfo.itemID)
        })
    end
end

local function getBags()
    local itemcache, tableObj = {}, {}
    _.forEach(_.range(Enum.BagIndex.Backpack, NUM_TOTAL_EQUIPPED_BAG_SLOTS), function(i)
        _.forEach(_.range(1, C_Container.GetContainerNumSlots(i)), function(j)
            local cinfo = C_Container.GetContainerItemInfo(i, j)
            local name = cinfo and C_Item.GetItemInfo(cinfo.itemID)
            addBagItem(tableObj, itemcache, cinfo, name)
        end)
    end)
    return tableObj
end

-- NUMBERS
local function getNumbers()
    local textureIDs = {6033345, 6033346, 6033347, 6033348, 6033349, 6033350, 6033351, 6033352, 6033353, 6033354}
    local tableObj = {}
    _.forEach(textureIDs, function(textureID, idx)
        local numName = tostring(idx)
        _.push(tableObj, {
            name = numName,
            texture = tostring(textureID),
            type = "number",
            search = safeFormat("%s %s", numName, tostring(textureID))
        })
    end)
    return tableObj
end

-- Daten hinzufügen
local i = 0
local function addData(name, obj)
    i = i + 1
    ns.IconSearchData.sections[i] = {
        idx = i,
        name = name,
        obj = obj
    }
end

-- Hauptfunktion zum Bauen der Icons
function ns.buildIcons()
    i = 0 -- Reset für wiederholte Aufrufe
    addData("Spells", getSpells())
    addData("Talents", getTalents())
    addData("Equipment", getEquipment())
    addData("Bags", getBags())
    addData("Numbers", getNumbers())
    ns.IconSearchData.sections = _.sortBy(ns.IconSearchData.sections, function(a) return a.idx end)
end