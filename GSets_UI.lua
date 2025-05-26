--[[
    GSets - User Interface Components
    Combines UI functionality -- Minimap functionality removed
]]

local ADDON_NAME, Internal = ...
local L = Internal.L
local Settings = Internal.Settings

-- Minimap Button Functionality Removed


--[[ HELP TIP SYSTEM ]]

local HelpTipBox_Anchor, HelpTipBox_SetText
do
    local helpTipPool = CreateFramePool("FRAME", UIParent, "GreenHelpTipTemplate")
    
    function HelpTipBox_Anchor(frame, target, anchor)
        if not frame.helpTip then
            frame.helpTip = helpTipPool:Acquire()
        end
        
        frame.helpTip:SetParent(frame)
        frame.helpTip:ClearAllPoints()
        
        if anchor == "TOP" then
            frame.helpTip:SetPoint("BOTTOM", target, "TOP", 0, 5)
        elseif anchor == "BOTTOM" then
            frame.helpTip:SetPoint("TOP", target, "BOTTOM", 0, -5)
        elseif anchor == "LEFT" then
            frame.helpTip:SetPoint("RIGHT", target, "LEFT", -5, 0)
        elseif anchor == "RIGHT" then
            frame.helpTip:SetPoint("LEFT", target, "RIGHT", 5, 0)
        else
            frame.helpTip:SetPoint("BOTTOM", target, "TOP", 0, 5)
        end
        
        frame.helpTip:Show()
    end
    
    function HelpTipBox_SetText(frame, text)
        if frame.helpTip then
            frame.helpTip.Text:SetText(text)
            frame.helpTip:SetSize(frame.helpTip.Text:GetStringWidth() + 20, frame.helpTip.Text:GetStringHeight() + 20)
        end
    end
end

Internal.HelpTipBox_Anchor = HelpTipBox_Anchor
Internal.HelpTipBox_SetText = HelpTipBox_SetText

--[[ DROPDOWN UTILITIES ]]

local function CreateDropDownInfo()
    return {
        text = "",
        value = nil,
        func = nil,
        checked = false,
        isTitle = false,
        disabled = false,
        tooltipTitle = nil,
        tooltipText = nil,
        hasArrow = false,
        menuList = nil,
        keepShownOnClick = false,
        notCheckable = false,
    }
end

local function AddDropDownButton(info, level)
    UIDropDownMenu_AddButton(info, level)
end

Internal.CreateDropDownInfo = CreateDropDownInfo
Internal.AddDropDownButton = AddDropDownButton

--[[ FRAME UTILITIES ]]

local function ToggleFrame()
    if BtWLoadoutsFrame and BtWLoadoutsFrame:IsShown() then
        BtWLoadoutsFrame:Hide()
    else
        if not BtWLoadoutsFrame then
            -- Create main frame if it doesn't exist
            BtWLoadoutsFrame = CreateFrame("Frame", "BtWLoadoutsFrame", UIParent, "BtWLoadoutsFrameTemplate")
        end
        BtWLoadoutsFrame:Show()
    end
end

Internal.ToggleFrame = ToggleFrame

--[[ STATIC POPUP DEFINITIONS ]]

