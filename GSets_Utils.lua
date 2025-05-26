--[[
    GSets - Utility Functions
    Combines Blockers and Version checking functionality
]]

local _, Internal = ...
local L = Internal.L

--[[ VERSION CHECKING ]]

local current = select(4, GetBuildInfo())
local function IsBuild(build)
    return build == current
end
local function IsAtleastBuild(build)
    return build <= current
end
local function IsExpansion(expansion)
    return expansion == GetExpansionLevel()
end

local seasons = {
    [1] = {
        [9] = 1670943600,
        [10] = 1683644400,
        [11] = 1699974000,
        [12] = 1713884400,
        [13] = 1725980400,
        [14] = 1741100400,
    },
    [2] = {
        [9] = 1671058800,
        [10] = 1683759600,
        [11] = 1700089200,
        [12] = 1713999600,
        [13] = 1726095600,
        [14] = 1741215600,
    },
    [3] = {
        [9] = 1670990400,
        [10] = 1683691200,
        [11] = 1700020800,
        [12] = 1713931200,
        [13] = 1726027200,
        [14] = 1741147200,
    },
    [4] = {
        [9] = 1671058800,
        [10] = 1683759600,
        [11] = 1700089200,
        [12] = 1713999600,
        [13] = 1726095600,
        [14] = 1741215600,
    },
    [5] = {
        [9] = 1671058800,
        [10] = 1683759600,
        [11] = 1700089200,
        [12] = 1713999600,
        [13] = 1726095600,
        [14] = 1741215600,
    },
}

local function GetSeasonStartTime(region, season)
    return seasons[region] and seasons[region][season]
end

local function GetCurrentSeason(region)
    local time = GetServerTime()
    local regionSeasons = seasons[region]
    if not regionSeasons then
        return nil
    end
    
    local currentSeason = nil
    for season, startTime in pairs(regionSeasons) do
        if time >= startTime then
            if not currentSeason or season > currentSeason then
                currentSeason = season
            end
        end
    end
    
    return currentSeason
end

-- Version check functions
Internal.IsBuild = IsBuild
Internal.IsAtleastBuild = IsAtleastBuild
Internal.IsExpansion = IsExpansion
Internal.GetSeasonStartTime = GetSeasonStartTime
Internal.GetCurrentSeason = GetCurrentSeason

-- Expansion checks
Internal.IsClassic = function() return IsExpansion(0) end
Internal.IsBurningCrusade = function() return IsExpansion(1) end
Internal.IsWrathOfTheLichKing = function() return IsExpansion(2) end
Internal.IsCataclysm = function() return IsExpansion(3) end
Internal.IsMistsOfPandaria = function() return IsExpansion(4) end
Internal.IsWarlordsOfDraenor = function() return IsExpansion(5) end
Internal.IsLegion = function() return IsExpansion(6) end
Internal.IsBattleForAzeroth = function() return IsExpansion(7) end
Internal.IsShadowlands = function() return IsExpansion(8) end
Internal.IsDragonflight = function() return IsExpansion(9) end
Internal.IsTheWarWithin = function() return IsExpansion(10) end

Internal.IsDragonflightOrBeyond = function() return GetExpansionLevel() >= 9 end
Internal.IsTheWarWithinOrBeyond = function() return GetExpansionLevel() >= 10 end

--[[ BLOCKERS ]]

-- Base blocker mixin
Internal.BlockerMixin = {}

function Internal.BlockerMixin:ShouldWait()
    return false
end

function Internal.BlockerMixin:GetWaitReasonMessage()
    return nil
end

function Internal.BlockerMixin:IsActive()
    return false
end

function Internal.BlockerMixin:PopupMessage()
    return nil, nil
end

function Internal.BlockerMixin:PopupMessagePartial()
    return nil, nil
end

function Internal.BlockerMixin:UsableItem()
    return nil
end

function Internal.BlockerMixin:GetEvents()
    return
end

-- Combat Blocker
local CombatBlockerMixin = CreateFromMixins(Internal.BlockerMixin)

function CombatBlockerMixin:ShouldWait()
    return true
end

function CombatBlockerMixin:GetWaitReasonMessage()
    return L["Waiting for combat to end"]
end

function CombatBlockerMixin:IsActive()
    return InCombatLockdown()
end

local CombatBlocker = CreateFromMixins(CombatBlockerMixin)

-- Casting Blocker
local CastingBlockerMixin = CreateFromMixins(Internal.BlockerMixin)

function CastingBlockerMixin:ShouldWait()
    return true
end

function CastingBlockerMixin:GetWaitReasonMessage()
    return L["Waiting for casting to end"]
end

function CastingBlockerMixin:IsActive()
    return UnitCastingInfo("player") ~= nil or UnitChannelInfo("player") ~= nil
end

local CastingBlocker = CreateFromMixins(CastingBlockerMixin)

-- Resting Blocker
local RestingBlockerMixin = CreateFromMixins(Internal.BlockerMixin)

function RestingBlockerMixin:PopupMessage()
    return L["You must be resting to change talents"], L["You are not resting"]
end

function RestingBlockerMixin:PopupMessagePartial()
    return L["Some sets could not be activated because you are not resting"], L["You are not resting"]
