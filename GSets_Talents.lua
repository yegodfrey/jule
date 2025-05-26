--[[
    GSets - Unified Talents System
    Combines Classic Talents, DF Talents, Hero Talents, and PvP Talents into one system
]]

local ADDON_NAME, Internal = ...
local L = Internal.L

-- Common imports
local UnitClass = UnitClass
local GetClassColor = C_ClassColor.GetClassColor
local GetSpecialization = GetSpecialization
local GetSpecializationInfo = GetSpecializationInfo
local GetSpecializationInfoByID = GetSpecializationInfoByID
local UIDropDownMenu_SetText = UIDropDownMenu_SetText
local UIDropDownMenu_EnableDropDown = UIDropDownMenu_EnableDropDown
local UIDropDownMenu_DisableDropDown = UIDropDownMenu_DisableDropDown
local UIDropDownMenu_SetSelectedValue = UIDropDownMenu_SetSelectedValue
local AddSet = Internal.AddSet
local DeleteSet = Internal.DeleteSet
local format = string.format

-- Talent type constants
local TALENT_TYPE_DF = 2
local TALENT_TYPE_HERO = 3
local TALENT_TYPE_PVP = 4

-- Active talent systems
GSETS_DF_TALENTS_ACTIVE = Internal.IsDragonflightOrBeyond
GSETS_HERO_TALENTS_ACTIVE = Internal.IsTheWarWithinOrBeyond

-- Unified talent set structure
local function CreateTalentSet(talentType, specID)
    local set = {
        type = "talents",
        talentType = talentType,
        specID = specID,
        name = "",
        useCount = 0,

        -- DF talents
        nodes = {},
        treeID = nil,
        -- Hero talents
        heroTreeID = nil,
        heroNodes = {},
        -- PvP talents
        pvpTalents = {},
        -- Common
        restrictions = {}
    }
    return set
end

-- Unified comparison function
local function CompareTalentSets(a, b)
    if a.specID ~= b.specID then
        return false
    end
    
    if a.talentType ~= b.talentType then
        return false
    end
    
    -- Compare based on talent type
    if false then -- TALENT_TYPE_CLASSIC removed
        return tCompare(a.talents, b.talents, 10)
    elseif a.talentType == TALENT_TYPE_DF then
        if a.treeID ~= b.treeID then
            return false
        end
        return tCompare(a.nodes, b.nodes, 10)
    elseif a.talentType == TALENT_TYPE_HERO then
        if a.heroTreeID ~= b.heroTreeID then
            return false
        end
        return tCompare(a.heroNodes, b.heroNodes, 10)
    elseif a.talentType == TALENT_TYPE_PVP then
        return tCompare(a.pvpTalents, b.pvpTalents, 10)
    end
    
    return true
end

-- Unified activation function
local function ActivateTalentSet(set)
    if not set then return end
    
    if false then -- TALENT_TYPE_CLASSIC removed
        -- Activate classic talents
        for tier = 1, MAX_TALENT_TIERS do
            local talentID = set.talents[tier]
            if talentID then
                LearnTalent(talentID)
            end
        end
    elseif set.talentType == TALENT_TYPE_DF and GSETS_DF_TALENTS_ACTIVE then
        -- Activate DF talents
        if C_ClassTalents and set.nodes then
            local configID = C_ClassTalents.GetActiveConfigID()
            if configID then
                for nodeID, nodeInfo in pairs(set.nodes) do
                    if nodeInfo.entryID then
                        C_Traits.SetSelection(configID, nodeID, nodeInfo.entryID)
                    end
                end
                C_ClassTalents.CommitConfig(configID)
            end
        end
    elseif set.talentType == TALENT_TYPE_HERO and GSETS_HERO_TALENTS_ACTIVE then
        -- Activate hero talents
        if C_Traits and set.heroNodes then
            local configID = C_ClassTalents.GetActiveConfigID()
            if configID then
                for nodeID, nodeInfo in pairs(set.heroNodes) do
                    if nodeInfo.entryID then
                        C_Traits.SetSelection(configID, nodeID, nodeInfo.entryID)
                    end
                end
                C_ClassTalents.CommitConfig(configID)
            end
        end
    elseif set.talentType == TALENT_TYPE_PVP then
        -- Activate PvP talents
        for slot, talentID in pairs(set.pvpTalents) do
            if talentID then
                LearnPvpTalent(talentID, slot)
            end
        end
    end
end

-- Unified talent mixin
BtWLoadoutsUnifiedTalentsMixin = {}