StaticPopupDialogs["GSETS_DELETE_SET"] = {
    text = L["Are you sure you want to delete %s?"],
    button1 = DELETE,
    button2 = CANCEL,
    OnAccept = function(self, data)
        if data and data.callback then
            data.callback()
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["GSETS_ACTIVATE_SET"] = {
    text = L["Activate %s?"],
    button1 = L["Activate"],
    button2 = CANCEL,
    OnAccept = function(self, data)
        if data and data.callback then
            data.callback()
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

--[[ LAUNCHER FUNCTIONALITY ]]

local launcher
function Internal.CreateLauncher()
    local LDB = LibStub and LibStub("LibDataBroker-1.1", true)
    if LDB then
        local tempTooltip
        launcher = LDB:NewDataObject(ADDON_NAME, {
            type = "data source",
            label = L["BtWLoadouts"],
            icon = [[Interface\ICONS\Ability_marksmanship]],
            OnClick = function(clickedframe, button)
                if button == "LeftButton" then
                    BtWLoadoutsFrame:SetShown(not BtWLoadoutsFrame:IsShown());
                elseif button == "RightButton" then
                    if tempTooltip then
                        tempTooltip:Hide()
                    end

                    if not BtWLoadoutsMinimapButton.Menu then
                        BtWLoadoutsMinimapButton.Menu = CreateFrame("Frame", BtWLoadoutsMinimapButton:GetName().."Menu", BtWLoadoutsMinimapButton, "UIDropDownMenuTemplate");
                        UIDropDownMenu_Initialize(BtWLoadoutsMinimapButton.Menu, BtWLoadoutsMinimapMenu_Init, "MENU");
                    end

                    ToggleDropDownMenu(1, nil, BtWLoadoutsMinimapButton.Menu, clickedframe, 0, -5);
                end
            end,
            OnTooltipShow = function(tooltip)
                tempTooltip = tooltip

                tooltip:SetText(L["BtWLoadouts"], 1, 1, 1);
                tooltip:AddLine(L["Click to open BtWLoadouts.\nRight Click to enable and disable settings."], nil, nil, nil, true);
                if Internal.IsActivatingLoadout() then
                    tooltip:AddLine(" ");
                    tooltip:AddLine(L["Activating Loadout"], 1, 1, 1);
                    tooltip:AddLine(Internal.GetWaitReason())
                end
                tooltip:Show()
            end,
        })
    end
end

function Internal.UpdateLauncher(text)
    if launcher then
        launcher.text = text
    end
end

local _,Internal = ...
local L = Internal.L

--[[ Filter Enumerators ]]
--[[
	All filter enumerators take 3 params:
	@limitations {table} that are used to filter items, currently supported: role, herotalents, character, class
	@includeLimitations {boolean} if the filtered items should be returned but flagged as filtered
	@includeOther {boolean} If an extra item on the end (called other) should be returned
	@return {function} {table} {startIndex} ipairs style
]]

local races = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 22, 25, 26, 27, 28, 29, 30, 31, 32, 34, 35, 36, 37, 52, 70, 84, 85}
local classes = {}
local specializations = {}
local herotalents = {}
do -- Build Spec List
	local _, _, classID = UnitClass("player")

	classes[#classes+1] = classID

	for specIndex=1,GetNumSpecializationsForClassID(classID) do
		local specID = GetSpecializationInfoForClassID(classID, specIndex)
		specializations[#specializations+1] = specID
	end
	for _,treeID in ipairs(Internal.GetHeroTalentTreeIDsByClassID(classID)) do
		herotalents[#herotalents+1] = treeID
	end

	local playerClassID = classID;
	for classIndex=1,GetNumClasses() do
		if classIndex ~= playerClassID and GetNumSpecializationsForClassID(classID) > 0 then
			classes[#classes+1] = classIndex

			local _, _, classID = GetClassInfo(classIndex)
			for specIndex=1,GetNumSpecializationsForClassID(classID) do
				local specID = GetSpecializationInfoForClassID(classID, specIndex);
				specializations[#specializations+1] = specID
			end
			
			for _,treeID in ipairs(Internal.GetHeroTalentTreeIDsByClassID(classID)) do
				herotalents[#herotalents+1] = treeID
			end
		end
	end
	
	function Internal.SortClassesByName()
		table.sort(classes, function (a, b)
			if a == playerClassID and b ~= playerClassID then
				return true
			elseif b == playerClassID and a ~= playerClassID then
				return false
			end
			return C_CreatureInfo.GetClassInfo(a).className < C_CreatureInfo.GetClassInfo(b).className
		end)

		wipe(specializations)
		for _,classID in ipairs(classes) do
			for specIndex=1,GetNumSpecializationsForClassID(classID) do
				local specID = GetSpecializationInfoForClassID(classID, specIndex);
				specializations[#specializations+1] = specID
			end
		end
	end
	function Internal.SortClassesByID()
		table.sort(classes, function (a, b)
			if a == playerClassID and b ~= playerClassID then
				return true
			elseif b == playerClassID and a ~= playerClassID then
				return false
			end
			return a < b
		end)

		wipe(specializations)
		for _,classID in ipairs(classes) do
			for specIndex=1,GetNumSpecializationsForClassID(classID) do
				local specID = GetSpecializationInfoForClassID(classID, specIndex);
				specializations[#specializations+1] = specID
			end
		end
	end
end
local instanceTypeEnumeratorList = {
	{ "party", L["Dungeon"], },
	{ "raid", L["Raid"], }, { "arena", L["Arena"], },
	{ "pvp", L["Battleground"], },
	{ "none", L["World"], }
}
local disabledEnumeratorList = {
	{ 0, L["Enabled"], },
	{ 1, L["Disabled"], },
}
local roleEnumertorList = {}
do -- Build role list
	for _,role in Internal.Roles() do
		roleEnumertorList[#roleEnumertorList+1] = { role, _G[role] }
	end
end
local instances = {}
do
    for _,expansion in ipairs(Internal.raidInfo) do
        for _,instanceID in ipairs(expansion.instances) do
            instances[#instances+1] = instanceID
        end
    end
    for _,expansion in ipairs(Internal.dungeonInfo) do
        for _,instanceID in ipairs(expansion.instances) do
            instances[#instances+1] = instanceID
        end
    end
end
local charaterEnumertorList = {} -- Reused for building character lists
Internal.Filters = {
	class = {
		name = L["Class"],
		enumerate = function (limitations, includeLimitations, includeOther)
			return function (tbl, index)
				index = index + 1
				if tbl[index] then
					local classInfo = C_CreatureInfo.GetClassInfo(tbl[index])
					local classColor = C_ClassColor.GetClassColor(classInfo.classFile)
					return index, classInfo.classFile, classColor:WrapTextInColorCode(classInfo.className)
				elseif includeOther and index == #tbl + 1 then
					return index, 0, L["Other"]
				end
			end, classes, 0
		end,
	},
	spec = {
		name = L["Specialization"],
        -- limitations: role, herotalents, character, class
		enumerate = function (limitations, includeLimitations, includeOther)
			local limitRole, limitHeroTalents, limitClassFile
			if limitations then
				limitRole = limitations.role
				if limitations.herotalents then
					limitHeroTalents = limitations.herotalents
					local classData = C_CreatureInfo.GetClassInfo(Internal.GetClassIDByHeroTalentTreeID(limitations.herotalents))
					limitClassFile = classData.classFile
				elseif limitations.character then
					local characterData = Internal.GetCharacterInfo(limitations.character)
					limitClassFile = characterData.class
				elseif limitations.class then
					local classData = C_CreatureInfo.GetClassInfo(limitations.class)
					limitClassFile = classData.classFile
				end
			end

			return function (tbl, index)
				repeat
					index = index + 1
				until not tbl[index] or includeLimitations or (
					(limitClassFile == nil or limitClassFile == (select(6, GetSpecializationInfoByID(tbl[index])))) and
					(limitHeroTalents == nil or Internal.IsHeroTalentTreeValidForSpecID(limitHeroTalents, tbl[index])) and
					(limitRole == nil or limitRole == (select(5, GetSpecializationInfoByID(tbl[index]))))
				)

				if tbl[index] then
					local _, specName, _, _, role, classFile, className = GetSpecializationInfoByID(tbl[index])
					local classColor = C_ClassColor.GetClassColor(classFile);
					local name = format("%s - %s", classColor:WrapTextInColorCode(className), specName)

					return index, tbl[index], name, not (
						(limitClassFile == nil or limitClassFile == classFile) and
						(limitHeroTalents == nil or Internal.IsHeroTalentTreeValidForSpecID(limitHeroTalents, tbl[index])) and
						(limitRole == nil or limitRole == role)
					)
				elseif includeOther and index == #tbl + 1 then
					return index, 0, L["Other"]
				end
			end, specializations, 0
		end,
	},
	covenant = {
		name = L["Covenant"],
		enumerate = function (limitations, includeLimitations, includeOther)
			return function (tbl, index)
				index = index + 1
				if tbl[index] then
					local covenantData = C_Covenants.GetCovenantData(tbl[index])
					return index, tbl[index], COVENANT_COLORS[covenantData.textureKit]:WrapTextInColorCode(covenantData.name)
				elseif includeOther and index == #tbl + 1 then
					return index, 0, L["Other"]
				end
			end, {1, 2, 3, 4}, 0
		end,
	},
	race = {
		name = L["Race"],
		enumerate = function (limitations, includeLimitations, includeOther)
			return function (tbl, index)
				index = index + 1
				if tbl[index] then
					return index, tbl[index], GetFactionColor(C_CreatureInfo.GetFactionInfo(tbl[index]).groupTag):WrapTextInColorCode(C_CreatureInfo.GetRaceInfo(tbl[index]).raceName)
				elseif includeOther and index == #tbl + 1 then
					return index, 0, L["Other"]
				end
			end, races, 0
		end,
	},
	class = {
		name = L["Class"],
		enumerate = function (limitations, includeLimitations, includeOther)
			return function (tbl, index)
				index = index + 1
				if tbl[index] then
					local classInfo = C_CreatureInfo.GetClassInfo(tbl[index])
					local classColor = C_ClassColor.GetClassColor(classInfo.classFile)
					return index, classInfo.classFile, classColor:WrapTextInColorCode(classInfo.className)
				elseif includeOther and index == #tbl + 1 then
					return index, 0, L["Other"]
				end
			end, classes, 0
		end,
	},
	spec = {
		name = L["Specialization"],
        -- limitations: role, herotalents, character, class
		enumerate = function (limitations, includeLimitations, includeOther)
			local limitRole, limitHeroTalents, limitClassFile
			if limitations then
				limitRole = limitations.role
				if limitations.herotalents then
					limitHeroTalents = limitations.herotalents
					local classData = C_CreatureInfo.GetClassInfo(Internal.GetClassIDByHeroTalentTreeID(limitations.herotalents))
					limitClassFile = classData.classFile
				elseif limitations.character then
					local characterData = Internal.GetCharacterInfo(limitations.character)
					limitClassFile = characterData.class
				elseif limitations.class then
					local classData = C_CreatureInfo.GetClassInfo(limitations.class)
					limitClassFile = classData.classFile
				end
			end

			return function (tbl, index)
				repeat
					index = index + 1
				until not tbl[index] or includeLimitations or (
					(limitClassFile == nil or limitClassFile == (select(6, GetSpecializationInfoByID(tbl[index])))) and
					(limitHeroTalents == nil or Internal.IsHeroTalentTreeValidForSpecID(limitHeroTalents, tbl[index])) and
					(limitRole == nil or limitRole == (select(5, GetSpecializationInfoByID(tbl[index]))))
				)

				if tbl[index] then
					local _, specName, _, _, role, classFile, className = GetSpecializationInfoByID(tbl[index])
					local classColor = C_ClassColor.GetClassColor(classFile);
					local name = format("%s - %s", classColor:WrapTextInColorCode(className), specName)

					return index, tbl[index], name, not (
						(limitClassFile == nil or limitClassFile == classFile) and
						(limitHeroTalents == nil or Internal.IsHeroTalentTreeValidForSpecID(limitHeroTalents, tbl[index])) and
						(limitRole == nil or limitRole == role)
					)
				elseif includeOther and index == #tbl + 1 then
					return index, 0, L["Other"]
				end
			end, specializations, 0
		end,
	},
	herotalents = {
		name = L["Hero Talents"],
		enumerate = function (limitations, includeLimitations, includeOther)
			return function (tbl, index)
				index = index + 1

				if tbl[index] then
					local tree = C_Traits.GetSubTreeInfo(Constants.TraitConsts.VIEW_TRAIT_CONFIG_ID, tbl[index])
					local class = C_CreatureInfo.GetClassInfo(Internal.GetClassIDByHeroTalentTreeID(tbl[index]))
					local classColor = C_ClassColor.GetClassColor(class.classFile);
					local name = format("%s - %s", classColor:WrapTextInColorCode(class.className), tree.name)

					return index, tbl[index], name
				elseif includeOther and index == #tbl + 1 then
					return index, 0, L["Other"]
				end
			end, herotalents, 0
		end,
	},
	role = {
		name = L["Role"],
		enumerate = function (limitations, includeLimitations, includeOther)
			return function (tbl, index)
				index = index + 1
				if tbl[index] then
					return index, unpack(tbl[index])
				elseif includeOther and index == #tbl + 1 then
					return index, 0, L["Other"]
				end
			end, roleEnumertorList, 0
		end,
	},
	character = {
		name = L["Character"],
		enumerate = function (limitations, includeLimitations, includeOther)
			wipe(charaterEnumertorList)

			local name = UnitName("player")
			local character = Internal.GetCharacterSlug();
			local characterInfo = Internal.GetCharacterInfo(character);
			if characterInfo then
				local classColor = C_ClassColor.GetClassColor(characterInfo.class);
				name = format("%s - %s", classColor:WrapTextInColorCode(characterInfo.name), characterInfo.realm);
			end
			charaterEnumertorList[#charaterEnumertorList+1] = {character, name}

			local playerCharacter = character
			for _,character in Internal.CharacterIterator() do
				if playerCharacter ~= character then
					local characterInfo = Internal.GetCharacterInfo(character);
					if characterInfo then
						local classColor = C_ClassColor.GetClassColor(characterInfo.class);
						name = format("%s - %s", classColor:WrapTextInColorCode(characterInfo.name), characterInfo.realm);
					end
					charaterEnumertorList[#charaterEnumertorList+1] = {character,name}
				end
			end

			return function (tbl, index)
				index = index + 1
				if tbl[index] then
					return index, unpack(tbl[index])
				elseif includeOther and index == #tbl + 1 then
					return index, 0, L["Other"]
				end
			end, charaterEnumertorList, 0
		end,
	},
	instanceType = {
		name = L["Instance Type"],
		enumerate = function (limitations, includeLimitations, includeOther)
			return function (tbl, index)
				index = index + 1
				if tbl[index] then
					return index, unpack(tbl[index])
				elseif includeOther and index == #tbl + 1 then
					return index, 0, L["Other"]
				end
			end, instanceTypeEnumeratorList, 0
		end,
	},
	instance = {
		name = L["Instance"],
		enumerate = function (limitations, includeLimitations, includeOther)
			return function (tbl, index)
				index = index + 1
				if tbl[index] then
					return index, tbl[index], GetRealZoneText(tbl[index])
				elseif includeOther and index == #tbl + 1 then
					return index, 0, L["Other"]
				end
			end, instances, 0
		end,
	},
	disabled = {
		name = L["Enabled"],
		enumerate = function (limitations, includeLimitations, includeOther)
			return function (tbl, index)
				index = index + 1
				if tbl[index] then
					return index, unpack(tbl[index])
				elseif includeOther and index == #tbl + 1 then
					return index, 0, L["Other"]
				end
			end, specializations, 0
		end,
	},
}
