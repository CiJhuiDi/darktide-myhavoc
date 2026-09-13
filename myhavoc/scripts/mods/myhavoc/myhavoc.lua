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
        -- 兜底：某些环境全局 os 拿不到，从 Mods.lua 取（同下方落盘 dump 的写法）
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
--              —— 但失败提示（err_*）、/havocstart 的「已开始」、诊断命令的输出不受影响
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

-- ########################## 命令参数解析（统一入口） ##########################
-- DMF 把命令后空格分隔的参数以 vararg 传进来（见 DMF commands.lua / chat_actions.lua L127-136）。
-- 统一成：第一个词当子命令（小写），raw 是完整参数串。
-- 不接受参数的命令用它挡下多余参数 —— 避免打错字时静默执行正事（以前 /havocgroup chekc 会直接建房）。
local function parse_command_args(...)
	local raw = table.concat({ ... }, " ")
	local first = raw:match("^%s*(%S*)") or ""

	return first:lower(), raw
end

-- 有多余参数时提示用法并返回 true（调用方直接 return）
local function reject_extra_args(raw, usage_key)
	if raw:match("%S") then
		mod:echo(mod:localize(usage_key))

		return true
	end

	return false
end

-- ########################## 每帧回调（计时/延迟动作的公共入口） ##########################
-- DMF 没有定时器 API。CLASS.InputManager.update 在任何场景（枢纽站/任务中）都每帧跑，
-- DMF 自己也 hook 它（dmf_hooks.lua L575），是最可靠的每帧入口。
local _tickers = {}
local _frame_hook_installed = false

local function frame_hook_install()
	if _frame_hook_installed then
		return true
	end

	local ok = pcall(function ()
		mod:hook_safe(CLASS.InputManager, "update", function (self, dt)
			for i = 1, #_tickers do
				pcall(_tickers[i], dt or 0)
			end
		end)
	end)

	_frame_hook_installed = ok == true

	return _frame_hook_installed
end

-- 通用落盘（游戏控制台看不到，方便排查）
local function dump_to_file(name, text)
	pcall(function ()
		local DMF = get_mod("DMF")
		local io_lib = DMF.deepcopy(Mods.lua.io)
		local os_lib = DMF.deepcopy(Mods.lua.os)
		local path = (os_lib.getenv("APPDATA") or "") .. "/Fatshark/Darktide/" .. name
		local file = io_lib.open(path, "w+")

		if file then
			file:write(text)
			file:close()
		end
	end)
end

-- /havoc 与 /myhavoc 同义。推荐 /havoc：前缀和 /havocstart /havocgroup 一致，
-- DMF 的补全是按前缀列命令的，这样才能把最常用的动作也列进去。
-- /myhavoc 保留为别名（早已写在 mod 简介里发出去过，不能废）。
local function command_send_order(...)
	local _, raw = parse_command_args(...)

	if reject_extra_args(raw, "usage_send") then
		return
	end

	send_my_havoc()
end

mod:command("havoc", mod:localize("command_description"), command_send_order)
mod:command("myhavoc", mod:localize("command_description"), command_send_order)

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

local function command_start_havoc(...)
	local _, raw = parse_command_args(...)

	if reject_extra_args(raw, "usage_start") then
		return
	end

	start_my_havoc()
end

mod:command("havocstart", mod:localize("command_description_start"), command_start_havoc)

-- ########################## 一键创建组队房间（/havocgroup） ##########################
-- 按自己的浩劫订单在「寻找队伍」挂一条招募，别人能直接看到并申请加入。
-- 逻辑照抄游戏自己的 group_finder_view（反编译存档：暗潮\99-临时文件\ref\src_group_finder_view.lua）：
--   标签   = "my_havoc_order"（游戏原生标签，勾上就是"按我的浩劫订单"）
--            + "havoc_order_threshold_<X>"（由订单 flags 里的 havoc-threshold- 推出）
--   config = havoc_order_owner / havoc_order_id / havoc_order_rank /
--            havoc_mission_template / havoc_circ_1..N / havoc_theme
--   调用   Managers.party_immaterium:start_party_finder_advertise(config, tags, region)
-- 原版是「打开寻找队伍界面 → 勾『我的浩劫订单』→ 点开始招募」，本命令省掉界面操作。

