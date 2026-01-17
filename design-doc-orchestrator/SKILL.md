---
name: design-doc-orchestrator
description: |
  Orchestrates the generation of comprehensive system design documentation 
  by coordinating specialized sub-agents. Use when creating full design 
  documentation for new projects, generating requirements-to-implementation 
  documents, or reverse-engineering existing systems. For individual phases 
  (e.g., cache strategy only), invoke the specific skill directly.
allowed-tools: Read, Write, Glob, Grep, Bash
---

# Design Doc Orchestrator

システム設計書一式を生成するオーケストレータ。
専門サブエージェントを順次呼び出して設計書を作成する。
新規プロジェクトの設計書作成、要件定義から実装準備までの一括生成、
既存システムのリバースエンジニアリングに使用する。

## サブエージェント一覧

| Phase | Agent | Skill | 出力ディレクトリ | 出力ファイル |
|-------|-------|-------|-----------------|-------------|
| 1 | hearing-agent | hearing-skill | 01_hearing/ | project_overview.md, hearing_result.md, glossary.md |
| 2 | requirements-agent | requirements-skill | 02_requirements/ | requirements.md, functional_requirements.md, non_functional_requirements.md |
| 3 | architecture-agent | architecture-skill | 03_architecture/ | architecture.md, adr.md, security.md, infrastructure.md, cache_strategy.md |
| 4 | database-agent | database-skill | 04_data_structure/ | data_structure.md |
| 5 | api-agent | api-skill | 05_api_design/ | api_design.md, integration.md |
| 6 | design-agent | design-skill | 06_screen_design/ | screen_list.md, screen_transition.md, component_catalog.md, details/screen_detail_SC-XXX.md |
| 7 | implementation-agent | implementation-skill | 07_implementation/ | coding_standards.md, environment.md, testing.md, operations.md |
| 8 | review-agent | review-skill | 08_review/ | consistency_check.md, review_template.md, project_completion.md |

## フェーズ順序の論理的根拠

| Phase | 名前 | 理由 |
|-------|------|------|
| 1 | ヒアリング | 要件を聞く |
| 2 | 要件定義 | 機能・非機能要件をまとめる |
| 3 | アーキテクチャ | 技術スタック・全体方針を先に決定 |
| 4 | データ構造 | エンティティを定義（APIの入出力の基盤） |
| 5 | API設計 | エンティティを使ってAPIを設計 |
| 6 | 画面設計 | APIを使って画面を設計 |
| 7 | 実装準備 | コーディング規約、テスト設計 |
| 8 | レビュー | 整合性チェック |

## ワークフロー

```
[開始]
    ↓
[Phase 1] hearing-agent を呼び出し
    入力: プロジェクトタイプ、ソースコード（あれば）
    出力: 01_hearing/*.md
    ↓
[Phase 2] requirements-agent を呼び出し
    入力: 01_hearing/hearing_result.md
    出力: 02_requirements/*.md
    ↓ ★ユーザーレビュー・承認必須★
[Phase 3] architecture-agent を呼び出し
    入力: 02_requirements/*.md
    出力: 03_architecture/*.md（キャッシュ戦略含む）
    ↓
[Phase 4] database-agent を呼び出し
    入力: 02_requirements/functional_requirements.md
    出力: 04_data_structure/*.md
    ↓
[Phase 5] api-agent を呼び出し
    入力: 02_requirements/*.md, 04_data_structure/*.md
    出力: 05_api_design/*.md
    ↓
[Phase 6] design-agent を呼び出し
    入力: 02_requirements/*.md, 05_api_design/*.md
    出力: 06_screen_design/*.md
    ↓
[Phase 7] implementation-agent を呼び出し
    入力: 03_architecture/*.md
    出力: 07_implementation/*.md
    ↓
[Phase 8] review-agent を呼び出し
    入力: docs/ 全体
    出力: 08_review/*.md
    ↓ 問題あれば修正サイクル
[完了]
```

## エージェント呼び出し方法

各エージェントは `.claude/agents/` に定義されている。
Claudeはタスク内容と各エージェントの `description` を照合し、
適切なサブエージェントを自動的に選択・起動する。

明示的に特定のスキルを使用したい場合は、
「hearing-skill を使ってヒアリングして」のように依頼する。

## 実行方法

### フル実行

「設計書を作成して」「新規プロジェクトの設計書を生成して」
→ オーケストレータが Phase 1 から順次実行

