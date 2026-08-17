--[[
    Name: myhavoc
    Author: 大肥鱼
    Version: 1.0.0

    聊天命令 /myhavoc:把自己的当前浩劫(Havoc)任务(层数 + 地图 + 词条)发到聊天,
    方便向队友展示本周浩劫任务。

    数据来源:Managers.data_service.havoc:current_order()
             (与 Havoc Auspex / Havoc Auspex Transmitter 同源,参考 Wobin 的开源实现)
    词条名:circumstance_templates 的 ui.display_name 本地化(官方中文/英文随游戏语言)
    地图名:mission_templates 的 mission_name 本地化
    发送:Managers.chat:send_channel_message,优先 PARTY 频道,其次 MISSION,最后 HUB
--]]

local mod = get_mod("myhavoc")

-- 模板表缓存(settings 数据在游戏 bundle 里,运行时 require;缓存避免重复加载)
local _circ_templates = false
local _mission_templates = false

local function load_templates()
    if _circ_templates ~= false then return end
    local ok1, c = pcall(require, "scripts/settings/circumstance/circumstance_templates")
    local ok2, m = pcall(require, "scripts/settings/mission/mission_templates")
    _circ_templates = ok1 and c or {}
    _mission_templates = ok2 and m or {}
end

-- 本地化显示名;拿不到或等于 key 本身时返回 nil
local function try_localize(key)
    if type(key) ~= "string" then return nil end
    local ok, s = pcall(function() return Managers.localization:localize(key) end)
    if ok and s and s ~= key and not s:match("^<") then return s end
    return nil
end

-- 兜底显示:把 id 转成可读标题(如 "ventilation_purge" -> "Ventilation Purge")
local function prettify(s)
    return (tostring(s):gsub("_", " "):gsub("(%a)([%w_]*)", function(a, b) return a:upper() .. b end))
end

-- 解析 flags 里的浩劫词条(形如 "havoc-circ-<id>"),返回排序后的显示名列表
local function parse_circumstances(flags)
    local names = {}
    if type(flags) ~= "table" then return names end
    load_templates()
    for k, v in pairs(flags) do
        local s = (type(k) == "string" and k) or (type(v) == "string" and v) or nil
        if s then
            local cid = s:match("^havoc%-circ%-(.+)$")
            if cid then
                local t = _circ_templates[cid]
                local display = t and t.ui and try_localize(t.ui.display_name)
                names[#names + 1] = display or prettify(cid)
            end
        end
    end
    table.sort(names)
    return names
end

-- 地图显示名
local function map_name(map_id)
    if type(map_id) ~= "string" then return nil end
    load_templates()
    local t = _mission_templates[map_id]
    if t and t.mission_name then
        local s = try_localize(t.mission_name)
        if s then return s end
    end
    return prettify(map_id)
end

-- 组装聊天文本(模板在 localization 里,{rank}/{map}/{mods} 占位)
local function build_message(order)
    local rank = tostring(order.rank or "?")
    local circs = parse_circumstances(order.flags)
    local mods_text = #circs > 0 and table.concat(circs, ", ") or "-"
    local map = map_name(order.map) or "?"
    return mod:localize("msg_havoc_order"):gsub("{rank}", rank):gsub("{map}", map):gsub("{mods}", mods_text)
end

-- 找可发送的聊天频道:优先队伍(PARTY),其次任务(MISSION),最后枢纽(HUB)
local function find_channel_handle(chat)
    local sessions = chat:sessions()
    local fallback
    for handle, channel in pairs(sessions) do
        local tag = channel.tag
        if tag == "PARTY" then
            return handle
        elseif tag == "MISSION" then
            fallback = fallback or handle
        elseif tag == "HUB" and not fallback then
            fallback = handle
        end
    end
    return fallback
end

-- 发消息到聊天;成功返回 true
local function send_to_chat(message)
    local chat = Managers.chat
    if not chat or type(chat.sessions) ~= "function" then
        mod:echo(mod:localize("err_no_chat"))
        return false
    end
    local handle = find_channel_handle(chat)
    if not handle then
        mod:echo(mod:localize("err_no_channel"))
        return false
    end
    local ok = pcall(chat.send_channel_message, chat, handle, message)
    if not ok then
        mod:echo(mod:localize("err_send_failed"))
        return false
    end
    return true
end

-- 拉取当前浩劫任务并发送
local function send_my_havoc()
    local svc
    pcall(function() svc = Managers.data_service and Managers.data_service.havoc end)
    if not svc or type(svc.current_order) ~= "function" then
        mod:echo(mod:localize("err_no_service"))
        return
    end

    local ok, promise = pcall(svc.current_order, svc)
    if not (ok and type(promise) == "table" and type(promise.next) == "function") then
        mod:echo(mod:localize("err_fetch_failed"))
        return
    end

    promise:next(function(order)
        if type(order) ~= "table" or type(order.blueprint) ~= "table" then
            mod:echo(mod:localize("err_no_order"))
            return
        end
        local bp = order.blueprint
        local payload = {
            rank  = order.rank or (type(order.data) == "table" and order.data.rank) or nil,
            map   = bp.map,
            flags = type(bp.flags) == "table" and bp.flags or {},
        }
        local message = build_message(payload)
        if send_to_chat(message) then
            mod:echo(mod:localize("sent") .. " " .. message)
        end
    end):catch(function()
        mod:echo(mod:localize("err_fetch_failed"))
    end)
end

mod:command("myhavoc", mod:localize("command_description"), send_my_havoc)
