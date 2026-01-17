---
name: review-skill
description: |
  Performs consistency checks and reviews on design documentation.
  Validates structure, cross-references, and completeness across all documents.
  Use when reviewing design documents, checking traceability, 
  validating ID consistency, or generating project completion summaries.
context: fork
allowed-tools: Read, Glob, Grep
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
| docs/08_review/consistency_check.md | {baseDir}/templates/consistency_check.md | 整合性チェック結果 |
| docs/08_review/review_template.md | {baseDir}/templates/review_template.md | 個別レビュー結果 |
| docs/08_review/project_completion.md | {baseDir}/templates/project_completion.md | 完了サマリー |

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

### Level 3: 完全性チェック

| チェック項目 |
|-------------|
| プレースホルダー `{{}}` 残存無し |
| 必須項目が全て記入済 |
| 詳細仕様が記載されている |
| 受入基準が検証可能 |

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
| BLOCKER | 参照先不在、重複ID |
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

## 変更履歴

| バージョン | 変更内容 |
|-----------|----------|
| 2.2.0 | 公式仕様準拠（description修正、allowed-tools追加、{baseDir}活用） |
| 2.1.0 | 前提条件・エラーハンドリング追加、review_template.md追加 |
| 2.0.0 | 出力ディレクトリを08_review/に変更 |
| 1.0.0 | 初版 |
