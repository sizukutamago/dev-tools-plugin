---
name: hearing
description: This skill should be used when the user asks to "gather project requirements", "conduct requirements interview", "analyze existing codebase", "create project overview", "reverse engineer codebase", or "start new project documentation". Supports both new project interviews and reverse-engineering of existing codebases.
version: 1.0.0
---

# Hearing Skill

プロジェクト要件のヒアリング・分析を行うスキル。
新規プロジェクト開始時、ステークホルダーからの要件収集、
プロジェクト概要の作成、既存ソースコードの分析に使用する。

## 前提条件

| 条件 | 必須 | 説明 |
|------|------|------|
| docs/ ディレクトリ | ○ | 出力先（なければ作成） |
| ソースコード | △ | リバースエンジニアリング時のみ |

## 出力ファイル

| ファイル | テンプレート | 説明 |
|---------|-------------|------|
| docs/01_hearing/project_overview.md | {baseDir}/references/project_overview.md | プロジェクト概要 |
| docs/01_hearing/hearing_result.md | {baseDir}/references/hearing_result.md | ヒアリング結果詳細 |
| docs/01_hearing/glossary.md | {baseDir}/references/glossary.md | 用語集 |

## 依存関係

| 種別 | 対象 |
|------|------|
| 前提スキル | なし（最初のフェーズ） |
| 後続スキル | requirements |

## ワークフロー

### 新規プロジェクトの場合

```
1. プロジェクトタイプを確認
   - webapp / mobile / api / batch / fullstack

2. 以下を順次ヒアリング（質問は最小限に）
   a. システム概要・目的
   b. 必須機能（3-5個程度）
   c. 追加機能（優先度付き）
   d. 主要な非機能要件
   e. 利用者情報
   f. 制約条件

3. ヒアリング結果をまとめる

4. 用語を抽出してglossary生成

5. プロジェクト概要を生成
```

### リバースエンジニアリングの場合

```
1. ソースコード構造を分析
   - ディレクトリ構成
   - 主要ファイル
   - 依存関係

2. 以下を抽出
   a. 技術スタック
   b. エンティティ/モデル
   c. API/エンドポイント
   d. 画面/コンポーネント

3. 分析結果をhearing_result形式でまとめる
```

## ヒアリングのコツ

- 一度に1-2個の質問に絞る
- 具体例を提示して選択しやすくする
- ユーザーが答えやすい形式で質問

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| ユーザー応答なし | 3回プロンプト後、デフォルト値で続行 |
| ソースコード解析失敗 | 対象ディレクトリ確認を促す |
| 出力先書き込み失敗 | docs/01_hearing/ の作成を試行 |

## コンテキスト更新

完了後、`docs/project-context.yaml` に記録:

```yaml
phases:
  hearing:
    status: completed
    files:
      - docs/01_hearing/project_overview.md
      - docs/01_hearing/hearing_result.md
      - docs/01_hearing/glossary.md
glossary:
  - term: "用語"
    definition: "定義"
```
