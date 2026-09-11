# Shaker源证据纠错与原生入口定位（2026-09-10）

后续状态：第十二批已完成原生数学及点击边界修复，见 [ShakerNativeCorrection.md](ShakerNativeCorrection.md)。下文保留第十一批当时的调查记录。

A06 第十一批，**证据批次，运行时抖动尚未修复**。前次审计虽正确否定双sin/线性衰减，但误把两个字段名与偏移对应，不能沿用旧结论实现。

## 字段与实际调用

独立信号：`il2cpp_dump/dump.cs:420570` 的Shaker字段、`decompiled/Shaker.c @ OnEnable 0x435690 / Update 0x4357e0`及CachedEvent.prefab：

| 字段 | 偏移 | prefab值 | 原作用途 |
| --- | --- | --- | --- |
| seed | 0x54 | 编辑器残留-4.4451404 | OnEnable重置Random.value*10-5 |
| frequence | 0x58 | 40 | 乘时间取样坐标 |
| currentFreq | 0x5c | 0 | OnEnable从maxSpeed@0x64复制，初始2 |
| currentVelocity | 0x60 | 0 | OnEnable清零，SmoothDamp跨帧保留 |
| maxSpeed | 0x64 | 2 | 初始currentFreq |
| time | 0x68 | 10 | 作为SmoothDamp第五参数maxSpeed |

实际为 `SmoothDamp(currentFreq,0,ref currentVelocity,deltaTime,time,deltaTime)`，而不是“初始10，再按2限速”。字段名不能替代实参追踪。

## 时间、种子、噪声

- DLL常量RVA1c92b98=10、1c9e584=5，确认seed为[-5,5]，克隆[-1,1]错误。
- Time.time传入RVA2c9dc0，第二参数常量RVA1c9e58c=6.2831854820251465。机器码处理绝对值、除法截断及余数，证实取余路径；不是无限累加局部phase。正有限时间用fmod(Time.time, float32(2π))再乘frequence。
- PerlinNoise横坐标为seed+1/+2/+3（位置）与+4/+5/+6（旋转），纵坐标为上述时间*frequence。每轴为 `(2*noise-1)*intension*currentFreq + capturedOrigin`；不能除以初始强度。
- 即使prefab local=1，当前OnEnable/Update直接读写Transform世界position/rotation。坐标换算必须继续核对，不能凭local字段改为局部坐标。

## SmoothDamp机器码

`dump.cs:343100`签名与RVA197a3e0..197a514：smoothTime至少0.0001，omega=2/smoothTime，x=omega*deltaTime，exp=1/(1+x+.48*x²+.235*x³)，change按maxSpeed*smoothTime限制，保留velocity并处理越过目标。常量字节由工具直接读出；还未做原生float32逐指令差分，不宣称等精度移植。

## 原生Perlin定位

GameAssembly的RVA1979fa0只是icall包装：首次解析字符串，然后跳转缓存指针。字符串RVA1d3d300为`UnityEngine.Mathf::PerlinNoise(System.Single,System.Single)`，不是算法本体。

已找到只读原作目录`Faust-local-source/Sultan's Game/UnityPlayer.dll`。该目录GameAssembly与_unpack/GameAssembly SHA256一致，完整哈希见生成的JSON。UnityPlayer内注册字符串raw0x18fcdf0/RVA0x18fe3f0，指向该字符串的指针表槽RVA0x18dfaa0（image base0x180000000）。下一步追该注册表对应函数地址，再恢复噪声内核及UI世界单位。

## 可重复检查

运行 `tools/audit_shaker_source.py`，产出 `docs/audit/shaker_source_evidence.json`：核对字段偏移、prefab值、11个二进制浮点常量、icall字符串、原作DLL版本对应及原生注册字符串位置。不下载、不执行原作、不改语料。此工具为审计产物，不能作为运行时内容转换层。

本次未修改抖动行为，不运行与此无关的GUT来冒充验收。A06继续开放；旧双sin、线性减时、种子与归一化振幅均待整链替换。
