# Action Catalog

Phase 2 のテストプランで使用可能な Playwright アクション一覧。
Phase 3 でメインエージェントが各アクションを対応する Playwright MCP ツールにマッピングして実行する。

## アクション一覧

| Action | Playwright MCP Tool | Required Params | Optional Params | 説明 |
|--------|---------------------|-----------------|-----------------|------|
| `navigate` | `browser_navigate` | Target (URL) | - | 指定 URL に遷移。**遷移後に自動安定化待機あり**（後述） |
| `click` | `browser_click` | Target, TargetRef | - | 要素をクリック |
| `type` | `browser_type` | Target, TargetRef, Input | submit | テキスト入力。submit=true で Enter も送信。**input[type=number] は制約あり**（後述） |
| `fill_form` | `browser_fill_form` | Input (JSON fields) | - | 複数フィールドを一括入力 |
| `select` | `browser_select_option` | Target, TargetRef, Input | - | ドロップダウンから選択 |
| `press_key` | `browser_press_key` | Input (key name) | - | キー押下（Tab, Enter, Escape 等） |
| `hover` | `browser_hover` | Target, TargetRef | - | 要素にホバー |
| `snapshot` | `browser_snapshot` | - | - | アクセシビリティスナップショット取得 |
| `screenshot` | `browser_take_screenshot` | - | Input (filename) | スクリーンショット保存 |
| `wait` | `browser_wait_for` | Input (text or time) | - | テキスト出現待ち or 秒数待ち |
| `navigate_back` | `browser_navigate_back` | - | - | ブラウザの「戻る」。**履歴依存のため使用制限あり**（後述） |
| `evaluate` | `browser_evaluate` | Input (JS function) | - | JavaScript 実行 |
| `tab_new` | `browser_tabs` | - | - | 新しいタブを開く |
| `verify_created` | `browser_snapshot` + assertion | Target (期待テキスト) | - | 作成操作後に遷移先で作成データの存在確認 |
| `verify_list_contains` | `browser_navigate` + `browser_snapshot` + assertion | Target (一覧URL), Input (期待テキスト) | - | 一覧ページで特定データの存在確認 |

## 実行時の自動挙動（Phase 3 オーケストレーター責務）

### navigate 後の二段階待機

全 `navigate` アクション実行後、オーケストレーターは以下の安定化処理を自動実行する:

1. **常時（軽量チェック）**: `browser_snapshot` を取得し、ページにコンテンツが存在することを確認
2. **条件時（拡張 wait_for）**: 以下のいずれかに該当する場合、明示的な `browser_wait_for` を追加実行:
   - SPA 兆候: snapshot に loading/spinner 表示がある
   - 同一 URL の過去ナビゲーションで要素参照失敗があった
   - snapshot が前回と同一（描画未完了の疑い）

### navigate_back の使用ガード

`navigate_back` はブラウザ履歴に依存するため再現性が低い。以下のルールを適用:

- **テストプラン生成時（Phase 2）**: `navigate_back` の使用は**限定用途**（ユーザーの自然な戻り操作をテストする場合のみ）。デフォルトは `navigate(URL明示)` を優先
- **実行時（Phase 3）**: `navigate_back` 実行後に現在 URL を検証。Assertion で期待パスが指定されている場合、不一致なら `navigate(期待URL)` にフォールバック
- **計画時バリデーション**: navigate_back が3回以上使われている、または直前URLが不明なケースは Planning Agent に警告

### type アクションの input[type=number] フォールバック

Playwright の `browser_type` / `fill()` は `input[type=number]` にテキスト文字列を入力できない（ブラウザの HTML5 バリデーションがブロック）。

**Phase 3 実行時のフォールバック手順**:

1. `browser_type(ref=TargetRef, text=Input)` を試行
2. 失敗（タイプエラー）した場合 → `browser_evaluate` で JS から直接入力:
   ```javascript
   (el) => { el.value = 'INPUT_VALUE'; el.dispatchEvent(new Event('input', {bubbles: true})); el.dispatchEvent(new Event('change', {bubbles: true})); }
   ```
3. evaluate 成功/失敗に関わらず、結果をログに記録
4. **注意**: evaluate による入力はブラウザのバリデーションをバイパスするため、サーバーサイドバリデーションのテストとして機能する

## フォーム送信後の自動検証（Phase 3 オーケストレーター責務）

フォーム送信ボタン（`click` アクションで submit ボタンをクリック）の後、オーケストレーターは以下を自動実行する:

1. **URL 変化検出**: 送信前後で URL を比較
   - URL 変化あり → 遷移先ページの `browser_snapshot` を取得
   - URL 変化なし → 同一ページで成功/エラーメッセージの有無を確認
