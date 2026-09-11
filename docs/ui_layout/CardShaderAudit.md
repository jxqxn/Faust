# 卡牌光照与闪烁轮廓：原作程序审计

本页记录审计时状态。后续已落地算法与当前缺口见 [CardShaderImplementation.md](CardShaderImplementation.md)，不能将本页“尚未替换运行时”作为最新进度。

日期：2026-09-10。范围：解释当前像素差异，核实原作做法；本批不修改运行时效果、不以截图拟合代替算法。

## 结论

当前 `card_metal.gdshader` 的光照主体、`card_flash.gdshader` 的轮廓计算都是近似实现，不是原作算法移植。此前恢复贴图、颜色采样、闪烁时序，并不能使这些部分成为像素级一致。

重要纠正：AssetRipper 的 `DummyShaderTextExporter` 只表示该次导出没有正文，**不表示原作着色器已不可获取**。本次使用本机已有 UnityPy 读取安装包 `sharedassets0.assets`，解压编译程序，再用 Windows `d3dcompiler_47.dll!D3DDisassemble` 得到实际 DXBC 汇编。未联网、未修改语料或原作。

## 可复查证据

- 工具：[audit_card_shaders.py](../../tools/audit_card_shaders.py)。依赖本机已有 UnityPy；输出指定目录，不下载依赖。
- [index.json](shader_evidence/index.json)：安装包 SHA256、Unity 版本、shader path ID、pass/关键词、参数绑定及原始参数字节。
- shader 184：`Sprite Shaders Ultimate/GUI SSU`；118 是 CardFlash 的无裁剪片元变体，135/152/169 为 alpha clip、rect clip、两者同时开启。
- shader 187：`CardShow/Default`；60 是金色材质的 Directional + LIGHTPROBE_SH + NORMALMAP + ALPHABLEND + METALLICGLOSSMAP + EMISSION + DETAIL_MULX2 片元变体；65/70/75保留其他光照/阴影关键词组合，14为对应一组顶点程序。
- 原语料路径前缀：`../Faust-local-source/_unpack/`。材质在 `unity_export/ExportedProject/Assets/Resources/materials/`；行为在 `engine_spec/decompiled/`。

这里的变体是安装包中存在、与材质关键词相符的程序；尚未做 GPU 帧捕获确认具体桌面 draw call 最终选用哪一个光照/裁剪变体。不能把存在的反射/阴影分支全部宣称为现场生效。

## 一、闪烁轮廓：已拿到确切公式

独立证据：`CardFlash.mat` 的 shader GUID 指向 `Sprite Shaders Ultimate_GUI SSU.shader.meta`；关键词恰好对应程序118的 `[17,46,61,89]`，即 UV空间、仅内轮廓、无全局shader淡化、启用内轮廓。

材质：`_InnerOutlineWidth=0.08`，`_InnerOutlineColor=(0.88235295,0.72840685,0.33725485,1)`，`_InnerOutlineFade=0`。

[184_118.asm](shader_evidence/184_118.asm) + 参数blob86可还原为（省略UI裁剪分支）：

```text
T = sample(MainTex, uv)
d = width * 100 / texture_dimensions
directions = {(-1,0),(1,0),(0,-1),(0,1),
              (.705,.705),(-.705,.705),(.705,-.705),(-.705,-.705)}
a_min = min(sample(MainTex, uv + direction*d).a for all 8 directions)
f = (1 - a_min) * InnerOutlineFade
output.rgb = lerp(T.rgb, InnerOutlineColor.rgb, f) * vertexColor.rgb
output.a = f * T.a * vertexColor.a
```

参数绑定：`cb0[5].zw` 为 `_MainTex_TexelSize.zw`；`cb0[11].z` 为 width（字节184）；`cb0[9].z` 为 fade（字节152）；`cb0[8]` 为 outline color（字节128）。原作默认width意味着纹理空间8 texels的轴向偏移，**不是屏幕上固定8像素**；显示缩放、sprite UV/图集范围和源纹理大小共同决定屏幕厚度。

