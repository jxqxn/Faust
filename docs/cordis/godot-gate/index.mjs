export default {
  name: 'godot-gate',
  inject: ['tools', 'shell'],
  apply(ctx) {
    ctx.tools.register({
      name: 'godot_run_tests',
      description: '跑测试：运行当前 Godot 项目的 GUT 测试套件（tools/run_gut.ps1），并做 SCRIPT ERROR/orphan/leak 门禁检查。工作目录取当前会话，任何 Godot 项目通用。返回通过或失败加测试摘要。',
      parameters: { type: 'object', properties: {}, additionalProperties: false },
      output: {
        schema: { type: 'string' },
        render: (_args, value) => [{ type: 'text', text: String(value) }]
      },
      timeoutMs: 300000,
      execute: async (_args, exec) => {
        const cwd = exec.agent?.session?.header?.cwd ?? process.cwd()
        const spec = ctx.shell.resolve({
          command: 'powershell -NoProfile -ExecutionPolicy Bypass -File tools/run_gut.ps1',
          workdir: cwd,
          timeoutMs: 300000
        })
        const result = await ctx.shell.run(spec)
        const body = (result.stdout.text + result.stderr.text).trim()
        const ok = result.exitCode === 0 && !result.timedOut && !result.aborted
        return (ok ? '通过\n' : '失败\n') + body
      }
    })
  }
}
