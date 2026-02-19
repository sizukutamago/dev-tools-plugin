# Test Plan Schema

Phase 2 の Planning Swarm エージェントが出力するテストプランのフォーマット。
Phase 3 の Execution でメインエージェントが解析・実行する。

## ファイル

出力先: `.work/monkey-test/02_plans/{agent-name}.md`

## フォーマット

```markdown
# Test Plan: {Agent Display Name}

> Agent: {agent-id}
> Generated: YYYY-MM-DD HH:MM
> Action Budget: N
> Starting Page: /
> Strategy: {1-2文のテスト戦略概要}

## Data Dependencies (optional)

ワークフローテスターがシーケンス間のデータ依存関係を宣言するセクション。
他のエージェント（explorer, naive-user 等）は通常このセクションを使用しない。

| Dep-ID | Resource Type | Name/Key | Created In | Used In |
|--------|--------------|----------|-----------|---------|
| D-001 | Scenario | "recon-{ts} Test Item" | SEQ-001 Step 5 | SEQ-002 Step 2 |
| D-002 | Plan | "recon-{ts} Test Plan" | SEQ-002 Step 4 | SEQ-003 Step 1 |

---

## Test Sequences

### SEQ-001: {テスト名}

**Starting URL**: /path
**Priority**: high | medium | low
**Description**: {このシーケンスの目的を1-2文で説明}
**Workflow**: WF-001 (optional, ワークフローテスターのみ)
**Data Seeds**: D-001 (optional, このシーケンスの前提データ)
**Data Creates**: D-002 (optional, このシーケンスが作成するデータ)

| Step | Action | Target | TargetRef | Input | Precondition | Assertion | Notes |
|------|--------|--------|-----------|-------|-------------|-----------|-------|
| 1 | navigate | / | - | - | - | title contains "Home" | - |
| 2 | click | "Sign Up" | E-002 | - | Page loaded | snapshot contains "form" | - |
| 3 | type | "Email" | E-010 | "test@example.com" | Form visible | - | 正常値 |
| 4 | type | "Password" | E-011 | "short" | Form visible | - | 境界値テスト |
| 5 | click | "Submit" | E-012 | - | Fields filled | snapshot contains "error" | バリデーション確認 |

---

### SEQ-002: {次のテスト名}
...

## Handoff Envelope

```yaml
kind: tester
agent_id: tester:{agent-name}
status: ok
action_count: {計画したアクション総数}
sequences: {シーケンス数}
artifacts:
  - path: .work/monkey-test/02_plans/{agent-name}.md
    type: test_plan
next: executor
```
```

## 列の定義

| 列 | 必須 | 説明 |
|----|------|------|
| **Step** | Yes | シーケンス内の連番（1始まり） |
| **Action** | Yes | 実行するアクション（action_catalog.md 参照） |
| **Target** | Yes | 操作対象の人間可読な説明（ラベル、テキスト等） |
| **TargetRef** | No | Recon カタログの要素 ID（E-001 等）。Self-healing の基点 |
| **Input** | No | 入力値。`-` は入力なし |
| **Precondition** | No | このステップの実行前提条件 |
| **Assertion** | No | 期待結果の検証条件。`-` は検証なし |
| **Notes** | No | 自由記述（エージェントの意図、代替操作メモ） |

## Assertion の書式

簡潔な自然言語で記述。メインエージェントが解釈して検証する。

| パターン | 例 | 検証方法 |
|---------|-----|---------|
| `title contains "X"` | `title contains "Home"` | ページタイトルに文字列を含む |
| `url contains "X"` | `url contains "/dashboard"` | URL に文字列を含む |
| `snapshot contains "X"` | `snapshot contains "error"` | アクセシビリティスナップショットに文字列を含む |
| `snapshot not contains "X"` | `snapshot not contains "500"` | スナップショットに文字列を含まない |
| `console has error` | - | コンソールにエラーが出力された |
| `network has 4xx/5xx` | - | ネットワークリクエストにエラーレスポンスがある |
| `dialog appeared` | - | ダイアログ/alert が表示された |
| `dialog not appeared` | - | ダイアログ/alert が表示されなかった |
| `console has no error` | - | コンソールにエラーが出力されていない |
| `network has no 4xx/5xx` | - | ネットワークリクエストにエラーレスポンスがない |
| `url matches "regex"` | `url matches "/scenarios/\\d+"` | URL が正規表現にマッチ（動的ルート遷移確認） |
| `snapshot contains created_data.{field}` | `snapshot contains created_data.name` | 作成済みデータのフィールド値がスナップショットに含まれる |
| `list count > N` | `list count > 0` | 一覧のアイテム件数が N を超える |
| `element enabled "X"` | `element enabled "実行"` | ラベル X のボタン/要素が活性化されている |
| `element disabled "X"` | `element disabled "削除"` | ラベル X のボタン/要素が無効化されている |

## アクション予算の管理

- 各 Step が 1 アクションとしてカウント
- `navigate` + `snapshot`（暗黙的）= 1 アクション
- シーケンス全体のアクション数が予算を超えないこと
- **予算超過時**: 残りのシーケンスを Priority 順にトリミング

## Priority の意味

| Priority | 説明 | 予算超過時 |
|----------|------|-----------|
| high | このエージェントの性格に最も関連するテスト | 最後まで残す |
| medium | 補完的なテスト | 予算次第で実行 |
| low | あれば嬉しいテスト | 先にカット |

## プラン JSON 形式（Phase 3b-compile 中間形式）

Phase 3b-compile でメインエージェントがプラン `.md` のテーブルをパースして生成する JSON 形式。CLI テストスクリプトの入力となる。

### フォーマット

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

### elementMeta の構築ルール

`01_recon_data.md` の Interactive Elements テーブルから TargetRef（E-NNN）を照合して構築する:

| JSON フィールド | テーブル列 | 説明 |
|---------------|----------|------|
| `ref` | TargetRef | Recon 要素 ID |
| `type` | Type | 要素タイプ（button, textbox 等） |
| `name` | Name/Label | 要素のラベル/名前 |
| `placeholder` | Attributes | placeholder 属性値を抽出 |
| `testid` | data-testid | data-testid 属性値（あれば） |
| `cssSelector` | CSS Selector | CSS セレクタ（あれば） |

TargetRef が `-` またはテーブルに該当行がない場合、`elementMeta` は `null` とする（navigate, snapshot 等の要素不要アクション）。

### Assertion 列のエスケープ

JSON 内で Assertion 文字列のダブルクォートはエスケープする:
- プラン `.md`: `snapshot contains "ダッシュボード"`
- プラン JSON: `"snapshot contains \"ダッシュボード\""`
