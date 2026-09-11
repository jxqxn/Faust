# A11 场景环境输入：卡牌光照模型已由数据定案（第三十三批）

`CardShaderAudit.md` 第 65 / 78 / 97 行把三件事挂在"实际现场绑定值待测"：

> 5. 存在SH环境光、反射立方体及其LOD/HDR解码、遮蔽计算。其实际贡献需拿到现场绑定值；不能因有分支就假定反射一定非零。
> 环境反射/SH | 完全未接 | 编译程序存在且绑定相关资源；**实际现场值待测**
> GameScene RenderSettings 的环境模式/颜色 …… 这些还没有完成现场绑定值对拍

本批把这三项**在导出场景数据里定案**——不需要现场抓帧，因为场景自己的序列化值就决定了它们。

## 1. 环境光不是 SH，是 Flat 单色

`GameScene.unity` 的 RenderSettings 块（整场景只有这一个，起始第 4 行）：

| 字段 | 值 | 含义 |
| --- | --- | --- |
| `m_AmbientMode` | **3** | **Flat** —— 只用 `m_AmbientSkyColor`，不烘 SH 探针 |
| `m_AmbientSkyColor` | `{0.212, 0.227, 0.259, 1}` | 唯一的平坦环境色 |
| `m_AmbientEquatorColor` | `{0.114, 0.125, 0.133, 1}` | **Flat 模式下不参与** |
| `m_AmbientGroundColor` | `{0.047, 0.043, 0.035, 1}` | **Flat 模式下不参与** |
| `m_AmbientIntensity` | `1` | 足额 |
| `m_SkyboxMaterial` | `{fileID: 0}` | **没有天空盒** |
| `m_CustomReflection` | `{fileID: 0}` | **没有自定义反射立方图** |
| `m_DefaultReflectionMode` | `0` | Skybox（但天空盒为空） |
| `m_ReflectionIntensity` | `1` | 强度 1 乘在"空的来源"上 |

`LightmapSettings` 里 `m_EnableBakedLightmaps: 0` / `m_EnableRealtimeLightmaps: 0` / `m_AO: 0` / `m_EnvironmentLightingMode: 0`——**没有任何烘焙 GI**。

**结论**：环境光 = 单一常量 `(0.212, 0.227, 0.259) × 1`；因为是 Flat 模式，`UNITY_LIGHTMODEL_AMBIENT` 就是它，不存在 SH 解码要还原。`CardShaderImplementation` 里那个 `ambient_diffuse = vec3(0.212, 0.227, 0.259)` 是**逐字正确**的，不是近似。

## 2. 环境反射 = 精确零

`UNITY_SAMPLE_TEXCUBE_LOD` 那一族分支在程序里存在，但**运行时没有可采样的立方图**：`m_SkyboxMaterial` 与 `m_CustomReflection` 都是 `{fileID: 0}`，且 Flat 模式下不生成 SH 探针。所以 `environment_specular = vec3(0.0)` 从"待测的未知量"变成**有源背书的确切值**。

> 这正是审计第 65 行警告的反面用法：不能因有分支就假定反射非零——现在可以说它**恰好为零**，依据是绑定源为空，不是"看起来黑"。

## 3. 只有一盏灯能照到卡牌

`GameScene.unity` 里恰好两个 `!u!108` Light，都是 `m_Type: 1`（Directional）、`m_Color: {1,1,1,1}`、`m_Intensity: 1`：

| 组件 | 宿主 | culling mask | 包含层 | 阴影 |
| --- | --- | --- | --- | --- |
| `&4869` | GO 157 "Directional Light" | `1073741824` = `0x40000000` | **只有 30** | `m_Type: 2`（软阴影） |
| `&4870` | GO 346 "Directional Light" | `2147483895` = `0x800000F7` | 0,1,2,4,5,6,7,31 | `m_Type: 0`（**无阴影**） |

卡牌 GameObject 在 **layer 5**（`CardNew` 根节点 `m_Layer: 5`）。逐位核对：

- `4870`：`0x800000F7` 的 bit5 = 1 → **照卡牌**；
- `4869`：`0x40000000` 只有 bit30 → **不照卡牌**。

