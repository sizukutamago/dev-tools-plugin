---
name: monkey-test
description: Orchestrate multiple AI agents with different personalities to perform monkey testing on web applications using Playwright MCP. Agents include spec-aware tester, naive user, security hunter, chaos input, and systematic explorer. Triggers on "monkey test", "monkey testing", "exploratory testing", "モンキーテスト", "自動テスト"
version: 1.2.0
---

# モンキーテストスキル

性格の異なる複数の AI テスターで Web アプリの堅牢性を検証する。
**Playwright MCP** でブラウザを操作し、**Swarm パターン**（並列エージェント）でテスト計画を生成する。

## 概要

| 項目 | 内容 |
|------|------|
| **対象** | 任意の Web アプリケーション（URL 指定） |
| **出力形式** | Markdown レポート + スクリーンショット |
| **中間成果物** | `.work/monkey-test/` に保存（`.gitignore` 対象） |
| **最終成果物** | `monkey-test-report.md` |

## 核心的制約

**Playwright MCP はメインエージェント（このスキルを実行する Claude Code）のみが使用可能。**
Task サブエージェントは Playwright にアクセスできない。

→ この制約を解決するため「偵察→計画（並列）→実行（順次）→集約」のフェーズ分離を採用。

## アーキテクチャ

```
┌───────────────────────────────────────────────────────────────┐
│                Orchestrator (SKILL.md / Main Agent)             │
│                ★ Playwright MCP はここだけ ★                    │
├───────────────────────────────────────────────────────────────┤
│                                                                │
│  Phase 0: Configuration                                        │
│  → URL、コンテキストモード、エージェント選択、アクション予算     │
│                                                                │
│  Phase 1: Recon (Main Agent, Playwright MCP)                   │
│  → BFS 巡回 → Interactive Discovery → Workflow Map 構築        │
│                                                                │
│  Phase 1b: Codebase Analysis (Task, optional)                  │
│  → コード/仕様分析 → ルート、バリデーション抽出                  │
│                                                                │
│  Phase 2a: Workflow Planning (Task × 1)                        │
│  ┌──────────┐                                                  │
│  │workflow  │ ← Workflow Map から CRUD テスト計画               │
│  │(opus)    │                                                  │
│  └────┬─────┘                                                  │
│       ▼                                                        │
│  Phase 3a: Workflow Execution (Main Agent, Playwright MCP)     │
│  → ワークフローテスト実行 → shared/created_data.json 生成      │
│  → 01_recon_data.md に動的ページの要素を追記                   │
│       │                                                        │
│       ▼                                                        │
│  Phase 2b: Planning Swarm (Task × 5, 並列)                     │
│  ┌──────────┬──────────┬──────────┬──────────┬──────────┐      │
│  │spec-     │naive-    │security- │chaos-    │explorer  │      │
│  │aware     │user      │hunter    │input     │          │      │
│  │(opus)    │(sonnet)  │(opus)    │(sonnet)  │(sonnet)  │      │
│  └────┬─────┴────┬─────┴────┬─────┴────┬─────┴────┬─────┘      │
│       └──────────┴──────────┼──────────┴──────────┘            │
│                             ▼                                   │
│  Phase 3b: CLI Parallel Execution (Main Agent + Bash)          │
│  → 3b-compile: プラン→JSON→test.js 生成                        │
│  → 3b-execute: 5エージェント並列実行（独立ブラウザ）            │
│  → 3b-reduce: NDJSON→実行ログ変換、Issue/Coverage 集約         │
│                             │                                   │
│  Phase 4: Reporting (Task)                                      │
│  → 全ログ統合 → monkey-test-report.md 生成                     │
└───────────────────────────────────────────────────────────────┘
```

## 作業ディレクトリ

Phase 開始前に作成する（`.gitignore` 対象）:

```
.monkey-test/                    ← 永続認証設定（.gitignore 推奨）
└── auth.json
```

```
.work/monkey-test/
├── 00_config.json
├── auth_storage_state.json      ← Phase 1 で保存（Cookie/セッション）
├── 01_recon_data.md
├── 01b_spec_context.md          (optional)
├── 02_plans/
│   ├── tester-workflow.md       ← Phase 2a で最初に生成
│   ├── tester-explorer.md
│   ├── tester-naive-user.md
│   ├── tester-chaos-input.md
│   ├── tester-security-hunter.md
│   └── tester-spec-aware.md
├── 03_execution/
│   ├── tester-workflow.md       ← Phase 3a で最初に実行
│   ├── tester-explorer.md
│   ├── tester-naive-user.md
│   └── ...
├── run/                         ← Phase 3b-compile で生成
│   ├── run_meta.json
│   ├── tester-explorer/
│   │   ├── plan.json
│   │   ├── test.js
│   │   ├── results.ndjson
│   │   └── screenshots/
│   └── ... (各エージェント)
├── shared/
│   ├── issue_registry.md
│   ├── created_data.json        ← Phase 3a で生成（JSON 正本）
│   └── created_data.md          ← Phase 3a で生成（ビュー用）
└── screenshots/
    ├── recon-P001.png
    └── ...
```

**事前準備**:
```bash
mkdir -p .work/monkey-test/{02_plans,03_execution,shared,screenshots,run}
```

---

## ワークフロー

### Phase 0: Configuration

**目的**: テスト対象と実行パラメータを決定する。

**手順**:

1. ユーザーから対象 URL を確認（コマンド引数があればそれを使用）

