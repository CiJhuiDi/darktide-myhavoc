return {
    mod_name = {
        en      = "My Havoc",
        ["zh-cn"] = "我的浩劫",
    },
    mod_description = {
        en      = "Chat commands: /havoc send your current Havoc order (rank, map, modifiers) to chat; /havocstart quick-start it; /havocgroup create a Group Finder room.",
        ["zh-cn"] = "聊天命令：/havoc 把当前浩劫任务（层数、地图、词条）发到聊天；/havocstart 一键开始；/havocgroup 按订单创建组队房间。",
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
        en      = "{time}[Havoc] Rank {rank} | {map} | {mods}",
        ["zh-cn"] = "{time}[浩劫] 第{rank}层 | {map} | {mods}",
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
    err_party_not_ready = {
        en      = "[myhavoc] Not all party members are in the hub yet (someone may still be loading). Starting now would drag them into the mission and may black-screen their client. Wait for them to arrive.",
        ["zh-cn"] = "[myhavoc] 队伍还没就绪：有队友不在枢纽站（可能还在加载或正在任务中）。现在开始会把他们一起拉进任务，可能导致其客户端黑屏。等他们进枢纽后再试。",
    },
    err_party_not_eligible = {
        en      = "[myhavoc] Some party members are not eligible for Havoc; cannot start.",
        ["zh-cn"] = "[myhavoc] 队伍中有玩家不满足浩劫条件，无法开始。",
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
        en      = "Show local echo for redundant / automatic messages (e.g. \"sent to chat\", \"order unchanged\", \"room created\"). Error and usage messages are always shown.",
        ["zh-cn"] = "显示「已发送到聊天」「订单无变化」「房间已创建/已关闭」这类冗余/自动回显。失败提示与用法提示始终显示，不受此开关影响。",
    },
    auto_send_not_havoc = {
        en      = "[myhavoc] Not a Havoc mission; auto-send skipped.",
        ["zh-cn"] = "[myhavoc] 本局不是浩劫任务，自动发送已跳过。",
    },
    command_description_group = {
        en      = "Create a Group Finder room from your Havoc order (args: cancel / check)",
        ["zh-cn"] = "按自己的浩劫订单创建组队房间（可选参数：cancel 关闭 / check 回查）",
    },
    group_creating = {
        en      = "[myhavoc] Creating a Group Finder room for Havoc rank %s...",
        ["zh-cn"] = "[myhavoc] 正在按浩劫第 %s 层创建组队房间…",
    },
    group_created = {
        en      = "[myhavoc] Group Finder room created.",
        ["zh-cn"] = "[myhavoc] 组队房间已创建。",
    },
    group_create_failed = {
        en      = "[myhavoc] Failed to create the room:",
        ["zh-cn"] = "[myhavoc] 创建组队房间失败：",
    },
    group_already_advertising = {
        en      = "[myhavoc] You are already recruiting; opened the Group Finder view (use /havocgroup cancel to close it).",
        ["zh-cn"] = "[myhavoc] 你已经在招募中，已为你打开寻找队伍界面（用 /havocgroup cancel 关闭）。",
    },
    group_cancelled = {
        en      = "[myhavoc] Group Finder room closed.",
        ["zh-cn"] = "[myhavoc] 组队房间已关闭。",
    },
    group_cancel_failed = {
        en      = "[myhavoc] Failed to close the room.",
        ["zh-cn"] = "[myhavoc] 关闭组队房间失败。",
    },
    group_no_order = {
        en      = "[myhavoc] No usable Havoc order found.",
        ["zh-cn"] = "[myhavoc] 没有找到可用的浩劫订单。",
    },
    group_no_account = {
        en      = "[myhavoc] Could not read your account id.",
        ["zh-cn"] = "[myhavoc] 读不到你的账号 id。",
    },
    group_not_in_hub = {
        en      = "[myhavoc] You must be in the hub to create a room.",
        ["zh-cn"] = "[myhavoc] 需要在枢纽站才能创建组队房间。",
    },
    group_open_view_after_create = {
        en      = "Open Group Finder after creating",
        ["zh-cn"] = "创建后自动打开寻找队伍界面",
    },
    group_open_view_after_create_description = {
        en      = "After /havocgroup creates the room, open the Group Finder view so you can watch join requests.",
        ["zh-cn"] = "/havocgroup 创建房间后自动打开「寻找队伍」界面，方便看入队申请。",
    },
    group_open_view_failed = {
        en      = "[myhavoc] Room created, but the Group Finder view could not be opened (you can open it manually).",
        ["zh-cn"] = "[myhavoc] 房间已创建，但「寻找队伍」界面没打开（可以手动开）。",
    },
    verify_started = {
        en      = "[myhavoc] Querying the backend room list... (%s s)",
        ["zh-cn"] = "[myhavoc] 正在向后端回查招募列表…（%s 秒后出结果）",
    },
    verify_found = {
        en      = "[myhavoc] Check done: your room IS in the backend list (%s rooms).",
        ["zh-cn"] = "[myhavoc] 回查完成：后端列表里【有】你的招募（共 %s 条）。",
    },
    verify_missing = {
        en      = "[myhavoc] Check done: your room is NOT in the backend list (%s rooms).",
        ["zh-cn"] = "[myhavoc] 回查完成：后端列表里【没有】你的招募（共 %s 条）。",
    },
    verify_failed = {
        en      = "[myhavoc] Check failed: could not open the room list.",
        ["zh-cn"] = "[myhavoc] 回查失败：列表接口调用出错。",
    },
    verify_no_hook = {
        en      = "[myhavoc] Check failed: could not install the timer hook.",
        ["zh-cn"] = "[myhavoc] 回查失败：装不上计时钩子。",
    },
    usage_send = {
        en      = "[myhavoc] /havoc takes no arguments (same as /myhavoc).",
        ["zh-cn"] = "[myhavoc] /havoc 不需要参数（与 /myhavoc 相同）。",
    },
    usage_start = {
        en      = "[myhavoc] /havocstart takes no arguments.",
        ["zh-cn"] = "[myhavoc] /havocstart 不需要参数。",
    },
    usage_group = {
        en      = "[myhavoc] Unknown option \"%s\". Usage: /havocgroup [cancel | check]",
        ["zh-cn"] = "[myhavoc] 未知参数「%s」。用法：/havocgroup [cancel | check]（cancel 关闭招募，check 回查列表）",
    },
}
