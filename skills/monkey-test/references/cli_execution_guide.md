# CLI 実行ガイド

Phase 3b の CLI 並列実行で使用するスクリプトテンプレート、NDJSON 形式、Locator Ladder、Reducer 仕様の参照ドキュメント。

## スクリプトテンプレート

Phase 3b-compile でメインエージェントが生成する `test.js` のテンプレート構造。

### ファイル構成

```
.work/monkey-test/run/
├── run_meta.json              ← 実行メタデータ（auth, baseUrl, budgets）
├── tester-explorer/
│   ├── plan.json              ← コンパイル済みプラン
│   ├── test.js                ← 生成されたテストスクリプト
│   ├── results.ndjson         ← 実行結果（行区切り JSON）
│   ├── screenshots/           ← エージェント固有スクリーンショット
│   └── console-errors.json    ← コンソールエラー
├── tester-naive-user/
│   └── ...
└── ... (各エージェント)
```

### run_meta.json

```json
{
  "run_id": "run-20260218-0900",
  "timestamp": "2026-02-18T09:00:00Z",
  "base_url": "http://localhost:3000",
  "auth": {
    "strategy": "none"
  },
  "budgets": {
    "tester-explorer": 30,
    "tester-naive-user": 30,
    "tester-chaos-input": 30,
    "tester-security-hunter": 40,
    "tester-spec-aware": 30
  },
  "timeout_sec": {
    "smoke": 120,
    "standard": 300,
    "deep": 600
  },
  "confidence_threshold": 0.6
}
```

Basic 認証の場合:

```json
{
  "auth": {
    "strategy": "basic",
    "username": "admin",
    "password": "secret123"
  }
}
```

### plan.json（コンパイル済みプラン形式）

Phase 3b-compile でメインエージェントがプラン `.md` のテーブルをパースして生成する中間形式。

```json
{
  "agentId": "tester-explorer",
  "sequences": [
    {
      "id": "SEQ-001",
      "name": "Dashboard Navigation Coverage",
      "startingUrl": "/",
      "priority": "high",
      "steps": [
        {
          "stepNum": 1,
          "action": "navigate",
          "target": "/",
          "elementMeta": null,
          "input": "/",
          "precondition": null,
          "assertion": "snapshot contains \"ダッシュボード\"",
          "notes": null
        },
        {
          "stepNum": 2,
          "action": "click",
          "target": "Sign Up",
          "elementMeta": {
            "ref": "E-002",
            "type": "button",
            "name": "Sign Up",
            "placeholder": null,
            "testid": null,
            "cssSelector": null
          },
          "input": null,
          "precondition": null,
          "assertion": "snapshot contains \"form\"",
          "notes": null
        }
      ]
    }
  ]
}
```

**elementMeta の構築**: `01_recon_data.md` の Interactive Elements テーブルから TargetRef（E-NNN）を照合して構築する。

| フィールド | ソース | 説明 |
|-----------|--------|------|
| `ref` | TargetRef 列 | Recon 要素 ID |
| `type` | Type 列 | 要素タイプ（button, textbox 等） |
| `name` | Name/Label 列 | 要素のラベル/名前 |
| `placeholder` | Attributes 列から抽出 | placeholder 属性値 |
| `testid` | Attributes 列から抽出 | data-testid 属性値（あれば） |
| `cssSelector` | -(オプション) | CSS セレクタ（Recon 拡張時） |

### test.js テンプレート