2. **永続認証設定の検出**:
   `.monkey-test/auth.json` が存在するか確認する。

   **存在する場合**: auth.json を読み込み、AskUserQuestion で再利用を確認:
   - 「前回の認証設定が見つかりました（戦略: {strategy}, ユーザー: {username}）。この設定を使いますか？」
     - **使う**: auth.json の内容を `00_config.json` の auth セクションにコピー。認証質問をスキップ
     - **設定し直す**: 初回フローへ（下記 Step 3 の認証質問を実行）
     - **認証なしで実行**: `auth.strategy = "none"` で続行

   **存在しない場合**: 初回フローへ（Step 3 の認証質問を実行）

3. AskUserQuestion で以下を確認:
   - **コンテキストモード**: `url-only`（URLのみ） / `url+spec`（仕様あり） / `url+codebase`（コード解析あり）
   - **認証**: `none`（不要）/ `credentials`（フォームログイン）/ `basic`（HTTP Basic 認証）/ `manual`（手動ログイン）
   - **エージェント選択**: デフォルト全5種を使うか、カスタム選択するか

   **`credentials` 選択時の追加質問**（別途 AskUserQuestion を実行）:
   - Q1: ログイン URL は？ → `/login`, `/auth/signin`, `/sign-in`, Other
   - Q2: ユーザー名フィールドのラベルは？ → `"Email"`, `"メールアドレス"`, `"Username"`, `"ユーザー名"`
   - Q3: パスワードフィールドのラベルは？ → `"Password"`, `"パスワード"`
   - Q4: ログイン成功の判定方法は？ → `URL 変化で判定`（url_changed）, `特定テキスト表示で判定`（text_visible）, `URL に特定パスを含むで判定`（url_contains）

   続けて、ユーザー名とパスワードの実値をテキストで直接入力してもらう（機密情報のため AskUserQuestion の選択肢には載せない）。

   **`basic` 選択時**: ユーザー名・パスワードをテキスト入力で確認。

   **全戦略共通**: 認証設定を `.monkey-test/auth.json` に保存（次回以降の再利用のため）。ディレクトリが存在しない場合は `mkdir -p .monkey-test` で作成。
   - **アクション予算プロファイル**: `smoke`（10）/ `standard`（30、デフォルト）/ `deep`（50）

   **予算プロファイル**:
   | プロファイル | default | security-hunter | 用途 |
   |------------|---------|----------------|------|
   | `smoke` | 10 | 15 | 素早い健全性チェック |
   | `standard` | 30 | 40 | 通常のテスト実行 |
   | `deep` | 50 | 70 | 網羅的テスト |

4. 設定を `.work/monkey-test/00_config.json` に保存:

```json
{
  "target_url": "https://example.com",
  "context_mode": "url-only",
  "spec_paths": [],
  "codebase_path": null,
  "auth": {
    "required": false,
    "strategy": "none",
    "login_url": null,
    "username_field_label": null,
    "password_field_label": null,
    "username": null,
    "password": null,
    "success_indicator": null
  },
  "agents": [
    "tester-workflow",
    "tester-explorer",
    "tester-naive-user",
    "tester-chaos-input",
    "tester-security-hunter",
    "tester-spec-aware"
  ],
  "action_budget": {
    "profile": "standard",
    "default": 30,
    "tester-workflow": 45,
    "tester-security-hunter": 40
  }
}
```

5. Issue Registry を初期化:

`.work/monkey-test/shared/issue_registry.md` に空テンプレートを書き込む:

```markdown
# Issue Registry

## Discovered Issues

（まだなし）

## Explored Paths

（まだなし）
```

**Done 条件**: config.json が作成され、作業ディレクトリが存在する。

---

### Phase 1: Recon（メインエージェント、Playwright MCP）

**目的**: ターゲットアプリの全ページ構造を収集し、インタラクティブ要素をカタログ化する。

**重要**: この Phase はメインエージェントが直接 Playwright MCP を使って実行する。Task に委譲しない。

**手順**:

1. **認証処理**（auth.required が true の場合）:
   - `manual` 戦略:
     a. ユーザーに「ブラウザでログインしてください」と伝え、完了を待つ
     b. ログイン完了報告後、**storageState を保存**:
        ```javascript
        browser_run_code({
          code: `async (page) => {
            const state = await page.context().storageState();
            return JSON.stringify(state);
          }`
        })
        ```
        戻り値を `.work/monkey-test/auth_storage_state.json` に Write する。
   - `credentials` 戦略:
     a. ログインページに遷移:
        ```
        browser_navigate(url=auth.login_url)
        ```
     b. フォーム存在確認（SPA レンダリング待機）:
        ```
        browser_snapshot()
        ```
        フォーム要素が見つからない場合は `browser_wait_for(text=auth.username_field_label)` で最大5秒待機。
     c. フォーム入力:
        ```
        browser_fill_form(fields=[
          { name: auth.username_field_label, type: "textbox", ref: (snapshot から動的取得), value: auth.username },
          { name: auth.password_field_label, type: "textbox", ref: (snapshot から動的取得), value: auth.password }
        ])
        ```
     d. ログインボタンをスナップショットから特定してクリック:
        ボタンラベル候補: `"ログイン"`, `"Log in"`, `"Sign in"`, `"Submit"`, `"サインイン"`
     e. ログイン成功判定（`auth.success_indicator` に基づく）:
        - `url_contains`: 現在 URL に `success_indicator.value` が含まれるか
        - `text_visible`: `browser_snapshot` に `success_indicator.value` が含まれるか
        - `url_changed`: URL が `auth.login_url` から変わったか
     f. **storageState 保存**:
        ```javascript
        browser_run_code({
          code: `async (page) => {
            const state = await page.context().storageState();
            return JSON.stringify(state);
          }`
        })
        ```
        戻り値を `.work/monkey-test/auth_storage_state.json` に Write する。
        この storageState は Phase 3b の CLI 並列実行で各エージェントのブラウザコンテキストに読み込まれる。
     g. 失敗時: 1回リトライ → それでも失敗なら `manual` 戦略にフォールバック
   - `basic` 戦略: `browser_run_code` で httpCredentials 付きコンテキストを生成:
     ```javascript
     mcp__playwright__browser_run_code({
       code: `async (page) => {
         const context = await page.context().browser().newContext({
           httpCredentials: { username: '${auth.username}', password: '${auth.password}' }
         });
         const newPage = await context.newPage();
         await newPage.goto('${target_url}');
         return await newPage.title();
       }`
     })
     ```
     以降の Phase 1 操作は、この新コンテキスト内のページで行う。