| 环节 | 当前克隆 | 原作 / 差异后果 |
|---|---|---|
| 轮廓采样半径 | `outline_pixels=2.5` | `0.08*100=8`源纹素；当前明显偏薄，具体屏幕倍率还需核对绑定纹理 |
| 对角采样 | `sin/cos(pi/4)`约0.707107 | 常量0.705；即使很小也不应继续自制 |
| alpha | 对中心和邻居均 `step(0.5)` | 连续alpha取min，乘中心alpha；当前软边被硬切，会出现不同锯齿与断口 |
| RGB | 始终纯outline金色 | 按f在原纹理RGB与金色之间混合；淡入/淡出不仅改变透明度，还改变颜色 |
| 顶点颜色 | 仅传入顶点alpha | 原作RGBA都参与；有色tint场景可能不同 |
| 裁剪 | 未移植对应Unity UI分支 | 原作另有135/152/169；需按实际父Mask启用 |

原作pass混合已核实：RGB=`SrcAlpha, OneMinusSrcAlpha`，alpha=`One, OneMinusSrcAlpha`。不能拿CardFlash材质中残留的`_DstBlend`字段当pass实际配置。

动画控制与像素算法是两个问题：`CardFlashController.Update`（RVA `0x52e330`, `dump.cs:317254`类）按 `deltaTime*speed` 推进/回退time，Clamp01后Evaluate曲线，写材质fade，到峰后回落；`Reset`（`0x52e2d0`）清time/方向/fade。CardNew prefab的speed3及曲线是独立参数证据。上一批已接此时序；但当前shader把fade只用于纯金色alpha，所以即使曲线正确，逐帧像素仍不正确。

## 二、光照：当前实现遗漏了完整的材质计算链

直接证据：[187_60.asm](shader_evidence/187_60.asm)，参数blob40及common parameters。不是根据属性名猜测“应该是Standard”。实际程序有以下计算：

1. 主纹理乘材质颜色；detail通过mask参与双倍乘色。
2. 金属度R决定漫反射与镜面反射分配，金属图alpha乘GlossMapScale决定平滑度。
3. 法线贴图使用打包法线解码：`x = sample.r * sample.a`，xy映射到[-1,1]，乘BumpScale，`z=sqrt(1-min(dot(xy,xy),1))`；再与detail normal混合，经顶点传入的切线/副切线/法线转换到世界空间并归一化。
4. 使用实际观察方向、世界光方向计算半角向量；有roughness平方、GGX形状分母、可见性项及五次方Fresnel相关计算。不是当前固定half-vector+经验指数的公式。
5. 存在SH环境光、反射立方体及其LOD/HDR解码、遮蔽计算。其实际贡献需拿到现场绑定值；不能因有分支就假定反射一定非零。
6. 尾部明确采样EmissionMap并乘EmissionColor加到RGB。

| 未照原作执行的位置 | 当前实现 | 已验证的原作区别 |
|---|---|---|
| 光照模型 | unshaded canvas，自制pow指数16–160 | 实际世界空间法线/视线/光源、粗糙度与Fresnel计算 |
| 金属能量分配 | `1-0.3*metal`，F0固定0.04 | 本包变体出现0.220916/0.779084的Gamma工作流常数；不是这套系数 |
| 颜色空间 | 把“与Godot普通TextureRect一致”当基础验证 | 原ProjectSettings.asset:60 `m_ActiveColorSpace=0`（Gamma），汇编还有SH光照转换；普通TextureRect相等不证明与Unity相等 |
| 法线 | RGB解码后把z硬保底0.2 | 原作重建z并转换TBN；导出的PNG是否已解包必须单独核对，不能盲目把DXT通道公式再套一次 |
| 全局亮度 | 稀有度对应四组手工RGB倍率 | 当前没有原作背书；原作使用材质和现场光照输入 |
| 纵向渐变 | `vertical_light_falloff=0.2065` | 当前没有原作背书，不能代替世界空间照明 |
| detail补偿 | 除以`CARD_DETAIL_MEANS*2` | 原作程序按纹素乘detail，不做此均值补偿 |
| 自发光 | 完全未接 | 金色材质启用`_EMISSION`且非零颜色；已证实程序实际相加 |
| 环境反射/SH | 完全未接 | 编译程序存在且绑定相关资源；实际现场值待测 |