```javascript
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const plan = require('./plan.json');
const config = require('../run_meta.json');

const AGENT_ID = plan.agentId;
const OUTPUT_DIR = __dirname;
const RESULT_FILE = path.join(OUTPUT_DIR, 'results.ndjson');
const SCREENSHOT_DIR = path.join(OUTPUT_DIR, 'screenshots');

// --- Locator Ladder ---
const ROLE_MAP = {
  link: 'link', button: 'button', textbox: 'textbox',
  checkbox: 'checkbox', radio: 'radio', combobox: 'combobox',
  slider: 'slider', spinbutton: 'spinbutton'
};

async function resolveLocator(page, meta, threshold) {
  if (!meta) return { status: 'SKIP', method: 'no-meta' };
  const strategies = [];

  if (meta.testid) {
    strategies.push({ loc: () => page.getByTestId(meta.testid), conf: 1.0, method: 'testid' });
  }
  if (meta.type && meta.name && ROLE_MAP[meta.type]) {
    strategies.push({ loc: () => page.getByRole(ROLE_MAP[meta.type], { name: meta.name }), conf: 0.9, method: 'role+name' });
  }
  if (meta.placeholder) {
    strategies.push({ loc: () => page.getByPlaceholder(meta.placeholder), conf: 0.8, method: 'placeholder' });
  }
  if (meta.name) {
    strategies.push({ loc: () => page.getByLabel(meta.name), conf: 0.75, method: 'label' });
    strategies.push({ loc: () => page.getByText(meta.name, { exact: false }), conf: 0.6, method: 'text' });
  }
  if (meta.cssSelector) {
    strategies.push({ loc: () => page.locator(meta.cssSelector), conf: 0.5, method: 'css' });
  }

  for (const s of strategies) {
    if (s.conf < threshold) return { status: 'UNRESOLVED', confidence: s.conf, method: s.method };
    try {
      const locator = s.loc();
      const count = await locator.count();
      if (count === 1) return { status: 'RESOLVED', locator, confidence: s.conf, method: s.method };
      if (count > 1) return { status: 'RESOLVED', locator: locator.first(), confidence: s.conf * 0.7, method: s.method + '+first' };
    } catch { continue; }
  }
  return { status: 'UNRESOLVED', confidence: 0, method: 'none' };
}

// --- Assertion Checker ---
const ASSERTION_PATTERNS = [
  { re: /^title contains "(.+)"$/, fn: async (page, m) => (await page.title()).includes(m[1]) },
  { re: /^url contains "(.+)"$/, fn: async (page, m) => page.url().includes(m[1]) },
  { re: /^url matches "(.+)"$/, fn: async (page, m) => new RegExp(m[1]).test(page.url()) },
  { re: /^snapshot contains "(.+)"$/, fn: async (page, m) => (await page.content()).includes(m[1]) },
  { re: /^snapshot not contains "(.+)"$/, fn: async (page, m) => !(await page.content()).includes(m[1]) },
  { re: /^element enabled "(.+)"$/, fn: async (page, m) => { const el = page.getByText(m[1]); return await el.isEnabled(); } },
  { re: /^element disabled "(.+)"$/, fn: async (page, m) => { const el = page.getByText(m[1]); return !(await el.isEnabled()); } },
  { re: /^dialog appeared$/, fn: async (page, m, ctx) => ctx.dialogAppeared },
  { re: /^dialog not appeared$/, fn: async (page, m, ctx) => !ctx.dialogAppeared },
  { re: /^console has error$/, fn: async (page, m, ctx) => ctx.consoleErrors.length > 0 },
  { re: /^console has no error$/, fn: async (page, m, ctx) => ctx.consoleErrors.length === 0 },
];

async function checkAssertion(page, expr, ctx) {
  for (const p of ASSERTION_PATTERNS) {
    const m = expr.match(p.re);
    if (m) return { pass: await p.fn(page, m, ctx), expr };
  }
  return { pass: null, expr, error: 'unknown assertion pattern' };
}

// --- Action Executor ---
async function executeAction(page, step, ctx) {
  switch (step.action) {
    case 'navigate': {
      const url = step.input?.startsWith('http') ? step.input : config.base_url + (step.input || step.target);
      await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 30000 });
      await page.waitForLoadState('networkidle', { timeout: 5000 }).catch(() => {});
      return { status: 'OK' };
    }
    case 'click': {
      const r = await resolveLocator(page, step.elementMeta, ctx.threshold);
      if (r.status !== 'RESOLVED') return r;
      await r.locator.click({ timeout: 10000 });
      return { status: 'OK', method: r.method, confidence: r.confidence };
    }
    case 'type': {
      const r = await resolveLocator(page, step.elementMeta, ctx.threshold);
      if (r.status !== 'RESOLVED') return r;
      try {
        await r.locator.fill(step.input || '', { timeout: 10000 });
      } catch {
        // Fallback for input[type=number]
        await r.locator.evaluate((el, val) => {
          el.value = val;
          el.dispatchEvent(new Event('input', { bubbles: true }));
          el.dispatchEvent(new Event('change', { bubbles: true }));
        }, step.input || '');
      }
      return { status: 'OK', method: r.method, confidence: r.confidence };
    }
    case 'snapshot': {
      return { status: 'OK', data: 'snapshot taken' };
    }
    case 'screenshot': {
      const fname = step.input || `${AGENT_ID}-step${step.stepNum}.png`;
      await page.screenshot({ path: path.join(SCREENSHOT_DIR, fname) });
      return { status: 'OK', filename: fname };
    }
    case 'wait': {
      if (/^\d+$/.test(step.input)) {
        await page.waitForTimeout(parseInt(step.input) * 1000);
      } else {
        await page.getByText(step.input).first().waitFor({ state: 'visible', timeout: 10000 });
      }
      return { status: 'OK' };
    }
    case 'evaluate': {
      const result = await page.evaluate(step.input);
      return { status: 'OK', data: result };
    }
    case 'select': {
      const r = await resolveLocator(page, step.elementMeta, ctx.threshold);
      if (r.status !== 'RESOLVED') return r;
      await r.locator.selectOption(step.input);
      return { status: 'OK', method: r.method, confidence: r.confidence };
    }
    case 'press_key': {
      await page.keyboard.press(step.input);
      return { status: 'OK' };
    }
    case 'hover': {
      const r = await resolveLocator(page, step.elementMeta, ctx.threshold);
      if (r.status !== 'RESOLVED') return r;
      await r.locator.hover();
      return { status: 'OK', method: r.method, confidence: r.confidence };
    }
    case 'verify_created': {
      const content = await page.content();
      return { status: content.includes(step.target) ? 'PASS' : 'FAIL' };
    }
    case 'verify_list_contains': {
      await page.goto(config.base_url + step.target, { waitUntil: 'domcontentloaded' });
      const content = await page.content();
      return { status: content.includes(step.input) ? 'PASS' : 'FAIL' };
    }
    default:
      return { status: 'UNKNOWN_ACTION', action: step.action };
  }
}

// --- Main Runner ---
(async () => {
  fs.mkdirSync(SCREENSHOT_DIR, { recursive: true });
  if (fs.existsSync(RESULT_FILE)) fs.unlinkSync(RESULT_FILE);

  const browser = await chromium.launch({ headless: true });
  const ctxOptions = {};
  if (config.auth?.strategy === 'basic') {
    ctxOptions.httpCredentials = { username: config.auth.username, password: config.auth.password };
  }
  const context = await browser.newContext(ctxOptions);
  const page = await context.newPage();

  const consoleErrors = [];
  page.on('console', msg => { if (msg.type() === 'error') consoleErrors.push({ text: msg.text(), url: page.url() }); });

  let dialogAppeared = false;
  page.on('dialog', async dialog => { dialogAppeared = true; await dialog.accept(); });

  const ctx = { threshold: config.confidence_threshold || 0.6, consoleErrors, dialogAppeared };
  const budget = config.budgets?.[AGENT_ID] || 30;
  let actionsUsed = 0;
  let issuesFound = 0;

  function writeResult(data) {
    fs.appendFileSync(RESULT_FILE, JSON.stringify({ run_id: config.run_id, agent_id: AGENT_ID, ts: new Date().toISOString(), ...data }) + '\n');
  }

  const sequences = plan.sequences.sort((a, b) => {
    const p = { high: 0, medium: 1, low: 2 };
    return (p[a.priority] || 2) - (p[b.priority] || 2);
  });

  for (const seq of sequences) {
    if (actionsUsed >= budget) { writeResult({ type: 'skip', seq: seq.id, reason: 'budget' }); break; }
    writeResult({ type: 'seq_start', seq: seq.id, name: seq.name });
    await page.goto(config.base_url + seq.startingUrl, { waitUntil: 'domcontentloaded', timeout: 30000 });

    for (const step of seq.steps) {
      if (actionsUsed >= budget) break;
      dialogAppeared = false;
      ctx.dialogAppeared = false;

      try {
        const result = await executeAction(page, step, ctx);
        actionsUsed++;

        let assertion = null;
        if (step.assertion && step.assertion !== '-') {
          assertion = await checkAssertion(page, step.assertion, ctx);
          if (assertion.pass === false) {
            issuesFound++;
            await page.screenshot({ path: path.join(SCREENSHOT_DIR, `${AGENT_ID}-${seq.id}-step${step.stepNum}.png`) }).catch(() => {});
          }
        }

        writeResult({ type: 'step', seq: seq.id, step: step.stepNum, action: step.action, target: step.target, status: result.status, locator_method: result.method || null, confidence: result.confidence || null, assertion: assertion ? { expr: step.assertion, pass: assertion.pass } : null });
      } catch (err) {
        actionsUsed++;
        issuesFound++;
        await page.screenshot({ path: path.join(SCREENSHOT_DIR, `${AGENT_ID}-${seq.id}-step${step.stepNum}-error.png`) }).catch(() => {});
        writeResult({ type: 'step', seq: seq.id, step: step.stepNum, action: step.action, status: 'ERROR', error: err.message });
      }
    }
    writeResult({ type: 'seq_end', seq: seq.id });
  }

  writeResult({ type: 'summary', actions_used: actionsUsed, budget, issues: issuesFound, self_heal_attempts: 0, self_heal_successes: 0 });
  await browser.close();
  process.exit(issuesFound > 0 ? 1 : 0);
})();
```