2. **成功判定**: 以下のいずれかで成功と判定
   - 新しい URL に遷移（例: `/scenarios/new` → `/scenarios/1`）
   - スナップショットに成功メッセージ（「作成しました」「保存しました」等）が含まれる
3. **データ記録**: 成功時、`shared/created_data.json` のリソースグループ配列に追記:
   ```json
   // created_data.json はリソースタイプ別の配列構造（SKILL.md Phase 3a 参照）
   // 例: scenarios 配列に追加
   {"id": 1, "name": "recon-{ts} Test Item", "url": "/scenarios/1", "created_by": "{agent-name}", "status": "active"}
   ```
4. **エラー記録**: 失敗時、実行ログに Assertion Fail として記録

**注意**: この自動検証は予算にカウントしない（暗黙的な監視の一部）。

## verify_created の実行フロー

1. `browser_snapshot` を取得
2. Target に指定されたテキストがスナップショットに含まれるか検証
3. 含まれる → PASS、含まれない → Assertion Fail

## verify_list_contains の実行フロー

1. `browser_navigate(url=Target)` で一覧ページに遷移
2. `browser_snapshot` を取得
3. Input に指定されたテキストがスナップショットに含まれるか検証
4. 含まれる → PASS、含まれない → Assertion Fail

## Assertion DSL パーサ仕様

Phase 3 でメインエージェントが Assertion 列を解釈する際のパターンマッチング:

| パターン | 正規表現 | 検証ロジック |
|---------|---------|------------|
| `title contains "X"` | `^title contains "(.+)"$` | `browser_snapshot` のタイトル部に X を含む |
| `url contains "X"` | `^url contains "(.+)"$` | 現在の URL に X を含む |
| `url matches "regex"` | `^url matches "(.+)"$` | 現在の URL が正規表現にマッチ |
| `snapshot contains "X"` | `^snapshot contains "(.+)"$` | スナップショット全文に X を含む |
| `snapshot not contains "X"` | `^snapshot not contains "(.+)"$` | スナップショット全文に X を含まない |
| `snapshot contains created_data.{field}` | `^snapshot contains created_data\.(\w+)$` | `shared/created_data.json` の該当フィールド値を動的解決 |
| `list count > N` | `^list count > (\d+)$` | スナップショット内のリストアイテム数が N を超える |
| `element enabled "X"` | `^element enabled "(.+)"$` | ラベル X の要素が `disabled` でない |
| `element disabled "X"` | `^element disabled "(.+)"$` | ラベル X の要素が `disabled` である |
| `console has error` | `^console has error$` | `browser_console_messages(level="error")` にエラーがある |
| `network has 4xx/5xx` | `^network has [45]xx` | `browser_network_requests` にエラーレスポンスがある |
| `dialog appeared` | `^dialog appeared$` | ダイアログが表示された |
| `dialog not appeared` | `^dialog not appeared$` | ダイアログが表示されなかった（XSS alert 未発火の確認等） |
| `console has no error` | `^console has no error$` | `browser_console_messages(level="error")` にエラーがない |
| `network has no 4xx/5xx` | `^network has no [45]xx$` | `browser_network_requests` にエラーレスポンスがない |

**created_data 参照の解決手順**:
1. `shared/created_data.json` を読み込む（リソースグループ配列形式）
2. 指定された field（例: `name`）をリソースグループの最新エントリから取得
   - 解決順: テストプランの Data Seeds で指定されたリソースタイプ → 全リソースグループの最新エントリ
   - 例: `created_data.name` → `scenarios` 配列の最後の要素の `name` フィールド
3. ファイルが存在しない場合は Assertion をスキップ（WARNING ログ）

## アクション数のカウント

各アクションは **1アクション** としてカウント。
ただし以下は暗黙的に実行され、カウント対象外:

- アクション後の自動 snapshot（Assertion 検証用）
- dialog の自動 accept
- console.error の監視

## TargetRef の解決フロー

Phase 3 でメインエージェントが実行する際:

1. **TargetRef あり**: Recon カタログの ref でアクセス試行
2. **ref が古い場合**: 新規 `browser_snapshot` → Target（ラベル/テキスト）で再検索
3. **TargetRef なし**: Target の説明文をもとにスナップショットから要素を特定
4. **見つからない場合**: スキップして issue 記録

## Input の書式

| 型 | 例 | 説明 |
|---|-----|------|
| 文字列 | `"test@example.com"` | そのままテキスト入力 |
| URL | `/products` | navigate の対象 |
| キー名 | `Enter`, `Tab`, `Escape` | press_key の対象 |
| 秒数 | `3` | wait の待機時間（秒） |
| テキスト | `"Loading..."` | wait のテキスト出現待ち |
| JS 関数 | `() => document.title` | evaluate の実行コード |
| JSON | `[{"name":"Email","type":"textbox","ref":"E-010","value":"test@example.com"}]` | fill_form のフィールド定義 |