所以克隆的"单光源 + 白色 + 强度 1 + 无阴影"四条都成立，而且 `light_color = vec3(1.0)` 是**唯一可达光源的实测值**，不是默认值。反过来也定了一条禁令：**不能拿 4869 的软阴影给 layer5 卡牌造投影**（`CardShaderAudit.md` 第 96 行已经这么写，现在有了 mask 位的逐位依据）。

`&4870` 的宿主 Transform `&4011` 根旋转四元数 `(.13040192, .043246232, -.005693473, .9905012)`、欧拉提示 `x:15, y:-5, z:0`——与审计第 95 行一致，本批核对无出入。

## 4. 颜色空间：登记为分歧，不宣称像素影响

`ProjectSettings.asset:60` `m_ActiveColorSpace: 0`（Gamma）。克隆的 `project.godot` 里**没有任何 rendering / color_space 设置**。

⚠️ **本批不把这条升级成"亮度偏差"结论。** 当初写这段时一度想直接断言"克隆渲染在 Linear、所以更亮"——但 Unity 的 Gamma 工作流与 Godot 内部线性/显示 sRGB 的对应关系**没有在本仓库验证过**，而 shader 里那些 Gamma 工作流常数（`0.220916` / `0.779084`）本来就是按 Gamma 数值写的。没有同帧对拍就说亮度方向，属于编造因果。

因此只做两件事：把设置**钉进测试**防止它悄悄变化，并在文档里登记为未验证分歧。

## 5. 仍未定案：`light_direction` 的 z 符号

shader 里 `light_direction = vec3(-0.08418598, 0.25881905, 0.96225019)`。

用源四元数算灯的 forward（Unity 旋转 `R*(0,0,1)`）：

```
R = [[1-2y²-2z²,      2xy-2wz,      2xz+2wy],
     [2xy+2wz,    1-2x²-2z²,      2yz-2wx],
     [2xz-2wy,      2yz+2wx,  1-2x²-2y²]]
R*(0,0,1) = (2xz+2wy, 2yz-2wx, 1-2x²-2y²)
          = (-0.08418598, +0.25881905, +0.96225019)
```

代入 `(x,y,z,w) = (.13040192, .043246232, -.005693473, .9905012)` 得到上面这个向量。也就是说 **shader 里存的是源的 forward 向量本身**，而 shader 的 `nl = clamp(dot(n, l), 0, 1)` 把 `l` 当"指向光源"用。两者要么差一个全局取负，要么 clone 的切线空间 z 朝向与源相反——**两种解释都能自洽，本批没有能判定的证据**，所以不动它，只把四元数与匀量的两个分量幅值钉进测试（`|x| = 0.08418598`、`|y| = sin15° = 0.25881905`，与欧拉提示 x:15/y:-5 吻合）。

> 留档给后续：要判定这一点需要一次**同帧卡面明暗对拍**（同一张金属卡、同一机位），本仓库目前没有这个能力，故不猜。

## 落地

- 新增 `tests/test_card_shader_scene_inputs.gd`（**8 测试 / 30 断言**）：直接从语料 `GameScene.unity` 与 `ProjectSettings.asset` 读 RenderSettings、两个灯的 mask/Light 块、灯的四元数，再解析 `ui/card_metal.gdshader` 的匀量做交叉断言。测的是"克隆匀量 == 场景序列化值"，不是"匀量 == 我记的数"。
- 覆盖点：Flat 模式必须无 SH 探针（并显式否定用赤道/地面色）；ambient 匀量逐字等于天空色；environment_specular 必须为零且说明来源为空；恰好两盏平行光且只有一盏含 layer5；卡牌那盏必须白/强度1/无阴影；带阴影那盏必须只含 layer30；颜色空间设置被钉住。
- 过程中修掉自己两个**测试** bug：`m_CullingMask:` 行有前导空格，`begins_with` 没 strip 导致收不到 mask；`vec3(0.0)` / `vec3(1.0)` 是合法 GLSL 短形式，解析器原本会塞进不等长的数组。两处都是测试解析器问题，不是被测事实问题。

## 与既有文档的关系

`CardShaderAudit.md` 第 65/78/97 行的"现场值待测"在本批**部分关闭**（环境光、环境反射、可达光源），第 70–77 行那些"未照原作执行"项（光照模型的 TBN/粗糙度/能量分配实现、法线打包、手工亮度倍率、纵向渐变、detail 均值补偿）**仍然开放**，本批没有碰渲染公式本身。
