"""Build offline readers and a complete evidence inventory; never changes runtime content."""
from pathlib import Path
import hashlib
import html
import json
import re

ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / 'docs'
OUT = DOCS / 'replica'

def write(name, value):
    (OUT / name).write_text(value, encoding='utf-8')

def role(path):
    name = path.as_posix().lower()
    if path.suffix in {'.png', '.jpg'}:
        return '截图或图像证据', 'presentation', '按文件记录的状态使用；不单凭截图认定过程等价'
    if path.suffix == '.asm':
        return '着色器反汇编证据', 'presentation', '用于具体程序/常量核验，不推定完整渲染等价'
    if path.suffix == '.log':
        return '历史运行日志', 'verification', '只证明该次运行；当前结果见verification正文'
    if path.suffix == '.csv':
        return '扫描候选或数据表', 'verification', '候选/统计不等于已验证问题或已通过'
    if 'research' in name or 'innovation' in name:
        return '研究来源与整合索引', '../design/evidence-and-decisions', '按来源日期、主张等级和决定状态使用'
    if 'shader' in name or 'shaker' in name or 'audio' in name or 'ui_layout' in name:
        return '原作结构或表现测量数据', 'presentation', '具体字段证据；静态作者值与运行测量分别解释'
    if path.suffix in {'.mjs', '.html'}:
        return '历史诊断工具或原型', 'verification', '不是当前产品契约或正式运行入口'
    return '状态审计与验证数据', 'verification', '范围以配套方法与输入记录为准'

# Resolve artifact citations to the integrated argument, not just a broad folder.
sections = []
for doc in sorted(OUT.glob('*.md')):
    for part in re.split(r'(?=<a id=")', doc.read_text(encoding='utf-8')):
        anchor = re.match(r'<a id="([^"]+)">', part)
        sections.append((doc.relative_to(ROOT).as_posix() + ('#' + anchor[1] if anchor else ''), part))
rows = []
documentary_paths = list(DOCS.rglob('*')) + list((ROOT / '.reasonix').rglob('*')) + list((ROOT / '.zcode').rglob('*'))
for p in sorted(documentary_paths):
    if not p.is_file() or p.suffix in {'.md', '.import', '.translation'} or p.name == '.gdignore' or OUT in p.parents:
        continue
    label, domain, boundary = role(p)
    if '.reasonix' in p.parts:
        if p.suffix == '.png':
            label, domain, boundary = '早期克隆诊断截图', 'presentation', '1152×648旧克隆窗口，控件错位且含AudioManager缺失报错；不是原作截图、当前UI目标或通过证据'
        else:
            label, domain, boundary = '应用会话元数据', 'verification', '标题和创建时间仅用于来源定位；不构成设计决定或执行计划'
    rows.append({'path': p.relative_to(ROOT).as_posix(), 'bytes': p.stat().st_size,
                 'sha256': hashlib.sha256(p.read_bytes()).hexdigest(), 'role': label,
                 'integrated_into': 'docs/replica/' + domain + '.md', 'boundary': boundary,
                 'argument_sections': [target for target, body in sections if p.name in body or p.relative_to(ROOT).as_posix() in body]})
write('evidence-manifest.json', json.dumps({'schema': 1, 'scope': 'Every non-Markdown documentary artifact under docs plus .reasonix and .zcode metadata/attachments; generated caches and integrated-reader outputs are excluded.', 'files': rows}, ensure_ascii=False, indent=2) + '\n')

css = '''body{margin:0;background:#f3f1eb;color:#262e32;font:16px/1.55 system-ui,"Microsoft YaHei",sans-serif}header{padding:24px 32px;background:#163e40;color:#fff}header p{max-width:960px;margin:8px 0 0}main{padding:24px 32px}input,select{padding:10px;border:1px solid #bcc8c4;border-radius:5px;font:inherit;background:white}input{width:min(600px,70vw)}a{color:#116b6b}table{border-collapse:collapse;background:white;width:100%;font-size:14px}th,td{text-align:left;vertical-align:top;border:1px solid #dce1dc;padding:8px;overflow-wrap:anywhere}th{background:#dfeae5;position:sticky;top:0}section{overflow:auto;margin-top:16px}small{color:#57676a}button{padding:8px 12px;cursor:pointer}pre{white-space:pre-wrap}#status{margin:14px 0}nav{display:flex;gap:12px;flex-wrap:wrap}details{background:white;margin:12px 0;padding:12px}'''
def page(title, subtitle, body, data, script):
    payload = json.dumps(data, ensure_ascii=False).replace('<', '\\u003c')
    return f'''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{title}</title><style>{css}</style><header><h1>{title}</h1><p>{subtitle}</p></header><main>{body}</main><script id="data" type="application/json">{payload}</script><script>{script}</script></html>'''

evidence_js = '''const data=JSON.parse(document.getElementById('data').textContent);const q=document.getElementById('q');const filter=document.getElementById('role');for(const v of [...new Set(data.map(x=>x.role))])filter.add(new Option(v,v));function render(){const term=q.value.toLowerCase();const rows=data.filter(x=>(!filter.value||x.role===filter.value)&&JSON.stringify(x).toLowerCase().includes(term));document.getElementById('status').textContent=`显示 ${rows.length} / ${data.length} 项`;const body=document.getElementById('rows');body.replaceChildren();for(const x of rows){const tr=document.createElement('tr');for(const key of ['path','role','boundary']){const td=document.createElement('td');if(key==='path'){const a=document.createElement('a');a.href='../../'+x.path;a.textContent=x.path;td.append(a);const s=document.createElement('small');s.textContent=' · '+Math.round(x.bytes/1024)+' KB';td.append(s)}else{td.textContent=x[key];if(key==='boundary'){for(const target of (x.argument_sections.length?x.argument_sections:[x.integrated_into])){const a=document.createElement('a');a.href='../../'+target;a.textContent=' → '+target.split('/').pop();td.append(document.createElement('br'),a)}}}tr.append(td)}body.append(tr)}}q.addEventListener('input',render);filter.addEventListener('change',render);render();'''
write('evidence-browser.html', page('证据资料册', '所有资料都有用途、所属章节和证据边界。历史日志、静态参数与本轮验收不混用；本页完全离线。', '<nav><input id="q" aria-label="搜索证据" placeholder="输入页面、方法、文件名或关键词"><select id="role" aria-label="证据类型"><option value="">全部类型</option></select></nav><div id="status"></div><section><table><thead><tr><th>文件</th><th>用途</th><th>解释边界</th></tr></thead><tbody id="rows"></tbody></table></section>', rows, evidence_js))