## NDJSON 結果形式

各行は独立した JSON オブジェクト。タイプ別のスキーマ:

### seq_start

```json
{"run_id":"run-001","agent_id":"tester-explorer","ts":"2026-02-18T10:00:00Z","type":"seq_start","seq":"SEQ-001","name":"Dashboard Nav"}
```

### step

```json
{"run_id":"run-001","agent_id":"tester-explorer","ts":"2026-02-18T10:00:01Z","type":"step","seq":"SEQ-001","step":1,"action":"navigate","target":"/","status":"OK","locator_method":null,"confidence":null,"assertion":null}
```

```json
{"run_id":"run-001","agent_id":"tester-explorer","ts":"2026-02-18T10:00:02Z","type":"step","seq":"SEQ-001","step":2,"action":"click","target":"Sign Up","status":"OK","locator_method":"role+name","confidence":0.9,"assertion":{"expr":"snapshot contains \"form\"","pass":true}}
```

### step（UNRESOLVED）

```json
{"type":"step","seq":"SEQ-001","step":3,"action":"click","target":"Submit","status":"UNRESOLVED","locator_method":"text","confidence":0.5,"assertion":null}
```

### step（ERROR）

```json
{"type":"step","seq":"SEQ-001","step":4,"action":"type","status":"ERROR","error":"TimeoutError: element not found"}
```

