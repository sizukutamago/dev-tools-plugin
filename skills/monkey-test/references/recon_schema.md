# Recon Data Schema

Phase 1 の偵察結果フォーマット。Planning Swarm エージェントへのインプットとなる。

## ファイル

出力先: `.work/monkey-test/01_recon_data.md`

## フォーマット

```markdown
# Recon Data

> Generated: YYYY-MM-DD HH:MM
> Target: https://example.com
> Pages discovered: N
> Total interactive elements: M
> Dynamic routes discovered: D
> Workflows identified: W
> Recon hash: <sha256 先頭8文字>

## Site Map

| ID | URL | Title | Parent | Depth | Discovery |
|----|-----|-------|--------|-------|-----------|
| P-001 | / | Home | - | 0 | link_bfs |
| P-002 | /about | About | P-001 | 1 | link_bfs |
| P-003 | /products | Products | P-001 | 1 | link_bfs |
| P-004 | /products/1 | Product Detail | P-003 | 2 | form_submit |

## Pages

### P-001: Home (/)

**URL**: https://example.com/
**Title**: Home
**Screenshot**: screenshots/recon-P001.png

#### Page Snapshot (excerpt)

ページのアクセシビリティスナップショットを **先頭80行** まで記録する。
Planning エージェントがページレイアウト・要素の配置関係・表示テキストを理解するための情報。

```
- navigation "Main Nav"
  - link "Home" [ref=s1]
  - link "Products" [ref=s2]
  - link "About" [ref=s3]
- main
  - heading "Welcome to Example" [level=1]
  - paragraph "Sign up today and get started..."
  - button "Sign Up" [ref=s4]
  - form
    - textbox "Search" [ref=s5] [placeholder="Search..."]
    - button "Search" [ref=s6]
- footer
  - link "Privacy" [ref=s7]
  - link "Terms" [ref=s8]
```

#### Interactive Elements

| Ref | Type | Name/Label | Attributes | data-testid | CSS Selector | Destination | Notes |
|-----|------|-----------|------------|-------------|--------------|-------------|-------|
| E-001 | link | "Products" | href=/products | - | - | /products | navigation |
| E-002 | button | "Sign Up" | - | - | - | /signup | Primary CTA |
| E-003 | textbox | "Search" | placeholder="Search...", type=text | - | - | - | - |

**data-testid / CSS Selector 列**（オプション）: Phase 1 Recon で `browser_evaluate` を使い、`data-testid` 属性と CSS セレクタを収集した場合に記録する。CLI 並列実行（Phase 3b）の Locator Ladder で使用。未収集の場合は `-` とする。role + name での解決（confidence 0.9）が十分なケースが多いため、必須ではない。

#### Forms

| Form ID | Action | Method | Fields |
|---------|--------|--------|--------|
| F-001 | /search | GET | search (text) |

---

(各ページごとに繰り返し)

## App Context

Phase 1 で自動収集されるアプリの基本情報。全 Planning エージェントへのインプット。
`01b_spec_context.md`（コード分析）とは独立して、URL のみモードでも生成される。

### Authentication

| 項目 | 値 |
|------|-----|
| 認証要否 | あり / なし |
| 認証方式 | form-login / oauth / none / manual |
| ログイン URL | /login（該当する場合） |
| ログイン後遷移先 | /dashboard |

### App Concepts

Recon 中に発見されたアプリの主要リソースとその関係。
ページタイトル・ナビゲーション・フォームラベルから推定。

| Resource | CRUD Pages | Depends On | Notes |
|----------|-----------|------------|-------|
| Scenario | /scenarios, /scenarios/new, /scenarios/[id] | - | テストシナリオ |
| Plan | /plans, /plans/new, /plans/[id] | Scenario | シナリオを含むテスト計画 |
| Run | /runs, /runs/[id] | Plan | プランの実行結果 |

### Navigation Structure

| 構造要素 | 説明 |
|---------|------|
| サイドバー | 全ページ共通。主要リソースへのリンク |
| タブ | /settings ページでタブ切り替え（一般/環境/変数） |
| ブレッドクラム | なし |

### Key Observations

Recon 中に観察した特記事項（全エージェントが知るべき情報）:

- `/settings` は非同期ロード。navigate 後に `wait_for("一般")` が必要
- `/scenarios/new` のフォーム送信ボタンは必須フィールド未入力時に disabled
- サイドバーのリンクは SPA 遷移（ページ全体リロードなし）

---

## Workflow Map

### Discovered Transitions

| From Page | Trigger | Action Type | To Page | Data Created |
|-----------|---------|-------------|---------|-------------|
| P-003 (/products/new) | Submit F-002 | form_submit | P-004 (/products/1) | Product |
| P-001 (/) | Click E-002 | button_click | P-005 (/signup) | - |

### Dynamic Route Patterns

| Pattern | Example | Discovered Via |
|---------|---------|---------------|
| /products/[id] | /products/1 | F-002 submit |

### Identified Workflows

| WF-ID | Name | Steps | Pages Involved |
|-------|------|-------|----------------|
| WF-001 | Product CRUD | Create→View→Edit→Delete | P-003,P-004 |

---

(BFS + Interactive Discovery の結果から自動生成。Interactive Discovery で遷移先が判明した場合のみ記録)

## Summary Statistics

| Metric | Count |
|--------|-------|
| Pages | N |
| Links | - |
| Buttons | - |
| Forms | - |
| Text inputs | - |
| Selects | - |
| Checkboxes | - |
```

