return {
    mod_name = {
        en      = "My Havoc",
        ["zh-cn"] = "我的浩劫",
    },
    mod_description = {
        en      = "Send your current Havoc order (rank, map and modifiers) to party chat with /myhavoc, and quick-start it with /havocstart.",
        ["zh-cn"] = "聊天命令：/myhavoc 把自己的当前浩劫任务（层数、地图、词条）发到队伍聊天；/havocstart 一键开始自己的浩劫任务。",
    },
    command_description = {
        en      = "Send your current Havoc order to chat.",
        ["zh-cn"] = "把自己的当前浩劫任务（层数、地图、词条）发到聊天。",
    },
    command_description_start = {
        en      = "Quick-start your own Havoc mission (activate order + start matchmaking).",
        ["zh-cn"] = "快速开始自己的浩劫任务（激活订单并开始匹配）。",
    },
    msg_havoc_order = {
        en      = "[Havoc] Rank {rank} | {map} | {mods}",
        ["zh-cn"] = "[浩劫] 第{rank}层 | {map} | {mods}",
    },
    sent = {
        en      = "[myhavoc] Sent to chat:",
        ["zh-cn"] = "[myhavoc] 已发送到聊天:",
    },
    err_no_service = {
        en      = "[myhavoc] Havoc service unavailable.",
        ["zh-cn"] = "[myhavoc] 浩劫服务不可用。",
    },
    err_fetch_failed = {
        en      = "[myhavoc] Failed to fetch Havoc order.",
        ["zh-cn"] = "[myhavoc] 获取浩劫任务失败。",
    },
    err_no_order = {
        en      = "[myhavoc] You have no active Havoc order.",
        ["zh-cn"] = "[myhavoc] 当前没有浩劫任务。",
    },
    err_no_chat = {
        en      = "[myhavoc] Chat is unavailable.",
        ["zh-cn"] = "[myhavoc] 聊天不可用。",
    },
    err_no_channel = {
        en      = "[myhavoc] No chat channel available.",
        ["zh-cn"] = "[myhavoc] 没有可用的聊天频道。",
    },
    err_send_failed = {
        en      = "[myhavoc] Failed to send message.",
        ["zh-cn"] = "[myhavoc] 消息发送失败。",
    },
    started = {
        en      = "[myhavoc] Havoc mission started!",
        ["zh-cn"] = "[myhavoc] 浩劫任务已开始！",
    },
    err_activate_failed = {
        en      = "[myhavoc] Failed to activate Havoc order.",
        ["zh-cn"] = "[myhavoc] 激活浩劫订单失败。",
    },
    err_ongoing_mission = {
        en      = "[myhavoc] You have an ongoing mission, cancel it first.",
        ["zh-cn"] = "[myhavoc] 已有进行中的任务，请先取消。",
    },
    err_start_failed = {
        en      = "[myhavoc] Failed to start the mission.",
        ["zh-cn"] = "[myhavoc] 启动任务失败。",
    },
    command_description_probe = {
        en      = "[diagnostic] Dump Havoc config and the raw backend settings response to a file.",
        ["zh-cn"] = "【诊断】把浩劫配置与后端原始返回 dump 到文件。",
    },
    probe_written = {
        en      = "[myhavoc] Probe written to %s",
        ["zh-cn"] = "[myhavoc] 探针已写入 %s",
    },
    probe_write_failed = {
        en      = "[myhavoc] Could not write probe file: %s",
        ["zh-cn"] = "[myhavoc] 探针写文件失败：%s",
    },
    probe_no_io = {
        en      = "[myhavoc] Sandbox io/os unavailable; probe aborted.",
        ["zh-cn"] = "[myhavoc] 拿不到沙箱 io/os，探针中止。",
    },
    probe_hs_keys = {
        en      = "[myhavoc] HavocSettings top-level keys: %s",
        ["zh-cn"] = "[myhavoc] HavocSettings 顶层 key：%s",
    },
    err_party_not_ready = {
        en      = "[myhavoc] Not all party members are in the hub yet (someone may still be loading). Starting now would drag them into the mission and may black-screen their client. Wait for them to arrive.",
        ["zh-cn"] = "[myhavoc] 队伍还没就绪：有队友不在枢纽站（可能还在加载或正在任务中）。现在开始会把他们一起拉进任务，可能导致其客户端黑屏。等他们进枢纽后再试。",
    },
    err_party_not_eligible = {
        en      = "[myhavoc] Some party members are not eligible for Havoc; cannot start.",
        ["zh-cn"] = "[myhavoc] 队伍中有玩家不满足浩劫条件，无法开始。",
    },
    probe_orders = {
        en      = "[myhavoc] available_orders: %d order(s) / %d map(s) / %d modifier(s)",
        ["zh-cn"] = "[myhavoc] available_orders：%d 条订单 / 地图 %d 张 / 词条 %d 条",
    },
    err_party_too_small = {
        en      = "[myhavoc] Not enough players: Havoc needs at least %d (you have %d).",
        ["zh-cn"] = "[myhavoc] 人数不够：浩劫至少需要 %d 人（当前 %d 人）。浩劫不会自动匹配，先组好队再来。",
    },
    auto_send_after_mission = {
        en      = "Auto-send order after each mission",
        ["zh-cn"] = "每局结束后自动发送浩劫订单",
    },
    auto_send_after_mission_description = {
        en      = "After a mission ends, send your current Havoc order to chat automatically. The end screen is used to wait ~6 seconds so the backend can settle the new order; if you leave it earlier, the order is sent immediately.",
        ["zh-cn"] = "每局结束后自动把当前浩劫订单发到聊天。结算画面出现后约等 6 秒再发（等后端结算新订单）；提前离开结算画面则立刻发。",
    },
    auto_send_only_if_changed = {
        en      = "Only send when the order changed",
        ["zh-cn"] = "仅在订单变化时发送",
    },
    auto_send_only_if_changed_description = {
        en      = "Skip sending when rank / map / modifiers are identical to the last order sent this session. Avoids repeating the same order into party chat every game.",
        ["zh-cn"] = "订单内容（层数 / 地图 / 词条）与本次会话上次发送的相同就跳过，避免每局都刷同一份订单。",
    },
    auto_send_unchanged = {
        en      = "[myhavoc] Order unchanged; not sent again.",
        ["zh-cn"] = "[myhavoc] 订单无变化，未重复发送。",
    },
    debug_mode = {
        en      = "Debug mode (verbose echo)",
        ["zh-cn"] = "调试模式（回显）",
    },
    debug_mode_description = {
        en      = "Show local echo for redundant / automatic messages (e.g. \"sent to chat\", \"order unchanged\"). Errors and explicit command feedback are always shown.",
        ["zh-cn"] = "显示「已发送到聊天」「订单无变化」这类冗余/自动回显。失败提示与手动命令的反馈不受此开关影响，始终显示。",
    },
}