### summary

```json
{"type":"summary","actions_used":10,"budget":30,"issues":0,"self_heal_attempts":2,"self_heal_successes":2}
```

## Locator Ladder

要素解決の優先順位。Recon データの elementMeta から複数の戦略を生成し、confidence が高い順に試行する。

| 優先度 | 方法 | Playwright API | Confidence | 説明 |
|-------|------|---------------|-----------|------|
| 1 | data-testid | `page.getByTestId()` | 1.0 | 最も安定。アプリが testid を持つ場合のみ |
| 2 | role + name | `page.getByRole()` | 0.9 | Recon の Type + Name/Label から生成。最も一般的 |
| 3 | placeholder | `page.getByPlaceholder()` | 0.8 | textbox の placeholder 属性 |
| 4 | label | `page.getByLabel()` | 0.75 | label 要素との関連付け |
| 5 | text | `page.getByText()` | 0.6 | 表示テキストで検索。曖昧マッチのリスクあり |
| 6 | CSS selector | `page.locator()` | 0.5 | DOM 構造依存。最も脆弱 |

### Confidence Gate

- threshold 未満（デフォルト 0.6）の場合、アクションを実行せず `UNRESOLVED` として記録
- threshold はプロファイルで調整可能: smoke=0.5, standard=0.6, deep=0.7

### 複数マッチ時

`locator.count() > 1` の場合、`.first()` を使用するが confidence を 0.7 倍に減衰。

## Reducer 仕様

Phase 3b-reduce でメインエージェントが各エージェントの NDJSON を集約して既存形式に変換する。

### 入力

- `run/{agent_id}/results.ndjson`（各エージェント）
- `run/{agent_id}/screenshots/`（各エージェント）

### 出力

- `03_execution/{agent-name}.md`（既存の実行ログ形式）
- `shared/issue_registry.md`（更新）
- `shared/created_data.json`（更新、新規データあれば）
- `screenshots/`（統合コピー）

### 変換ルール

| NDJSON type | 実行ログへのマッピング |
|-------------|---------------------|
| `seq_start` | `### SEQ-NNN: {name}` セクション開始 |
| `step` (OK) | テーブル行: Step / Action / Target / Result=OK / Issue=- |
| `step` (UNRESOLVED) | テーブル行: Result=UNRESOLVED (confidence=X) / Issue=NOTE |
| `step` (ERROR) | テーブル行: Result=ERROR / Issue=YES + スクリーンショット参照 |
| `step` (assertion fail) | テーブル行: Result=FAIL / Issue=YES |
| `summary` | ヘッダーメタデータ（Actions completed, Issues found） |

### Self-Healing メトリクス

NDJSON の `summary` 行から `self_heal_attempts` と `self_heal_successes` を抽出し、実行ログの Self-Healing Metrics テーブルに記載。

## データ名前空間

並列実行時のデータ競合を回避するための規約。

### 書き込みルール

- 各エージェントは `run/{agent_id}/` 配下にのみ書き込む（shared write 禁止）
- テストデータ作成時のプレフィックス: `{agent_id}_{timestamp}`
- `created_data.json` への書き込みは Reducer が一括実行

### 競合回避パターン

| 操作 | パターン | 例 |
|------|---------|-----|
| シナリオ作成 | `{agent_id}_` プレフィックス | `tester-explorer_20260218T100000 Test Scenario` |
| ファイル書き込み | agent ローカルディレクトリ | `run/tester-explorer/results.ndjson` |
| スクリーンショット | agent ローカルディレクトリ | `run/tester-explorer/screenshots/` |
