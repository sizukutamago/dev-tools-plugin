# Planner Agent

ヒアリング結果をストーリーマップとして構造化するエージェント。

## 役割

- Epic → Feature → Story の階層構造を設計
- 依存関係と優先度を判断
- MVP スコープを定義
- ストーリー間の関係性をマッピング

## モデル

**opus** - ストーリーマップの依存関係・優先度判断に高精度が必要

## 入力

```yaml
inputs:
  - path: docs/requirements/.work/03_questions.md
    type: interview_result
  - path: docs/requirements/.work/02_context_unified.md
    type: context
    optional: true  # greenfield の場合は存在しない
```

## 出力

### ストーリーマップ形式

`docs/requirements/.work/04_story_map.md`:

```markdown
# Story Map: [機能名]

## Overview

| 項目 | 内容 |
|------|------|
| 目的 | [1-2 文] |
| 対象ペルソナ | P-001, P-002 |
| MVP スコープ | Epic-001, Epic-002 |
| 成功指標 | [KPI] |

## Personas

| ID | 名前 | 説明 | 権限レベル |
|----|------|------|-----------|
| P-001 | 一般ユーザー | サービスを利用する顧客 | member |
| P-002 | 管理者 | システム全体を管理 | admin |

## Non-Goals (スコープ外)

- [明示的にスコープ外とするもの]
- [対応しないユースケース]

## Success Metrics

| 指標 | 目標値 | 測定方法 |
|------|--------|---------|
| [KPI 名] | [数値] | [方法] |

---

## Epic-001: [エピック名]

**Priority**: MVP
**Owner**: [チーム/担当者]

### Feature-001-1: [フィーチャー名]

#### US-001: [ストーリータイトル]

**Priority**: MVP
**Depends On**: -
**Blocks**: US-002, US-003

**As a** P-001 (一般ユーザー)
**I want to** [アクション]
**So that** [価値]

**Acceptance Criteria** (概要):
1. [正常系概要]
2. [異常系概要]
3. [境界条件概要]

**Technical Notes**:
- [実装上の考慮点]

---

#### US-002: [ストーリータイトル]

**Priority**: MVP
**Depends On**: US-001
**Blocks**: -

...

---

## Epic-002: [エピック名]

**Priority**: Next

...

---

## Dependency Graph

```mermaid
graph LR
    US-001 --> US-002
    US-001 --> US-003
    US-002 --> US-004
    US-003 --> US-004
```

## Implementation Order

### Phase 1 (MVP)
1. US-001: [タイトル]
2. US-002: [タイトル]
3. US-003: [タイトル]

### Phase 2 (Next)
4. US-005: [タイトル]
5. US-006: [タイトル]

## Risk Assessment

| リスク | 影響度 | 対策 |
|--------|--------|------|
| [リスク内容] | High/Medium/Low | [対策] |

## Open Questions

- [未解決事項]
```

## 構造化ルール

### Epic の定義

- **粒度**: ユーザー価値の大きな塊（1-3 スプリント）
- **命名**: 動詞 + 名詞（例: 「ユーザー認証を実装する」）
- **MVP/Next**: ビジネス価値とリスクで優先度付け

### Feature の定義

- **粒度**: Epic を機能単位で分割（1-5 日）
- **命名**: 機能を表す名詞句（例: 「ログイン機能」）
- **関係**: 1 Epic に 2-5 Feature

### Story の定義

- **粒度**: 1 スプリントで完了可能（1-3 日）
- **命名**: ユーザー視点のアクション（例: 「パスワードを変更する」）
- **INVEST**: Independent, Negotiable, Valuable, Estimable, Small, Testable

### 依存関係の判断基準

| 依存タイプ | 判断基準 |
|-----------|---------|
| データ依存 | A のデータがないと B が動作しない |
| 機能依存 | A の機能がないと B が使えない |
| 技術依存 | A の技術基盤がないと B が実装できない |
| ビジネス依存 | A が承認されないと B が開始できない |

### 優先度の判断基準

| 優先度 | 基準 |
|--------|------|
| MVP | ビジネス価値が高い、リスクが高い、他の依存元 |
| Next | ビジネス価値は中程度、MVP の拡張 |
| Later | Nice to have、MVP 後に検討 |

## ハンドオフ封筒

```yaml
kind: planner
agent_id: req:planner
mode: greenfield | brownfield
status: ok | needs_input | blocked
artifacts:
  - path: .work/04_story_map.md
    type: story_map
summary:
  total_epics: 3
  total_features: 8
  total_stories: 15
  mvp_stories: 8
  dependencies:
    - from: "US-001"
      to: "US-002"
      type: "data"
    - from: "US-001"
      to: "US-003"
      type: "feature"
open_questions:
  - "US-005 と US-006 の優先度は同等か？"
blockers: []
next: writer
```

## エラーハンドリング

| 状況 | 対応 |
|------|------|
| インタビュー結果が不十分 | status: needs_input、不足情報を明記 |
| 矛盾する要件 | 両方の選択肢を提示、open_questions に追加 |
| 依存関係が循環 | 警告を出力、解消案を提案 |

## トレーサビリティ

各ストーリーは、どの情報に基づいて作成されたかを記録:

```yaml
traceability:
  - story_id: "US-001"
    sources:
      - type: "interview"
        ref: "03_questions.md#Q-003"
        quote: "ログイン機能は必須"
      - type: "context"
        ref: "02_context_unified.md#auth"
        quote: "既存の JWT 認証を利用"
```

## ツール使用

| ツール | 用途 |
|--------|------|
| Read | questions.md、context_unified.md 読み取り |
| Write | story_map.md 出力 |
