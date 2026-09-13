# darktide-myhavoc

暗潮(Warhammer 40,000: Darktide)Mod:浩劫(Havoc)任务工具——`/havoc` 把自己的当前浩劫任务(层数、地图、词条)发到聊天展示给队友,`/havocstart` 一键开始自己的浩劫任务,`/havocgroup` 按订单创建组队房间。

> Darktide mod: `/havoc` sends your current Havoc order (rank, map, modifiers) to party chat; `/havocstart` quick-starts your own Havoc mission; `/havocgroup` creates a Group Finder room from your order.

## 功能 / Features

- 聊天命令 `/havoc`:把当前浩劫任务发到聊天(**时间戳** + 层数 + 地图 + 词条)
  (`/myhavoc` 为旧名,仍然可用,两者等价)
- 聊天命令 `/havocgroup`:**按自己的浩劫订单一键创建「寻找队伍」房间**(队友可直接申请加入;
  已经在招募中则不重复创建,直接打开界面;`/havocgroup cancel` 关闭)
- 聊天命令 `/havocstart`:一键开始自己的浩劫任务(激活订单 + 启动匹配,与浩劫面板「开始」同链路;已有进行中任务会提示先取消)
- **每局结束自动把浩劫订单发到聊天**(**仅浩劫局**;可在 DMF 设置里关；默认"订单没变就不重复发")
- 词条与地图名跟随游戏语言(中文客户端显示中文,英文显示英文)
- 需要 [Darktide Mod Framework (DMF)](https://github.com/Darktide-Mod-Framework/Darktide-Mod-Framework)

## 安装 / Install

1. 从 [Releases](https://github.com/CiJhuiDi/darktide-myhavoc/releases) 下载 zip
2. 解压 `myhavoc` 文件夹到游戏目录 `mods/` 下;或用 [DarktideModManager](https://github.com/CiJhuiDi/DarktideModManager) 直接导入 zip
3. 确认 `mods/mod_load_order.txt` 里有 `myhavoc` 这一行

## 使用 / Usage

游戏内按回车打开聊天栏,输入:

```
/havoc              # 发送自己的浩劫任务信息到聊天(旧名 /myhavoc 等价)
/havocstart         # 一键开始自己的浩劫任务
/havocgroup         # 按自己的浩劫订单创建组队房间(枢纽站内)
/havocgroup cancel  # 关闭自己的组队房间
/havocgroup check   # 回查后端招募列表(诊断用)
```

中文客户端示例输出:

```
[10:35] [浩劫] 第26层 | 德雷科定居点 | 通风净化、灯火管制
```

English example:

```
[10:35] [Havoc] Rank 26 | Hab Dreyko | Ventilation Purge, Lights Out
```

时间戳是发送时的本机时间(`HH:MM`);万一取不到时间会自动省略,不影响消息本体。

## 更新记录 / Changelog

- **v1.3.5**:新增 `/havocgroup`——按自己的浩劫订单**一键创建组队房间**(等价于在「寻找队伍」里勾选"我的浩劫订单"并开始招募)
- **v1.3.3**:`/myhavoc` 输出加时间戳(本机时间 `HH:MM`,取不到时自动省略);自动发送**限定为浩劫局**——此前打完普通任务也会播报自己的浩劫订单
- **v1.3.1**:本地回显并入「调试模式」开关(默认关):关掉后不再刷「已发送到聊天」「订单无变化」这类冗余提示,失败提示照常显示
- **v1.3.0**:新增"每局结束自动发送浩劫订单"(结算画面出现约 6 秒后发，等后端结算；可在设置里关闭，默认订单无变化不重复发)
- **v1.2.0**:`/havocstart` 补官方进场闸门——队友还在加载/不在枢纽站时拒绝开始(此前会把队友一起拉进任务,导致其客户端黑屏);新增 `/havocprobe` 诊断命令
- **v1.1.0**:新增 `/havocstart` 一键开始自己的浩劫任务(激活订单 + 启动匹配)
- **v1.0.0**:首个版本,`/myhavoc` 发送浩劫任务信息到聊天

## 鸣谢 / Credits

数据来源与渲染思路参考 Wobin 的开源项目 [Havoc Auspex](https://github.com/Wobin/HavocAuspex) / Havoc Auspex Transmitter。

## 许可 / License

MIT License —— 详见 [LICENSE](LICENSE)。
