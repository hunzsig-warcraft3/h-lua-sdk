---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by hunzs.
--- DateTime: 2020/5/8 22:18
--- Updated: 2021/1/22 00:19
---

-- hslk 初始化
hslk_init()

-- 全局秒钟
cj.TimerStart(cj.CreateTimer(), 1.00, true, htime.clock)

-- 预读 preReadUnit
local preReadUnit = cj.CreateUnit(hplayer.player_passive, HL_ID.unit_token, 0, 0, 0)
hattributeSetter.relyRegister(preReadUnit)
hunit.del(preReadUnit)

-- 同步
hsync.init()

---default handle and protect
local def = { "global" }
for i = 0, bj_MAX_PLAYERS - 1, 1 do
    table.insert(def, cj.Player(i))
end
for _, d in ipairs(def) do
    hcache.alloc(d)
    hcache.protect(d)
end
def = nil

-- register APM
hevent.pool("global", hevent_default_actions.player.apm, function(tgr)
    for i = 1, bj_MAX_PLAYERS, 1 do
        cj.TriggerRegisterPlayerUnitEvent(tgr, cj.Player(i - 1), EVENT_PLAYER_UNIT_ISSUED_TARGET_ORDER, nil)
        cj.TriggerRegisterPlayerUnitEvent(tgr, cj.Player(i - 1), EVENT_PLAYER_UNIT_ISSUED_POINT_ORDER, nil)
        cj.TriggerRegisterPlayerUnitEvent(tgr, cj.Player(i - 1), EVENT_PLAYER_UNIT_ISSUED_ORDER, nil)
    end
end)

for i = 1, bj_MAX_PLAYERS, 1 do
    -- init
    hplayer.players[i] = cj.Player(i - 1)
    -- 英雄模块初始化
    hhero.player_allow_qty[i] = 1
    hhero.player_heroes[i] = {}

    cj.SetPlayerHandicapXP(hplayer.players[i], 0) -- 经验置0

    hcache.set(hplayer.players[i], CONST_CACHE.PLAYER_GOLD_PREV, 0)
    hcache.set(hplayer.players[i], CONST_CACHE.PLAYER_GOLD_TOTAL, 0)
    hcache.set(hplayer.players[i], CONST_CACHE.PLAYER_GOLD_COST, 0)
    hcache.set(hplayer.players[i], CONST_CACHE.PLAYER_GOLD_RATIO, 100)
    hcache.set(hplayer.players[i], CONST_CACHE.PLAYER_LUMBER_PREV, 0)
    hcache.set(hplayer.players[i], CONST_CACHE.PLAYER_LUMBER_TOTAL, 0)
    hcache.set(hplayer.players[i], CONST_CACHE.PLAYER_LUMBER_COST, 0)
    hcache.set(hplayer.players[i], CONST_CACHE.PLAYER_LUMBER_RATIO, 100)
    hcache.set(hplayer.players[i], CONST_CACHE.PLAYER_EXP_RATIO, 100)
    hcache.set(hplayer.players[i], CONST_CACHE.PLAYER_SELL_RATIO, 50)
    hcache.set(hplayer.players[i], CONST_CACHE.PLAYER_APM, 0)
    hcache.set(hplayer.players[i], CONST_CACHE.PLAYER_DAMAGE, 0)
    hcache.set(hplayer.players[i], CONST_CACHE.PLAYER_BE_DAMAGE, 0)
    hcache.set(hplayer.players[i], CONST_CACHE.PLAYER_KILL, 0)
    if ((cj.GetPlayerController(hplayer.players[i]) == MAP_CONTROL_USER)
        and (cj.GetPlayerSlotState(hplayer.players[i]) == PLAYER_SLOT_STATE_PLAYING)) then
        --
        hplayer.qty_current = hplayer.qty_current + 1

        -- 默认开启自动换木
        hplayer.setIsAutoConvert(hplayer.players[i], true)
        hcache.set(hplayer.players[i], CONST_CACHE.PLAYER_STATUS, hplayer.player_status.gaming)

        -- 玩家离开游戏
        hevent.pool(hplayer.players[i], hevent_default_actions.player.leave, function(tgr)
            cj.TriggerRegisterPlayerEvent(tgr, hplayer.players[i], EVENT_PLAYER_LEAVE)
        end)
        -- 玩家选中单位
        hevent.pool(hplayer.players[i], hevent_default_actions.player.selection, function(tgr)
            cj.TriggerRegisterPlayerUnitEvent(tgr, hplayer.players[i], EVENT_PLAYER_UNIT_SELECTED, nil)
        end)
        hevent.onSelection(hplayer.players[i], 1, function(evtData)
            hcache.set(evtData.triggerPlayer, CONST_CACHE.PLAYER_SELECTION, evtData.triggerUnit)
        end)
        -- 玩家取消选择单位
        hevent.onDeSelection(hplayer.players[i], function(evtData)
            hcache.set(evtData.triggerPlayer, CONST_CACHE.PLAYER_SELECTION, nil)
        end)
        -- 玩家聊天接管
        hevent.pool(hplayer.players[i], hevent_default_actions.player.chat, function(tgr)
            cj.TriggerRegisterPlayerChatEvent(tgr, hplayer.players[i], "", false)
        end)
    else
        hcache.set(hplayer.players[i], CONST_CACHE.PLAYER_STATUS, hplayer.player_status.none)
    end
