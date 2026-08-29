# 浮士德工作流插件化 Recipe（DSH/Cordis 实战记录）

> 状态：2026-08-14 落盘。记录「把项目重复步骤变成 DSH 运行时能力」的完整做法，供后续会话复用。
> 目的：下一次新会话想加工具、加 skill、改预设时，不用重新踩坑。

## 30 秒版

DSH 里「万物皆可插件」有两层：

1. **动态插件**（`cordis_define` / `cordis_run`）：当前会话内存态，重启即失。用于实验。
2. **Agent 预设**（`$HOME/.dsh/.agent-presets/<id>/`）：磁盘持久，每次会话自动加载。用于交付。

把项目步骤插件化的通用模式：**脚本/方法论 → 注册成 skill + 工具 + 提示段**，先动态实验，再持久化。

## 检查运行时（写代码前必做）

用 `cordis_inspect_list` 列出 Provider，再用 `cordis_inspect_query` 查精确契约。关键 Provider：

| Provider | 用途 |
|---|---|
| Host `Service`（listService） | 全部可注入服务：`skills`、`systemPrompt`、`shell`、`tools`、`fs`、`web`… |
| Host `Builtin`（listBuiltins） | `harness.defineTool/registerTool/handle`、`ctx`、`console`、`btoa/atob` |
| Host `Tool`（listTools） | 当前可见工具清单（避免命名冲突） |
| Host `Event`（listEvents） | 生命周期事件（`tools/change`、`skills/change`、`agent/pre-step`…） |
| Client `Slots` / `Theme` | 页面 UI（本 recipe 未用到，需要界面时再查） |

注意：Inspect 的 `referencedTypes` 常为空——字段形状要在 DSH 源码里确认，例如
`E:\dsh\node_modules\@deepseek-ai\dsh\node_modules\@deepseek-ai\dsh-tools\lib\types\schema.d.ts`
是 `defineTool` 精确入参，`dsh-shell\lib\types\types.d.ts` 是 `ShellExecRequest/ShellRunResult`。

## 组合模式（动态插件）

一个 Host 插件可以同时注册四类能力（`faust-1` 的实例）：

```js
return {
  apply(ctx) {
    // 1. skill：把方法论变成可加载的 skill（如 faust-clone-reference、faust-case-study-method）
    const skills = ctx.get('skills')
    if (skills !== undefined) {
      skills.register({
        name: 'faust-case-study-method',       // kebab-case，机器标识符不能中文
        description: '中文描述（显示给 agent 路由）',
        content: '方法论文本（给 agent 读的正文）',
      })
    }

    // 2. 提示段：注入工作流指引（order 100–199 是工具指引区间）
    const prompt = ctx.get('systemPrompt')
    if (prompt !== undefined) {
      prompt.section({
        name: 'faust:workflow-tools',
        order: 150,
        text: '何时用什么工具、遵循什么 skill…',
      })
    }

    // 3. 模型工具：把脚本变成可调用工具
    const tool = harness.defineTool({
      name: 'faust_check_research',            // 英文标识符，不能中文
      description: '查研究：运行设计研究一致性检查…（中文描述）',
      parameters: {},                          // 逐属性 DSL；有参时如 { x: { type: 'string', required: true } }
      output: {
        schema: { type: 'string' },            // ValueSchemaSpec
        render: (args, value) => [{ type: 'text', text: value }],  // 必须返回 content block 数组
      },
      timeoutMs: 120000,
      execute: async (args, exec) => {
        const shell = ctx.get('shell')
        if (shell === undefined) return 'shell 服务不可用'
        const spec = shell.resolve({ command: '…', workdir: '<Faust 仓库根目录>', timeoutMs: 120000 })  // 机器相关路径不要写死，从会话 cwd 或环境变量取
        const result = await shell.run(spec)   // { exitCode, timedOut, aborted, stdout:{text}, stderr:{text} }
        return (result.exitCode === 0 ? '通过\n' : '失败\n') + (result.stdout.text + result.stderr.text).trim()
      },
    })
    harness.registerTool(ctx, tool)
  },
}
```

要点：

- 工具 `name` 必须是英文标识符（机器调用）；**描述可以用中文**。
- `output.render` 必须返回 `[{ type: 'text', text: … }]` 数组。
- `execute` 返回必须匹配 `output.schema`（返回字符串配 `{ type: 'string' }`）。
- `ctx.get('shell')` / `ctx.get('skills')` 用可选获取 + undefined 检查；`systemPrompt`/`tools` 是硬依赖也可 `inject`。
- 注册即属于插件 fiber，stop/update 自动卸载，无需手动清理。

## 持久化成 Agent 预设

标准 preset 复制到用户根后编辑。目录结构：

```
$HOME/.dsh/.agent-presets/<id>/
├── agent.cordis.yml                 # composition（= 基底预设的 + 追加的插件行）
├── preset.yml                       # name: 显示名 / description
└── plugins/<插件>/index.mjs         # 插件本体（本地模块）
```

`agent.cordis.yml` 里追加一行（本插件只消费 host 服务、不发布服务，松散放置即可，无需 isolate realm）：

```yaml
- id: faust-workflow
  name: ./plugins/faust-workflow/index.mjs
```

**零 import 铁律**：本地模块被 `import(file://…)` 加载，内部若写 `import '…' from '@deepseek-ai/dsh-tools'` 会从 preset 目录向上找 node_modules 而失败（harness 的 node_modules 不在上级链上）。所以本地模块必须零 import：

