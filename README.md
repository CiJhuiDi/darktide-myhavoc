# darktide-myhavoc

暗潮(Warhammer 40,000: Darktide)Mod:在游戏聊天栏输入 `/myhavoc`,把自己的当前浩劫(Havoc)任务——**层数、地图、词条**——发送到聊天,方便向队友展示。

> Darktide mod: type `/myhavoc` in chat to send your current Havoc order (rank, map, modifiers) to your strike team.

## 功能 / Features

- 聊天命令 `/myhavoc`:一键把当前浩劫任务发到聊天(层数 + 地图 + 词条)
- 发送优先级:队伍聊天 → 任务聊天 → 枢纽聊天
- 词条与地图名跟随游戏语言(中文客户端显示中文,英文显示英文)
- 没有浩劫任务时给出友好提示,不会崩
- 需要 [Darktide Mod Framework (DMF)](https://github.com/Darktide-Mod-Framework/Darktide-Mod-Framework)

## 安装 / Install

1. 从 [Releases](https://github.com/CiJhuiDi/darktide-myhavoc/releases) 下载 zip
2. 解压 `myhavoc` 文件夹到游戏目录 `mods/` 下;或用 [DarktideModManager](https://github.com/CiJhuiDi/DarktideModManager) 直接导入 zip
3. 确认 `mods/mod_load_order.txt` 里有 `myhavoc` 这一行

## 使用 / Usage

游戏内按回车打开聊天栏,输入:

```
/myhavoc
```

中文客户端示例输出:

```
[浩劫] 第26层 | 德雷科定居点 | 通风净化、灯火管制
```

English example:

```
[Havoc] Rank 26 | Hab Dreyko | Ventilation Purge, Lights Out
```

## 鸣谢 / Credits

数据来源与渲染思路参考 Wobin 的开源项目 [Havoc Auspex](https://github.com/Wobin/HavocAuspex) / Havoc Auspex Transmitter。
