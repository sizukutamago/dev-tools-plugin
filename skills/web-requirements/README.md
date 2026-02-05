# Web 要件定義スキル

Web 開発の要件定義を支援するスキル。**Swarm パターン**（並列エージェント実行）で網羅性を高め、ユーザーストーリー＋受け入れ基準（Gherkin 形式）を生成。

## 概要

| 項目 | 内容 |
|------|------|
| **対象** | 新規開発（greenfield）・既存改修（brownfield）の両方 |
| **出力形式** | ユーザーストーリー（As a...）+ Gherkin 形式 AC（Given/When/Then） |
| **中間成果物** | `docs/requirements/.work/` に保存（`.gitignore` 対象） |
| **最終成果物** | `docs/requirements/user-stories.md` |

## アーキテクチャ

### Swarm パターンの採用理由

単一エージェントでは観点の抜け漏れが発生しやすい。複数の専門エージェントを並列実行し、Two-step Reduce でマージすることで網羅性を担保。

```
┌─────────────────────────────────────────────────────────────────┐
│                    Orchestrator (SKILL.md)                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Phase 1: Explorer Swarm (並列)                                │
│  ┌─────────┬─────────┬─────────┬─────────┬─────────┐           │
│  │  tech   │ domain  │   ui    │integrat.│   nfr   │           │
│  │ (sonnet)│ (opus)  │(sonnet) │ (opus)  │(sonnet) │           │
│  └────┬────┴────┬────┴────┬────┴────┬────┴────┬────┘           │
│       └─────────┴─────────┼─────────┴─────────┘                │
│                           ▼                                     │
│                    Aggregator (opus)                            │
│                    Two-step Reduce                              │
│                           │                                     │
│  Phase 2: Interviewer     │                                     │
│  (AskUserQuestion 直接)   │                                     │
│                           ▼                                     │
│  Phase 3: Planner (opus)                                       │
│                           │                                     │
│  Phase 4: Writer (sonnet) │                                     │
│                           ▼                                     │
│  Phase 5: Reviewer Swarm (並列)                                │
│  ┌─────────┬─────────┬─────────┬─────────┬─────────┐           │
│  │complete.│consist. │ quality │testabil.│   nfr   │           │
│  │ (haiku) │ (opus)  │ (haiku) │ (haiku) │ (haiku) │           │
│  └────┬────┴────┬────┴────┬────┴────┬────┴────┬────┘           │
│       └─────────┴─────────┼─────────┴─────────┘                │
│                           ▼                                     │
│                    Aggregator (opus)                            │
│                    統合レビュー                                 │
│                           │                                     │
│  Phase 6: Gate 判定       │                                     │
│                           ▼                                     │
│                    user-stories.md                              │
└─────────────────────────────────────────────────────────────────┘
```

### エージェント一覧

| 役割 | エージェント | モデル | 責務 |
|------|-------------|--------|------|
| **Explorer Swarm** | `explorer:tech` | sonnet | 技術スタック、依存関係、アーキテクチャ |
| | `explorer:domain` | **opus** | ドメインモデル、業務ルール、例外・境界条件 |
| | `explorer:ui` | sonnet | コンポーネント構造、状態管理 |
| | `explorer:integration` | **opus** | 外部 API、認証、データフロー、障害時設計 |
| | `explorer:nfr` | sonnet | セキュリティ、パフォーマンス、運用 |
| **Interviewer** | (オーケストレーター内) | - | AskUserQuestion ツール直接使用 |
| **Planner** | `req:planner` | **opus** | ストーリーマップ構造化、依存関係判断 |
| **Writer** | `req:writer` | sonnet | ユーザーストーリー生成 |
| **Aggregator** | `req:aggregator` | **opus** | Swarm 結果マージ、矛盾解消 |
| **Reviewer Swarm** | `reviewer:completeness` | haiku | 完全性（必須項目、AC 網羅性） |
| | `reviewer:consistency` | **opus** | 一貫性（用語統一、横断的矛盾検出） |
| | `reviewer:quality` | haiku | 品質（曖昧語、INVEST 原則） |
| | `reviewer:testability` | haiku | テスト可能性（AC 実装可否） |
| | `reviewer:nfr` | haiku | 非機能（セキュリティ、a11y） |

## 参照ファイル

| ファイル | 内容 |
|---------|------|
| `references/user_stories_format.md` | 出力フォーマット仕様 |
| `references/quality_rules.md` | 品質ルール（曖昧語・禁則） |
| `references/handoff_schema.md` | ハンドオフ封筒スキーマ |
| `references/scope_manifest.md` | スコープ分割仕様 |
| `references/interview_questions.md` | AskUserQuestion 用質問テンプレート |

## 関連ドキュメント

- [SKILL.md](./SKILL.md) - AI 向けワークフロー・Phase 詳細
