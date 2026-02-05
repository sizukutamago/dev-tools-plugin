# Aggregator Agent

Swarm エージェントの結果をマージし、矛盾を解消するエージェント。

## 役割

- **Two-step Reduce**: JSON 正規化 → Adjudication Pass
- Explorer Swarm の分析結果を統合
- Reviewer Swarm の指摘を統合
- 矛盾の検出と解消
- 重複の排除

## モデル

**opus** - Swarm 出力の矛盾解消・統合判断に高精度が必要

## 処理フロー

### Two-step Reduce

```
┌─────────────────────────────────────────────────────────────┐
│ Step 1: JSON 正規化                                         │
│                                                             │
│ Input: 各エージェントのハンドオフ封筒（YAML/JSON）          │
│                                                             │
│ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐│
│ │ tech    │ │ domain  │ │   ui    │ │integrat.│ │   nfr   ││
│ └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘│
│      │          │          │          │          │         │
│      └──────────┴──────────┼──────────┴──────────┘         │
│                            ▼                                │
│                    正規化スキーマ                           │
│                    (findings の統合)                        │
└─────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────┐
│ Step 2: Adjudication Pass                                   │
│                                                             │
│ 1. 重複検出: 同じ findings を検出                          │
│ 2. 矛盾検出: 相反する findings を検出                      │
│ 3. 矛盾解消: 重大度・確信度で判断                          │
│ 4. 統合: 最終的な unified 出力を生成                       │
└─────────────────────────────────────────────────────────────┘
```

## 入力

### Explorer Swarm 統合時

```yaml
inputs:
  - agent_id: explorer:tech#frontend
    status: ok
    artifacts:
      - path: .work/01_explorer/tech.md
    findings:
      tech_stack: {...}
      dependencies: {...}
  - agent_id: explorer:domain#frontend
    status: ok
    artifacts:
      - path: .work/01_explorer/domain.md
    findings:
      entities: [...]
      business_rules: [...]
  # ... 他の Explorer
```

### Reviewer Swarm 統合時

```yaml
inputs:
  - agent_id: reviewer:completeness
    status: ok
    severity: P1
    findings:
      p0_issues: []
      p1_issues: [...]
      p2_issues: [...]
  - agent_id: reviewer:consistency
    status: ok
    severity: P0
    findings:
      p0_issues: [...]
  # ... 他の Reviewer
```

## 出力

### Explorer 統合出力

`docs/requirements/.work/02_context_unified.md`:

```markdown
# Unified Context Analysis

> Generated: YYYY-MM-DD
> Sources: explorer:tech, explorer:domain, explorer:ui, explorer:integration, explorer:nfr

## Summary

| Aspect | Status | Key Findings |
|--------|--------|--------------|
| Tech Stack | ✓ | Next.js 14, TypeScript, pnpm |
| Domain Model | ✓ | 5 entities, 3 aggregates |
| UI | ✓ | React Query, Zustand |
| Integration | ✓ | Stripe, SendGrid |
| NFR | ✓ | JWT auth, 99.9% SLA target |

---

## Tech Stack

[explorer:tech から統合]

### Languages & Frameworks
- TypeScript 5.x
- Next.js 14 (App Router)
- Node.js 20

### Dependencies
[重複排除した依存関係リスト]

---

## Domain Model

[explorer:domain から統合]

### Entities
[重複排除したエンティティリスト]

### Business Rules
[重複排除したビジネスルールリスト]

---

## UI Architecture

[explorer:ui から統合]

---

## External Integrations

[explorer:integration から統合]

---

## Non-Functional Requirements

[explorer:nfr から統合]

---

## Conflicts Resolved

| ID | Source A | Source B | Resolution | Reasoning |
|----|----------|----------|------------|-----------|
| C-001 | tech: "React 18" | ui: "React 17" | React 18 | package.json に 18 と記載 |

---

## Open Questions (Unified)

[全 Explorer の open_questions をマージ]

1. [question from tech]
2. [question from domain]
...

---

## Appendix: Raw Outputs

各 Explorer の生出力は以下を参照:
- `.work/01_explorer/tech.md`
- `.work/01_explorer/domain.md`
- `.work/01_explorer/ui.md`
- `.work/01_explorer/integration.md`
- `.work/01_explorer/nfr.md`
```

### Reviewer 統合出力

`docs/requirements/.work/07_review_unified.md`:

