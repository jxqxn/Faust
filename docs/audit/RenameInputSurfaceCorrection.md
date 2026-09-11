# 改名输入表面纠偏（2026-09-10，第十三批）

从 A08 的输入框/placeholder 候选取项。本批只修已核实的背景绘制、文字内距、横向对齐和独立占位字体；不宣称整个改名流程已完成。

## 本次直接证据

只读 `unity_export/ExportedProject/Assets/Resources/prefab/PromptChangeName.prefab`：

- Image114477046003934300：input_bg，m_Type=0（Simple），PreserveAspect=0。克隆30像素九宫边缘无依据，现独立 TextureRect 整幅缩放。
- Input 根224571718729274231：826×90；TextArea224722951815217645：anchors全幅、pos(0,-.5)、sizeDelta(-20,-13)，换算Rect(10,7,806,77)。克隆40/20内距错误；现透明样式内距10/7/10/6，保持完整根的可点击面积。
- Text114279359913592680：horizontalAlignment=2（居中），文字颜色(1,.9764706,.6862745,1)；TextTranslate114384403120170545 style=@TITLE_H3。当前输入仍为原 Title 字体固定50。
- Placeholder114094320201520353：TextTranslate key=PROMPT_CHANGE_NAME_INPUT_PLACEHOLDER。原 content/textstyle.json 为 xiquemuye SDF，css_size范围40–75；不能与正文共享 LineEdit 的字体和固定50。现用独立标签读取同一原配置并订阅字号变化。
- `TextTranslate.c` UpdateTextInternal 0x1566ad0（144–171）：先按key查TextStyleNode、缺失再按style查，GetFontAsset后set_font；随后UpdateFontSize并按css_size订阅。不是仅靠prefab默认fontAsset推断最终字体。
- `PromptChangeNameController.c` OnEnable 0x585220 与 `dump.cs:323419`：Input@0x78为TMP_InputField，初始化先清空再写现有名字。占位显隐必须覆盖程序设值，不能只监听用户text_changed。

## 验证

`test_prompt_preferred_layout.gd` 4测试/28断言通过，包括826×90命中区域、10/7/10/6内距、两套独立字体、xxl下占位75而正文50，以及程序设置/清空名称后的占位显隐。占位隐藏也检查宿主当前输入法组合串；真实中文IME组合流程未验。

`verify_prompt_preferred_layout.gd` 1280×720、1920×1080 实际输入A、点击确认/取消与共用确认框状态均PASS。最终日志无SCRIPT ERROR、ERROR、ObjectDB或orphan报告。截图为克隆GPU验证，不替代原机对拍。

## 新确认的行为差异，下一批处理

必须保留这些缺口，不能继承过去“改名1:1”的结论：

1. 原Input m_CharacterLimit=0；IsValidName 0x584de0检查.NET UTF-16 String.Length为1–20，而当前克隆直接把输入硬截断20，并以Unicode码点计数。
2. IsValidName使用IsNullOrEmpty，未Trim；克隆strip_edges改变名称。原非法长名称/禁词会禁用Confirm并显示ILLEGAL_NAME，空串禁用且清提示；当前未实时接入。
3. 原Datapool.HasBanWords 0x4131c0经maskWordsHelper@0x2a8调用HasMaskWord。克隆未迁词库载入/判定；不能自制词表或默认为已支持。
4. OnNameSubmit 0x585490只验证并SetSelectionGameObject(Confirm)，不提交。OnConfirm 0x585000还检查Input@0x260状态并经SetCardName后DoClose；当前Enter直提交流程不同，字段0x260须与TMP_InputField dump继续核对。
5. 输入框Selectable的ColorTint、TMP Geometry垂直对齐、placeholder斜体、RectMask负padding、主面板Full图片/遮罩、手柄导航仍未验收。本批没有添加目测补偿。