金色 `card/item/gold.mat`：BumpScale .3680556，GlossMapScale .75，Color=(1,.8333333,.63888,1)，EmissionColor=(.04513899,.04513899,.02083,1)；EmissionMap非空。不能把同时序列化的 `_Metallic=.393`、`_Glossiness=.71`、`_Parallax=.0393` 全部当成当前变体有效输入：金属贴图变体使用贴图，未启用parallax关键词。

## 三、之前“屏幕位置改变法线”的说法需要纠正

`CardRender.Update`（RVA `0x53a8e0`, `dump.cs:317785`）确实在enableOffset时取得世界位置、WorldToScreenPoint、GetScreenOffset，再对needUpdateOffsetMaterials调用SetFloat。`GameController.GetScreenOffset`（`0x5508a0`, `dump.cs:320205`）确实将屏幕坐标线性映射到配置范围。

**但是写入参数不等于GPU使用参数。** 本次解压的CardShow/Default整个程序blob中 `_NormalOffsetX/Y`绑定名计数都是0；所选顶点14和片元60中也没有相应常量读取。两属性仍出现在shader Properties中。本次证据不支持克隆把normal_offset直接加到normal.xy的做法。这很可能给当前卡牌额外制造了原作该变体并不存在的位置色变。

结论限于本机安装包的这个shader及核对的变体；应继续核查其他材质shader、游戏版本与实际draw call。不能因此推断所有原作材质的offset写入都无效。

## 四、材质层、灯光和最终合成也要一并对齐

- `CardRender.InitImage`（`0x5390f0`, `dump.cs:317803`附近）为image选择并实例化材质，另取卡图纹理写入材质，再加入dynamicMaterials。
- `CardRenderItem.Init`（`0x538670`, `dump.cs:317856`附近）另为bg选材质并加入needUpdateOffsetMaterials。两集合不能混为一谈。
- `CardRenderChar`还有单独的forground（`dump.cs:317834`附近）。当前按kind/rare复用一套shader的实现，仍需逐层核对对应材质、法线、金属/自发光图；不能因外框颜色相似就认为所有层都对应。
- GameScene Light4870（GO346、Transform4011）：白色、intensity1、无阴影；culling mask2147483895包含卡牌layer5；根旋转四元数(.13040192,.043246232,-.005693473,.9905012)。当前固定half-vector没有使用它。
- Light4869只照layer30，启用soft shadows；不能据这盏灯给layer5卡牌制造投影。
- GameScene RenderSettings的环境模式/颜色，与camera、Canvas空间、质量设置、texture sampler、压缩、mip、sprite图集UV以及多层alpha共同影响结果。这些还没有完成现场绑定值对拍，不宣称像素完成。

## 执行顺序与验收边界

1. 先用上述精确公式替换Flash算法；保持源纹理UV与采样半径语义，核查遮罩变体和顶点tint。逐帧比较起始/上升/峰值/下降/结束，不能只看静止金边。
2. 建立每个卡层的原材质绑定表，复原已证实的Gamma、法线、金属、detail、自发光与世界空间输入；清除手工light/均值补偿/垂直渐变。offset必须按实际GPU消费证据处理。
3. 获取原作实际帧中的光源、相机、SH/反射和纹理采样输入，再做同卡同位置同状态比较。优先石/铜/银/金与人物/物品/苏丹卡，覆盖选中、候选、拖动、详情。
4. 验收包括透明软边和逐帧局部差分。现有GUT只证明功能/时序，GPU普通贴图等值测试只证明颜色采样链；两者均不作为原作像素验收。

本批结果是**已查明算法层面的差异、获得可移植的真实程序证据**；尚未把新算法接入产品，也未完成原作GPU现场捕获。
