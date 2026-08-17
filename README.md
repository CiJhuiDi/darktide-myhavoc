# darktide-myhavoc

暗潮(Warhammer 40,000: Darktide)Mod:浩劫(Havoc)任务工具——`/myhavoc` 把自己的当前浩劫任务(层数、地图、词条)发到聊天展示给队友,`/havocstart` 一键开始自己的浩劫任务。

> Darktide mod: `/myhavoc` sends your current Havoc order (rank, map, modifiers) to party chat; `/havocstart` quick-starts your own Havoc mission.

## 功能 / Features

- 聊天命令 `/myhavoc`:把当前浩劫任务发到聊天(层数 + 地图 + 词条)
- 聊天命令 `/havocstart`:一键开始自己的浩劫任务(激活订单 + 启动匹配,与浩劫面板「开始」同链路;已有进行中任务会提示先取消)
- 词条与地图名跟随游戏语言(中文客户端显示中文,英文显示英文)
- 需要 [Darktide Mod Framework (DMF)](https://github.com/Darktide-Mod-Framework/Darktide-Mod-Framework)

## 安装 / Install

1. 从 [Releases](https://github.com/CiJhuiDi/darktide-myhavoc/releases) 下载 zip
2. 解压 `myhavoc` 文件夹到游戏目录 `mods/` 下;或用 [DarktideModManager](https://github.com/CiJhuiDi/DarktideModManager) 直接导入 zip
3. 确认 `mods/mod_load_order.txt` 里有 `myhavoc` 这一行

## 使用 / Usage

游戏内按回车打开聊天栏,输入:

```
/myhavoc        # 发送自己的浩劫任务信息到聊天
/havocstart     # 一键开始自己的浩劫任务
```

中文客户端示例输出:

```
[浩劫] 第26层 | 德雷科定居点 | 通风净化、灯火管制
```

English example:

```
[Havoc] Rank 26 | Hab Dreyko | Ventilation Purge, Lights Out
```

## 更新记录 / Changelog

- **v1.1.0**:新增 `/havocstart` 一键开始自己的浩劫任务(激活订单 + 启动匹配)
- **v1.0.0**:首个版本,`/myhavoc` 发送浩劫任务信息到聊天

## 鸣谢 / Credits

数据来源与渲染思路参考 Wobin 的开源项目 [Havoc Auspex](https://github.com/Wobin/HavocAuspex) / Havoc Auspex Transmitter。