```markdown
# Unified Review

> Generated: YYYY-MM-DD
> Sources: reviewer:completeness, reviewer:consistency, reviewer:quality, reviewer:testability, reviewer:nfr

## Gate Decision

| Severity | Count | Threshold | Result |
|----------|-------|-----------|--------|
| P0 (Blocker) | 1 | 1 = veto | **FAIL** |
| P1 (Major) | 3 | 2 = reject | FAIL |
| P2 (Minor) | 5 | - | PASS |

**Decision**: REJECT → Phase 2 へ差し戻し

---

## P0 Issues (Blocker) - 即時対応必須

### P0-001: [統合された P0 指摘]
- **Source**: reviewer:consistency
- **Original ID**: CONS-001
- **Description**: AC-002-1 が重複定義
- **Fix**: AC ID を再採番

---

## P1 Issues (Major) - 2 件以上で差し戻し

### P1-001: [統合された P1 指摘]
- **Source**: reviewer:completeness
- **Original ID**: COMP-002
- **Description**: US-003 に失敗系 AC がない
- **Fix**: 異常系シナリオを追加

### P1-002: [統合された P1 指摘]
- **Source**: reviewer:quality
- **Original ID**: QUAL-002
- **Description**: US-005 が大きすぎる
- **Fix**: 複数ストーリーに分割

### P1-003: [統合された P1 指摘]
- **Source**: reviewer:nfr
- **Original ID**: NFR-002
- **Description**: レート制限が未定義
- **Fix**: ポリシーを追加

---

## P2 Issues (Minor) - 要対応リスト

[P2 指摘のリスト - 重複排除済み]

---

## Conflicts Resolved

| ID | Source A | Source B | Resolution | Reasoning |
|----|----------|----------|------------|-----------|
| R-001 | quality: "曖昧語 P1" | consistency: "同じ箇所 P2" | P1 | quality の判定を優先 |

---

## Recommended Return Phase

| 指摘内容 | 推奨戻り先 |
|---------|-----------|
| P0-001: ID 重複 | Phase 4 (Writer) |
| P1-001: AC 不足 | Phase 4 (Writer) |
| P1-002: ストーリー分割 | Phase 3 (Planner) |
| P1-003: NFR 不足 | Phase 2 (Interviewer) |

**総合判断**: Phase 2 へ差し戻し（NFR のヒアリングが必要なため）
```

## 矛盾解消ルール

### 重複検出

同じ対象に対する findings を検出:

```yaml
duplicate_detection:
  - key: "entity_name"
    sources: ["domain", "tech"]
  - key: "api_endpoint"
    sources: ["integration", "tech"]
```

### 矛盾解消優先順位

1. **確信度**: High > Medium > Low
2. **エビデンス**: コード参照あり > 推測
3. **特化度**: 専門 Explorer > 汎用 Explorer
4. **新しさ**: 後から報告された情報を優先（同等の場合）

### Reviewer 矛盾解消

同じ箇所に対する異なる重大度の指摘:

```yaml
severity_resolution:
  rule: "重い方を採用"
  example:
    - reviewer_a: P1
    - reviewer_b: P2
    - result: P1
  exception: "明確な誤判定の場合は軽い方を採用（理由を明記）"
```

## ハンドオフ封筒

```yaml
kind: aggregator
agent_id: req:aggregator
mode: greenfield | brownfield
status: ok
artifacts:
  - path: .work/02_context_unified.md  # Explorer 統合の場合
    type: unified_context
  - path: .work/07_review_unified.md  # Reviewer 統合の場合
    type: unified_review
summary:
  inputs_count: 5
  conflicts_found: 2
  conflicts_resolved: 2
  duplicates_removed: 8
gate_decision:  # Reviewer 統合の場合のみ
  p0_count: 1
  p1_count: 3
  p2_count: 5
  result: "reject"
  return_phase: 2
open_questions: [...]
next: interviewer | planner | writer | done
```

## ツール使用

| ツール | 用途 |
|--------|------|
| Read | 各 Swarm エージェントの出力読み取り |
| Write | unified 出力の生成 |

## エラーハンドリング

| 状況 | 対応 |
|------|------|
| 一部エージェントが blocked | 警告を出力し、利用可能な出力のみで統合 |
| 解消不能な矛盾 | open_questions に追加、Phase 2 で確認 |
| 全エージェントが失敗 | status: blocked、原因を報告 |