layout = json.loads((OUT / 'layout-data.json').read_text(encoding='utf-8'))
layout_js = '''const data=JSON.parse(document.getElementById('data').textContent),select=document.getElementById('source'),q=document.getElementById('q'),view=document.getElementById('view');for(const d of data)select.add(new Option(d.title,d.id));if(data.some(d=>d.id===location.hash.slice(1)))select.value=location.hash.slice(1);function render(){const d=data.find(x=>x.id===select.value);if(!d)return;history.replaceState(null,'','#'+d.id);view.replaceChildren();const term=q.value.toLowerCase();let table=null,count=0;for(const line of ((d.generated_text ? '# 最新导出表\\n'+d.generated_text+'\\n# 整合时的原始表与补充说明（历史）\\n' : '')+d.text).split(/\\r?\\n/)){if(line.startsWith('|')){if(/^\\|[ |:\\-]+\\|$/.test(line))continue;const cells=line.slice(1,-1).split(/(?<!\\\\)\\|/).map(s=>s.trim().replaceAll('\\\\|','|'));if(term&&!line.toLowerCase().includes(term))continue;if(!table){table=document.createElement('table');view.append(table)}const tr=document.createElement('tr');for(const s of cells){const td=document.createElement('td');td.textContent=s;tr.append(td)}table.append(tr);count++}else{table=null;if(!line.trim())continue;if(term&&!line.toLowerCase().includes(term))continue;const p=document.createElement(line.startsWith('#')?'h3':'p');p.textContent=line.replace(/^#+ /,'');view.append(p)}}document.getElementById('status').textContent=d.old_path+' · '+count+' 条匹配表格行'}select.addEventListener('change',render);q.addEventListener('input',render);render();'''
write('layout-browser.html', page('原作布局数据册', '按页面选择，再搜索节点路径或字段。保留完整原始表格与补充说明；静态表不代表运行时已通过。', '<nav><select id="source" aria-label="选择页面"></select><input id="q" aria-label="搜索节点" placeholder="搜索节点、字体、位置或图像引用"></nav><div id="status"></div><section id="view"></section>', layout, layout_js))

summary = ['# 证据资料与再生成\n', '[打开可搜索证据册](evidence-browser.html)；[查看逐文件哈希与章节归属](evidence-manifest.json)。\n',
           '所有截图、JSON、CSV、反汇编、日志、旧诊断原型及隐藏目录附件都已登记用途与解释边界。文件保留原路径是为了保持测试/导出工具的稳定输入，不是未整合材料；旧平行Markdown已删除。当前状态只见[验收正文](verification.md)。\n',
           '## 证据类型\n', '| 类型 | 文件数 | 使用方式 |\n|---|---:|---|']
for label in sorted({x['role'] for x in rows}):
    members = [x for x in rows if x['role'] == label]
    summary.append(f'| {label} | {len(members)} | {members[0]["boundary"]} |')
summary.extend(['\n## 维护\n', '运行 tools/build_documentation_views.py 更新离线阅读器及清单，再运行 tools/check_workspace_documentation.py。导出布局仍写入原JSON，并更新统一layout-data.json；不再生成旧Markdown。新资料没有登记或退役旧正文复现时，校验必须失败。\n',
                '原始创新ZIP已从工作区删除，仅通过843f0100的Git对象追溯；清单和校验器可离线核验。仓库外的双端运行材料由[外部证据登记](external-evidence.json)统一承载路径、哈希与用途，不复制原作完整存档进项目。\n'])
write('evidence.md', '\n'.join(summary))
print(f'Built offline readers: {len(layout)} layout sources, {len(rows)} registered documentary artifacts.')

# External evidence is indexed locally; original saves are not copied into the repo.
external_path = OUT / 'external-evidence.json'
if external_path.exists():
    external = json.loads(external_path.read_text(encoding='utf-8'))
    existing = {x['path']: x for x in external['files']}
    roots = sorted({str(Path(x['path']).parent) for x in external['files'] if Path(x['path']).parent.name in {'Faust-phase-close-20260914', 'Faust-dual-replay-20260914', 'Faust-dual-replay-followup-20260914'}})
    for root in roots:
        for p in Path(root).rglob('*'):
            if not p.is_file():
                continue
            key = p.as_posix()
            record = existing.setdefault(key, {'path': key, 'integrated_into': 'docs/replica/verification.md', 'role': '本轮验证及整合过程记录', 'boundary': '按最新验收解释；脚本与旧日志不构成当前执行指令'})
            record.update(bytes=p.stat().st_size, sha256=hashlib.sha256(p.read_bytes()).hexdigest())
    external['files'] = sorted(existing.values(), key=lambda x:x['path'])
    write('external-evidence.json', json.dumps(external, ensure_ascii=False, indent=2) + '\n')
    print(f'External evidence indexed: {len(existing)} files.')
