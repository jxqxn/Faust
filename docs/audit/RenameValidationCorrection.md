# 改名输入校验与确认边界（第十四批，2026-09-10）

从 A08 第十三批发现继续实施。原作证据为 `PromptChangeNameController.c` IsValidName0x584de0 / OnNameChanged0x585450 / OnNameSubmit0x585490 / OnConfirm0x585000，独立信号为 `dump.cs:323419` 控制器字段/签名、`dump.cs:361469` TMP_InputField类，以及 PromptChangeName.prefab m_CharacterLimit=0 和 `content/ui.json` ILLEGAL_NAME。

## 已修边界

- 输入框不再硬截断20字符。控制器以 UTF-16 单元计长度：十个非BMP表情=20，追加一个ASCII字符即无效。
- 每次文字变化重新设置Confirm可用性。程序设初始值和清空同样生效。空串禁用并清提示；超长字符串禁用并读取原ILLEGAL_NAME文案。
- 原 String.IsNullOrEmpty 不等于Trim；表面层提交原字符串，不再strip_edges。
- 原OnNameSubmit只将选择移至Confirm。克隆Enter不再直接提交；第二次操作确认按钮才触发submitted。
- 原OnConfirm中Input+0x260已由dump核为m_AllowInput。克隆在输入仍有编辑焦点时拒绝确认；真实鼠标点击先转移焦点再确认。

## 验证

专用测试5项/42断言、UI81项/1073断言，共86项/1115断言通过。最终日志检查无SCRIPT ERROR、ERROR、ObjectDB泄漏、orphan报告。曾因GUT断言的第4参数误传说明文字导致测试内部报错而总计仍显示通过；已纠正调用并重跑，最终数字只取日志干净的结果。

1280×720及1920×1080实际输入：输入A、按下/释放Enter后只选中Confirm且未提交，再点击确认，取消及共用确认框流程均PASS。使用 `tools/verify_prompt_preferred_layout.gd`，日志 `approximation-rename-validation-{1280,1920}.log`。

## 原始存储链仍有偏差，不算整链完成

本次继续打开 `ChangeName.c` Do0x4f30e0、`PromptChangeNameController.c` Show0x585890、SetPlayerName0x585530、SetSpecialCardName0x585600：

1. `ChangeName.Do`直接把操作value@0x18传给ShowChangeName。Show中value=0走Player.name@0x20；非零走Player.player_card_name@0x170按配置ID覆盖。Show无必须找到某张手牌UID的门。
2. 克隆 `_queue_change_name` 先查实例UID，未找到直接返回；payload未保存card_id。GameScreen消费再调用set_card_custom_name，仅写单实例。这是独立的状态域偏差，会影响同ID多张牌及未来新生成牌，下一批必须修调用链，不能只在UI设置一次显示名。
3. `GameState.set_card_custom_name`仍Trim/截断32；`set_player_card_name`仍Trim；Player.name目前由原存档导入器明确列为DROPPED。表面层保留空格的测试不能外推到持久化。
4. HasBanWords仍未迁：Datapool.LoadBanWords0x4145c0读取资源、AES解密后初始化MaskWordsHelper；HasBanWords0x4131c0调用该对象HasMaskWord。不得以本批长度通过替代禁词判定；本批未新增词表或转换配置。
5. Show还将Cancel对象禁用（后续取消/关闭及手柄链待联合核实）。当前取消能力不是本批已验证原作等价行为。

剩余输入ColorTint、TMP文本渲染和Full背景边界沿用第十三批留档。原机同帧及完整输入法生命周期未验收。
