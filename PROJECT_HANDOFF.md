# myhavoc · 项目交接摘要

> **给新会话的快速上手文档**：读完这个 + 通用规范（`暗潮\01-开发规范\Darktide-Mod开发规范.md`）即可接手。
> 最后更新：2026-08-18 01:05 | 当前版本：v1.1.0（已发布）

---

## 一、项目是什么

《战锤40K：暗潮》的浩劫(Havoc)任务工具 mod（DMF Lua mod）。聊天命令操作自己的浩劫任务：
- **`/myhavoc`**：把当前浩劫任务(层数/地图/词条)发到队伍聊天，向队友展示
- **`/havocstart`**（v1.1.0）：一键开始自己的浩劫任务（激活订单 + 启动匹配）

- **位置**：`D:\DeepseekWorkspace\暗潮\04-Mods\myhavoc\`（`myhavoc\` 子目录是 mod 本体）
- **仓库**：https://github.com/CiJhuiDi/darktide-myhavoc（v1.0.0 + v1.1.0 两个 Release，zip 在 release\）
- **状态**：✅ 已发布；`/havocstart` 待用户实机验证

## 二、文件结构

```
myhavoc/
├── myhavoc.mod                  # DMF 入口（version = "1.1.0"、author = "CiJhuiDi"）
├── README.md                    # 仓库门面（中英双语）
├── README.txt                   # 包内说明（中文）
├── 开发文档.md                  # 本 mod 开发细节
├── release\myhavoc_1.1.0.zip   # 发布包（gitignore）
└── scripts\mods\myhavoc\
    ├── myhavoc.lua              # 主逻辑（两个命令 + 数据 + 发送）
    ├── myhavoc_data.lua         # 元数据
    └── myhavoc_localization.lua # 多语言 en + zh-cn
```

## 三、实现要点

### 数据源（浩劫任务）

```lua
Managers.data_service.havoc:current_order()   -- Promise
-- order.rank            层数
-- order.blueprint.map   地图 id（mission_templates 的 key）
-- order.blueprint.flags 词条表，形如 "havoc-circ-<circumstance_id>"
```

- 词条显示名：`circumstance_templates[<id>].ui.display_name` → `Managers.localization:localize`（官方中文自动）
- settings 数据（mission_templates/circumstance_templates）在游戏 bundle 里，**反编译源码没有**，运行时 `pcall(require)` 加载

### 发送消息

```lua
Managers.chat:send_channel_message(channel_handle, text)
-- handle 从 Managers.chat:sessions() 遍历，channel.tag 是字符串
-- 优先级：PARTY → MISSION → HUB
```

### /havocstart 启动链路（v1.1.0）

对照游戏内浩劫面板「开始」按钮（`scripts/ui/views/havoc_play_view/havoc_play_view.lua` 的 `_cb_on_mission_start`，反编译在线仓库有 UI 层）：

```lua
-- 1. 拿可启动 mission id：有 ongoing_mission_id 直接复用，否则激活订单
order.ongoing_mission_id 或 svc:activate_havoc_mission(order.id)
-- 2. 启动匹配（公开 + 首选区域）
Managers.party_immaterium:wanted_mission_selected(mission.id, false, region)
-- region = Managers.data_service.region_latency:get_prefered_mission_region()
```

- 400 `already_has_ongoing_mission` 特判 → 提示「已有进行中的任务，请先取消」

### DMF 命令

`mod:command("myhavoc"/"havocstart", 描述, fn)` —— 玩家聊天栏 `/xxx` 触发；DMF 拦截命令原文，不会发出去。

## 四、踩坑/要点

- 本地化语言代码是 `zh-cn`（DMF 按 `Application.user_setting("language_id")` 匹配，缺省回落 en）
- 词条 flags 的键或值都可能是字符串，解析两种兼容
- 所有外部调用（promise/服务/发送）套 pcall 防崩
- 描述文本四处同步：localization / README.md / 开发文档 / Release 说明（改功能后别漏）

## 五、参考

- 数据/渲染思路：Wobin 的 Havoc Auspex / Havoc Auspex Transmitter（源码归档 `暗潮\99-临时文件\havoc_auspex_ref\`）
- 开发规范：`暗潮\01-开发规范\Darktide-Mod开发规范.md`
- 游戏源码：`暗潮\02-游戏源码\Darktide-Source-Code`（havoc_service.lua 等）；UI 层在线仓库 Aussiemon/Darktide-Source-Code

## 六、待办

- [ ] 用户实机验证 `/havocstart`（接订单 → 命令 → 开始匹配）
- [ ] 有问题则修 + bump + 发新 Release