### 単体実行（個別フェーズ）

「API設計だけ作成して」
→ api-skill が直接実行される

「キャッシュ戦略を設計して」
→ architecture-skill が直接実行される
   ※オーケストレータは起動しない

## 初期化

### 出力ディレクトリ構造

```
docs/
├── 01_hearing/
│   ├── project_overview.md
│   ├── hearing_result.md
│   └── glossary.md
├── 02_requirements/
│   ├── requirements.md
│   ├── functional_requirements.md
│   └── non_functional_requirements.md
├── 03_architecture/
│   ├── architecture.md
│   ├── adr.md
│   ├── security.md
│   ├── infrastructure.md
│   └── cache_strategy.md
├── 04_data_structure/
│   └── data_structure.md
├── 05_api_design/
│   ├── api_design.md
│   └── integration.md
├── 06_screen_design/
│   ├── screen_list.md
│   ├── screen_transition.md
│   ├── component_catalog.md
│   └── details/
│       └── screen_detail_SC-XXX.md
├── 07_implementation/
│   ├── coding_standards.md
│   ├── environment.md
│   ├── testing.md
│   └── operations.md
├── 08_review/
│   ├── consistency_check.md
│   ├── review_template.md
│   └── project_completion.md
└── project-context.yaml
```

### プロジェクトコンテキスト

各エージェント間で共有する情報は `docs/project-context.yaml` で管理する。
これは本スキルシステム独自のパターンであり、以下を一元管理する:

- プロジェクト基本情報
- ID採番状態（FR, NFR, SC, API, ENT, ADR）
- トレーサビリティ情報
- フェーズ完了状態

初回実行時、`{baseDir}/../shared/project-context.yaml` をテンプレートとして
`docs/project-context.yaml` にコピーして使用する。

## ID体系

| ID | 形式 | 例 |
|----|------|-----|
| FR | FR-XXX | FR-001 |
| NFR | NFR-[CAT]-XXX | NFR-PERF-001 |
| SC | SC-XXX | SC-001 |
| API | API-XXX | API-001 |
| ENT | ENT-{Name} | ENT-User |
| ADR | ADR-XXXX | ADR-0001 |

## ユーザー確認ポイント

### 必須（Phase 2 完了後）

要件定義の承認が必要。承認されるまで Phase 3 に進まない。

```
「機能要件・非機能要件を作成しました。レビューをお願いします。」

[要件一覧を表示]

承認 / 修正依頼 を選択してください。
```

## エラーハンドリング

### エージェント実行エラー

| エラー種別 | 対応 |
|-----------|------|
| ファイル読み込み失敗 | 前提フェーズの完了確認、不足ファイルを報告 |
| ID採番衝突 | project-context.yaml の id_registry を確認・修正 |
| テンプレート不在 | スキルディレクトリの templates/ を確認 |
| 出力先書き込み失敗 | docs/ ディレクトリの存在・権限を確認 |

### リトライポリシー

```
エラー発生
    ↓
エラー内容をユーザーに報告
    ↓
ユーザー選択: [リトライ] / [スキップ] / [中断]
    ↓
リトライ: 最大3回まで
スキップ: 次フェーズへ（警告を記録）
中断: 現状を保存して終了
```

### レビューでの問題検出時

```
BLOCKER 検出
    ↓
該当フェーズを特定
    ↓
修正提案を生成
    ↓
ユーザー承認後、該当エージェントを再実行
    ↓
再レビュー（最大3サイクル）
```

## 依存関係

```mermaid
graph TD
    P1[Phase 1: hearing] --> P2[Phase 2: requirements]
    P2 --> P3[Phase 3: architecture]
    P2 --> P4[Phase 4: database]
    P4 --> P5[Phase 5: api]
    P3 --> P7[Phase 7: implementation]
    P5 --> P6[Phase 6: design]
    P6 --> P8[Phase 8: review]
    P7 --> P8
```

## 変更履歴

| バージョン | 日付 | 変更内容 |
|-----------|------|----------|
| 2.2.0 | 2026-01-12 | 公式仕様準拠（description修正、allowed-tools追加） |
| 2.1.0 | - | エラーハンドリング強化、依存関係明示 |
| 2.0.0 | - | フェーズ順序変更、キャッシュ戦略追加 |
| 1.0.0 | - | 初版 |
