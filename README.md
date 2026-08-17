# darktide-myhavoc

Darktide mod: send your current Havoc order to chat with `/myhavoc`.

## Features

- Type `/myhavoc` in the in-game chat to post your current Havoc order — rank, map and modifiers — so your strike team can see it
- Sends to party chat first, falls back to mission chat, then hub chat
- Modifier and map names follow your game language (English / 中文)
- No active Havoc order? You get a friendly in-chat notice instead of a crash

## Requirements

- [Darktide Mod Framework](https://github.com/Darktide-Mod-Framework/Darktide-Mod-Framework) (DMF)

## Install

1. Download the zip from [Releases](../../releases)
2. Extract `myhavoc` into `<game>/mods/` — or import the zip with [DarktideModManager](https://github.com/CiJhuiDi/DarktideModManager)
3. Make sure `mods/mod_load_order.txt` contains a line with `myhavoc`

## Usage

Open the chat and type:

```
/myhavoc
```

Example output (Chinese client):

```
[浩劫] 第26层 | 德雷科定居点 | 通风净化、灯火管制
```

Example output (English client):

```
[Havoc] Rank 26 | Hab Dreyko | Ventilation Purge, Lights Out
```

## Credits

Data source and rendering approach inspired by [Havoc Auspex](https://github.com/Wobin/HavocAuspex) / Havoc Auspex Transmitter by Wobin.
