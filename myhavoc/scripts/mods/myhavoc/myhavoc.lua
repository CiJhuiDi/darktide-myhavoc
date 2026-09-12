--[[
    Name: myhavoc
    Author: CiJhuiDi
    Version: 1.1.0

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

-- 当前本地时间，返回 "[10:35] "；取不到时返回空串（消息照常发，不因为拿不到时间就失败）
local function now_stamp()
    local fmt = "%H:%M"
    local ok, value = pcall(function () return os.date(fmt) end)

    if not (ok and type(value) == "string") then
        -- 兜底：某些环境全局 os 拿不到，从 Mods.lua 取（同 probe 的写法）
        ok, value = pcall(function ()
            return get_mod("DMF").deepcopy(Mods.lua.os).date(fmt)
        end)
    end

    if ok and type(value) == "string" then
        return "[" .. value .. "] "
    end

    return ""
end

-- 组装聊天文本(模板在 localization 里,{time}/{rank}/{map}/{mods} 占位)
-- {time} 自带方括号与尾空格；取不到时间时是空串，模板里不会留下空括号
local function build_message(order)
    local rank = tostring(order.rank or "?")
    local circs = parse_circumstances(order.flags)
    local mods_text = #circs > 0 and table.concat(circs, ", ") or "-"
    local map = map_name(order.map) or "?"
    return mod:localize("msg_havoc_order")
        :gsub("{time}", now_stamp())
        :gsub("{rank}", rank)
        :gsub("{map}", map)
        :gsub("{mods}", mods_text)
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

-- 调试模式：控制「冗余/自动回显」是否输出
--   关（默认）：不显示「已发送到聊天」「订单无变化」这类噪音
--              —— 但失败提示（err_*）、/havocstart 的「已开始」、/havocprobe 的输出不受影响
--   开：全部输出
local function debug_on()
    return mod:get("debug_mode") == true
end

local function echo_debug(text)
    if debug_on() then
        mod:echo(text)
    end
end

-- 订单签名（用于"订单没变就不重复发"）
local function order_signature(payload)
    return table.concat({
        tostring(payload.rank or ""),
        tostring(payload.map or ""),
        table.concat(parse_circumstances(payload.flags), ","),
    }, "|")
end

-- 拉取当前浩劫任务并发送；hooks 可选：
--   filter(sig) -> 是否发送；skip(sig) -> 被拦下时回调；done(sig) -> 发送成功后回调
-- DMF 会把命令后的参数当字符串传进来，所以 hooks 必须判类型
local function send_my_havoc(hooks)
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
        local signature = order_signature(payload)
        local allowed = type(hooks) ~= "table" or type(hooks.filter) ~= "function" or hooks.filter(signature)

        if allowed then
            local message = build_message(payload)

            if send_to_chat(message) then
                -- 聊天栏里本来就能看到消息本身，这句回显只在调试模式下输出
                echo_debug(mod:localize("sent") .. " " .. message)

                if type(hooks) == "table" and type(hooks.done) == "function" then
                    hooks.done(signature)
                end
            end
        elseif type(hooks) == "table" and type(hooks.skip) == "function" then
            hooks.skip(signature)
        end
    end):catch(function()
        mod:echo(mod:localize("err_fetch_failed"))
    end)
end

mod:command("myhavoc", mod:localize("command_description"), send_my_havoc)

-- ########################## 每局结束自动发送浩劫订单 ##########################
-- 打完一局队伍还在，顺手把（可能已刷新的）浩劫订单贴到聊天，省得每次手打 /myhavoc。
-- 触发：结算画面(EndView)出现后等 AUTO_SEND_DELAY 秒再发（等后端结算新订单）；
--       提前离开结算画面时由 on_exit 立即发（兜底）。
-- 开关：auto_send_after_mission（默认开）；auto_send_only_if_changed（默认开，订单没变不刷屏）
-- 只在**浩劫局**结束后发：普通任务结束同样会进 EndView，但那时订单没变，发了就是刷屏

local AUTO_SEND_DELAY = 6

-- 是不是浩劫局（不是就别在结算时自动播报浩劫订单）
--
-- **在任务初始化那一刻记录**，而不是等 EndView 再现场判断：
--   游戏自己在开局就把答案给了 ——
--     gameplay_init_step_managers.lua L98:
--       Managers.state.difficulty = DifficultyManager:new(is_server, resistance, challenge, havoc_data)
--     difficulty_manager.lua L19-24:
--       if havoc_data then self._parsed_havoc_data = Havoc.parse_data(havoc_data) end
--   即只有浩劫局才传 havoc_data。
--   现场判断不可靠：EndView 触发时局内 manager 可能已经拆掉，一律判成"不是浩劫"
--   → 连浩劫局都不播报（2026-09-12 实测踩到）。
local _havoc_hook_ok = false

do
    local DifficultyManager
    local ok, mod_table = pcall(require, "scripts/managers/difficulty/difficulty_manager")

    if ok and type(mod_table) == "table" then
        DifficultyManager = mod_table
    elseif type(CLASSES) == "table" then
        DifficultyManager = CLASSES.DifficultyManager
    end

    if type(DifficultyManager) == "table" then
        _havoc_hook_ok = pcall(function ()
            mod:hook(DifficultyManager, "init", function (func, self, is_server, resistance, challenge, havoc_data)
                mod._session_havoc = havoc_data ~= nil

                return func(self, is_server, resistance, challenge, havoc_data)
            end)
        end)
    end
end

-- 诊断串：调试模式下随跳过提示一起输出，下一次出问题一眼定位
local function havoc_diag()
    local ok1, v1 = pcall(function ()
        return Managers.state.difficulty:get_parsed_havoc_data()
    end)
    local ok2, v2 = pcall(function ()
        return Managers.state.game_mode:game_mode():extension("havoc"):get_current_rank()
    end)

    return string.format("(hooked=%s captured=%s diff=%s gm=%s)",
        tostring(_havoc_hook_ok),
        tostring(mod._session_havoc),
        ok1 and tostring(v1 ~= nil) or "ERR",
        ok2 and tostring(v2 ~= nil) or "ERR")
end

local function is_havoc_mission()
    -- 开局记下的结果说了算
    if mod._session_havoc ~= nil then
        return mod._session_havoc == true
    end

    -- 兜底：hook 没挂上（找不到类表）时只能现场判断
    local ok, value = pcall(function ()
        return Managers.state.difficulty:get_parsed_havoc_data() ~= nil
    end)

    if ok and value then
        return true
    end

    ok, value = pcall(function ()
        return Managers.state.game_mode:game_mode():extension("havoc"):get_current_rank() ~= nil
    end)

    return ok and value == true
end

local function auto_send_run()
    if mod._auto_fired then return end

    mod._auto_fired = true

    if mod:get("auto_send_after_mission") == false then return end

    -- 普通任务结束也会走到这里，但不是浩劫局就别发（订单根本没变化，纯刷屏）
    if not is_havoc_mission() then
        echo_debug(mod:localize("auto_send_not_havoc") .. " " .. havoc_diag())

        return
    end

    send_my_havoc({
        filter = function (signature)
            if mod:get("auto_send_only_if_changed") == false then return true end

            return mod._auto_last_sig ~= signature
        end,
        skip = function ()
            echo_debug(mod:localize("auto_send_unchanged"))
        end,
        done = function (signature)
            mod._auto_last_sig = signature
        end,
    })
end

-- EndView 上的三个 hook 各自 pcall：任何一个方法不存在都不影响其余两个
local function try_hook_endview(method, handler)
    pcall(function () mod:hook_safe(CLASS.EndView, method, handler) end)
end

try_hook_endview("on_enter", function ()
    mod._auto_fired = false
    mod._auto_t = 0
end)

try_hook_endview("update", function (self, dt, ...)
    if mod._auto_fired then return end

    mod._auto_t = (mod._auto_t or 0) + (dt or 0)

    if mod._auto_t >= AUTO_SEND_DELAY then
        auto_send_run()
    end
end)

try_hook_endview("on_exit", function ()
    auto_send_run()
end)

-- ########################## 快速开始自己的浩劫任务 ##########################
-- 链路与游戏内浩劫面板"开始"按钮一致(havoc_play_view._cb_on_mission_start)：
--   有 ongoing_mission_id 直接用；否则 activate_havoc_mission(order.id) 激活
--   → party_immaterium:wanted_mission_selected(mission_id, private, region) 启动匹配
-- 官方浩劫面板的「开始」闸门（havoc_play_view._update_can_play）：
--   任一队员不在枢纽站（还在加载 / 在任务里）就不允许开始。
-- /havocstart 原来没这道闸，队友加载中时会被一并拉进任务 → 其客户端黑屏，只能重启游戏。
local function party_block_reason()
	local pm = Managers.party_immaterium

	if not pm then return nil end

	-- 1) 全员就位（官方 PartyImmateriumManager.are_all_members_in_hub）：
	--    发起者自己必须在枢纽站；队友可以是枢纽站或训练场（灵能室）；
	--    加载中 / 在任务里的队友会被判不通过。
	local ok, all_hub = pcall(function() return pm:are_all_members_in_hub() end)

	if ok and all_hub == false then
		return "err_party_not_ready"
	end

	-- 2) 队员浩劫资格（官方同款）
	local ok2, all_can_play = pcall(function()
		return Managers.data_service.havoc:can_all_party_members_play_havoc()
	end)

	if ok2 and all_can_play == false then
		return "err_party_not_eligible"
	end

	-- 3) 人数：官方 min_participants（后端实测 2）—— 浩劫不自动匹配，单人开不了
	local min_participants = 1

	pcall(function()
		local svc = Managers.data_service and Managers.data_service.havoc

		if svc and type(svc.get_settings) == "function" then
			local settings = svc:get_settings()

			min_participants = tonumber(settings and settings.min_participants) or 1
		end
	end)

	min_participants = math.max(min_participants, 1)

	local party_size = 1

	pcall(function()
		local members = pm:all_members()

		if type(members) == "table" and #members > 0 then
			party_size = #members
		end
	end)

	if party_size < min_participants then
		return "err_party_too_small", min_participants, party_size
	end

	return nil
