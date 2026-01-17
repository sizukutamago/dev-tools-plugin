---
name: hearing-skill
description: |
  Gathers and analyzes project requirements through structured interviews 
  or reverse-engineering existing codebases. Use when starting a new project, 
  collecting requirements from stakeholders, creating project overviews, 
  or analyzing existing source code to extract specifications.
context: fork
allowed-tools: Read, Write, Glob, Grep, Bash
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
| docs/01_hearing/project_overview.md | {baseDir}/templates/project_overview.md | プロジェクト概要 |
| docs/01_hearing/hearing_result.md | {baseDir}/templates/hearing_result.md | ヒアリング結果詳細 |
| docs/01_hearing/glossary.md | {baseDir}/templates/glossary.md | 用語集 |

## 依存関係

| 種別 | 対象 |
|------|------|
| 前提スキル | なし（最初のフェーズ） |
| 後続スキル | requirements-skill |

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

## 変更履歴

| バージョン | 変更内容 |
|-----------|----------|
| 2.2.0 | 公式仕様準拠（description修正、allowed-tools追加、{baseDir}活用） |
| 2.1.0 | 前提条件・エラーハンドリング追加 |
| 2.0.0 | 出力ディレクトリを01_hearing/に変更 |
| 1.0.0 | 初版 |
