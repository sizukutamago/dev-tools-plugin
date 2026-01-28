# ai-skills

設計書作成ワークフロースキルとエージェント集。8フェーズの設計プロセスを自動化する Claude Code プラグイン。

## インストール

このディレクトリを Claude Code のプラグインディレクトリに配置するか、symlink を作成します。

## スキル一覧

| スキル | 説明 | トリガーフレーズ |
|--------|------|----------------|
| hearing | プロジェクト要件のヒアリング・分析 | "gather project requirements", "reverse engineer codebase" |
| requirements | 機能要件・非機能要件の定義 | "define requirements", "create functional requirements" |
| architecture | システムアーキテクチャ・セキュリティ設計 | "design system architecture", "create ADR" |
| database | データ構造・エンティティ定義 | "design data model", "create entity definitions" |
| api | RESTful API・外部連携仕様設計 | "design API", "create REST endpoints" |
| design | 画面設計・UI仕様 | "design UI", "create screen specifications" |
| implementation | 実装準備ドキュメント作成 | "create coding standards", "design test strategy" |
| review | 設計書整合性チェック・レビュー | "review design documents", "check document consistency" |
| design-doc-orchestrator | 設計書一式を順次生成 | "create design documents", "run design workflow" |
| web-design-guidelines | Web UI ガイドライン準拠チェック | "review my UI", "check accessibility" |
| vercel-react-best-practices | React/Next.js パフォーマンス最適化 | "optimize React code", "improve Next.js performance" |
| agent-browser | ブラウザ自動操作 | "test web page", "automate browser" |
| biome | Linting/Formatting 設定 | "setup biome", "configure linter" |
| dependency-cruiser | アーキテクチャ依存検証 | "setup dependency cruiser", "check architecture" |

## エージェント一覧

| エージェント | 色 | 説明 |
|-------------|-----|------|
| hearing | blue | プロジェクト要件ヒアリング |
| requirements | green | 要件定義 |
| architecture | purple | アーキテクチャ設計 |
| database | orange | データ構造定義 |
| api | cyan | API設計 |
| design | magenta | 画面設計 |
| implementation | yellow | 実装準備 |
| review | red | 設計書レビュー |

## 使用方法

### フルワークフロー実行

```
/design-docs
```

または

```
設計書を作成して
```

### 個別スキル実行

```
/hearing
/requirements
/api
```

## ディレクトリ構造

```
ai-skills/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   ├── hearing/
│   │   ├── SKILL.md
│   │   └── references/
│   ├── requirements/
│   ├── architecture/
│   ├── database/
│   ├── api/
│   ├── design/
│   ├── implementation/
│   ├── review/
│   ├── design-doc-orchestrator/
│   ├── web-design-guidelines/
│   ├── vercel-react-best-practices/
│   │   └── references/rules/
│   ├── agent-browser/
│   ├── biome/
│   │   ├── SKILL.md
│   │   ├── commands/
│   │   │   └── setup-biome.md
│   │   └── templates/
│   │       └── biome.base.json
│   ├── dependency-cruiser/
│   │   ├── SKILL.md
│   │   ├── commands/
│   │   │   └── setup-depcruise.md
│   │   └── templates/
│   │       ├── .dependency-cruiser.base.js
│   │       └── presets/
│   │           ├── ddd.js
│   │           └── frontend.js
│   └── shared/
│       └── references/
├── agents/
│   ├── hearing.md
│   ├── requirements.md
│   ├── architecture.md
│   ├── database.md
│   ├── api.md
│   ├── design.md
│   ├── implementation.md
│   └── review.md
├── commands/
│   └── design-docs.md
└── README.md
```

## 設計書出力先

すべての設計書は `docs/` ディレクトリに生成されます:

```
docs/
├── 01_hearing/
├── 02_requirements/
├── 03_architecture/
├── 04_data_structure/
├── 05_api_design/
├── 06_screen_design/
├── 07_implementation/
├── 08_review/
└── project-context.yaml
```

## ID体系

| ID | 形式 | 例 |
|----|------|-----|
| FR | FR-XXX | FR-001 |
| NFR | NFR-[CAT]-XXX | NFR-PERF-001 |
| SC | SC-XXX | SC-001 |
| API | API-XXX | API-001 |
| ENT | ENT-{Name} | ENT-User |
| ADR | ADR-XXXX | ADR-0001 |

## 言語ポリシー

このプラグインでは以下の言語使用ルールを適用しています:

| 項目 | 言語 | 理由 |
|------|------|------|
| `description` フィールド | 英語 | Claude のトリガー検出が英語キーワードで最適化されるため |
| 本文・ドキュメント | 日本語 | 開発者向けの可読性を優先 |
| コード例・コメント | 日本語/英語 | コンテキストに応じて選択 |

**例**: SKILL.md の frontmatter

```yaml
---
name: hearing
description: Gather project requirements through user interviews or reverse engineer existing codebase.
---

# ヒアリング

プロジェクト要件を収集・整理するフェーズ...
```

## ライセンス

MIT
