export default {
  name: 'faust-tools',
  inject: ['tools', 'shell', 'systemPrompt'],
  apply(ctx) {
    const skills = ctx.get('skills')
    if (skills !== undefined) {
      skills.register({
        name: 'faust-clone-reference',
        description: '浮士德项目的逆向验证方法论：证据层级、双信号规则、SRC 指针与语料库导航。用于任何依赖《苏丹的游戏》原作行为的任务。',
        content: [
          "Use in the Faust repo for any task whose correctness depends on the original Sultan's Game: reverse-engineered mechanics, rite/event/loot generation, DSL semantics, card interactions, dice, counters, tags, scope filters, branches, gold dice, or source-backed fidelity claims. Do NOT treat wiki pages, project comments, prior summaries, or this skill as primary evidence.",
          "",
          "PATHS",
          "- Clone workspace: C:/Users/User/Documents/GitHub/Faust",
          "- Read-only corpus (never modify/copy): C:/Users/User/Documents/GitHub/Faust-local-source/_unpack",
          "- Decompiled code: _unpack/engine_spec/decompiled/*.c",
          "- Symbols/layouts: _unpack/il2cpp_dump/dump.cs",
          "- Original config: _unpack/data/config",
          "- Handoff indexes: _unpack/engine_spec/handoff",
          "",
          "EVIDENCE HIERARCHY (highest first)",
          "1. Decompiled .c method bodies (behavioral fact).",
          "2. dump.cs (class/field/method/RVA/signature fact; no method behavior).",
          "3. Original JSON/i18n/save samples (config and observable-data fact).",
          "4. Markdown/Wiki/comments/prior agent conclusions (navigation hints only).",
          "If a Markdown claim conflicts with .c or config, stop and report the conflict; do not average sources.",
          "",
          "DUAL-SIGNAL RULE (high risk)",
          "Before implementing comparison direction, inclusive/exclusive boundary, off-by-one, sign semantics, clamp/truncation/zero-floor, random count/replacement/draw order, or card consumption/cleanup/death, require ONE .c signal PLUS ONE independent signal (config arithmetic/text, dump symbols, another call site, i18n, save sample, runtime observation). If signals disagree, mark [CONFLICT] and do not guess.",
          "",
          "SRC POINTER FORMAT",
          "[SRC: decompiled/FuncCompare.c @ IsSatisfied (RVA 0x3fc060, dump.cs:416927)]",
          "",
          "NAVIGATION (run from _unpack/engine_spec)",
          "node lookup.js FuncCompare",
          "node show_func.js IsSatisfied FuncCompare.c",
          "node trace_addr.js 0x3fc060",
          "",
          "OUTPUT CONTRACT",
          "Separate: verified facts with SRC pointers; config observations; inferences; conflicts/open questions; implementation priorities and tests. Do not call a feature faithful/complete/original-compatible when unsupported DSL keys, missing event content, or unverified runtime transitions can still change outcomes."
        ].join('\n')
      })

      skills.register({
        name: 'faust-case-study-method',
        description: '浮士德项目竞争作品案例研究方法论：读模板、联网取证、区分证据强度、落盘文档、登记主张与来源、更新检查器与索引、闭合验证。用于为任何游戏作品建立设计研究案例。',
        content: [
          '用于为竞争作品建立 Faust 设计研究案例。目标是把「已查证事实 / 推断 / 待验证」分开并登记进研究证据体系，而不是把猜测写成结论。',
          '',
          '1. 读模板。参考 docs/design/ 下已有案例研究的章节结构（如 unicorn-overlord-autobattle-narrative-reference.md、loop-hero-loop-structure-reference.md）：1 新会话先读结论 / 2 为什么与 Faust 相关 / 3 已由公开资料确认的结构 / 4 与参照系的差异 / 5 对当前核心矛盾的启示与反例 / 6 正确位置 / 7 对 Faust 的直接约束。',
          '2. 联网取证。优先一手来源：开发者访谈、官方复盘（postmortem）、权威攻略的精确数值、官方销量公告。用 web_search 和网页抓取，记录 URL。',
          '3. 区分证据强度。已查证事实标 A（带来源）；推断与媒体解释标 B/C；没有数据支撑的结论登记为缺口（前缀-GAP-XXX，等级 U），不得写成已测参数。',
          '4. 落盘研究文档。路径 docs/design/<slug>-<主题>-reference.md。',
          '5. 登记主张。在 docs/research/faust-game-design-data-research.md 的主张登记表（### 2.5）追加行：| 前缀-编号 | 主张 | 类别 | 等级 A/B/C/U | 来源 ID | 限制 |。前缀用作品缩写（如 LH、UO），编号从 001 起。',
          '6. 登记来源。在来源登记表追加行：| 前缀-官方-编号 | 来源 | 日期/版本 | 数据或方法 | 主要限制 |。',
          '7. 更新一致性检查器 tools/check_design_research.ps1：把新前缀加进作品 ID 正则（(?:SG|FE3H|P5R|BG|MJ|UX|NARR|FAUST|LOCAL|TEL|UO|NAB|LH) 中），并把新文档纳入必读入口清单。',
          '8. 更新索引 docs/research/README.md 的研究主题索引，加一行指向新文档和主张 ID。',
          '9. 闭合验证。运行 tools/check_design_research.ps1，必须通过：无未知 ID、无重复 ID、无坏链接、快照新鲜。不通过就不算完成。',
          '10. 诚实边界。没有玩家遥测或实验数据的领域，明确写「尚无数据」，不引用类比补写。'
        ].join('\n')
      })
    }

    ctx.systemPrompt.section({
      name: 'faust:workflow-tools',
      order: 150,
      text: '浮士德工作流工具（来自全局 faust-tools 与 godot-gate 插件）：改完代码前用 godot_run_tests（GUT 套件 + SCRIPT ERROR/orphan/leak 门禁）；引用设计研究数字或改研究文档前用 faust_check_research；新增内容或标记 DSL 键受支持前用 faust_audit_dsl；开始竞争作品案例研究前用 faust_new_case 生成任务单。逆向验证遵循 faust-clone-reference skill，案例研究遵循 faust-case-study-method skill。'
    })

    const runGate = (name, description, command, timeoutMs) => {
      ctx.tools.register({
        name,
        description,
        parameters: { type: 'object', properties: {}, additionalProperties: false },
        output: {
          schema: { type: 'string' },
          render: (_args, value) => [{ type: 'text', text: String(value) }]
        },
        timeoutMs,
        execute: async (_args, _exec) => {
          const spec = ctx.shell.resolve({
            command,
            workdir: 'C:/Users/User/Documents/GitHub/Faust',
            timeoutMs
          })
          const result = await ctx.shell.run(spec)
          const body = (result.stdout.text + result.stderr.text).trim()
          const ok = result.exitCode === 0 && !result.timedOut && !result.aborted
          return (ok ? '通过\n' : '失败\n') + body
        }
      })
    }

    runGate(
      'faust_check_research',
      '查研究：运行设计研究一致性检查（tools/check_design_research.ps1）：快照新鲜度、主张/来源登记完整性、文档可发现性和链接健康。返回通过或失败加检查输出。',
      'powershell -NoProfile -ExecutionPolicy Bypass -File tools/check_design_research.ps1',
      120000
    )

    runGate(
      'faust_audit_dsl',
      '审规则：导出 Faust DSL 覆盖审计（tools/export_dsl_audit.gd）：每个不受支持的 condition/result/action 键，含配置类型、ID、路径和位置。返回导出路径加摘要。',
      'C:/Tools/Godot/4.7-stable/Godot_v4.7-stable_win64.exe --headless --path . --script tools/export_dsl_audit.gd',
      120000
    )

    ctx.tools.register({
      name: 'faust_new_case',
      description: '新案例研究：为竞争作品生成设计研究任务单（产出文档路径、主张/来源前缀、检查器与索引更新点、闭合验证命令）。',
      parameters: {
        type: 'object',
        properties: {
          game_name: { type: 'string', description: '游戏中文名，如 循环勇者' },
          game_slug: { type: 'string', description: '游戏英文 slug，如 loop-hero' },
          prefix: { type: 'string', description: '主张/来源前缀（作品缩写），如 LH、UO' }
        },
        required: ['game_name', 'game_slug', 'prefix'],
        additionalProperties: false
      },
      output: {
        schema: { type: 'string' },
        render: (_args, value) => [{ type: 'text', text: String(value) }]
      },
      execute: async (args, _exec) => {
        return [
          '新案例研究任务单：' + args.game_name + '（' + args.game_slug + '）',
          '',
          '1. 产出文档：docs/design/' + args.game_slug + '-reference.md（章节结构照 unicorn-overlord / loop-hero 模板：1 新会话先读结论 / 2 为什么与 Faust 相关 / 3 已确认结构 / 4 差异 / 5 启示与反例 / 6 正确位置 / 7 对 Faust 的直接约束）',
          '2. 主张登记：docs/research/faust-game-design-data-research.md 主张登记表（### 2.5）追加 ' + args.prefix + '-001 起，格式 | 前缀-编号 | 主张 | 类别 | A/B/C/U | 来源 ID | 限制 |',
          '3. 来源登记：来源登记表追加 ' + args.prefix + '-OFFICIAL-001 起',
          '4. 检查器更新：tools/check_design_research.ps1 作品 ID 正则加入 ' + args.prefix + '（当前含 SG|FE3H|P5R|BG|MJ|UX|NARR|FAUST|LOCAL|TEL|UO|NAB|LH），并把新文档纳入必读入口清单',
          '5. 索引更新：docs/research/README.md 研究主题索引加一行',
          '6. 闭合验证：powershell -NoProfile -ExecutionPolicy Bypass -File tools/check_design_research.ps1（必须通过）',
          '7. 证据纪律：无数据的结论登记为 ' + args.prefix + '-GAP-001（U 级未知），不得写成已测参数'
        ].join('\n')
      }
    })
  }
}