## 監視アクション（Mogwai）

Phase 3 実行中にメインエージェントが追加で監視する項目。
エージェントのテストプランには含まれず、オーケストレーターが自動実行する。

| 監視項目 | Playwright MCP Tool | トリガー | 対象エージェント |
|---------|---------------------|---------|----------------|
| console.error | `browser_console_messages(level="error")` | 各アクション後 | 全共通 |
| ネットワークエラー | `browser_network_requests` | 各シーケンス後 | 全共通 |
| レスポンスヘッダー | `browser_network_requests` | 各シーケンス後 | security-hunter |
| ダイアログ検知 | `browser_handle_dialog` | 随時（自動） | 全共通 |

## セキュリティテスト用ペイロード例

security-hunter エージェントが Input で使用する代表的なペイロード。
**注意**: テスト環境でのみ使用。本番環境への適用は禁止。

### XSS

```
<script>alert('xss')</script>
"><img src=x onerror=alert(1)>
javascript:alert(1)
<svg onload=alert(1)>
```

### SQL Injection

```
' OR 1=1 --
'; DROP TABLE users; --
1 UNION SELECT null,null,null
" OR ""="
```

### パストラバーサル

```
../../../etc/passwd
..%2F..%2F..%2Fetc%2Fpasswd
```

### 特殊文字

```
<>&"'/\`
${7*7}
{{7*7}}
%00
```

## カオス入力用データ例

chaos-input エージェントが Input で使用する代表的なデータ。

| カテゴリ | 例 |
|---------|-----|
| 極端な長さ | `"a" × 10000` |
| 空文字列 | `""` |
| Unicode 異常 | `"\u200B\u200B\u200B"` (Zero-Width Space) |
| RTL テキスト | `"\u202Eabcd"` |
| 絵文字シーケンス | `"\uD83D\uDE00\uD83D\uDE01\uD83D\uDE02"` |
| 負数 | `"-1"`, `"-999999"` |
| 浮動小数点 | `"0.0000001"`, `"NaN"`, `"Infinity"` |
| 日付境界 | `"0000-01-01"`, `"9999-12-31"` |
| NULL バイト | `"test\x00value"` |

## Locator Ladder（CLI 実行時の要素解決）

Phase 3b の CLI 並列実行では、Playwright MCP の ref ではなく Locator Ladder パターンで要素を解決する。

| 優先度 | 方法 | Playwright API | Confidence | ソース |
|-------|------|---------------|-----------|--------|
| 1 | data-testid | `page.getByTestId()` | 1.0 | Recon の Attributes 列 |
| 2 | role + name | `page.getByRole()` | 0.9 | Recon の Type + Name/Label 列 |
| 3 | placeholder | `page.getByPlaceholder()` | 0.8 | Recon の Attributes 列 |
| 4 | label | `page.getByLabel()` | 0.75 | Recon の Name/Label 列 |
| 5 | text | `page.getByText()` | 0.6 | Target 列の表示テキスト |
| 6 | CSS selector | `page.locator()` | 0.5 | Recon 拡張（オプション） |

**Confidence Gate**: threshold 未満（デフォルト 0.6）のロケーターは使用せず、ステップを `UNRESOLVED` として記録。

## CLI マッピング

Phase 3b の CLI スクリプトで各アクションが使用する Playwright Node API:

| Action | MCP Tool (Phase 3a) | CLI API (Phase 3b) |
|--------|---------------------|---------------------|
| `navigate` | `browser_navigate` | `page.goto()` |
| `click` | `browser_click` | `locator.click()` |
| `type` | `browser_type` | `locator.fill()` + evaluate fallback |
| `fill_form` | `browser_fill_form` | 複数 `locator.fill()` |
| `select` | `browser_select_option` | `locator.selectOption()` |
| `press_key` | `browser_press_key` | `page.keyboard.press()` |
| `hover` | `browser_hover` | `locator.hover()` |
| `snapshot` | `browser_snapshot` | `page.accessibility.snapshot()` |
| `screenshot` | `browser_take_screenshot` | `page.screenshot()` |
| `wait` | `browser_wait_for` | `page.waitForTimeout()` / `getByText().waitFor()` |
| `evaluate` | `browser_evaluate` | `page.evaluate()` |
| `verify_created` | `browser_snapshot` + match | `page.content()` + includes |
| `verify_list_contains` | `browser_navigate` + match | `page.goto()` + `page.content()` + includes |

詳細は `references/cli_execution_guide.md` を参照。
