---
name: review
description: This skill should be used when the user asks to "review design documents", "check document consistency", "validate traceability", "generate completion summary", "audit design specifications", or "check ID consistency". Performs consistency checks and reviews on design documentation.
version: 1.0.0
---

# Review Skill

設計書の整合性チェック・レビューを行うスキル。
構造チェック、相互参照検証、完全性確認を実施し、
プロジェクト完了サマリーを生成する。

## 前提条件

| 条件 | 必須 | 説明 |
|------|------|------|
| docs/ 配下の設計書 | ○ | レビュー対象 |
| docs/project-context.yaml | △ | ID・トレーサビリティ情報 |

## 出力ファイル

| ファイル | テンプレート | 説明 |
|---------|-------------|------|
| docs/08_review/consistency_check.md | {baseDir}/references/consistency_check.md | 整合性チェック結果 |
| docs/08_review/review_template.md | {baseDir}/references/review_template.md | 個別レビュー結果 |
| docs/08_review/project_completion.md | {baseDir}/references/project_completion.md | 完了サマリー |

## 依存関係

| 種別 | 対象 |
|------|------|
| 前提スキル | 全スキル（最終フェーズ） |
| 後続スキル | なし |

## ワークフロー

```
1. 全設計書を読み込み
2. Level 1: 構造チェック
3. Level 2: 整合性チェック
4. Level 3: 完全性チェック
5. 問題を分類（BLOCKER/WARNING）
6. consistency_check.md を生成
7. project_completion.md を生成
```

## レビューレベル

### Level 1: 構造チェック

| チェック項目 |
|-------------|
| YAMLフロントマター存在 |
| 必須セクション存在 |
| 見出し階層が適切 |
| テーブル形式が正しい |

### Level 2: 整合性チェック

| チェック項目 |
|-------------|
| ID形式準拠（FR-XXX, SC-XXX等） |
| 重複ID無し |
| 孤児ID無し |
| 参照先存在 |
| 用語統一（glossary準拠） |
| Goals/Non-Goals と FR の整合性 |
| エラーパターンと architecture の整合性 |
| テスト戦略と implementation の整合性 |

### Level 3: 完全性チェック

| チェック項目 |
|-------------|
| プレースホルダー `{{}}` 残存無し |
| 必須項目が全て記入済 |
| 詳細仕様が記載されている |
| 受入基準が検証可能 |
| **画面詳細ファイル完全性** |

### Level 4: 出力ファイル完全性チェック

全フェーズの必須出力ファイルが存在するかをチェックする。

#### 必須ファイル一覧

| フェーズ | 必須ファイル |
|---------|-------------|
| Phase 1: Hearing | `01_hearing/project_overview.md`, `hearing_result.md`, `glossary.md` |
| Phase 2: Requirements | `02_requirements/requirements.md`, `functional_requirements.md`, `non_functional_requirements.md` |
| Phase 3: Architecture | `03_architecture/architecture.md`, `adr.md`, `security.md`, `infrastructure.md` |
| Phase 4: Database | `04_data_structure/data_structure.md` |
| Phase 5: API | `05_api_design/api_design.md`, `integration.md` |
| Phase 6: Design | `06_screen_design/screen_list.md`, `screen_transition.md`, `component_catalog.md`, `error_patterns.md`, `ui_testing_strategy.md`, `details/screen_detail_SC-XXX.md` (全SC-ID分) |
| Phase 7: Implementation | `07_implementation/coding_standards.md`, `environment.md`, `testing.md`, `operations.md` |
| Phase 8: Review | `08_review/consistency_check.md`, `project_completion.md` |

#### 画面詳細ファイル完全性

| チェック項目 | 説明 |
|-------------|------|
| 全SC-IDに対応するファイル存在 | screen_list.md内の全SC-IDに対してscreen_detail_SC-XXX.mdが存在 |
| ファイル命名規則準拠 | `screen_detail_SC-XXX.md` 形式 |
| 必須セクション存在 | 基本情報、画面レイアウト、コンポーネント構成、状態管理、ユーザー操作、API連携 |

**検証手順**:
```
1. 各フェーズの必須ファイルが存在するか確認
2. screen_list.md から全SC-IDを抽出
3. details/ ディレクトリ内のファイルを列挙
4. 不足ファイルを BLOCKER として報告
```

## トレーサビリティチェック

- 全FRに対応するSCが存在
- 画面操作に対応するAPIが存在
- APIレスポンスのENTが定義済

## 判定基準

| 判定 | 条件 |
|------|------|
| ✅ PASS | BLOCKER 0件、WARNING ≤5件 |
| ⚠️ WARNING | BLOCKER 0件、WARNING >5件 |
| ❌ BLOCKER | BLOCKER ≥1件 |

## 問題分類

| 分類 | 例 |
|------|-----|
| BLOCKER | 参照先不在、重複ID、**必須ファイル不足**、**画面詳細ファイル不足** |
| WARNING | 孤児ID、プレースホルダー残存 |

## 修正サイクル

```
レビュー結果: 問題あり
    ↓
該当フェーズを特定
    ↓
修正を提案
    ↓
再レビュー（最大3回）
```

## コンテキスト更新

```yaml
phases:
  review:
    status: completed
    files:
      - docs/08_review/consistency_check.md
      - docs/08_review/review_template.md
      - docs/08_review/project_completion.md
    result:
      overall: PASS
      blockers: 0
      warnings: 2
```

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| 設計書不在 | 存在するファイルのみレビュー、欠落を報告 |
| project-context.yaml 不在 | ファイル単体でチェック、トレーサビリティはスキップ |
| 修正サイクル超過 | 現状で完了、残課題を project_completion.md に記録 |