## 要素 Ref の命名規則

- `P-NNN`: ページ ID（発見順）
- `E-NNN`: 要素 ID（グローバル連番）
- `F-NNN`: フォーム ID（グローバル連番）
- `WF-NNN`: ワークフロー ID（発見順）

## Site Map の Discovery 列

| 値 | 説明 |
|---|------|
| `link_bfs` | BFS リンク巡回で発見 |
| `form_submit` | Interactive Discovery でフォーム送信後の遷移先として発見 |
| `button_click` | Interactive Discovery で CTA ボタンクリック後の遷移先として発見 |

## Interactive Elements の Destination 列

ボタン・リンク・フォーム送信の遷移先 URL。Interactive Discovery で確認された場合のみ記録。遷移しない要素は `-` とする。

## Dynamic Route Patterns の検出ルール

URL のパスセグメントを以下のルールで正規化:

| パターン | 正規化 | 例 |
|---------|--------|-----|
| 数値のみ | `[id]` | `/scenarios/1` → `/scenarios/[id]` |
| UUID 形式 | `[uuid]` | `/items/a1b2c3d4-...` → `/items/[uuid]` |
| 英数字+ハイフン（slug 風） | `[slug]` | `/posts/my-first-post` → `/posts/[slug]` |

## Page Snapshot のルール

各ページの `browser_snapshot` 結果を **先頭80行** まで記録する。Planning エージェントがページの実際の構造を理解するために使用。

- **目的**: 要素テーブルだけでは分からない「ページ上の配置関係」「表示テキスト」「ナビゲーション構造」を伝える
- **行数制限**: 最大80行（大きなページでも予算を圧迫しない程度に truncate）
- **フォーマット**: Playwright の `browser_snapshot` 出力をそのまま記録
- **ref 値**: スナップショット内の ref（`[ref=s1]` 等）は実行時に変わりうるため、Planning エージェントは Interactive Elements テーブルの Ref（`E-NNN`）を優先して使用すること

## 要素の Type 一覧

| Type | 説明 | 例 |
|------|------|-----|
| link | ナビゲーションリンク | `<a>` |
| button | ボタン | `<button>`, `role="button"` |
| textbox | テキスト入力 | `<input type="text">`, `<textarea>` |
| checkbox | チェックボックス | `<input type="checkbox">` |
| radio | ラジオボタン | `<input type="radio">` |
| combobox | ドロップダウン | `<select>` |
| slider | スライダー | `<input type="range">` |

## Recon ハッシュ

`sha256(全ページの URL + 要素数)` の先頭8文字。
Phase 3 実行時に Recon データの変更検知に使用（フィードバックループ）。

## 巡回戦略

### BFS 巡回（Phase 1 前半）

1. **BFS 優先**（上限20ページ）
2. `url+codebase` モード時は、ソースコードのルート定義を BFS シードに追加
3. リンク密度が低いページ（リンク数 ≤ 2）は DFS で深い遷移を追跡
4. 外部リンク（異なるドメイン）はスキップ
5. 同一 URL のフラグメント違い（`#section`）は同一ページとして扱う

### Interactive Discovery（Phase 1 後半、BFS 完了後）

BFS で発見したフォーム・CTA ボタンを操作して、フォーム送信後の遷移先ページを発見する。

1. **上限15操作**（BFS の余剰があれば追加可能）
2. BFS で発見したフォーム (F-NNN) を最小有効データで送信
3. Primary CTA ボタンをクリック（safe_mode 適用、後述）
4. 各操作後:
   a. `browser_snapshot` で遷移先ページの構造取得
   b. URL が未知なら Site Map に追加（Discovery = `form_submit` / `button_click`）
   c. 動的ルートパターン検出（上記「Dynamic Route Patterns の検出ルール」参照）
   d. 遷移先の Interactive Elements もカタログ化
5. `browser_navigate` で元ページに戻る（`navigate_back` は使わない）
6. 外部ドメインへの遷移はブロック（同一オリジンのみ）
7. 同一 Dynamic Route Pattern への遷移は2回目以降スキップ（無限ループ防止）

### Interactive Discovery の safe_mode

操作対象から以下を除外:

- ラベルに `削除`, `Delete`, `Destroy`, `Reset`, `Remove` を含むボタン
- ラベルに `支払`, `Pay`, `Purchase`, `Invite`, `Export` を含むボタン
- `type="submit"` かつ form action が外部ドメインのフォーム
- confirm ダイアログを伴う操作（ダイアログ出現時は dismiss して次へ）

### Interactive Discovery の入力データ選定ルール

| フィールドタイプ | 入力値 |
|---|---|
| textbox (name/title系) | `"recon-{timestamp} Test Item"` |
| textbox (url系) | `"https://example.com"` |
| textbox (description系) | `"Auto-generated for recon at {timestamp}"` |
| combobox | 最初の選択肢 |
| checkbox | チェック ON |
| number/spinbutton | フィールドの現在値をそのまま使用 |

### バリデーション失敗時のフォールバック

- 送信後に URL が変化しない場合、エラーメッセージの有無を確認
- エラーがある場合、入力値を調整して1回だけリトライ（最大2回試行）
- 2回失敗したら「未発見ルート」として記録し次のフォームへ進む