```js
export default {
  name: 'faust-workflow',
  inject: ['tools', 'shell', 'systemPrompt'],
  apply(ctx) {
    // 不用 harness.defineTool，直接用 ctx.tools.register 写原始 ToolDefinition：
    ctx.tools.register({
      name: 'faust_check_research',
      description: '…',
      parameters: { type: 'object', properties: {}, additionalProperties: false },  // 原始 JSON Schema
      output: { schema: { type: 'string' }, render: (_a, v) => [{ type: 'text', text: String(v) }] },
      execute: async (_args, _exec) => { /* 同动态插件，用 ctx.shell */ },
    })
  },
}
```

模块导出形状：`export default { name, inject, apply }`（loader 的 `unwrapExports` 会解包 default）。

## 验证与交付

- 挂载验证：临时插件注入 `agentPresets` 调 `standingKeyFor('<id>')`，失败会抛错、成功返回。
  ```js
  return { inject: ['agentPresets'], async apply(ctx) { await ctx.agentPresets.standingKeyFor('<id>') } }
  ```
  把结果写文件再读，拿确定性结论。
- 真实会话验证：按「动态加载」节加载后，直接问 agent「列出 faust 开头的工具」，能看到才算数；重建预设则开新会话验证。
- GUI 操作：**删预设**可在「设置 → Agent 预设」卡片上点；**改内容**只能改文件（GUI 只读查看 + 打开位置）。

## 已踩的坑（重复者勿再踩）

1. **Windows 直接跑 GUI 程序不等待**：PowerShell 直接执行 `godot.exe` 会立即返回、`$LASTEXITCODE` 为空。验证时要 `Start-Process -Wait -PassThru` 或走 DSH `shell.run`（其内部会等待）。
2. **不要并行跑两个 Godot 实例**：两个实例同时访问 `user://`（app_userdata/Faust）会互相干扰，GUT 进程可能在测试中途被杀（表现为日志截断 + exit 1）。一次只跑一个。
3. **`export_dsl_audit.gd` 的 `--out` 参数**：必须写成 `-- --out user://xxx`（`--` 之后才是 user args），裸传路径会被忽略、写回默认目录。
4. **中文命名**：工具名/skill 名/预设 id 是机器标识符不能中文；描述、提示段、显示名（preset.yml 的 `name`）可以中文。
5. **版本只增不改**：动态插件每个改动是新的不可变包（pkg-N），旧版留作回滚，不要覆盖。
6. **host 层 patch 替换同名插件会回滚**：把 `cordis.patch.yml` 里已挂载的插件行直接替换成「同名工具的新插件」时，新树与旧树同名注册冲突 → 应用失败、回滚保留旧树（工具列表不变，看起来像没生效）。解法：**先删后加**——第一次 patch 只留新插件（旧树被替换卸载），等生效后再把其余插件加回去。

## 现状盘点（2026-08-14，最终版）

两个插件已通过 `cordis.patch.yml` 挂到 host 层（全局，所有会话可用，实时生效）：

| 插件 | 能力 | 通用性 |
|---|---|---|
| `godot-gate` | 工具 `godot_run_tests`（跑测试） | **通用**——任何 Godot 项目可用，工作目录取当前会话 |
| `faust-tools` | 工具 `faust_check_research`（查研究）、`faust_audit_dsl`（审规则）、`faust_new_case`（新案例研究）；skill `faust-clone-reference`（逆向对照）、`faust-case-study-method`（案例研究方法）；提示段 `faust:workflow-tools` | Faust 特定——硬编码 Faust 仓库路径 |

源码在 `docs/cordis/godot-gate/index.mjs` 与 `docs/cordis/faust-tools/index.mjs`；运行时复制到 `$DSH_HOME/profiles/web/plugins/` 下同结构，由 `cordis.patch.yml` insert 引用。

> **2026-08-14 决策**：不建任何浮士德预设（已删「浮士德工作流」）——改用 host 层 `cordis.patch.yml` 挂载，所有模式（含创造模式）直接有这些工具，实时生效。

## host 层挂载（官方推荐，所有模式可用）

官方文档（`dsh-agent-presets/README`）原话：「预设层没有 patch 语义来表达『standard 加一处改动』，**那是 bundle 层 `cordis.patch.yml` 的能力**」。用户自己的 `cordis.patch.yml`（profile 级与 home 级）就是挂在 **host composition（全局）** 上的 patch 层：

1. 插件源码放 `$DSH_HOME/profiles/web/plugins/<插件>/index.mjs`（本地模块，零 import，见前文铁律）。
2. `cordis.patch.yml` 里 insert：
   ```yaml
   - insert:
       - id: godot-gate
         name: ./plugins/godot-gate/index.mjs
   - insert:
       - id: faust-tools
         name: ./plugins/faust-tools/index.mjs
   ```
3. **实时生效**：`watchUserPatches` 监视该文件，改动无需重启；应用失败会回滚到最后一个好树（stderr 有警告）。

> 注：cordis（创造模式）预设的 `tool-cordis` 是进程级单例（Inspect Provider 全局只能注册一次），所以**同一进程内只有一个预设能含它**——这是「创造模式是特权模式」的设计；host 层全局插件不受此限（只要不注册单例服务）。

> 注：`code` 预设的显示名就是「PTC 模式」（preset.yml 的 `name` 字段），这是「ptc」一词的来源。