2. **初期ページ**:
   ```
   mcp__playwright__browser_navigate(url=target_url)
   mcp__playwright__browser_snapshot()
   ```

3. **BFS 巡回**（上限20ページ）:
   - スナップショットからリンク（`<a href>`）を抽出
   - 同一ドメインの内部リンクのみ追跡
   - 各ページで:
     a. `browser_navigate` で遷移
     b. `browser_snapshot` で構造取得
     c. `browser_take_screenshot` でスクリーンショット保存（`screenshots/recon-P{NNN}.png`）
     d. **Page Snapshot 記録**: スナップショットの先頭80行を Recon データの `#### Page Snapshot (excerpt)` に記録（Planning エージェントがページ構造を理解するため）
     e. インタラクティブ要素（button, link, textbox, checkbox, radio, combobox, slider）をカタログ化
     f. **Destination 列の記録**: リンクの href を記録、ボタンの遷移先は Interactive Discovery で後追い
   - フラグメント違い（`#section`）は同一ページ
   - 外部ドメインはスキップ

4. **Interactive Discovery**（BFS 完了後、safe_mode ON、上限15操作）:

   BFS で発見したフォーム (F-NNN) と Primary CTA ボタンを操作して、フォーム送信後の遷移先ページを発見する。

   **safe_mode ガード** — 操作対象から以下を除外:
   - ラベルに `削除`, `Delete`, `Destroy`, `Reset`, `Remove` を含むボタン
   - ラベルに `支払`, `Pay`, `Purchase`, `Invite`, `Export` を含むボタン
   - `type="submit"` かつ form action が外部ドメインのフォーム
   - confirm ダイアログを伴う操作（ダイアログ出現時は dismiss して次へ）

   **入力データ選定ルール**（`recon-{timestamp}` プレフィックスでユニーク化）:
   | フィールドタイプ | 入力値 |
   |---|---|
   | textbox (name/title系) | `"recon-{timestamp} Test Item"` |
   | textbox (url系) | `"https://example.com"` |
   | textbox (description系) | `"Auto-generated for recon at {timestamp}"` |
   | combobox | 最初の選択肢 |
   | checkbox | チェック ON |
   | number/spinbutton | フィールドの現在値をそのまま使用 |

   **各操作の手順**:
   a. フォームの全必須フィールドに上記ルールで入力
   b. Submit ボタンをクリック
   c. `browser_snapshot` で遷移先ページの構造取得
   d. URL が未知なら Site Map に追加（Discovery = `form_submit` / `button_click`）
   e. 動的ルートパターン検出:
      - 数値 → `[id]`（例: `/scenarios/1` → `/scenarios/[id]`）
      - UUID → `[uuid]`
      - 英数字+ハイフン → `[slug]`
   f. 遷移先の Interactive Elements もカタログ化
   g. `browser_navigate` で元ページに戻る（`navigate_back` は使わない）

   **バリデーション失敗時のフォールバック**:
   - 送信後に URL が変化しない場合、エラーメッセージの有無を確認
   - エラーがある場合、入力値を調整して1回だけリトライ（最大2回試行）
   - 2回失敗したら「未発見ルート」として記録し次のフォームへ進む

   **無限ループ防止**: 同一 Dynamic Route Pattern への遷移は2回目以降スキップ

5. **URL シード追加**（`url+codebase` モード時、Phase 1b 完了後のみ）:
   - `url+codebase` モードでは **Phase 1b を Phase 1 と並行して起動** し、Phase 1b 完了後に追加巡回を行う
   - Phase 1b の結果からルート定義を取得し、BFS でまだ発見されていない URL を追加巡回する
   - Phase 1b が未完了の場合はスキップ（Phase 1b の完了を待たない）

6. **App Context 生成**:
   BFS + Interactive Discovery の過程で観察した情報から、App Context セクションを生成:
   - **Authentication**: ログイン画面の有無、認証方式、ログイン後の遷移先
   - **App Concepts**: ページタイトル・ナビゲーション・フォームラベルから主要リソースとその関係を推定
   - **Navigation Structure**: サイドバー/タブ/ブレッドクラム等の構造
   - **Key Observations**: 非同期ロード、disabled 条件、SPA 挙動等の特記事項
   → 全 Planning エージェントがアプリの基本仕様を理解できるようにする