end

local function start_my_havoc()
	-- 先过官方闸门，宁可不开，也不能把加载中的队友拉进任务
	local block, arg1, arg2 = party_block_reason()

	if block then
		if arg1 then
			mod:echo(mod:localize(block, arg1, arg2))
		else
			mod:echo(mod:localize(block))
		end

		return
	end

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
		if type(order) ~= "table" then
			mod:echo(mod:localize("err_no_order"))
			return
		end

		-- 1. 拿可启动的 mission id（有 ongoing 直接复用，否则激活订单）
		local activate_promise

		if order.ongoing_mission_id then
			activate_promise = Promise.resolved({ id = order.ongoing_mission_id })
		elseif order.id and type(svc.activate_havoc_mission) == "function" then
			local ok2, p2 = pcall(svc.activate_havoc_mission, svc, order.id)

			if not (ok2 and type(p2) == "table" and type(p2.next) == "function") then
				mod:echo(mod:localize("err_activate_failed"))
				return
			end

			activate_promise = p2
		else
			mod:echo(mod:localize("err_activate_failed"))
			return
		end

		activate_promise:next(function(mission)
			if not (mission and mission.id) then
				mod:echo(mod:localize("err_activate_failed"))
				return
			end

			-- 2. 启动匹配（与浩劫面板一致：公开匹配 + 首选区域）
			local private_match = false
			local prefered_mission_region

			pcall(function()
				prefered_mission_region = Managers.data_service.region_latency:get_prefered_mission_region()
			end)

			local ok3 = pcall(function()
				Managers.party_immaterium:wanted_mission_selected(mission.id, private_match, prefered_mission_region)
			end)

			if ok3 then
				mod:echo(mod:localize("started"))
			else
				mod:echo(mod:localize("err_start_failed"))
			end
		end):catch(function(err)
			-- 已有进行中任务的 400 特判（与游戏内提示一致）
			if err and err.code == 400 and type(err.description) == "string"
				and string.find(err.description, "already_has_ongoing_mission")
			then
				mod:echo(mod:localize("err_ongoing_mission"))
			else
				mod:echo(mod:localize("err_activate_failed"))
			end
		end)
	end):catch(function()
		mod:echo(mod:localize("err_fetch_failed"))
	end)
