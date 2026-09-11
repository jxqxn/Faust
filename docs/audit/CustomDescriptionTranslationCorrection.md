# 剧情描述键与详情显示（第十七批，2026-09-10）

接续第十六批。原作ChangeCardName同一操作类同时处理name/text；本批将克隆的描述分支接入同一注册、保存、翻译链，不再直接保存展开文字。

## 原作依据

- ChangeCardName构造0x4f2a30组装 `change_card_<类型>_<片段>`；stringliteral.json 0x259a4e0=text。PreDo闭包0x5089e0的text分支调用Card.set_custom_text，参数为已注册键。
- Datapool.BuildCustomText0x40d400 / MergeCustomTextToDefaultLanguage0x417dc0与上批为同一表。当前原配置有28处描述定义、28唯一描述键，无冲突；加上12处/10唯一名称键，共40处/38键。
- CardInfoNewController.Show0x537000（443起）先检查Card.custom_text@0x58：非空则直接Common.Translate，空才读取CardNode.text；之后ProcessPlaceholders。独立字段证据dump.cs:389609，Show签名dump.cs:317628。
- 与GetName不同，这里**没有**“译文等于键则回退”的分支。未知描述键要保留其原字符串。

## 实现

ConfigDB的名称专用表合并为custom_card_translates，键构造与递归登记函数扩展为name/text共用。均是原content的运行时索引，没有新增或改写内容配置。

Result槽位及既有table/total描述入口改写原键；GameState保存完整custom_text，不Trim；详情所取card_data_for在非空custom_text时翻译，然后沿现有详情占位符处理。未知键原样返回，空字符串回退配置正文。

## 验证

- card_evolution17测试/114断言：原作键写入、名称/描述共存、描述键存读档、未知键与名称不同的回退规则、空白保留、空值恢复配置正文。
- 原存档导入桥6测试/83断言（含真实auto_save样本），UI81测试/1073断言。共104测试/1270断言；最终日志无ERROR、SCRIPT ERROR、ObjectDB泄漏或orphan报告。
- verify_card_text_translation.gd：从存档恢复原名称/描述键，打开生产CardInfoView，核对正文译文。1280×720和1920×1080均PASS；截图card_text_translation_preferred_1280.png / 1920.png，已查看1280截图。此为克隆运行验证，不代表原机同帧像素验收。

## 仍待核实

table/total/槽位操作的完整目标选择、复制演出、当前语言/Mod/通用UI翻译键，以及ProcessPlaceholders完整语义仍开放。本批未把描述核验外推为这些链已经等价。沿用旧克隆存档的字面描述会因翻译未命中而保留原文；无需将它猜测成某个原作键。
