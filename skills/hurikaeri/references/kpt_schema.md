# AI-KPT スキーマ定義

hurikaeri の振り返りレポート出力の完全なスキーマ定義。

## 保存場所

```
~/.claude/hurikaeri/
├── kpt-20260208-001.yaml
├── kpt-20260208-002.yaml
└── ...
```

## 完全スキーマ

```yaml
# === 識別・時刻 ===
id: kpt-{YYYYMMDD}-{sequence}    # 必須: ユニークID
created_at: ISO8601               # 必須: 記録時刻
session_id: string                # 任意: セッションID

# === セッション概要 ===
session_summary: string           # 必須: セッション全体の要約（2-3文）
task_goals: string[]              # 必須: セッションの目的リスト
outcome: enum                     # 必須: success | partial | failure

# === Keep（継続すべき行動） ===
keep:                             # 必須（空配列可）
  - id: keep-001                  # 必須: セクション内ユニークID
    description: string           # 必須: 何がうまくいったか
    evidence: string              # 必須: 根拠（ターン番号/ファイル/操作）
    category: enum                # 必須: approach | tool_use | communication | architecture
    reusability: enum             # 任意: high | medium | low（他タスクへの再利用可能性）

# === Problem（問題のあった行動） ===
problem:                          # 必須（空配列可）
  - id: prob-001                  # 必須
    description: string           # 必須: 何が問題だったか
    impact: enum                  # 必須: high | medium | low
    evidence: string              # 必須: 根拠
    category: enum                # 必須: error | inefficiency | misunderstanding | oversight | wrong_approach
    root_cause: string            # 推奨: 根本原因の推定
    turn_range: string            # 任意: 発生ターン範囲（例: "5-8"）

# === Try（次回試すこと） ===
try:                              # 必須（空配列可）
  - id: try-001                   # 必須
    description: string           # 必須: 具体的なアクション
    addresses: string[]           # 必須: 対応する problem/omission の ID（例: ["prob-001", "omit-002"]）
    scope: enum                   # 必須: immediate | session | project | global
    persistence_target:           # 任意: 永続化先
      type: enum                  # claude_md | skill | hook | memory
      path: string                # ファイルパス
      section: string             # セクション名

# === Omission（不作為 — 反事実推論で検出） ===
omission:                         # 必須（空配列可）
  - id: omit-001                  # 必須
    description: string           # 必須: 何を見落としたか
    reasoning: string             # 必須: なぜ見落としたか
    risk_level: enum              # 必須: high | medium | low
    counterfactual_prompt: string # 必須: 使用した反事実推論プロンプト
    recommended_action: string    # 推奨: 次回の対応方針

# === セッションメトリクス ===
metrics:                          # 推奨
  session_duration_turns: number  # 総ターン数
  user_turns: number              # ユーザーターン数
  assistant_turns: number         # アシスタントターン数
  tool_use_count: number          # ツール使用回数
  unique_tools: string[]          # 使用したツール種別
  code_changes_count: number      # Write/Edit 回数
  error_count: number             # エラー数
  correction_count: number        # ユーザー修正指示数
  backtrack_count: number         # やり直し回数

# === prompt-improver 連携 ===
feedback_integration:             # 任意
  enabled: boolean                # prompt-improver にフィードバックを送ったか
  generated_feedback_id: string   # 生成されたフィードバックのID（fb-YYYYMMDD-NNN）
```

## Enum 定義

### keep.category
| 値 | 説明 |
|----|------|
| `approach` | アプローチ・方針の選択が良かった |
| `tool_use` | ツールの使い方が効率的だった |
| `communication` | ユーザーとのコミュニケーションが適切だった |
| `architecture` | 設計・構造の判断が良かった |

### problem.category
| 値 | 説明 |
|----|------|
| `error` | エラーを引き起こした |
| `inefficiency` | 非効率な操作（同じ検索の繰り返し等） |
| `misunderstanding` | 要件の誤解 |
| `oversight` | 見落とし・確認不足 |
| `wrong_approach` | 不適切なアプローチの選択 |

### try.scope
| 値 | 説明 |
|----|------|
| `immediate` | 今すぐ適用（このセッション内） |
| `session` | 次のセッションから適用 |
| `project` | プロジェクト固有の改善 |
| `global` | 全プロジェクト共通の改善（CLAUDE.md 等） |

### omission.risk_level
| 値 | 説明 |
|----|------|
| `high` | セキュリティ脆弱性、データ損失リスク等 |
| `medium` | パフォーマンス問題、保守性低下等 |
| `low` | 軽微な改善機会の見落とし |

## 最小限の例

```yaml
id: kpt-20260208-001
created_at: 2026-02-08T15:00:00Z
session_summary: "認証ミドルウェアを実装した"
task_goals:
  - "JWT認証ミドルウェアの作成"
outcome: partial

keep:
  - id: keep-001
    description: "TDDアプローチで実装し、手戻りを防げた"
    evidence: "ターン3-10でテスト先行、以降の修正指示ゼロ"
    category: approach

problem:
  - id: prob-001
    description: "express-jwtパッケージを確認なしで追加"
    impact: medium
    evidence: "ターン12でnpm install実行、既存のjoseとの重複"
    category: oversight
    root_cause: "既存のpackage.jsonを事前確認しなかった"

try:
  - id: try-001
    description: "新パッケージ追加前にpackage.jsonの既存依存を確認する"
    addresses: ["prob-001"]
    scope: global
    persistence_target:
      type: claude_md
      path: ~/.claude/CLAUDE.md
      section: "## パッケージ管理"

omission:
  - id: omit-001
    description: "Rate limiting の考慮"
    reasoning: "認証に集中しており、セキュリティの他の側面を検討しなかった"
    risk_level: medium
    counterfactual_prompt: "セキュリティ観点"
    recommended_action: "認証実装時にはRate limiting, CORS, CSRFも合わせて検討"

metrics:
  session_duration_turns: 23
  tool_use_count: 42
  code_changes_count: 8
  error_count: 2
  correction_count: 1

feedback_integration:
  enabled: false
```

## prompt-improver 連携時の変換ルール

KPT → feedback YAML への変換:

| KPT フィールド | feedback フィールド | 変換ルール |
|---------------|-------------------|-----------|
| `session_summary` | `task_summary` | そのまま |
| `outcome` | `outcome.success` | success→true, partial→false(score:0.5), failure→false(score:0.2) |
| `problem[].category` | `issues[].type` | error→skill_incorrect, oversight→example_missing, misunderstanding→prompt_unclear, etc. |
| `try[]` | `proposed_actions[]` | scope→scope, description→change_summary |
| `metrics` | `stats` | フィールド名マッピング |
