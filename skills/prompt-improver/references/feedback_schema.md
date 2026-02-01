# フィードバックスキーマ定義

フィードバックデータの完全なスキーマ定義。Codexとの設計相談を基に策定。

## 保存場所

```
~/.claude/feedback/
├── fb-20260201-001.yaml
├── fb-20260201-002.yaml
└── ...
```

## 完全スキーマ

```yaml
# === 識別・時刻 ===
id: fb-{YYYYMMDD}-{sequence}    # 必須: ユニークID
created_at: ISO8601             # 必須: 記録時刻
occurred_at: ISO8601            # 任意: 発生時刻（記録と異なる場合）
updated_at: ISO8601             # 任意: 更新時刻

# === タスク情報 ===
task_summary: string            # 必須: タスクの要約（1-2文）
session_id: string              # 任意: セッションID

# === 結果評価 ===
outcome:                        # 必須
  success: boolean              # 必須: 成功判定
  score: 0.0-1.0                # 任意: 成功度スコア
  rationale: string             # 必須: 評価理由

# === 問題リスト ===
issues:                         # 必須（空配列可）
  - issue_id: string            # 必須: issue内のユニークID
    type: enum                  # 必須: 問題タイプ（下記参照）
    description: string         # 必須: 問題の説明
    target:                     # 必須: 関連するファイル/セクション
      type: enum                # 必須: ターゲットタイプ
      path: string              # 必須: ファイルパス
      section: string           # 任意: セクション名/見出し
      line: number              # 任意: 行番号
      symbol: string            # 任意: 関数名/クラス名
    severity: enum              # 必須: 深刻度
    confidence: 0.0-1.0         # 任意: 確信度
    impact: string              # 任意: ユーザー影響の説明
    frequency: string           # 任意: 発生頻度の説明
    evidence_ref: string        # 任意: 証拠への参照

# === コンテキスト（再現性） ===
context:                        # 推奨
  skill_name: string            # 使用したスキル名
  skill_version: string         # スキルバージョン/commit
  prompt_hash: string           # プロンプトのハッシュ
  repo: string                  # リポジトリ名
  runtime:
    model: string               # モデルID
    temperature: number         # 温度パラメータ
    tools_version: string       # Claude Codeバージョン
  locale: string                # ロケール

# === 参照（重いデータは別保存） ===
input_refs:                     # 任意
  - type: transcript | log | screenshot | artifact
    path: string
    excerpt: string             # 抜粋（任意）
output_refs:                    # 任意
  - type: string
    path: string

# === メトリクス ===
metrics:                        # 任意
  tokens: number                # トークン数
  latency_ms: number            # レイテンシ
  cost: number                  # コスト

# === 再現情報 ===
repro:                          # 任意
  steps: string[]               # 再現手順
  seed: string                  # シード値
  minimal_case: string          # 最小再現ケース

# === フィードバック元 ===
source: enum                    # 推奨: user | self | eval | prod-log
user_feedback: string           # 任意: ユーザーからの直接コメント

# === 改善提案 ===
suggested_improvement: string   # 任意: 簡潔な改善提案（1文）
proposed_actions:               # 推奨: 詳細な改善アクション
  - scope: enum                 # skill | claude_md | hook | command | other
    change_summary: string      # 変更内容の要約
    expected_impact: enum       # critical | high | medium | low
    effort: enum                # high | medium | low

# === トリアージ・進捗 ===
triage:                         # 任意
  status: enum                  # open | triaged | in_progress | fixed | verified | wont_fix
  priority: enum                # critical | high | medium | low
  owner: string                 # 担当者
  labels: string[]              # タグ/ラベル

# === 解決情報 ===
resolution:                     # 任意（解決後に追加）
  fix_ref: string               # 修正commit/PR
  verified_at: ISO8601          # 検証時刻
  regression_test_ref: string   # 回帰テスト参照

# === プライバシー ===
privacy:                        # 任意
  redacted: boolean             # 編集済みフラグ
  redaction_notes: string       # 編集内容のメモ
```

## Enum定義

### issue.type
| 値 | 説明 |
|----|------|
| `prompt_unclear` | プロンプト/指示が曖昧 |
| `skill_incomplete` | スキルの情報不足 |
| `skill_incorrect` | スキルの情報が誤り |
| `hook_missing` | hookが未設定 |
| `hook_incorrect` | hookの動作が不正 |
| `example_missing` | 具体例が不足 |
| `pattern_missing` | パターン/テンプレート不足 |
| `context_lost` | コンテキストの喪失 |
| `misunderstanding` | 要件の誤解 |
| `other` | その他 |

### target.type
| 値 | 説明 |
|----|------|
| `claude_md` | CLAUDE.mdファイル |
| `skill` | SKILLファイル |
| `hook` | hooks設定 |
| `command` | コマンド定義 |
| `agent` | エージェント定義 |
| `other` | その他 |

### severity / priority / expected_impact
| 値 | 説明 |
|----|------|
| `critical` | 重大（即時対応必要） |
| `high` | 高（優先対応） |
| `medium` | 中（通常対応） |
| `low` | 低（余裕があれば） |

### triage.status
| 値 | 説明 |
|----|------|
| `open` | 未対応 |
| `triaged` | トリアージ済み |
| `in_progress` | 対応中 |
| `fixed` | 修正済み |
| `verified` | 検証済み |
| `wont_fix` | 対応しない |

## 最小限の例

```yaml
id: fb-20260201-001
created_at: 2026-02-01T12:00:00Z
task_summary: "ログイン機能の実装"
outcome:
  success: true
  rationale: "要件通り実装完了"
issues: []
```

## 問題ありの例

```yaml
id: fb-20260201-002
created_at: 2026-02-01T14:30:00Z
task_summary: "認証APIの設計"
outcome:
  success: false
  score: 0.4
  rationale: "セキュリティ要件を満たさなかった"
issues:
  - issue_id: issue-001
    type: example_missing
    description: "JWT認証の具体的な実装例がなかった"
    target:
      type: skill
      path: ~/.claude/skills/architecture/SKILL.md
      section: "## セキュリティパターン"
    severity: high
    confidence: 0.9
  - issue_id: issue-002
    type: prompt_unclear
    description: "トークンの有効期限に関する指針がなかった"
    target:
      type: claude_md
      path: ~/.claude/CLAUDE.md
      section: "## セキュリティ規約"
    severity: medium

context:
  skill_name: architecture
  skill_version: 1.2.0
  runtime:
    model: claude-opus-4-5-20251101

source: user
user_feedback: "JWTの例があれば助かった"

proposed_actions:
  - scope: skill
    change_summary: "JWT認証の実装例を追加"
    expected_impact: high
    effort: low
  - scope: claude_md
    change_summary: "トークン有効期限のガイドラインを追加"
    expected_impact: medium
    effort: low

triage:
  status: open
  priority: high
  labels: [security, documentation]
```
