# Handoff Envelope Schema

エージェント間のハンドオフ封筒スキーマ定義。

## 概要

ハンドオフ封筒は、Swarm エージェント間でデータを受け渡すための標準化されたスキーマ。
各エージェントはこの形式で出力を生成し、次のエージェント（または Aggregator）に渡す。

## 基本スキーマ

```yaml
# 全エージェント共通フィールド
kind: explorer | reviewer | planner | writer | aggregator
agent_id: string  # 例: "explorer:tech#shard-frontend"
mode: greenfield | brownfield
status: ok | needs_input | conflict | blocked
artifacts:
  - path: string  # 出力ファイルパス（.work/ からの相対パス）
    type: context | finding | question | story | review | unified
open_questions:
  - string  # 未解決の質問
blockers:
  - string  # ブロッカー（status: blocked の場合は必須）
next: explorer | interviewer | planner | writer | reviewer | aggregator | done
```

## エージェント別スキーマ

### Explorer

```yaml
kind: explorer
agent_id: explorer:tech#shard-frontend  # 種類#shard
mode: brownfield
status: ok
artifacts:
  - path: .work/01_explorer/tech.md
    type: context
findings:
  # 種類によって異なる
  # explorer:tech の場合
  tech_stack:
    language: string
    framework: string
    runtime: string
  dependencies:
    production: [{name, version, purpose}]
    development: [{name, version, purpose}]
  architecture:
    pattern: string
    layers: [{name, path}]
  constraints: [string]
  technical_debt: [string]
open_questions: [string]
blockers: []
next: aggregator
```

### Reviewer

```yaml
kind: reviewer
agent_id: reviewer:completeness
status: ok
severity: P0 | P1 | P2 | null  # Reviewer 専用
artifacts:
  - path: .work/06_reviewer/completeness.md
    type: review
findings:
  p0_issues:
    - id: string  # 例: "COMP-001"
      category: string
      description: string
      location: string  # ファイル:行番号
      fix: string
  p1_issues:
    - # 同上
  p2_issues:
    - # 同上
summary:
  total_stories: number
  # その他の統計
open_questions: []
blockers: []
next: aggregator
```

### Planner

```yaml
kind: planner
agent_id: req:planner
mode: greenfield | brownfield
status: ok
artifacts:
  - path: .work/04_story_map.md
    type: story_map
summary:
  total_epics: number
  total_features: number
  total_stories: number
  mvp_stories: number
  dependencies:
    - from: string  # US-ID
      to: string    # US-ID
      type: data | feature | technical | business
traceability:
  - story_id: string
    sources:
      - type: interview | context
        ref: string  # 参照先
open_questions: [string]
blockers: []
next: writer
```

### Writer

```yaml
kind: writer
agent_id: req:writer
mode: greenfield | brownfield
status: ok
artifacts:
  - path: docs/requirements/user-stories.md
    type: story
summary:
  total_stories: number
  total_ac: number
  ac_per_story_avg: number
  stories_with_failure_ac: number
traceability:
  - story_id: string
    sources: [string]  # Q-XXX, context:XXX
open_questions: []
blockers: []
next: reviewer
```

### Aggregator

```yaml
kind: aggregator
agent_id: req:aggregator
mode: greenfield | brownfield
status: ok
artifacts:
  - path: .work/02_context_unified.md  # または .work/07_review_unified.md
    type: unified_context | unified_review
summary:
  inputs_count: number
  conflicts_found: number
  conflicts_resolved: number
  duplicates_removed: number
conflicts_resolved:
  - id: string
    source_a: string
    source_b: string
    resolution: string
    reasoning: string
# Reviewer 統合の場合のみ
gate_decision:
  p0_count: number
  p1_count: number
  p2_count: number
  result: pass | reject | veto
  return_phase: number | null  # 差し戻し先
open_questions: [string]
next: interviewer | planner | writer | done
```

## ステータス定義

| ステータス | 説明 | 必須フィールド |
|-----------|------|---------------|
| `ok` | 正常完了 | artifacts |
| `needs_input` | 追加情報が必要 | open_questions |
| `conflict` | 矛盾を検出、解消が必要 | conflicts |
| `blocked` | 処理不能 | blockers |

## 重大度定義（Reviewer のみ）

| 重大度 | 説明 | 判定への影響 |
|--------|------|-------------|
| `P0` | Blocker | 1 つでも veto |
| `P1` | Major | 2 つ以上で差し戻し |
| `P2` | Minor | 通過（要対応リスト） |
| `null` | 指摘なし | 通過 |

## next フィールドのルール

| 現在 | 次のエージェント | 条件 |
|------|----------------|------|
| Explorer | aggregator | 常に |
| Aggregator (Explorer) | interviewer | brownfield |
| Aggregator (Explorer) | planner | greenfield（インタビュー完了後） |
| Interviewer | planner | ヒアリング完了 |
| Planner | writer | 常に |
| Writer | reviewer | 常に |
| Reviewer | aggregator | 常に |
| Aggregator (Reviewer) | done | gate pass |
| Aggregator (Reviewer) | interviewer | gate reject (NFR 不足) |
| Aggregator (Reviewer) | planner | gate reject (構造問題) |
| Aggregator (Reviewer) | writer | gate reject (記述問題) |

## バリデーションルール

### 必須フィールド

全てのハンドオフ封筒に必須:
- `kind`
- `agent_id`
- `status`
- `next`

status に応じた必須フィールド:
- `ok`: `artifacts`
- `needs_input`: `open_questions`（1 件以上）
- `blocked`: `blockers`（1 件以上）

### agent_id フォーマット

```
{type}:{subtype}#{shard}

例:
- explorer:tech
- explorer:domain#frontend
- reviewer:completeness
- req:planner
- req:writer
- req:aggregator
```

### artifacts.path フォーマット

```
.work/XX_phase/filename.md
docs/requirements/user-stories.md

例:
- .work/01_explorer/tech.md
- .work/02_context_unified.md
- .work/03_questions.md
- .work/04_story_map.md
- .work/06_reviewer/completeness.md
- .work/07_review_unified.md
- docs/requirements/user-stories.md
```

## シリアライズ形式

YAML を推奨（可読性重視）。JSON でも可。

```yaml
# YAML 形式（推奨）
kind: explorer
agent_id: explorer:tech
mode: brownfield
status: ok
artifacts:
  - path: .work/01_explorer/tech.md
    type: context
findings:
  tech_stack:
    language: TypeScript
```

```json
// JSON 形式
{
  "kind": "explorer",
  "agent_id": "explorer:tech",
  "mode": "brownfield",
  "status": "ok",
  "artifacts": [
    {"path": ".work/01_explorer/tech.md", "type": "context"}
  ],
  "findings": {
    "tech_stack": {"language": "TypeScript"}
  }
}
```