7. **Workflow Map 生成**:
   BFS + Interactive Discovery の結果から、Workflow Map セクションを生成:
   - Discovered Transitions: フォーム送信/ボタンクリックによるページ遷移の記録
   - Dynamic Route Patterns: 検出された動的ルートのパターン一覧
   - Identified Workflows: 遷移グラフから推定される E2E ワークフロー

8. **Recon データ生成**:
   `references/recon_schema.md` のフォーマットに従い `.work/monkey-test/01_recon_data.md` を生成。
   Recon ハッシュ（`sha256(全ページURL+要素数)` の先頭8文字）を記録。

**Done 条件**: `01_recon_data.md` が作成され、1ページ以上の情報が含まれ、App Context・Workflow Map セクションが存在する。

**失敗時**: ページが0件 → URL が間違っているか認証が必要。ユーザーに確認。

---

### Phase 1b: Codebase Analysis（Task、オプション）

**目的**: ソースコードや仕様文書から、テストに有用なコンテキストを抽出する。

**実行条件**: `context_mode` が `url+spec` または `url+codebase` の場合のみ。

**実行タイミング**: `url+codebase` モードでは **Phase 1 と並行して Task 起動** する。Phase 1 の Step 5 で結果を利用するが、Phase 1b の完了を待たずに Phase 1 は先行完了可能。

**手順**:

Task ツールで `monkey-test-analyzer` エージェントを起動:

```
Task(
  subagent_type="general-purpose",
  prompt="agents/analyzer.md の指示に従い、以下のコードベースを分析して .work/monkey-test/01b_spec_context.md を生成してください。\n\n[config の codebase_path や spec_paths を含める]",
  model="sonnet"
)
```

**Done 条件**: `01b_spec_context.md` が作成されている。

---

### Phase 2a: Workflow Planning（Task × 1）

**目的**: tester-workflow エージェントのテストプランを先行して生成する。

**背景**: tester-workflow が作成するテストデータ（`created_data.json`）を後続5エージェントが参照するため、workflow の計画→実行を先行させる必要がある。

**手順**:

```
Task(
  subagent_type="general-purpose",
  name="monkey-tester-workflow",
  prompt="agents/swarm/tester-workflow.md の指示に従い、テストプランを生成してください。\n\nRecon データ: [01_recon_data.md の内容（Workflow Map・App Context・Page Snapshot 含む）]\n\nSpec Context: [01b_spec_context.md の内容（あれば）]\n\nアクション予算: 45\n\n出力先: .work/monkey-test/02_plans/tester-workflow.md\n\n[references/test_plan_schema.md]\n[references/action_catalog.md]",
  model="opus"
)
```

**Done 条件**: `02_plans/tester-workflow.md` が生成されている。

---

### Phase 3a: Workflow Execution（メインエージェント、Playwright MCP）

**目的**: tester-workflow のテストプランを実行し、テストデータを生成する。

**重要**: この Phase はメインエージェントが直接実行する。

**手順**:

1. **認証状態確認**（auth.required が true の場合）:
   - `browser_navigate(url=target_url)` でホームに遷移
   - 認証が必要かつ URL がログインページにリダイレクトされた場合（`auth.login_url` を含む URL に遷移した場合）:
     → Phase 1 の認証処理を再実行（セッション切れへの対応）
   - リダイレクトされなければ認証状態は有効

2. **テストプラン実行**: Phase 3b と同じ実行手順（後述）で `tester-workflow` のプランを実行

3. **created_data.json 生成**: 実行中にフォーム送信が成功した場合、作成されたデータを記録:

```json
{
  "scenarios": [
    {"id": 1, "name": "recon-20260213 Test Item", "url": "/scenarios/1", "created_by": "tester-workflow", "status": "active"}
  ],
  "plans": [
    {"id": 1, "name": "recon-20260213 Test Plan", "url": "/plans/1", "scenarios": [1], "created_by": "tester-workflow", "status": "active"}
  ],
  "runs": [
    {"id": 1, "url": "/runs/1", "plan_id": 1, "status": "completed", "created_by": "tester-workflow"}
  ]
}
```

   保存先: `.work/monkey-test/shared/created_data.json`（JSON 正本）

4. **created_data.md 生成**: ビュー用の Markdown も併存生成:

```markdown
# Created Test Data

## Scenarios
| ID | Name | URL | Status |
|----|------|-----|--------|
| 1 | recon-20260213 Test Item | /scenarios/1 | active |

## Plans
...

## Runs
...
```

   保存先: `.work/monkey-test/shared/created_data.md`

5. **Recon データ差分更新**: 動的ページで発見した新要素を `01_recon_data.md` に追記:
   - 動的ページ（例: `/scenarios/1`）の Interactive Elements を追加
   - Site Map に動的ページを追加（既に Interactive Discovery で追加済みなら要素のみ追記）

**Done 条件**: `tester-workflow` の実行ログが `03_execution/` に生成され、`created_data.json` が存在する。

---

### Phase 2b: Planning Swarm（Task × 5、並列）

**目的**: 残り5エージェントが性格に基づいたテストプランを生成する。

**手順**:

1. 残り5エージェントを **並列** で Task 起動:

```
# 全エージェントを同時に起動（1つのメッセージで複数の Task 呼び出し）
Task(
  subagent_type="general-purpose",
  name="monkey-tester-explorer",
  prompt="agents/swarm/tester-explorer.md の指示に従い、テストプランを生成してください。\n\nRecon データ: [01_recon_data.md の内容（更新済み、App Context・Page Snapshot 含む）]\n\nSpec Context: [01b_spec_context.md の内容（あれば）]\n\nCreated Data: [shared/created_data.json の内容]\n\nアクション予算: 30\n\n出力先: .work/monkey-test/02_plans/tester-explorer.md",
  model="sonnet"
)

Task(
  subagent_type="general-purpose",
  name="monkey-tester-naive-user",
  prompt="agents/swarm/tester-naive-user.md の指示に従い...\n\nSpec Context: [01b_spec_context.md の内容（あれば）]\n\nCreated Data: [shared/created_data.json の内容]",
  model="sonnet"
)

Task(
  subagent_type="general-purpose",
  name="monkey-tester-chaos-input",
  prompt="agents/swarm/tester-chaos-input.md の指示に従い...\n\nSpec Context: [01b_spec_context.md の内容（あれば）]\n\nCreated Data: [shared/created_data.json の内容]",
  model="sonnet"
)

Task(
  subagent_type="general-purpose",
  name="monkey-tester-security-hunter",
  prompt="agents/swarm/tester-security-hunter.md の指示に従い...\n\nSpec Context: [01b_spec_context.md の内容（あれば）]\n\nCreated Data: [shared/created_data.json の内容]",
  model="opus"
)

Task(
  subagent_type="general-purpose",
  name="monkey-tester-spec-aware",
  prompt="agents/swarm/tester-spec-aware.md の指示に従い...\n\nSpec Context: [01b_spec_context.md の内容（あれば）]\n\nCreated Data: [shared/created_data.json の内容]",
  model="opus"
)
```

