# 改名状态域与持久化纠偏（第十五批，2026-09-10）

接续 RenameValidationCorrection.md 的状态域缺口，修正 A08 的提交链，而非只改变卡面文字。

## 原作方法与独立信号

- ChangeName.c Do0x4f30e0直接把value@0x18传给GameController.ShowChangeName；没有查询手牌/仪式槽或要求实例存在。
- PromptChangeNameController.c Show0x585890：目标0绑定GetPlayerName/SetPlayerName，其余绑定GetSpecialCardName/SetSpecialCardName。SetPlayerName0x585530直接写Player.name@0x20；SetSpecialCardName0x585600写player_card_name@0x170，以配置id为键，不Trim。
- dump.cs:391488 Player字段、原save_samples/auto_save.json的name、player_card_name独立支持两个持久化域。
- CardExtensions.c GetName0x37ff50 / 0x3801b0：配置id表优先，随后custom_name和CardNode名称路径。CardNode路径对定义的player标签查Player.name。stringliteral.json地址0x25828f8值为player；content/tag.json code=player/name=主角；content/cards.json的2000001含主角标签。当前改动使用定义标签，未把玩家名条件扩大到运行时新增标签。
- GetPlayerName0x584a20：已有Player.name则直接返回；否则从player.cards选HasTag(player)者的配置名，无匹配取配置2000001。独立谓词源码PromptChangeNameController.__c.c 0x59fc10。

## 实现

1. Result._queue_change_name保留原card_id，不再寻找UID、因没有卡而跳过。0目标同样进入提示队列。
2. GameState新增player_display_name，对应Player.name；set_prompt_name按0/配置id分派。配置id名保留原字符串，不再strip_edges；实例custom_name不被提示改名覆盖。
3. GameScreen消费时使用payload.card_id。旧克隆存档的待处理提示缺card_id时，才从旧UID恢复配置id；新操作不走该兼容路径。
4. 提示初始名称取各自原域；配置id覆盖作用于已有及未来生成的同id卡。定义具有主角标签、且没有更高优先名称时，显示Player.name。
5. 玩家名进入SaveSystem序列化/反序列化，以及OriginalSaveImporter导入与同瞬间diff；缺新字段的旧存档默认空字符串。新局清空玩家名和配置id卡名，避免沿用上一局。

## 验证

- card_evolution：15测试/96断言；包括无卡也排队、目标0、同id多实例、未来生成、保留空格、配置id表高于玩家名、待处理提示随存档恢复和新局清空。
- 原存档导入桥：6测试/83断言，含语料auto_save真实样本，name新增同瞬间比较。name不再报告DROPPED。
- UI完整回归：81测试/1073断言。合计102测试/1252断言；最终日志无引擎错误、orphan或泄漏报告。
- verify_rename_state_input.gd：1280×720、1920×1080实际输入带空格的名称、点击确认、检查两个同id实例和序列化恢复后的新卡，均PASS。截图rename_state_preferred_1280.png / 1920.png是克隆实机证据，不冒充原机同帧。

## 保留的未完成项

禁词资源解密/MaskWordsHelper、Cancel与手柄流程、TMP及Full背景仍开放。Card.custom_name在原作中是可翻译键，GetName仅在翻译有效时采用；克隆现有直接显示custom_name行为未在本批改动。Player.NotifyPlayerNameChanged下游其他文字占位/通知消费者尚未全链审计。不得将本批读写边界视为所有名称格式化与所有页面都已完成。
