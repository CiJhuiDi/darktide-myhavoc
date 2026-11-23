return {
    mod_name = {
        en      = "My Havoc",
        ["zh-cn"] = "我的浩劫",
    },
    mod_description = {
        en      = "Chat commands: /havoc sends your current Havoc order (rank, map, modifiers) to chat; /havocstart quick-starts it; /havocgroup creates a Group Finder room.",
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
        en      = "Sent to chat:",
        ["zh-cn"] = "已发送到聊天：",
    },
    err_no_service = {
        en      = "Havoc service unavailable.",
        ["zh-cn"] = "浩劫服务不可用。",
    },
    err_fetch_failed = {
        en      = "Failed to fetch Havoc order.",
        ["zh-cn"] = "获取浩劫任务失败。",
    },
    err_no_order = {
        en      = "You have no active Havoc order.",
        ["zh-cn"] = "当前没有浩劫任务。",
    },
    err_no_chat = {
        en      = "Chat is unavailable.",
        ["zh-cn"] = "聊天不可用。",
    },
    err_no_channel = {
        en      = "No chat channel available.",
        ["zh-cn"] = "没有可用的聊天频道。",
    },
    err_send_failed = {
        en      = "Failed to send message.",
        ["zh-cn"] = "消息发送失败。",
    },
    started = {
        en      = "Havoc mission started!",
        ["zh-cn"] = "浩劫任务已开始！",
    },
    err_activate_failed = {
        en      = "Failed to activate Havoc order.",
        ["zh-cn"] = "激活浩劫订单失败。",
    },
    err_ongoing_mission = {
        en      = "You have an ongoing mission, cancel it first.",
        ["zh-cn"] = "已有进行中的任务，请先取消。",
    },
    err_start_failed = {
        en      = "Failed to start the mission.",
        ["zh-cn"] = "启动任务失败。",
    },
    err_party_not_ready = {
        en      = "Not everyone is in the hub yet; starting now would pull them into the mission.",
        ["zh-cn"] = "还有队友未进入枢纽站，现在开始会把他们一起拉进任务。",
    },
    err_party_not_eligible = {
        en      = "Some party members are not eligible for Havoc; cannot start.",
        ["zh-cn"] = "队伍中有玩家不满足浩劫条件，无法开始。",
    },
    err_party_too_small = {
        en      = "Not enough players: Havoc needs at least %d (you have %d).",
        ["zh-cn"] = "人数不够：浩劫至少需要 %d 人（当前 %d 人）。",
    },
    auto_send_after_mission = {
        en      = "Auto-send order after each mission",
        ["zh-cn"] = "每局结束后自动发送浩劫订单",
    },
    auto_send_after_mission_description = {
        en      = "After a Havoc mission ends in victory, send your current Havoc order to chat automatically.",
        ["zh-cn"] = "浩劫任务胜利后，自动把当前浩劫订单发到聊天。",
    },
    debug_mode = {
        en      = "Debug mode (verbose echo)",
        ["zh-cn"] = "调试模式（回显）",
    },
    debug_mode_description = {
        en      = "Show automatic echoes such as \"sent to chat\" and \"order unchanged\". Errors and usage hints are always shown.",
        ["zh-cn"] = "显示「已发送到聊天」「订单无变化」这类自动回显。错误与用法提示始终显示。",
    },
    auto_send_not_victory = {
        en      = "Mission failed; order broadcast skipped.",
        ["zh-cn"] = "本局失败，已跳过订单播报。",
    },
    auto_send_not_havoc = {
        en      = "Not a Havoc mission; auto-send skipped.",
        ["zh-cn"] = "本局不是浩劫任务，自动发送已跳过。",
    },
    command_description_group = {
        en      = "Create a Group Finder room from your Havoc order (cancel / check)",
        ["zh-cn"] = "按自己的浩劫订单创建组队房间（cancel / check）",
    },
    command_description_regroup = {
        en      = "Leave the current party and rebuild your Havoc room",
        ["zh-cn"] = "退队并按自己的浩劫订单重建房间",
    },
    regroup_leaving = {
        en      = "Leaving the current party...",
        ["zh-cn"] = "正在退出当前队伍…",
    },
    regroup_rebuilding = {
        en      = "Rebuilding the Havoc room...",
        ["zh-cn"] = "正在重建浩劫房间…",
    },
    regroup_busy = {
        en      = "Regroup is already in progress.",
        ["zh-cn"] = "重建流程正在进行中，稍等。",
    },
    regroup_leave_failed = {
        en      = "Failed to leave the party.",
        ["zh-cn"] = "退出队伍失败。",
    },
    group_creating = {
        en      = "Creating a Group Finder room for Havoc rank %s...",
        ["zh-cn"] = "正在按浩劫第 %s 层创建组队房间…",
    },
    group_created = {
        en      = "Group Finder room created.",
        ["zh-cn"] = "组队房间已创建。",
    },
    group_create_failed = {
        en      = "Failed to create the room:",
        ["zh-cn"] = "创建组队房间失败：",
    },
    group_already_advertising = {
        en      = "You are already recruiting; opened the Group Finder view (use /havocgroup cancel to close it).",
        ["zh-cn"] = "你已经在招募中，已为你打开寻找队伍界面（/havocgroup cancel 关闭）。",
    },
    group_cancelled = {
        en      = "Group Finder room closed.",
        ["zh-cn"] = "组队房间已关闭。",
    },
    group_cancel_failed = {
        en      = "Failed to close the room.",
        ["zh-cn"] = "关闭组队房间失败。",
    },
    group_no_order = {
        en      = "No usable Havoc order found.",
        ["zh-cn"] = "没有找到可用的浩劫订单。",
    },
    group_no_account = {
        en      = "Could not read your account id.",
        ["zh-cn"] = "无法读取账号信息。",
    },
    group_not_in_hub = {
        en      = "You must be in the hub to create a room.",
        ["zh-cn"] = "需要在枢纽站才能创建组队房间。",
    },
    group_party_full = {
        en      = "Your party is full (4/4); recruiting is not available.",
        ["zh-cn"] = "队伍已满（4/4），无法发起招募。",
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
        en      = "Room created, but the Group Finder view could not be opened.",
        ["zh-cn"] = "房间已创建，但没能打开「寻找队伍」界面。",
    },
    verify_started = {
        en      = "Checking the room list... (%s s)",
        ["zh-cn"] = "正在回查招募列表…（%s 秒）",
    },
    verify_found = {
        en      = "Check done: your room is listed (%s rooms).",
        ["zh-cn"] = "回查完成：列表中有你的招募（共 %s 条）。",
    },
    verify_missing = {
        en      = "Check done: your room is NOT listed (%s rooms).",
        ["zh-cn"] = "回查完成：列表中没有你的招募（共 %s 条）。",
    },
    verify_failed = {
        en      = "Check failed: could not open the room list.",
        ["zh-cn"] = "回查失败：无法获取招募列表。",
    },
    verify_no_hook = {
        en      = "Check failed: could not install the timer hook.",
        ["zh-cn"] = "回查失败：无法安装计时钩子。",
    },
    usage_send = {
        en      = "/havoc takes no arguments (same as /myhavoc).",
        ["zh-cn"] = "/havoc 不需要参数（与 /myhavoc 相同）。",
    },
    usage_start = {
        en      = "/havocstart takes no arguments.",
        ["zh-cn"] = "/havocstart 不需要参数。",
    },
    usage_group = {
        en      = "Unknown option \"%s\". Usage: /havocgroup [cancel | check]",
        ["zh-cn"] = "未知参数「%s」。用法：/havocgroup [cancel | check]",
    },
    usage_regroup = {
        en      = "/havocregroup takes no arguments.",
        ["zh-cn"] = "/havocregroup 不需要参数。",
    },
}