2. **全エージェント共通**の prompt に以下を含める:
   - エージェント定義ファイル（agents/swarm/*.md）の全文を Read して渡す
   - `01_recon_data.md` の内容（**Phase 3a で更新済み**、動的ページの要素・App Context・Page Snapshot 含む）
   - `01b_spec_context.md` の内容（**全エージェントに渡す**、存在する場合）← ログインフロー・基本仕様は全員が知るべき
     - **naive-user への注記**: Spec Context は「参考資料」として渡すが、このエージェントは性格上あえて無視する前提
   - `shared/created_data.json` の内容（**Phase 3a で生成**、テストデータの URL 含む）
   - `shared/issue_registry.md` の内容（tester-workflow の発見を含む）
   - アクション予算
   - `references/test_plan_schema.md` のフォーマット仕様
   - `references/action_catalog.md` のアクション一覧

   **コンテキスト量の最適化**（ページ数が多い場合）:
   - Page Snapshot: 20ページ超の場合、各エージェントの担当ページのみ渡す（explorer は全ページ、他は担当フォーカス）
   - Spec Context: 全文が長大な場合、Summary セクション + エージェント関連部分のみ抽出
   - Issue Registry: 重複情報を除外し、未解決 issue のみ渡す

3. 各エージェントの出力ファイル: `.work/monkey-test/02_plans/{agent-name}.md`

4. **created_data.json の URL をテスト対象に追加**:
   各エージェントは `created_data.json` 内のリソース URL（`/scenarios/1`, `/plans/1` 等）を追加のテスト対象ページとして使用する。

**Done 条件**: 残り5エージェントのテストプランが `02_plans/` に生成されている。

---

### Phase 3b: CLI 並列実行（メインエージェント + Bash）

**目的**: 残り5エージェントのテストプランを CLI（Playwright Node API）で**並列実行**し、結果を記録する。

**重要**: Phase 3b は 3 つのサブフェーズで構成される。

#### Phase 3b-compile: スクリプト生成（メインエージェント）

各エージェントのテストプラン `.md` を実行可能な Node.js スクリプトに変換する。

1. `.work/monkey-test/run/run_meta.json` を生成（auth, baseUrl, budgets, confidence_threshold）
   - `auth.strategy` が `"credentials"` または `"manual"` の場合:
     - `auth.storage_state_path` に `"../../auth_storage_state.json"` を設定
     - `.work/monkey-test/auth_storage_state.json` が存在することを確認（存在しない場合は WARNING ログ）
   - `auth.strategy` が `"basic"` の場合: 既存通り `username` / `password` を設定
2. 各エージェント用ディレクトリ `run/{agent-name}/` を作成
3. 各プラン `.md` を読み込み、テーブルをパースして `run/{agent-name}/plan.json` を生成:
   - `01_recon_data.md` の Interactive Elements から TargetRef → elementMeta を構築
   - Assertion 列の文字列をエスケープ
   - Priority でシーケンスをソート
4. `cli_execution_guide.md` のテンプレートに基づき `run/{agent-name}/test.js` を生成

**plan.json 形式**: `references/test_plan_schema.md` の「プラン JSON 形式」セクション参照。
**test.js テンプレート**: `references/cli_execution_guide.md` 参照。

**Basic 認証**: `run_meta.json` の `auth.strategy === "basic"` の場合、スクリプト内で `browser.newContext({ httpCredentials })` が自動設定される。

#### Phase 3b-execute: 並列実行（Bash）

5つのエージェントスクリプトを Bash で並列実行する。

```bash
timeout {timeout_sec} bash -c '
  node .work/monkey-test/run/tester-explorer/test.js &
  node .work/monkey-test/run/tester-naive-user/test.js &
  node .work/monkey-test/run/tester-chaos-input/test.js &
  node .work/monkey-test/run/tester-security-hunter/test.js &
  node .work/monkey-test/run/tester-spec-aware/test.js &
  wait
'
```

**タイムアウト**: smoke=120s, standard=300s, deep=600s
**終了コード**: 各スクリプトは issues > 0 で exit 1。`wait` は最後のプロセスの終了を待つ。

**前提条件**: `playwright` が `node_modules/` にインストール済みであること。未インストールの場合は `npx playwright install chromium` を実行。

#### Phase 3b-reduce: 結果集約（メインエージェント）

並列実行の結果を既存フォーマットに変換する。

1. 各 `run/{agent-name}/results.ndjson` を読み込む
2. NDJSON を `03_execution/{agent-name}.md` フォーマットに変換（後述の Reducer ルール）
3. `shared/issue_registry.md` を更新
4. `shared/created_data.json` を更新（エージェントが作成したデータがあれば）
5. スクリーンショットを `run/{agent-name}/screenshots/` → `screenshots/` にコピー

**Reducer 変換ルール**:

| NDJSON type | 実行ログへのマッピング |
|-------------|---------------------|
| `seq_start` | `### SEQ-NNN: {name}` セクション開始 |
| `step` (OK) | テーブル行: Result=OK |
| `step` (UNRESOLVED) | テーブル行: Result=UNRESOLVED (confidence=X) |
| `step` (ERROR) | テーブル行: Result=ERROR + スクリーンショット参照 |
| `step` (assertion fail) | テーブル行: Result=FAIL |
| `summary` | ヘッダーの Actions completed / Issues found |

**NDJSON 形式詳細**: `references/cli_execution_guide.md` 参照。

#### Locator Ladder

CLI スクリプトでの要素解決は Locator Ladder パターンを使用:

| 優先度 | 方法 | Confidence |
|-------|------|-----------|
| 1 | data-testid | 1.0 |
| 2 | role + name | 0.9 |
| 3 | placeholder | 0.8 |
| 4 | label | 0.75 |
| 5 | text | 0.6 |
| 6 | CSS selector | 0.5 |

**Confidence Gate**: threshold 未満は `UNRESOLVED`（実行しない）。詳細は `references/action_catalog.md` の「Locator Ladder」セクション参照。

#### データ名前空間（並列競合回避）

- 各エージェントは `run/{agent-name}/` にのみ書き込み
- テストデータ作成時のプレフィックス: `{agent-name}_{timestamp}`
- `created_data.json` への追記は Reducer が一括実行

### 共通実行手順（Phase 3a / 3b 共通）

**Phase 3 安全性ポリシー**:
Phase 1 の safe_mode（偵察用）とは別に、Phase 3 でも以下のガードを適用:
- **破壊的操作の制限**: テストプランに明示的に含まれていない限り、`削除`/`Delete`/`Destroy` ボタンはクリックしない
- **ダイアログ処理**: ダイアログ出現時は `accept=true` で自動承認するが、**ダイアログ内容を実行ログに記録**する
- **外部遷移ブロック**: テスト対象ドメイン外への遷移が発生した場合は即座に `navigate` で元ページに戻る
- **エージェント間分離**: 各エージェントの実行開始前に `browser_navigate(url=target_url)` でホーム状態にリセットする（後述）

**各エージェントの実行手順**:

1. テストプランを読み込む: `.work/monkey-test/02_plans/{agent-name}.md`

2. Issue Registry を読み込む: `.work/monkey-test/shared/issue_registry.md`

3. `created_data.json` を読み込む（存在する場合）: `.work/monkey-test/shared/created_data.json`

4. 各テストシーケンス（Priority: high → medium → low 順）:

   a. **開始 URL に遷移**:
   ```
   mcp__playwright__browser_navigate(url=starting_url)
   ```

   b. **自動安定化待機**（navigate 後に毎回実行）:
   - 軽量チェック: `browser_snapshot` でコンテンツ存在確認
   - 条件時: loading 兆候、過去の要素参照失敗歴がある場合は `browser_wait_for` で拡張待機
   - 詳細は `references/action_catalog.md`「navigate 後の二段階待機」参照

   c. **各ステップを実行**:
   アクションテーブルの各行を上から順に実行。Action 列を以下の Playwright MCP にマッピング:

   | Action | MCP ツール | パラメータ |
   |--------|-----------|-----------|
   | navigate | `browser_navigate` | url=Target |
   | click | `browser_click` | ref=TargetRef, element=Target |
   | type | `browser_type` | ref=TargetRef, text=Input |
   | fill_form | `browser_fill_form` | fields=Input (JSON) |
   | select | `browser_select_option` | ref=TargetRef, values=[Input] |
   | press_key | `browser_press_key` | key=Input |
   | hover | `browser_hover` | ref=TargetRef, element=Target |
   | snapshot | `browser_snapshot` | - |
   | screenshot | `browser_take_screenshot` | filename=Input |
   | wait | `browser_wait_for` | text=Input or time=Input |
   | navigate_back | `browser_navigate_back` | -（**実行後に URL 検証、不一致時は navigate にフォールバック**） |
   | evaluate | `browser_evaluate` | function=Input |
   | tab_new | `browser_tabs(action="new")` | - |
   | verify_created | `browser_snapshot` + assertion | Target=期待テキスト。snapshot に含まれるか検証 |
   | verify_list_contains | `browser_navigate` + `browser_snapshot` + assertion | Target=一覧URL, Input=期待テキスト |

   **type の input[type=number] フォールバック**:
   `browser_type` が失敗した場合、`browser_evaluate` で JS 経由の直接入力にフォールバック。
   詳細は `references/action_catalog.md`「type アクションの input[type=number] フォールバック」参照。

   c. **Assertion 検証**（Assertion 列が `-` でない場合）:
   - `browser_snapshot` を取得
   - Assertion の条件を検証:
     - `title contains "X"`: ページタイトルにXを含むか
     - `url contains "X"`: 現在のURLにXを含むか
     - `snapshot contains "X"`: スナップショットのテキストにXを含むか
     - `snapshot not contains "X"`: 含まないか
     - `console has error`: `browser_console_messages(level="error")` でエラーがあるか
     - `console has no error`: エラーがないか
     - `network has 4xx/5xx`: `browser_network_requests` でエラーレスポンスがあるか
     - `network has no 4xx/5xx`: エラーレスポンスがないか
     - `dialog appeared`: ダイアログが表示されたか
     - `dialog not appeared`: ダイアログが表示されなかったか（XSS テスト等）

   d. **Issue 検出時**:
   - `browser_take_screenshot(filename="screenshots/{agent}-SEQ{NNN}-{step}.png")`
   - 実行ログに issue として記録
   - 重大度を判定:
     - **Critical**: XSS反映、認証バイパス、データ漏洩
     - **High**: バリデーション欠如、CSRF無し、500エラー
     - **Medium**: UI崩れ、不適切なエラーメッセージ、コンソールエラー
     - **Low**: 軽微なUI問題、パフォーマンス警告

   e. **アクション予算管理**:
   - 各ステップ実行で予算を1消費
   - 予算超過時: 残りのシーケンスを Priority 順にスキップ（low → medium）

4. **要素参照の解決**（Self-healing）:
   - TargetRef（E-NNN）で `browser_click`/`browser_type` を試行
   - ref が古い（要素が見つからない）場合:
     1. `browser_snapshot` で最新の構造を取得
     2. Target（ラベル/テキスト）で要素を再検索
     3. 見つかればその ref で実行
     4. 見つからなければスキップして issue 記録
   - **動的ページの要素解決**: TargetRef が未指定（`-`）の場合:
     1. 現在の URL が Dynamic Route Pattern にマッチするか確認
     2. `browser_snapshot` で最新要素一覧を取得
     3. Target（ラベル）で要素を検索
     4. 発見した要素の ref を使用して操作
   - **Self-Healing メトリクス記録**: 各エージェントの実行ログに以下を記録:
     - Self-Healing 試行回数
     - 成功回数 / 失敗回数
     - 元 ref → 新 ref のマッピング一覧
   - メトリクスはレポートの安定性指標セクションに反映

4b. **created_data Assertion の解決**:
   Assertion に `created_data.{field}` が含まれる場合:
   1. `shared/created_data.json` を読み込む（リソースグループ配列形式）
   2. テストプランの Data Seeds で指定されたリソースタイプの最新エントリから field を取得
      - Data Seeds 未指定の場合: 全リソースグループの最新エントリを探索
   3. 値を Assertion 文字列に展開して検証
   4. ファイルが存在しない場合は WARNING ログを出力し、Assertion をスキップ

4c. **フォーム送信後の自動検証**（tester-workflow 実行時）:
   `click` アクションで submit ボタンをクリックした後:
   1. URL 変化を確認
   2. 成功/エラーメッセージを検出
   3. 成功時は `shared/created_data.json` に記録
   詳細は `references/action_catalog.md`「フォーム送信後の自動検証」参照

5. **監視（Mogwai）**:
   - 各アクション後: `browser_console_messages(level="error")` でエラーチェック
   - 各シーケンス後: `browser_network_requests` でネットワークエラーチェック
   - ダイアログ出現時: `browser_handle_dialog(accept=true)` で自動承認、記録

6. **フィードバックループ**:
   - あるエージェントの要素参照失敗率 > 50% → UI構造が変化している
   - 対応: `browser_snapshot` で変化ページを再スキャン、`01_recon_data.md` を部分更新
   - 次のエージェントのプランで影響がある部分のみ、Target ラベルベースで要素を解決

7. **実行ログ生成**:
   各エージェントの実行結果を `.work/monkey-test/03_execution/{agent-name}.md` に書き込む:

```markdown
# Execution Log: {Agent Name}

> Agent: {agent-id}
> Executed: YYYY-MM-DD HH:MM
> Actions completed: {used}/{budget}
> Issues found: {count}
> Recon hash: {hash}

## Sequence Results

### SEQ-001: {テスト名}

| Step | Action | Target | Result | Issue? |
|------|--------|--------|--------|--------|
| 1 | navigate | / | OK | - |
| 2 | click | E-003 | OK | - |
| 3 | type | E-020 | OK | - |
| 4 | click | E-022 | ASSERTION FAIL | ISS-001 |

## Issues

### ISS-001: {Issue Title}

**Severity**: {critical|high|medium|low}
**Sequence**: SEQ-{NNN}, Step {N}
**Expected**: {Assertion の期待値}
**Actual**: {実際の結果}
**Screenshot**: screenshots/{agent}-SEQ{NNN}-{step}.png
**Page URL**: {URL}
**Snapshot excerpt**: {関連部分のスナップショット抜粋}

## Coverage

| Pages visited | Elements interacted | Forms submitted |
|---------------|--------------------|-----------------|
| {n}/{total} | {n}/{total} | {n}/{total} |

## Console Errors

| Page | Error |
|------|-------|
| {url} | {message} |

## Network Errors

| URL | Status | Method |
|-----|--------|--------|
| {url} | {status} | {method} |
```

8. **Issue Registry 更新**:
   各エージェント実行完了後、`.work/monkey-test/shared/issue_registry.md` を更新:
   - Discovered Issues に新しい issue を追加
   - Explored Paths に訪問したページを追加

**Done 条件**: 全エージェントの実行ログが `03_execution/` に生成されている。

---

### Phase 4: Reporting（Task エージェント）

**目的**: 全実行ログを統合して最終レポートを生成する。

**手順**:

1. Task ツールで `monkey-test-reporter` エージェントを起動:

```
Task(
  subagent_type="general-purpose",
  prompt="agents/reporter.md の指示に従い、レポートを生成してください。\n\n実行ログ: [03_execution/ の全ファイル内容]\nIssue Registry: [shared/issue_registry.md]\nRecon データ: [01_recon_data.md の内容（Workflow Map・Site Map 含む）]\nCreated Data: [shared/created_data.json の内容（存在する場合）]\nConfig: [00_config.json]\n\n出力先: monkey-test-report.md（プロジェクトルート）",
  model="sonnet"
)
```

2. レポート生成後、ユーザーにサマリーを報告:
   - 発見した issue 数（重大度別）
   - カバレッジ率
   - 上位3件の発見
   - レポートファイルのパス

**Done 条件**: `monkey-test-report.md` が生成されている。

---

## エラーハンドリング

| エラー | Phase | 対応 |
|--------|-------|------|
| URL 到達不能 | 1 | 中断。ユーザーに URL 確認を依頼 |
| ログイン失敗（credentials） | 1 | 1回リトライ → manual フォールバック |
| ログインフォーム未検出 | 1 | SPA 待機5秒 → 失敗なら manual フォールバック |
| CAPTCHA 検出 | 1 | manual にフォールバック |
| storageState 未生成 | 3b | WARNING ログ、CLI は認証なしで続行 |
| セッション Cookie 期限切れ | 3b | assertion fail → レポートに「認証切れ」フラグ |
| 0ページ発見 | 1 | 中断。URL か認証を確認 |
| Interactive Discovery でフォーム送信失敗 | 1 | 2回リトライ → 「未発見ルート」記録、次フォームへ |
| safe_mode 該当ボタン | 1 | スキップしてログに記録 |
| ナビゲーションタイムアウト | 3a/3b | issue 記録、次シーケンスへ |
| 要素参照切れ | 3a/3b | Self-healing（ラベルで再検索）、それでも失敗ならスキップ |
| ダイアログ/alert | 3a/3b | `browser_handle_dialog(accept=true)` で承認、記録 |
| ページクラッシュ | 3a/3b | critical issue 記録、開始 URL へ戻る |
| アクション予算超過 | 3a/3b | 実行停止、次エージェントへ |
| 要素参照失敗率 > 50% | 3b | フィードバックループ発動（部分再偵察） |
| エージェントプラン解析失敗 | 2a/2b | 警告ログ、次エージェントへ |
| created_data.json 読み込み失敗 | 3b | WARNING ログ、created_data 参照 Assertion をスキップ |
| Stale URL 検出（404） | 3b | 該当 URL を参照するシーケンスをスキップ |

## ツール使用ルール

### Playwright MCP（Phase 1, 3 のみ）

- `browser_navigate`: ページ遷移
- `browser_snapshot`: アクセシビリティスナップショット（要素の ref を取得する主手段）
- `browser_click`: 要素クリック（ref 必須）
- `browser_type`: テキスト入力（ref 必須）
- `browser_fill_form`: 複数フィールド一括入力
- `browser_take_screenshot`: スクリーンショット保存
- `browser_console_messages`: コンソールメッセージ取得
- `browser_network_requests`: ネットワークリクエスト取得
- `browser_handle_dialog`: ダイアログ処理

### Task（Phase 1b, 2a, 2b, 4）

- エージェント定義ファイルの内容と参照データを prompt に含める
- model パラメータはエージェント定義の model に合わせる
- Phase 2a は tester-workflow **単独起動**
- Phase 2b は残り5エージェントを **1つのメッセージで並列起動**
- Phase 2b の prompt には `created_data.json` の内容を含める

### Read/Write

- 中間成果物の読み書きは `.work/monkey-test/` 配下
- 最終レポートはプロジェクトルート

## 参照ファイル

| ファイル | 用途 |
|---------|------|
| `references/recon_schema.md` | Phase 1 の出力フォーマット（Workflow Map 含む） |
| `references/test_plan_schema.md` | Phase 2 の出力フォーマット（Data Dependencies 含む） |
| `references/action_catalog.md` | Phase 3 のアクションマッピング（Assertion DSL 含む） |
| `references/personality_guide.md` | カスタムエージェント作成ガイド |
| `agents/swarm/tester-workflow.md` | E2E ワークフローテスター（Phase 2a/3a で先行実行） |
| `agents/swarm/*.md` | その他テスターエージェント定義 |
| `agents/analyzer.md` | コードベース分析エージェント |
| `agents/reporter.md` | レポート集約エージェント |
| `references/cli_execution_guide.md` | CLI 並列実行ガイド（テンプレート、NDJSON、Locator Ladder、Reducer） |