end

mod:command("havocstart", mod:localize("command_description_start"), start_my_havoc)

-- 客户端静态配置 HavocSettings（/havocprobe 用）
local _havoc_settings = false

local function havoc_settings()
	if _havoc_settings ~= false then return _havoc_settings end

	local ok, t = pcall(require, "scripts/settings/havoc_settings")
	_havoc_settings = (ok and type(t) == "table") and t or nil

	return _havoc_settings
end

-- ########################## /havocprobe：数据探针（诊断用） ##########################
-- 把两份数据完整 dump 到文件，用来确认：
--   1) 客户端配置 HavocSettings 的真实结构 —— 核对 /havocpool 的字段假设
--   2) 后端 /data/havoc/settings 的原始返回 —— 客户端解析时只取了 rankSystem（最高等级/部署次数），
--      其余字段被丢弃；如果真的存在「每周轮换池」，只可能藏在这里
-- 输出文件：%APPDATA%/Fatshark/Darktide/myhavoc_probe.txt

local _probe_io, _probe_os = nil, nil

-- 拿游戏沙箱的 io / os（与 scoreboard_fixes 同一套写法）
local function probe_sandbox()
	if _probe_io then return _probe_io, _probe_os end

	local ok, DMF = pcall(get_mod, "DMF")

	if not (ok and type(DMF) == "table" and type(DMF.deepcopy) == "function") then
		return nil, nil
	end

	local ok_io, io_lib = pcall(function () return DMF.deepcopy(Mods.lua.io) end)
	local ok_os, os_lib = pcall(function () return DMF.deepcopy(Mods.lua.os) end)

	if ok_io and ok_os then
		_probe_io, _probe_os = io_lib, os_lib
	end

	return _probe_io, _probe_os
