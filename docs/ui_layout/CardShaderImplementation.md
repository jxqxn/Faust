# 卡牌着色器落地与验收边界（2026-09-10）

## 已落地

本批承接 [CardShaderAudit.md](CardShaderAudit.md)，将已核实算法接入共享CardWidget；不是宣称整个卡牌表现已经像素完成。

- `ui/card_flash.gdshader`：移植原作GUI SSU fragment118。使用width .08×100×实际纹理texel size、四轴/四对角（.705）采样、连续alpha最小值、原纹理与金色随fade混合、RGBA顶点tint。删除2.5px、step(.5)、纯金色填充算法；沿用已核实的单次往返曲线。
- `assets/original/ui/card_outline.png.import`：关闭Godot自动修补透明像素RGB，保留原纹理颜色用于原作的混色算法。源贴图256×512、bilinear、clamp；原作resources.assets Texture2D270与语料PNG的RGBA逐像素一致。
- `ui/card_metal.gdshader`：移植fragment60/75的Gamma金属计算主干：F0 .220916、漫反射权重 .779084、粗糙度、GGX分布/可见性、Fresnel、Gamma spec sqrt、法线z重建、真实视线/半角、自发光。删除经验指数16–160、固定half-vector、稀有度亮度倍率、纵向渐变及detail均值补偿。
- `ui/card_widget.gd`：删除无编译消费证据的每帧normal_offset；绑定各类型/稀有度自发光贴图和颜色，人物stone_f保留独立颜色。共享底框和人物前景均使用此链。
- 旧测试中“必须改变normal_offset”“必须使用 .2065/.3 等拟合值”的断言已淘汰，改验原材质输入及实际光源变化不改变alpha。

## 贴图与原材质输入

本批只补入6张原PNG：`card_e_6 / card_d_0 / card_e_3 / card_e_1 / card_e_5 / card_e_2`。源头是 `unity_export/ExportedProject/Assets/Texture2D`；未编辑content配置。原材质在 `Assets/Resources/materials/card/{kind}/{tier}.mat`。

| 层类型 | 石/铜/金 EmissionMap | 银 EmissionMap |
|---|---|---|
| char底框/前景 | card_e_6 | card_d_0 |
| item底框 | card_e_3 | card_e_1 |
| sudan底框 | card_e_5 | card_e_2 |

颜色直接来自材质：石(.14150941,.14150941,.14150941)、铜(0,.04861112,.11458)、银(0,0,0)、金(.04513899,.04513899,.02083)；石人物前景独立为(0,.02430556,.08333)。银虽然有贴图，但颜色为0，不虚构发光贡献。

法线解包独立验证：本机sharedassets0.assets的Texture2D100/114/116，对应导出 `card_n_0/1/2.png`。原图A通道与导出R通道、原图G与导出G的逐像素差均为0。因此Godot采样已解包RG，按原程序BumpScale重建z；不能再做一次原压缩格式的R×A解码。

行为背书：`CardRenderChar.Init 0x538030`分别绑定bg/foreground/image；`CardRenderItem.Init 0x538670`绑定bg/image；`CardRender.InitImage 0x5390f0`选择材质及卡图；字段对应 `dump.cs:317717` CardRender、`:317831` CardRenderChar。材质不同层未合成一张自制贴图。

## 场景适配：有依据，但尚非现场GPU捕获

使用的静态输入来自GameScene：

- Light4870 / Transform4011：白色intensity1，旋转(.13040192,.043246232,-.005693473,.9905012)，换算到卡平面TBN的光向量(-.08418598,.25881905,.96225019)。本灯无阴影，包含卡牌layer5。
- MainUI Canvas7581：Screen Space Camera、plane distance100；Camera4416：orthographic size5，Transform3882位置(0,0,-10)、单位旋转。当前每片元从屏幕坐标反算平面视线，并考虑Godot画布2D旋转。
- RenderSettings：Flat环境模式3，颜色(.212,.227,.259)。当前作为静态ambient_diffuse；不是已捕获的运行时SH。
- 环境镜面反射输入暂为0；**没有复刻探针立方体采样、LOD/HDR解码、box projection或probe blending**。原作是否在此场景产生非零贡献仍需捕获。

手牌/拖动/仪式中的变换深度、实际SH、探针、纹理采样及选中层的完整draw-call输入仍未对齐。这些缺口没有通过调参掩盖。

## 独立像素验证

新增工具直接执行原作汇编指令，**不读取Godot shader算法生成答案**：

1. `tools/card_flash_asm_reference.py`执行blob118的29条数值/纹理指令，生成有软边、孔洞、RGB变化的纹理测试。`tools/verify_card_flash_pixels.gd`实际GPU渲染比较：32/64/128三种尺寸×fade0/.25/.75/1，共12例，顶点tint(.8,.9,.7,.6)，黑底alpha合成。
2. `tools/card_metal_asm_reference.py`执行fragment60；纹理覆盖不同法线、金属度、平滑度、detail及自发光。`tools/verify_card_metal_pixels.gd`比较直接光/环境漫反射/自发光/组合4例。受控探针为黑，SH输入固定；使用不透明材质隔离shader算术与HDR混合问题。

两组最终最大RGB通道差均为1/255（浮点输出约 .0039216），阈值2/255；参考数据在 `.godot/` 可重建。结果在 [flash_gpu_results.json](shader_evidence/flash_gpu_results.json) 与 [metal_gpu_results.json](shader_evidence/metal_gpu_results.json)。这证明**受控输入下已移植算术的吻合程度**，不是原作整帧误差。

还观察到需要单独处理的边界：HDR高光RGB>1且alpha=.6时，Godot当前非HDR 2D目标的合成会先钳制源RGB，不能用“浮点RGB先乘alpha再钳制”的参考作为同一个合成管线。原作Camera4416允许HDR，但本批没有捕获最终目标格式；此问题保留为阻止透明拖动像素验收的明确缺口，未通过修改亮度绕过。金属算术测试因此明确隔离在alpha=1，原有透明颜色/轮廓测试仍覆盖alpha<1。

## 功能与运行验证

- GUT：UI81测试/1072断言；候选闪烁3/55；手牌分页6/44；合计90测试/1171断言全过。
- 1280×720、1920×1080 GPU：候选动态、选中金币、装备拖放遮挡、装备后详情全部通过。截图为 `card_reference_*_{1280,1920}.png`；2560旧图不代表本批。
- 材质中性采样4色块误差0；改变真实光方向使52821像素变色，alpha变化0。
- 使用computer-use观察原作2560×1440桌面，并打开治理家业、点击人物槽核对候选放大/首项选中。工具截图未构成同步逐帧差分，不拿它声称闪烁峰值已逐像素验收。
- `git diff --check`通过；最终测试/运行日志无ERROR、SCRIPT ERROR、orphan或泄漏。没有提交、推送或修改content。

## 下一项硬门槛

需要原作GPU帧捕获，读取具体draw call的常量缓冲、反射纹理与目标格式，再替换上面的静态环境适配并完成透明拖动对拍。本机已检查C:\Tools、Program Files、Program Files (x86)、Downloads及Local Programs，未找到RenderDoc或dxcap；现有Nsight Systems/Compute不是此处需要的D3D11资源帧检查器。下载新的帧捕获工具受仓库AGENTS.md联网报备规则约束，当前未下载。
