---
name: hearing
description: This skill should be used when the user asks to "gather project requirements", "conduct requirements interview", "analyze existing codebase", "create project overview", "reverse engineer codebase", or "start new project documentation". Supports both new project interviews and reverse-engineering of existing codebases.
version: 1.0.0
agent: Plan
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

### 構造化質問プロセス

`commands/dig.md` の方法論に従う:

1. **Clarify**: 曖昧点を特定
2. **Ask**: AskUserQuestion で構造化質問（2-4問、各2-4選択肢）
3. **Process**: 決定をテーブル形式で記録
4. **Show**: サマリーを提示、新たな曖昧点があればPhase 2へ

詳細は `commands/dig.md` を参照。

### 調査ツール

技術選択や不明点がある場合、質問前に調査:
- **WebSearch**: ベストプラクティス、ライブラリ比較
- **Context7 MCP**: 公式ドキュメント参照（利用可能な場合）

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
