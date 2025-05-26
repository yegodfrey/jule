-- Define Localization table

local _, Internal = ...

local L = {}
setmetatable(L, {
    __index = function (self, key)
        return key
    end,
})
Internal.L = L

local ACTION_BAR = HUD_EDIT_MODE_ACTION_BAR_LABEL or "Action Bar %d"
local STANCE_BAR = HUD_EDIT_MODE_STANCE_BAR_LABEL or "Stance Bar %d"

-- Fallbacks for items missing translations
L["Talents"] = TALENTS
L["PvP Talents"] = PVP_TALENTS
-- Equipment functionality removed
L["Set: %s"] = ITEM_SET_BONUS
-- Equipment functionality removed
L["Activate"] = TALENT_SPEC_ACTIVATE
L["Update"] = UPDATE
L["Delete"] = DELETE
L["Name"] = NAME
L["Specialization"] = SPECIALIZATION
L["None"] = NONE
L["New"] = NEW
L["World"] = WORLD
L["Dungeons"] = DUNGEONS
L["Raids"] = RAIDS
L["Arena"] = ARENA
L["Battlegrounds"] = BATTLEGROUNDS
L["Other"] = OTHER
L["Enabled"] = VIDEO_OPTIONS_ENABLED
L["Soulbinds"] = COVENANT_PREVIEW_SOULBINDS

L["Action Bar 2"] = format(ACTION_BAR, 2)
L["Action Bar 3"] = format(ACTION_BAR, 3)
L["Action Bar 4"] = format(ACTION_BAR, 4)
L["Action Bar 5"] = format(ACTION_BAR, 5)
L["Action Bar 6"] = format(ACTION_BAR, 6)
L["Action Bar 7"] = format(ACTION_BAR, 7)
L["Action Bar 8"] = format(ACTION_BAR, 8)
L["Stance Bar 1"] = format("%s %d", STANCE_BAR, 1)
L["Stance Bar 2"] = format("%s %d", STANCE_BAR, 2)
L["Stance Bar 3"] = format("%s %d", STANCE_BAR, 3)
L["Stance Bar 4"] = format("%s %d", STANCE_BAR, 4)
-- Simplified Chinese translations. Thanks to afish1984 on Curse

if GetLocale() ~= "zhCN" then return; end

local _, Internal = ...
local L = Internal.L

L["Action Bars"] = "动作条"
L["Activate"] = "激活"
L["Activate loadout %s?"] = "激活配置%s？"
L[ [=[Activate spec %s?
This set will require a tome or rested to activate]=] ] = "激活%s专精？\\n需要使用一个书卷或在休息区执行。"
L[ [=[Activate spec %s?
This will use a Tome]=] ] = "使用一个书卷激活%s专精？"
L["Add"] = "新增"
L["Any"] = "任何"
L["Arena"] = "竞技场"

L["Battlegrounds"] = "战场"
L["BtWLoadouts"] = "BtWLoadouts"
L["Class"] = "职业"

L[ [=[Click to open BtWLoadouts.
Right Click to enable and disable settings.]=] ] = "左键点击：显示BtWLoadouts界面。右键点击：启用或禁用设置。"
L["Delete"] = "删除"
L["Dungeons"] = "地下城"
L["Enabled"] = "启用"
-- Equipment functionality removed
-- Equipment functionality removed
L["Log"] = "日志"

L["New Loadout"] = "新配置"

L["Loadout"] = "配置"
L["Loadouts"] = "配置"
L["Settings"] = "设置"



L["Unnamed"] = "未命名"
L["Update"] = "更新"
L["Warfront"] = "战争前线"


L["World"] = "世界"