local GROUP_FINDER_VIEW = "group_finder_view"
local HAVOC_ORDER_TAG = "my_havoc_order"

-- 本机账号 id
local function local_account_id()
	local ok, account_id = pcall(function ()
		local player = Managers.player:local_player(1) or Managers.player:local_player()

		return player and player:account_id()
	end)

	return ok and account_id or nil
end

-- 自己是不是在枢纽站（寻找队伍是枢纽站功能，任务里挂招募没意义）
local function myself_in_hub()
	local ok, in_hub = pcall(function ()
		return Managers.party_immaterium:get_myself():presence_name() == "hub"
	end)

	return ok and in_hub == true
end

-- 错误转文本（后端返回的错误常常是 table，直接 tostring 只有 "table: 0x..."）
local function error_text(error)
	if type(error) == "string" then
		return error
	end

	local ok, text = pcall(function ()
		return table.tostring(error, 10)
	end)

	if ok and type(text) == "string" then
		return (text:gsub("%s+", " "))
	end

	return tostring(error)
end

-- 失败详情落盘（游戏控制台看不到，方便排查）
local function dump_group_error(error, config, tags, region)
	pcall(function ()
		local DMF = get_mod("DMF")
		local io_lib = DMF.deepcopy(Mods.lua.io)
		local os_lib = DMF.deepcopy(Mods.lua.os)
		local path = (os_lib.getenv("APPDATA") or "") .. "/Fatshark/Darktide/myhavoc_group_error.txt"
		local file = io_lib.open(path, "w+")

		if not file then
			return
		end

		file:write("myhavoc /havocgroup 失败详情\n\n== error ==\n")
		file:write(error_text(error) .. "\n")
		file:write("\n== region ==\n" .. tostring(region) .. "\n")
		file:write("\n== tags ==\n" .. table.concat(tags or {}, "\n") .. "\n")
		file:write("\n== config ==\n")

		for key, value in pairs(config or {}) do
			file:write(string.format("%s = %s\n", tostring(key), tostring(value)))
		end

		file:write("\n== party ==\n")

		local party = Managers.party_immaterium
		local ok_leader, is_leader = pcall(function ()
			return party.is_party_leader and party:is_party_leader() or "n/a"
		end)

		file:write("party_id        = " .. tostring(party and party:party_id()) .. "\n")
		file:write("is_party_leader = " .. (ok_leader and tostring(is_leader) or "ERR") .. "\n")
		file:write("num_members     = " .. tostring(party and party.num_members and party:num_members()) .. "\n")
		file:write("presence        = " .. tostring(party and party:get_myself() and party:get_myself():presence_name()) .. "\n")
		file:close()
	end)
end

-- 把 available_orders()[1] 组装成 config + 阈值标签；数据不完整返回 nil
local function build_advertise_payload(order, account_id)
	if type(order) ~= "table" then
		return nil
	end

	local blueprint = order.blueprint or {}
	local data = order.data or {}
	local template = blueprint.template or {}
	local flags = blueprint.flags or {}

	local rank = data.rank and tostring(data.rank)
	local mission_template = template.id

	if not order.id or not rank or not mission_template or not next(flags) then
		return nil
	end

	local config = {
		havoc_order_owner = account_id,
		havoc_order_id = order.id,
		havoc_order_rank = rank,
		havoc_mission_template = mission_template,
	}

	local threshold_tag
	local circ_index = 1

	for flag in pairs(flags) do
		if type(flag) == "string" then
			local circ = flag:match("^havoc%-circ%-(.+)$")
			local theme = flag:match("^havoc%-theme%-(.+)$")
			local threshold = flag:match("^havoc%-threshold%-(.+)$")

			if circ then
				config["havoc_circ_" .. circ_index] = circ
				circ_index = circ_index + 1
			elseif theme then
				config.havoc_theme = theme
			elseif threshold then
				threshold_tag = threshold
			end
		end
	end

	return config, threshold_tag
end

