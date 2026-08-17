myhavoc 1.1.0 - 浩劫任务 Mod(暗潮 Darktide)
================================================

功能
----
- 在聊天栏输入 /myhavoc,把自己的当前浩劫(Havoc)任务信息发送到聊天,
  方便向队友展示:层数、地图、词条。
- 在聊天栏输入 /havocstart,一键快速开始自己的浩劫任务
  (激活订单 + 启动匹配,与浩劫面板"开始"按钮同链路)。

示例输出(中文客户端):
  [浩劫] 第26层 | 德雷科定居点 | 通风净化、灯火管制

安装
----
方式一(DMM 管理器,推荐):
  1. 打开 Darktide Mod Manager
  2. 导入本 zip(myhavoc_1.0.0.zip)
  3. 在模组列表启用 myhavoc

方式二(手动):
  1. 解压,把 myhavoc 文件夹放进游戏目录 mods/ 下
  2. 确认 mods/mod_load_order.txt 里有 myhavoc 这一行(没有就手动加)

使用
----
  1. 游戏内进入枢纽站(接了浩劫任务后)
  2. 按回车打开聊天栏,输入 /myhavoc 回车 → 消息会发到队伍聊天(发自己任务信息)
  3. 输入 /havocstart 回车 → 直接开始自己的浩劫任务(有进行中任务会提示先取消)
  4. 本地会收到 [myhavoc] 已发送/已开始 的反馈

说明与限制
----------
- 需要有"当前浩劫任务"(每天刷新的浩劫订单)才有数据;
  没有时会提示"当前没有浩劫任务"
- 词条/地图名跟随游戏语言(中文客户端显示中文,英文显示英文)
- 发送频道优先级:队伍(PARTY) > 任务(MISSION) > 枢纽(HUB)
- 卸载:在 DMM 里删除,或删掉 mods/myhavoc 文件夹并移除 load order 行

技术说明
--------
- 数据来源:Managers.data_service.havoc:current_order()
- 词条:circumstance_templates 的 ui.display_name 本地化
- 发送:Managers.chat:send_channel_message
- 参考实现:Wobin 的 Havoc Auspex / Havoc Auspex Transmitter(开源)