function BtWLoadoutsUnifiedTalentsMixin:OnLoad()
    self.sets = {}
    self.selectedSet = nil
    self.talentType = TALENT_TYPE_DF -- Default to DF
end

function BtWLoadoutsUnifiedTalentsMixin:OnShow()
    self:Update()
end

function BtWLoadoutsUnifiedTalentsMixin:SetTalentType(talentType)
    self.talentType = talentType
    self:Update()
end

function BtWLoadoutsUnifiedTalentsMixin:Update()
    -- Update UI based on current talent type
    self:UpdateSets()
    self:UpdateButtons()
end

function BtWLoadoutsUnifiedTalentsMixin:UpdateSets()
    -- Load sets for current talent type
    local sets = Internal.GetSets("talents")
    self.sets = {}
    
    for _, set in pairs(sets) do
        if set.talentType == self.talentType then
            table.insert(self.sets, set)
        end
    end
    
    table.sort(self.sets, function(a, b)
        return a.name < b.name
    end)
end

function BtWLoadoutsUnifiedTalentsMixin:CreateSet()
    local specID = GetSpecialization()
    if not specID then return end
    
    local set = CreateTalentSet(self.talentType, specID)
    set.name = L["New Set"]
    
    -- Capture current talents based on type
    if false then -- TALENT_TYPE_CLASSIC removed
        self:CaptureClassicTalents(set)
    elseif self.talentType == TALENT_TYPE_DF then
        self:CaptureDFTalents(set)
    elseif self.talentType == TALENT_TYPE_HERO then
        self:CaptureHeroTalents(set)
    elseif self.talentType == TALENT_TYPE_PVP then
        self:CapturePvPTalents(set)
    end
    
    AddSet("talents", set)
    self:Update()
end

function BtWLoadoutsUnifiedTalentsMixin:CaptureClassicTalents(set)
    -- Classic talents removed
end

function BtWLoadoutsUnifiedTalentsMixin:CaptureDFTalents(set)
    if not GSETS_DF_TALENTS_ACTIVE or not C_ClassTalents then return end
    
    local configID = C_ClassTalents.GetActiveConfigID()
    if not configID then return end
    
    local treeID = C_ClassTalents.GetTraitTreeForSpec(GetSpecialization())
    set.treeID = treeID
    
    local nodes = C_Traits.GetTreeNodes(configID)
    for _, nodeID in ipairs(nodes) do
        local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID)
        if nodeInfo and nodeInfo.currentSelection then
            set.nodes[nodeID] = {
                entryID = nodeInfo.currentSelection,
                rank = nodeInfo.currentRank or 1
            }
        end
    end
end

function BtWLoadoutsUnifiedTalentsMixin:CaptureHeroTalents(set)
    if not GSETS_HERO_TALENTS_ACTIVE or not C_Traits then return end
    
    -- Similar to DF talents but for hero talent trees
    local configID = C_ClassTalents.GetActiveConfigID()
    if not configID then return end
    
    -- Get hero talent tree info and capture selections
    -- Implementation would be similar to DF talents
end

function BtWLoadoutsUnifiedTalentsMixin:CapturePvPTalents(set)
    local pvpTalents = C_SpecializationInfo.GetAllSelectedPvpTalentIDs()
    if pvpTalents then
        for slot, talentID in pairs(pvpTalents) do
            set.pvpTalents[slot] = talentID
        end
    end
end

function BtWLoadoutsUnifiedTalentsMixin:ActivateSet(set)
    if not set then return end
    
    ActivateTalentSet(set)
    self.selectedSet = set
end

-- Register the unified talent system
Internal.AddLoadoutSegment({
    key = "talents",
    name = L["Talents"],
    after = "actionbars",
    
    GetSets = function()
        return Internal.GetSets("talents")
    end,
    
    GetCurrentSet = function()
        -- Return current talent configuration as a set
        local specID = GetSpecialization()
        if not specID then return nil end
        
        -- This would need to detect which talent system is active
        -- and return the appropriate current configuration
        return nil
    end,
    
    SetIsValidForPlayer = function(set)
        return set.specID == GetSpecialization()
    end,
    
    ActivateSet = ActivateTalentSet,
    
    CompareSet = CompareTalentSets
})

-- Export functions for external use
Internal.CreateTalentSet = CreateTalentSet
Internal.CompareTalentSets = CompareTalentSets
Internal.ActivateTalentSet = ActivateTalentSet
Internal.TALENT_TYPE_DF = TALENT_TYPE_DF
Internal.TALENT_TYPE_HERO = TALENT_TYPE_HERO
Internal.TALENT_TYPE_PVP = TALENT_TYPE_PVP