end

-- 恢复生命监听器
hmonitor.create(CONST_MONITOR.LIFE_BACK, 0.5,
    function(object)
        local val = hattribute.get(object, "life_back")
        hunit.addCurLife(object, val * 0.5)
    end,
    function(object)
        if (his.dead(object) or his.deleted(object)) then
            return true
        end
        local val = hattribute.get(object, "life_back")
        if (val > 0 and hunit.getCurLifePercent(object) >= 100) then
            return true
        end
        return false
    end
)

-- 恢复魔法监听器
hmonitor.create(CONST_MONITOR.MANA_BACK, 0.7,
    function(object)
        local val = hattribute.get(object, "mana_back")
        hunit.addCurMana(object, val * 0.7)
    end,
    function(object)
        if (his.dead(object) or his.deleted(object)) then
            return true
        end
        local val = hattribute.get(object, "mana_back")
        if (val <= 0 and hunit.getCurManaPercent(object) >= 100) then
            return true
        end
        return false
    end
)

-- 硬直监听器（没收到伤害时,每1秒恢复3%硬直）
hmonitor.create(CONST_MONITOR.PUNISH, 1,
    function(object)
        local punish_current = hattribute.get(object, "punish_current")
        local punish = hattribute.get(object, "punish")
        local val = math.floor(0.03 * punish)
        if (punish_current + val > punish) then
            hattribute.set(object, 0, { punish_current = "=" .. punish })
        else
            hattribute.set(object, 0, { punish_current = "+" .. val })
        end
    end,
    function(object)
        local punish_current = hattribute.get(object, "punish_current")
        local punish = hattribute.get(object, "punish")
        return punish_current >= punish or his.dead(object) or his.deleted(object) or his.beDamaging(object) or his.enablePunish(object) == false
    end
)

-- 沉默
local silentTrigger = cj.CreateTrigger()
cj.TriggerAddAction(silentTrigger, function()
    local triggerUnit = cj.GetTriggerUnit()
    if (his.silent(triggerUnit)) then
        cj.IssueImmediateOrder(triggerUnit, "stop")
    end
end)

-- 缴械
local unArmTrigger = cj.CreateTrigger()
cj.TriggerAddAction(unArmTrigger, function()
    local attacker = cj.GetAttacker()
    if (his.unarm(attacker)) then
        cj.IssueImmediateOrder(attacker, "stop")
    end
end)
for i = 1, bj_MAX_PLAYERS, 1 do
    cj.TriggerRegisterPlayerUnitEvent(silentTrigger, hplayer.players[i], EVENT_PLAYER_UNIT_SPELL_CHANNEL, nil)
    cj.TriggerRegisterPlayerUnitEvent(unArmTrigger, hplayer.players[i], EVENT_PLAYER_UNIT_ATTACKED, nil)
end
