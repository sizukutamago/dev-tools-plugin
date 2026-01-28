---
name: hearing
description: This skill should be used when the user asks to "gather project requirements", "conduct requirements interview", "analyze existing codebase", "create project overview", "reverse engineer codebase", or "start new project documentation". Supports both new project interviews and reverse-engineering of existing codebases.
version: 2.0.0
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
| 連携スキル | research（技術調査時） |

## ワークフロー

### Phase 0: EnterPlanMode

**必須**: スキル起動直後に実行

```
1. EnterPlanMode ツールを呼び出す
2. 計画モードでヒアリングを実施
3. 決定事項を計画ファイルに記録
```

### Phase 1: Initial Context

プロジェクトの基本情報を収集:

1. **AskUserQuestion** でプロジェクトタイプを確認
2. システム概要を自由記述で収集

### Phase 2: Deep Dive

以下のカテゴリについて **AskUserQuestion** で深掘り:

| カテゴリ | 質問数目安 | 必須 |
|---------|-----------|------|
| Goals/Non-Goals | 2-3問 | ○ |
| 機能スコープ | 2-4問 | ○ |
| 非機能要件 | 1-2問 | ○ |
| 技術制約 | 1-2問 | △ |
| 利用者情報 | 1問 | ○ |

**重要**: 曖昧な回答があれば、追加質問で深掘りする

### Phase 3: Research（必要時）

**軽微な調査**:
- WebSearch でベストプラクティスを調査
- 調査結果を次の質問の選択肢に反映

**本格的な技術調査が必要な場合**:
- research スキルを呼び出し
- 調査結果を AskUserQuestion の選択肢に反映

### Phase 4: Decision Recording

全ての決定をテーブル形式で記録:

| 項目 | 選択 | 理由 | 備考 |
|------|------|------|------|

曖昧点があれば Phase 2 に戻る

### Phase 5: ExitPlanMode

**必須**: ユーザー承認を得る

1. ExitPlanMode ツールを呼び出す
2. ユーザーが計画を承認するまで待機

### Phase 6: Output Generation

承認後に実行:

1. hearing_result.md を生成
2. project_overview.md を生成
3. glossary.md を生成
4. project-context.yaml を更新

## リバースエンジニアリングの場合

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

## ツール使用ルール

### EnterPlanMode / ExitPlanMode

- 起動直後に EnterPlanMode 必須
- ExitPlanMode 前に成果物を生成しない
- ユーザー承認なしに次フェーズに進まない

### AskUserQuestion

- 全ての重要決定に使用必須
- 各質問は 2-4 個の選択肢
- 各選択肢に pros/cons を含める
- 曖昧な回答は追加質問で深掘り

### research スキル連携

| 状況 | アクション |
|------|----------|
| 技術選定が必要 | research スキルを呼び出し |
| 外部サービス比較が必要 | research スキルを呼び出し |
| 軽微な調査 | WebSearch で直接調査 |

## 質問テンプレート

### プロジェクトタイプ

| 選択肢 | 説明 |
|--------|------|
| webapp | ブラウザで動作するWebアプリケーション |
| mobile | iOS/Androidネイティブまたはハイブリッドアプリ |
| api | バックエンドAPI、マイクロサービス |
| batch | 定期実行処理、データ処理パイプライン |
| fullstack | フロントエンド + バックエンド一体型 |

### リリース範囲

| 選択肢 | 説明 |
|--------|------|
| MVP最小限 | コア機能1-2個のみ、素早くリリースして検証 |
| 標準セット | 主要機能を網羅、一般的なリリース規模 |
| フル機能 | 想定機能をすべて含む、大規模リリース |

### 非機能優先度

| 選択肢 | 説明 |
|--------|------|
| パフォーマンス | 応答速度、処理能力を最優先 |
| セキュリティ | 認証・認可、データ保護を最優先 |
| 可用性 | 稼働率、障害対応を最優先 |
| 保守性 | コード品質、拡張性を最優先 |

## Goals/Non-Goals 定義ガイド

| 種別 | 定義 | 例 |
|------|------|-----|
| Goals | 達成すべきビジネス/ユーザー目標 | 「注文完了率90%以上」「モバイル対応」 |
| Non-Goals | 明示的に除外する機能・範囲 | 「管理画面」「多言語対応」「オフライン機能」 |

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