-- 把选中标签的**完整祖先链**补进列表（照抄 group_finder_view 的实际行为）
-- 勾「我的浩劫订单」时，成品招募带的是 game_mode -> havoc -> 叶子 整条链。
-- 缺了祖先，别人按常规筛选（浩劫分类）就搜不到我们的房间。
-- 2026-09-13 实测踩坑：/havocgroup check 回查后端列表，别人都有 havoc+game_mode，只有我们没有。
--
-- 注意：**不能只加 root_tag 的父**。后端标签表（social:get_group_finder_tags）实际是：
--   game_mode   rootTag=true
--     havoc               parents=game_mode
--       my_havoc_order           parents=havoc
--       havoc_order_threshold_N  parents=havoc
-- my_havoc_order 的父是 havoc，而 havoc 不是 rootTag ——
-- 官方 L1666-1678 只加「父里 root_tag 的那些」，是建立在
-- 「界面里勾叶子前必须先把祖先勾上」这一前提下的（所以原版 _selected_tags 里本来就有 havoc）。
-- 我们直接调接口没这个前提，必须自己把祖先链补齐。
-- 父关系由 unlocks 反向推（同 _format_group_finder_tags）；拿不到数据就不加（不阻断创建）。
local function expand_parent_tags(tags, callback)
	local social = Managers.data_service and Managers.data_service.social

	if not (social and social.get_group_finder_tags) then
		callback(tags)

		return
	end

	local ok, promise = pcall(function ()
		return social:get_group_finder_tags()
	end)

	if not (ok and promise) then
		callback(tags)

		return
	end

	promise:next(function (data)
		local list = data and data.tags and data.tags.tags

		if type(list) ~= "table" then
			callback(tags)

			return
		end

		local parents_map = {}

		for i = 1, #list do
			local tag = list[i]

			if type(tag) == "table" and type(tag.unlocks) == "table" then
				for j = 1, #tag.unlocks do
					local child = tag.unlocks[j]

					parents_map[child] = parents_map[child] or {}
					parents_map[child][#parents_map[child] + 1] = tag.name
				end
			end
		end

		local existing = {}
		local queue = {}

		for i = 1, #tags do
			existing[tags[i]] = true
			queue[#queue + 1] = tags[i]
		end

		-- 广度优先沿父链往上走（existing 兼作去重与防环）
		local index = 1

		while index <= #queue do
			local name = queue[index]
			index = index + 1

			local parents = parents_map[name]

			if parents then
				for j = 1, #parents do
					local parent = parents[j]

					if not existing[parent] then
						existing[parent] = true
						tags[#tags + 1] = parent
						queue[#queue + 1] = parent
					end
				end
			end
		end

		callback(tags)
	end):catch(function ()
		callback(tags)
	end)
end

-- 拿地区 id；为空就先拉一次。
-- BackendUtilities.prefered_mission_region 默认是 ""，只有 fetch_regions_latency 跑过才有值
-- （游戏里进「寻找队伍」/任务板时会自己拉；直接敲命令就可能还是空 —— 空地区会被后端拒绝）
local function resolve_region(callback)
	local service = Managers.data_service.region_latency
	local region = service and service:get_prefered_mission_region()

	if type(region) == "string" and region ~= "" then
		callback(region)

		return
	end

	local called = false

	local function done()
		if called then
			return
		end

		called = true
		callback(service and service:get_prefered_mission_region())
	end

	local ok, promise = pcall(function ()
		return service:fetch_regions_latency()
	end)

	if not (ok and promise) then
		done()

		return
	end

	promise:next(done):catch(done)
end

-- 关掉自己的招募
local function cancel_group_advertise()
	local party = Managers.party_immaterium

	if not (party and party.cancel_party_finder_advertise) then
		mod:echo(mod:localize("err_no_service"))

		return
	end

	local ok = pcall(function ()
		party:cancel_party_finder_advertise()
	end)

	-- 成功只是“回显”，走调试开关；失败必须始终显示
	if ok then
		echo_debug(mod:localize("group_cancelled"))
	else
		mod:echo(mod:localize("group_cancel_failed"))
	end
end

-- ########################## 创建后自动打开「寻找队伍」 ##########################
-- 为什么不能直接在创建成功的 promise 回调里开：
--   UIManager.open_view 有多条**静默失败**路径 ——
--     ① ui_view_handler._open：视图已在活跃表里就直接 return（什么都不做），
--        而 UIManager 不管里面成没成，一律 `return true`
--     ② 视图正在关闭（closing）时 force_close 未必来得及清干净 → 又掉进 ①
--     ③ view_is_available 不通过时只弹框、不返回原因（group_finder_view 带 killswitch
--        = GameParameters.show_group_finder）
--   而 promise 回调是在帧内更新中跑的，时机很敏感。
--
-- 实测（2026-09-14，用户反馈「重启游戏后第一次一定打不开」）：
--   症状 = 界面**闪一下就没了**；游戏日志显示首次打开要现场加载视图关卡：
--     [ScriptWorld] Registering level named: "content/levels/ui/group_finder/group_finder"
--   并造成 168ms 卡顿（RI::wait_for_fence），紧接着界面被关掉。
--   之后几次因为关卡已在内存里、没有这个卡顿，所以都正常 —— 这就是「只有第一次」的来源。
--
-- 做法：挂到下一帧再开 → 开完验证真的 active → 没成就在超时窗口内限流重试 →
--      **开成之后还要守一会儿**：被关掉就再开（最多 GROUP_FINDER_MAX_REOPENS 次）
--      → 彻底失败则明确提示 + 落盘诊断，不再静默。
local GROUP_FINDER_OPEN_TIMEOUT = 5
local GROUP_FINDER_WATCH_SECONDS = 0.8
local GROUP_FINDER_MAX_REOPENS = 2
local GROUP_FINDER_RETRY_INTERVAL = 0.15

local _open_finder = {
	log = {},
	next_try = 0,
	opened = false,
	opened_t = nil,
	pending = false,
	reopens = 0,
	t = 0,
	tries = 0,
}

local function finder_log_push(line)
	local log = _open_finder.log

	log[#log + 1] = line

	-- 只留最后 14 行
	while #log > 14 do
		table.remove(log, 1)
	end
end

-- 拿视图状态；拿不到返回 nil
local function finder_view_state()
	local ui = Managers.ui

	if not ui then
		return nil
	end

	local ok, state = pcall(function ()
		return {
			available = ui:view_is_available(GROUP_FINDER_VIEW),
			active = ui:view_active(GROUP_FINDER_VIEW),
			closing = ui._view_handler and ui._view_handler:is_view_closing(GROUP_FINDER_VIEW),
		}
	end)

	if ok and type(state) == "table" then
		return state
	end

	return nil
end

-- 诊断串（失败时落盘，下一次出问题一眼定位）
local function finder_diag()
	local state = finder_view_state()
	local parts = { "tries=" .. tostring(_open_finder.tries), "reopens=" .. tostring(_open_finder.reopens) }

	if state then
		parts[#parts + 1] = "available=" .. tostring(state.available)
		parts[#parts + 1] = "active=" .. tostring(state.active)
		parts[#parts + 1] = "closing=" .. tostring(state.closing)
	else
		parts[#parts + 1] = "state=nil"
	end

	pcall(function ()
		parts[#parts + 1] = "gp_show_group_finder=" .. tostring(GameParameters and GameParameters.show_group_finder)
	end)

	return table.concat(parts, " ")
end

local function finder_dump_trace(header)
	dump_to_file("myhavoc_openview_trace.txt", header .. "\n\n" .. table.concat(_open_finder.log, "\n") .. "\n")
end

local function finder_open_failed()
	_open_finder.pending = false

	local diag = finder_diag()

	dump_to_file("myhavoc_openview_error.txt", "myhavoc 自动打开「寻找队伍」失败\n\n" .. diag .. "\n\n== 尝试轨迹 ==\n" .. table.concat(_open_finder.log, "\n") .. "\n")
	mod:echo(mod:localize("group_open_view_failed"))
	echo_debug("open_view diag = " .. diag)
end

-- 返回 true=现在是开着的；false=还没成，可重试；nil=重试也没意义（如 killswitch 关着）
local function finder_open_step()
	local state = finder_view_state()

	if not state then
		return false
	end

	-- 开关被关：重试无意义（每次都会弹一个不可用弹框），直接报
	if state.available == false then
		return nil
	end

	if state.active and not state.closing then
		return true
	end

	-- 正在关闭：先强制关掉，下一拍再开
	if state.closing then
		pcall(function ()
			Managers.ui:close_view(GROUP_FINDER_VIEW, true)
		end)

		return false
	end

	local called, opened = pcall(function ()
		return Managers.ui:open_view(GROUP_FINDER_VIEW)
	end)

	if not (called and opened) then
		return false
	end

	-- open_view 返回 true 也可能是静默 no-op，再确认一次
	local after = finder_view_state()

	return (after and after.active and not after.closing) and true or false
end

local function finder_open_tick(dt)
	if not _open_finder.pending then
		return
	end

	_open_finder.t = _open_finder.t + dt

	if _open_finder.t < _open_finder.next_try then
		return
	end

	_open_finder.next_try = _open_finder.t + GROUP_FINDER_RETRY_INTERVAL
	_open_finder.tries = _open_finder.tries + 1

	-- 开**之前**的状态（上次的 bug：记的是开之后的状态，等于没记）
	local before = finder_view_state()
	local active_before = (before and before.active and not before.closing) and true or false

	local done = finder_open_step()

	finder_log_push(string.format("t=%.2f try=%d 开前: active=%s closing=%s avail=%s -> 开后=%s", _open_finder.t, _open_finder.tries, tostring(before and before.active), tostring(before and before.closing), tostring(before and before.available), tostring(done)))

	if done == nil then
		finder_open_failed()

		return
	end

	if done == true then
		if not _open_finder.opened then
			_open_finder.opened = true
			_open_finder.opened_t = _open_finder.t

			finder_log_push("  ^ 首次打开")
		elseif not active_before then
			-- 之前开成过，这一拍发现它没了 → 重开
			_open_finder.reopens = _open_finder.reopens + 1

			finder_log_push(string.format("  ^ 被关掉了，重开第 %d 次", _open_finder.reopens))
		end

		-- 守着：窗口内继续看它还在不在（首次那一下会被关卡加载的卡顿带崩，重开一次就好了）
		local watching = (_open_finder.t - (_open_finder.opened_t or 0)) < GROUP_FINDER_WATCH_SECONDS
		local can_reopen = _open_finder.reopens < GROUP_FINDER_MAX_REOPENS

		if watching and can_reopen then
			return
		end

		_open_finder.pending = false

		finder_dump_trace(string.format("myhavoc 自动打开「寻找队伍」：成功（tries=%d, reopens=%d, t=%.2fs）", _open_finder.tries, _open_finder.reopens, _open_finder.t))

		return
	end

	if _open_finder.t >= GROUP_FINDER_OPEN_TIMEOUT then
		finder_open_failed()
	end
end

-- 挂到下一帧再开（不在 promise 回调的帧内直接开）
local function request_group_finder_open()
	if not frame_hook_install() then
		-- 装不上钩子就退回原来的做法：直接开一次，成不成随它
		finder_open_step()

		return
	end

	_open_finder.pending = true
	_open_finder.t = 0
	_open_finder.next_try = 0
	_open_finder.tries = 0
	_open_finder.opened = false
	_open_finder.opened_t = nil
	_open_finder.reopens = 0
	_open_finder.log = {}
end

_tickers[#_tickers + 1] = finder_open_tick

-- 一键创建
local function create_group_advertise()
	local party = Managers.party_immaterium

	if not (party and party.start_party_finder_advertise) then
		mod:echo(mod:localize("err_no_service"))

		return
	end

	if not myself_in_hub() then
		mod:echo(mod:localize("group_not_in_hub"))

		return
	end

	-- 已经有招募了：不重复创建，直接把寻找队伍界面打开（用户 2026-09-14 定）
	if party.is_party_advertisement_active and party:is_party_advertisement_active() then
		-- 只是“已在进行中”的回显（界面会开出来），走调试开关
		echo_debug(mod:localize("group_already_advertising"))
		request_group_finder_open()

		return
	end

	local havoc = Managers.data_service.havoc

	if not (havoc and havoc.available_orders) then
		mod:echo(mod:localize("err_no_service"))

		return
	end

	local account_id = local_account_id()

	if not account_id then
		mod:echo(mod:localize("group_no_account"))

		return
	end

	local function advertise(config, tags, region)
		local call_ok, promise = pcall(function ()
			return party:start_party_finder_advertise(config, tags, region)
		end)

		if not call_ok or not promise then
			mod:echo(mod:localize("group_create_failed"))

			return
		end

		-- 创建过程的回显同样只是“回声”（成功与否看界面/失败提示），走调试开关
		echo_debug(mod:localize("group_creating", config.havoc_order_rank))

		promise:next(function ()
			echo_debug(mod:localize("group_created"))

			if mod:get("group_open_view_after_create") ~= false then
				request_group_finder_open()
			end
		end):catch(function (error)
			dump_group_error(error, config, tags, region)
			mod:echo(mod:localize("group_create_failed") .. " " .. error_text(error))
		end)
	end

	havoc:available_orders():next(function (orders)
		local order = orders and orders[1]
		local config, threshold_tag = build_advertise_payload(order, account_id)

		if not config then
			mod:echo(mod:localize("group_no_order"))

			return
		end

		local tags = { HAVOC_ORDER_TAG }

		if threshold_tag then
			tags[#tags + 1] = threshold_tag
		end

		resolve_region(function (region)
			expand_parent_tags(tags, function (final_tags)
				echo_debug("group tags = " .. table.concat(final_tags, ", "))
				advertise(config, final_tags, region)
			end)
		end)
	end):catch(function ()
		mod:echo(mod:localize("err_fetch_failed"))
	end)
end

-- ########################## 招募自检（/havocgroup check） ##########################
-- 「用命令挂的招募，别人在寻找队伍里找不到」有两种可能，看创建返回码分不出来：
--   A. 后端压根没存下这条招募（参数/前后置问题）
--   B. 存下了，但搜索条件不匹配（标签/地区筛选问题）
-- 这里用后端自己的列表接口回查：拿自己的 party_id 去问「(region, 空标签) 有哪些招募」，
-- 看自己在不在里面。走的是和寻找队伍界面完全相同的链路
-- （group_finder_view._start_advertisements_stream → grpc:party_finder_list_advertisements_stream）。

local VERIFY_SECONDS = 5

local _verify = { installed = false, active = false, t = 0 }

-- 自检输出落盘（与失败详情同目录，文件名区分）
local function dump_verify(text)
	dump_to_file("myhavoc_group_probe.txt", text)
end

-- 标签表原数据（名字 / rootTag / locked / 父标签）—— 核对「根父标签该不该加、加没加上」
local function verify_tag_lines()
	local lines = { "", "== group finder tags（* 是咱们用的） ==" }
	local list = _verify.tag_list

	if type(list) ~= "table" then
		lines[#lines + 1] = "(拿不到标签表)"

		return lines
	end

	local parents_map = {}

	for i = 1, #list do
		local tag = list[i]

		if type(tag) == "table" and type(tag.unlocks) == "table" then
			for j = 1, #tag.unlocks do
				local child = tag.unlocks[j]

				parents_map[child] = parents_map[child] or {}
				parents_map[child][#parents_map[child] + 1] = tag.name
			end
		end
	end

	lines[#lines + 1] = "tag count = " .. tostring(#list)

	for i = 1, #list do
		local tag = list[i]

		if type(tag) == "table" then
			local mine = tag.name == "my_havoc_order" or tag.name == "havoc_order_threshold_6"

			lines[#lines + 1] = string.format("%s%s | rootTag=%s locked=%s parents=%s", mine and "* " or "  ", tostring(tag.name), tostring(tag.rootTag), tostring(tag.locked), table.concat(parents_map[tag.name] or {}, ","))
		end
	end

	return lines
end

local function verify_write()
	local entries = _verify.entries or {}
	local mine = _verify.party_id
	local lines = {}
	local found = false

	lines[#lines + 1] = "myhavoc /havocgroup check 结果"
	lines[#lines + 1] = ""
	lines[#lines + 1] = "region          = " .. tostring(_verify.region)
	lines[#lines + 1] = "my party_id     = " .. tostring(mine)
	lines[#lines + 1] = "advertise_state = " .. error_text(_verify.state)
	lines[#lines + 1] = "list count      = " .. tostring(#entries)

	for i = 1, #entries do
		local entry = entries[i]
		local is_mine = entry.party_id == mine

		if is_mine then
			found = true
		end

		lines[#lines + 1] = string.format("[%d] party_id = %s%s", i, tostring(entry.party_id), is_mine and "   <<== 自己" or "")
		lines[#lines + 1] = "    tags = " .. table.concat(entry.tags or {}, ", ")

		local config = entry.config or {}
		local keys = {}

		for key in pairs(config) do
			keys[#keys + 1] = tostring(key)
		end

		table.sort(keys)

		for _, key in ipairs(keys) do
			lines[#lines + 1] = "    config." .. key .. " = " .. tostring(config[key])
		end
	end

	for _, line in ipairs(verify_tag_lines()) do
		lines[#lines + 1] = line
	end

	_verify.found = found
	dump_verify(table.concat(lines, "\n") .. "\n")
end

local function verify_tick(dt)
	if not _verify.active then
		return
	end

	_verify.t = _verify.t + (dt or 0)

	local ok, events = pcall(function ()
		return Managers.grpc:get_party_finder_list_advertisements_events(tostring(_verify.stream_id))
	end)

	if ok and type(events) == "table" then
		for i = 1, #events do
			local event = events[i]

			if type(event) == "table" and event.type == "advertisement_entries_update" and type(event.entries) == "table" then
				_verify.entries = event.entries
			end
		end
	end

	if _verify.t >= VERIFY_SECONDS then
		_verify.active = false

		pcall(function ()
			Managers.grpc:abort_operation(_verify.stream_id)
		end)
		verify_write()
		mod:echo(mod:localize(_verify.found and "verify_found" or "verify_missing", #(_verify.entries or {})))
	end
end

-- 计时全靠这个钩子：DMF 没有定时器 API，但自己就在 hook CLASS.InputManager.update
-- （dmf_hooks.lua L575），说明这个类在任何场景（枢纽站/任务中）都在每帧跑
local _verify_ticker_registered = false

-- 计时全靠公共每帧钩子（DMF 没有定时器 API；CLASS.InputManager.update 到处都是）
local function verify_install_hook()
	if not _verify_ticker_registered then
		_verify_ticker_registered = true
		_tickers[#_tickers + 1] = verify_tick
	end

	return frame_hook_install()
end

local function check_group_advertise()
	local party = Managers.party_immaterium

	if not (party and party.party_id) then
		mod:echo(mod:localize("err_no_service"))

		return
	end

	if not verify_install_hook() then
		mod:echo(mod:localize("verify_no_hook"))

		return
	end

	_verify.entries = nil
	_verify.tag_list = nil
	_verify.t = 0
	_verify.active = false
	_verify.party_id = party:party_id()
	_verify.state = party.advertise_state and party:advertise_state() or nil

	-- 顺便把标签表抓下来（能不能加根父标签看它）
	local social = Managers.data_service and Managers.data_service.social

	if social and social.get_group_finder_tags then
		local ok_tags, tags_promise = pcall(function ()
			return social:get_group_finder_tags()
		end)

		if ok_tags and tags_promise then
			tags_promise:next(function (data)
				_verify.tag_list = data and data.tags and data.tags.tags or nil

				verify_write()
			end)
		end
	end

	resolve_region(function (region)
		_verify.region = region

		local ok, promise, stream_id = pcall(function ()
			return Managers.grpc:party_finder_list_advertisements_stream(region, {})
		end)

		if not (ok and promise and stream_id) then
			mod:echo(mod:localize("verify_failed"))

			return
		end

		_verify.stream_id = stream_id
		_verify.active = true

		mod:echo(mod:localize("verify_started", VERIFY_SECONDS))
	end)
end

-- /havocgroup        按自己的浩劫订单创建组队房间
-- /havocgroup cancel 关闭自己的招募
-- /havocgroup check  回查后端列表里有没有自己的招募（诊断用）
local function run_havoc_group(...)
	local sub = parse_command_args(...)

	if sub == "" or sub == "create" then
		create_group_advertise()
	elseif sub == "cancel" then
		cancel_group_advertise()
	elseif sub == "check" then
		check_group_advertise()
	else
		-- 带上收到的参数：这样下一回截图/回话就能直接分清
		-- 「跑到用法分支了」还是「跑到别的分支/旧代码」
		mod:echo(mod:localize("usage_group", sub))
	end
end

mod:command("havocgroup", mod:localize("command_description_group"), run_havoc_group)
