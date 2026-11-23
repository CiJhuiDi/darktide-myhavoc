myhavoc 1.3.7 - 浩劫任务 Mod(暗潮 Darktide)
================================================

功能
----
- 在聊天栏输入 /havoc,把当前浩劫(Havoc)任务发到聊天(带本机时间戳):
  层数、地图、词条。/myhavoc 为旧名,等价。
- 在聊天栏输入 /havocstart,一键开始自己的浩劫任务
  (激活订单 + 启动匹配,与浩劫面板"开始"按钮同链路)。
- 在聊天栏输入 /havocgroup,在枢纽站按自己的浩劫订单一键创建组队房间;
  /havocgroup cancel 关闭,/havocgroup check 回查房间有没有挂上。
- 在聊天栏输入 /havocregroup,退队并按自己的浩劫订单重建房间(枢纽站内)。
- 浩劫局胜利结束后,自动把当前订单发到聊天;可在 DMF 设置里关。
- 设置里的「调试模式」默认关闭:关闭时不显示「已发送到聊天」这类回显;
  失败提示始终显示。排查问题时打开它。

示例输出(中文客户端):
  [10:35] [浩劫] 第26层 | 德雷科定居点 | 通风净化、灯火管制

安装
----
方式一(DMM 管理器,推荐):
  1. 打开 Darktide Mod Manager
  2. 导入本 zip(myhavoc_1.3.7.zip)
  3. 在模组列表启用 myhavoc

方式二(手动):
  1. 解压,把 myhavoc 文件夹放进游戏目录 mods/ 下
  2. 确认 mods/mod_load_order.txt 里有 myhavoc 这一行(没有就手动加)

使用
----
  1. 进枢纽站(有浩劫订单后),按回车打开聊天栏
  2. /havoc 回车 → 把当前任务信息发到聊天
  3. /havocstart 回车 → 直接开始自己的浩劫任务(有进行中任务会提示先取消)
  4. /havocgroup 回车 → 按订单创建组队房间,并打开「寻找队伍」界面
  5. /havocregroup 回车 → 先退出当前队伍,再按订单重建房间(旧队友不会跟过来)

说明与限制
----------
- 需要有当前浩劫订单才有数据,没有时会提示"当前没有浩劫任务"
- 词条/地图名跟随游戏语言(中文客户端显示中文,英文显示英文)
- 发送频道:任务 > 队伍(仅在确实组队时) > 枢纽(大厅);组队时不会再默认发进大厅
- 队伍没有严格意义上的队长:/havocregroup 不判断身份,一律先退队再建新房
- /havocstart 与官方浩劫面板同规则:自己必须在枢纽站,有队友未就位会被拒绝
  (否则会把他一起拉进任务,导致其客户端黑屏);浩劫不自动匹配,至少需要 2 人
- 卸载:在 DMM 里删除,或删掉 mods/myhavoc 文件夹并移除 load order 行

技术说明
--------
- 数据来源:Managers.data_service.havoc:current_order()
- 词条:circumstance_templates 的 ui.display_name 本地化
- 发送:Managers.chat:send_channel_message
- 参考实现:Wobin 的 Havoc Auspex / Havoc Auspex Transmitter(开源)
