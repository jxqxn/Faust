# 剧情改名键及默认译文纠偏（第十六批，2026-09-10）

A08前批区分了玩家输入和剧情名称。本批修复剧情改名将显示文字直接写进Card.custom_name的近似；保留原content不变。

## 事实与来源

- ChangeCardName.c构造函数0x4f2a30：字段0x20拼接 `change_card_` + 类型name + `_` + 操作唯一片段。三个字符串由stringliteral.json地址0x2595cb0/0x25794c0/0x257f458确认。不是完整带选择器的DSL键。
- 同构造调用Common.AddCustomCardText0x384290，注册该键及SingleValue<string>操作对象；PreDo闭包ChangeCardName.__c__DisplayClass6_0.c 0x5089e0将0x20键写入Card.custom_name，随后复制卡演出链另行处理。
- Datapool.BuildCustomText0x40d400将注册列表转为custom_card_text，重复相同值可重复登记，冲突报告；MergeCustomTextToDefaultLanguage0x417dc0将它合入default_language_translates。dump.cs:423235/423239/423295/423297独立确认列表、字典与默认/当前语言域。
- Datapool.Translate0x422740先查当前语言，再查默认语言，均无结果返回输入键；Common.Translate0x384bc0委托此翻译接口。
- CardExtensions.GetName0x37ff50：配置id玩家覆盖优先；custom_name非空才调用Translate，只有译文不同于键才返回，否则进入CardNode名称路径。未知键不能直接显示。

## 实现范围

ConfigDB按已加载的原始配置建立运行时custom_card_name_translates，与原作注册表职责对应；不写新内容表、不导出中间格式。遍历当前content的12处剧情名称定义得到10个唯一键、零值冲突。这里只承载这些默认中文名称；其他UI翻译键、外部语言/Mod覆盖尚未接入。

槽位及table/total既有执行入口现在写 `change_card_name_<id>`；set_card_custom_name不再Trim或截断32，允许原字段清空。card_data_for通过默认名称索引取显示文字，未知键回退配置名/玩家名，配置id玩家覆盖仍优先。

## 验证

- card_evolution 16测试/108断言：原作镜中生灵键的存读档、未解析键回退、字段清空、table实际执行写键、主角玩家名及配置id覆盖优先级。
- 原存档导入桥6测试/83断言，包含真实auto_save样本。该样本并不能单独证明全部10个译文分支，名称键边界另由直接源码及原配置支撑。
- UI81测试/1073断言；合计103测试/1264断言。最终日志无SCRIPT ERROR、ERROR、orphan或泄漏报告；git diff --check通过。
- 两条旧测试曾把直接存中文文字当正确答案，现改用原配置存在的键和译文，未为测试新增虚构翻译记录。

## 未完成项

当前语言/Mod覆盖、其他可作为custom_name的通用翻译键、custom_text同类注册/翻译、NotifyPlayerNameChanged消费者、禁词与TMP仍开放。本次发现table/total既有选择分支包含首次命中即return，选择器域及多目标行为须回原OperationFilter/ChangeCardName.PreDo独立核查；本批仅修它写入的字段值，不据此宣称整个选择器已正确。

既有旧克隆存档若把任意中文文字直接存custom_name，现在会按原作未解析键回退；未盲目将其迁入玩家配置id表，因为那会将单实例历史值扩散到全部同id卡。原作格式的键保持不变。