end

-- 递归序列化（带循环引用保护与长度上限）
local function probe_dump(v, indent, seen, out, depth)
	if #out > 40000 or depth > 12 then return end

	if type(v) == "table" then
		if seen[v] then
			out[#out + 1] = indent .. "<循环引用>"
			return
		end

		seen[v] = true
		out[#out + 1] = indent .. "{"

		local keys = {}

		for k in pairs(v) do keys[#keys + 1] = k end

		table.sort(keys, function (a, b) return tostring(a) < tostring(b) end)

		for i = 1, #keys do
			local k = keys[i]
			local val = v[k]
			local key = type(k) == "string" and k or ("[" .. tostring(k) .. "]")

			if type(val) == "table" then
				out[#out + 1] = indent .. "  " .. key .. " ="
				probe_dump(val, indent .. "    ", seen, out, depth + 1)
			else
				out[#out + 1] = indent .. "  " .. key .. " = " .. tostring(val)
			end
		end

		out[#out + 1] = indent .. "}"
		seen[v] = nil
	else
		out[#out + 1] = indent .. tostring(v)
	end
end

local function probe_top_keys(v)
	local keys = {}

	if type(v) == "table" then
		for k in pairs(v) do keys[#keys + 1] = tostring(k) end
		table.sort(keys)
	end

	return table.concat(keys, ", ")
end

local function probe_count(t)
	local n = 0

	if type(t) == "table" then
		for _ in pairs(t) do n = n + 1 end
	end

	return n
end

local function probe_join_keys(t)
	local keys = {}

	if type(t) == "table" then
		for k in pairs(t) do keys[#keys + 1] = tostring(k) end
		table.sort(keys)
	end

	return table.concat(keys, ", ")
end

-- 从一份 order 里抠出地图 id 与词条 id
local function probe_order_bits(order)
	local bp = type(order) == "table" and order.blueprint
	local map_id

	if type(bp) == "table" then
		local t = bp.template

		if type(t) == "table" and type(t.id) == "string" then
			map_id = t.id
		elseif type(t) == "string" then
			map_id = t
		elseif type(bp.map) == "string" then
			map_id = bp.map
		end
	end

	local circs = {}

	if type(bp) == "table" and type(bp.flags) == "table" then
		for k, v in pairs(bp.flags) do
			local str = (type(k) == "string" and k) or (type(v) == "string" and v) or nil
			local cid = str and str:match("^havoc%-circ%-(.+)$")

			if cid then circs[#circs + 1] = cid end
		end
	end

	return map_id, circs
end

local function run_havoc_probe()
	local io_lib, os_lib = probe_sandbox()

	if not io_lib then
		mod:echo(mod:localize("probe_no_io"))
		return
	end

	local out = {}
	local function w(line) out[#out + 1] = line end

	w("myhavoc probe")
	w("")

	-- 1) 客户端配置
	local HS = havoc_settings()

	w("===== 1) HavocSettings =====")
	w("顶层 key: " .. probe_top_keys(HS))
	w("")

	if HS then
		probe_dump(HS, "", {}, out, 1)
	else
		w("(读取失败 / 未加载)")
	end

	w("")

	-- 2) 客户端解析后的 settings
	local svc = Managers.data_service and Managers.data_service.havoc
	local parsed

	w("===== 2) havoc:get_settings() =====")

	if svc and type(svc.get_settings) == "function" then
		local ok, res = pcall(svc.get_settings, svc)

		if ok then
			parsed = res
			w("顶层 key: " .. probe_top_keys(parsed))
			w("")
			probe_dump(parsed, "", {}, out, 1)
		else
			w("(调用失败: " .. tostring(res) .. ")")
		end
	else
		w("(不可用)")
	end

	w("")

	local finished = false
	local function finish(extra)
		if finished then return end
		finished = true

		if extra then w(extra) end

		local path = (os_lib.getenv("APPDATA") or "") .. "/Fatshark/Darktide/myhavoc_probe.txt"
		local f, err = io_lib.open(path, "w+")

		if not f then
			mod:echo(mod:localize("probe_write_failed", tostring(err)))
			return
		end

		f:write(table.concat(out, "\n"))
		f:close()

		mod:echo(mod:localize("probe_written", path))
		mod:echo(mod:localize("probe_hs_keys", probe_top_keys(HS)))
	end

	-- 3.5) 任务板 mission_board（本周任务列表，含 flags）
	local function mission_board()
		w("")
		w("===== 5) 任务板 mission_board =====")

		local requested = false

		pcall(function ()
			local iface = Managers.backend and Managers.backend.interfaces
			local mb = iface and iface.mission_board

			if not (mb and type(mb.fetch) == "function") then return end

			local promise = mb:fetch(nil, 1)

			if not (type(promise) == "table" and type(promise.next) == "function") then return end

			requested = true

			promise:next(function (data)
				w("body 顶层 key: " .. probe_top_keys(data))
				w("missions 条数: " .. (type(data) == "table" and type(data.missions) == "table" and #data.missions or 0))
				w("")
				probe_dump(data, "", {}, out, 1)
				finish()
			end):catch(function (err)
				finish("任务板请求失败: " .. tostring(err))
			end)
		end)

		if not requested then
			finish("(任务板不可用：backend.interfaces.mission_board.fetch 拿不到)")
		end
	end

	-- 4) 后端原始 settings
	local function backend_settings()
		w("")
		w("===== 4) 后端原始 /data/havoc/settings =====")

		local requested = false

		pcall(function ()
			local ok_req, BackendUtilities = pcall(require, "scripts/foundation/managers/backend/utilities/backend_utilities")

			if not (ok_req and type(BackendUtilities) == "table") then return end
			if not (Managers.backend and type(Managers.backend.title_request) == "function") then return end

			local builder = BackendUtilities.url_builder():path("/data"):path("/havoc"):path("/settings")
			local promise = Managers.backend:title_request(builder:to_string(), { method = "GET" })

			if not (type(promise) == "table" and type(promise.next) == "function") then return end

			requested = true

			promise:next(function (data)
				w("status = " .. tostring(data and data.status))
				w("body 顶层 key: " .. probe_top_keys(data and data.body))
				w("")
				probe_dump(data, "", {}, out, 1)
				mission_board()
			end):catch(function (err)
				w("请求失败: " .. tostring(err))
				mission_board()
			end)
		end)

		if not requested then
			w("(无法发起请求：backend_utilities / title_request 不可用)")
			mission_board()
		end
	end

	-- 3) available_orders（本周可选的浩劫订单列表）
	local function dump_orders(orders)
		local maps, circs = {}, {}
		local n = type(orders) == "table" and #orders or 0

		if type(orders) == "table" then
			for i = 1, #orders do
				local map_id, list = probe_order_bits(orders[i])

				if map_id then maps[map_id] = true end

				for k = 1, #list do circs[list[k]] = true end
			end
		end

		w("===== 3) available_orders（本周可选的浩劫订单）=====")
		w("订单数: " .. n)
		w("地图数: " .. probe_count(maps))
		w("  地图: " .. probe_join_keys(maps))
		w("词条数: " .. probe_count(circs))
		w("  词条: " .. probe_join_keys(circs))
		w("")
		probe_dump(orders, "", {}, out, 1)

		mod:echo(mod:localize("probe_orders", n, probe_count(maps), probe_count(circs)))

		backend_settings()
	end

	if svc and type(svc.available_orders) == "function" then
		local ok, promise = pcall(svc.available_orders, svc)

		if ok and type(promise) == "table" and type(promise.next) == "function" then
			promise:next(function (orders)
				dump_orders(orders)
			end):catch(function (err)
				w("===== 3) available_orders =====")
				w("(失败: " .. tostring(err) .. ")")
				backend_settings()
			end)

			return
		end
	end

	w("===== 3) available_orders =====")
	w("(不可用)")
	backend_settings()
end

mod:command("havocprobe", mod:localize("command_description_probe"), run_havoc_probe)