end

function RestingBlockerMixin:IsActive()
    return not IsResting()
end

local RestingBlocker = CreateFromMixins(RestingBlockerMixin)

-- Tome Blocker
local TomeBlockerMixin = CreateFromMixins(Internal.BlockerMixin)

function TomeBlockerMixin:PopupMessage()
    return L["You need a Tome to change talents"], L["Missing Tome"]
end

function TomeBlockerMixin:PopupMessagePartial()
    return L["Some sets could not be activated because you need a Tome"], L["Missing Tome"]
end

function TomeBlockerMixin:IsActive()
    return not IsResting() and GetItemCount(141446) == 0 -- Tome of the Tranquil Mind
end

function TomeBlockerMixin:UsableItem()
    return 141446 -- Tome of the Tranquil Mind
end

local TomeBlocker = CreateFromMixins(TomeBlockerMixin)

-- Level Blocker
local LevelBlockerMixin = CreateFromMixins(Internal.BlockerMixin)

function LevelBlockerMixin:PopupMessage()
    return L["You are not high enough level"], L["Level too low"]
end

function LevelBlockerMixin:PopupMessagePartial()
    return L["Some sets could not be activated because your level is too low"], L["Level too low"]
end

function LevelBlockerMixin:IsActive()
    return UnitLevel("player") < 10
end

local LevelBlocker = CreateFromMixins(LevelBlockerMixin)

-- Export blockers
Internal.CombatBlocker = CombatBlocker
Internal.CastingBlocker = CastingBlocker
Internal.RestingBlocker = RestingBlocker
Internal.TomeBlocker = TomeBlocker
Internal.LevelBlocker = LevelBlocker

--[[ SHARE AND ENCODING UTILITIES ]]

local format = string.format
local wipe = table.wipe
local concat = table.concat

local function StringToTable(text)
    local stringType = text:sub(1,1)
    if stringType == "{" then
        local func, err = loadstring("return " .. text, "Import")
        if not func then
            return false, err
        end
        setfenv(func, {});
        return pcall(func)
    else
        return false, L["Invalid string"]
    end
end

local function TableToString(tbl)
    local str = {}
    for k,v in pairs(tbl) do
        if type(k) == "number" then
            k = "[" .. k .. "]"
        elseif type(k) ~= "string" then
            error(format(L["Invalid key type %s"], type(k)))
        end

        if type(v) == "table" then
            v = TableToString(v)
        elseif type(v) == "string" then
            v = format("%q", v)
        elseif type(v) ~= "number" and type(v) ~= "boolean" then
            error(format(L["Invalid value type %s for key %s"], type(v), tostring(k)))
        end

        str[#str+1] = k .. "=" .. tostring(v)
    end
    return "{" .. concat(str, ",") .. "}"
end

local Base64Encode, Base64Decode
do
    local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    function Base64Encode(data)
        return ((data:gsub('.', function(x)
            local r,b='',x:byte()
            for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
            return r;
        end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
            if (#x < 6) then return '' end
            local c=0
            for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
            return b:sub(c+1,c+1)
        end)..({ '', '==', '=' })[#data%3+1])
    end
    function Base64Decode(data)
        data = string.gsub(data, '[^'..b..'=]', '')
        return (data:gsub('.', function(x)
            if (x == '=') then return '' end
            local r,f='',(b:find(x)-1)
            for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
            return r;
        end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
            if (#x ~= 8) then return '' end
            local c=0
            for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
            return string.char(c)
        end))
    end
end

local function Encode(content, format)
    if #format == 1 then
        if format == "N" then
            return "N" .. content
        elseif format == "B" then
            return "B" .. Base64Encode(content)
        else
            error("Unsupported format")
        end
    elseif #format > 1 then
        local f, ormat = format:match("^([A-Z])([A-Z]*)$")
        return Encode(Encode(content, ormat), f)
    end
end

local function Decode(content, err)
    local format, content = content:match("^([A-Z])(.*)$")

    if format == "N" then
        return true, content
    elseif format == "B" then
        return Decode(Base64Decode(content))
    else
        return false, err or L["Unsupported format"]
    end
end

Internal.StringToTable = StringToTable
Internal.TableToString = TableToString
Internal.Base64Encode = Base64Encode
Internal.Base64Decode = Base64Decode
Internal.Encode = Encode
Internal.Decode = Decode

-- Blocker registry
local blockers = {
    CombatBlocker,
    CastingBlocker,
    RestingBlocker,
    TomeBlocker,
    LevelBlocker,
}

function Internal.GetActiveBlockers()
    local activeBlockers = {}
    for _, blocker in ipairs(blockers) do
        if blocker:IsActive() then
            table.insert(activeBlockers, blocker)
        end
    end
    return activeBlockers
end

function Internal.HasActiveBlockers()
    for _, blocker in ipairs(blockers) do
        if blocker:IsActive() then
            return true
        end
    end
    return false
end

function Internal.GetWaitingBlockers()
    local waitingBlockers = {}
    for _, blocker in ipairs(blockers) do
        if blocker:IsActive() and blocker:ShouldWait() then
            table.insert(waitingBlockers, blocker)
        end
    end
    return waitingBlockers
end