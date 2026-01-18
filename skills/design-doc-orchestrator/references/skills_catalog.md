# Skills Catalog

設計書作成ワークフローで使用する全スキルの一覧と連携パターン。

## スキル一覧

| # | スキル名 | 役割 | 出力ディレクトリ |
|---|---------|------|-----------------|
| 1 | hearing | プロジェクト要件ヒアリング・分析 | docs/01_hearing/ |
| 2 | requirements | 機能要件・非機能要件の定義 | docs/02_requirements/ |
| 3 | architecture | システムアーキテクチャ設計 | docs/03_architecture/ |
| 4 | database | データ構造・エンティティ定義 | docs/04_data_structure/ |
| 5 | api | API設計・外部連携仕様 | docs/05_api_design/ |
| 6 | design | 画面設計・UI仕様 | docs/06_screen_design/ |
| 7 | implementation | 実装準備ドキュメント | docs/07_implementation/ |
| 8 | review | 整合性チェック・レビュー | docs/08_review/ |

## 連携パターン

### 順次実行パターン（フル実行）

オーケストレータが全フェーズを順次実行:

```
hearing → requirements → architecture → database → api → design → implementation → review
```

**トリガー例**:
- 「設計書を作成して」
- 「新規プロジェクトの設計書を生成して」
- 「プロジェクト〇〇の設計書一式を作成」

### 単体実行パターン

特定のスキルのみを直接実行:

```
[スキル単体]
```

**トリガー例**:
- 「API設計だけ作成して」 → api スキル
- 「キャッシュ戦略を設計して」 → architecture スキル
- 「画面遷移図を作成して」 → design スキル

### 部分実行パターン

特定のフェーズから開始:

```
[開始フェーズ] → ... → review
```

**トリガー例**:
- 「要件定義から始めて」 → requirements から開始
- 「API設計以降を実行して」 → api から開始

## スキル間のデータ依存

### 入力依存関係

| スキル | 必須入力 | オプション入力 |
|--------|---------|---------------|
| hearing | なし | ソースコード（リバースエンジニアリング時） |
| requirements | hearing_result.md | glossary.md |
| architecture | non_functional_requirements.md | functional_requirements.md |
| database | functional_requirements.md | - |
| api | functional_requirements.md, data_structure.md | - |
| design | functional_requirements.md, api_design.md | - |
| implementation | architecture.md | adr.md |
| review | docs/ 全体 | project-context.yaml |

### 出力→入力の連鎖

```
hearing.hearing_result.md
    ↓
requirements.functional_requirements.md
    ↓
database.data_structure.md
    ↓
api.api_design.md
    ↓
design.screen_list.md
```

## ID体系と採番責任

| ID種別 | 形式 | 採番スキル |
|--------|------|-----------|
| FR | FR-XXX | requirements |
| NFR | NFR-[CAT]-XXX | requirements |
| ENT | ENT-{Name} | database |
| API | API-XXX | api |
| SC | SC-XXX | design |
| ADR | ADR-XXXX | architecture |

## トレーサビリティマトリクス

| 関係 | 記録スキル | 格納先 |
|------|-----------|--------|
| FR → ENT | database | project-context.yaml |
| FR → API | api | project-context.yaml |
| FR → SC | design | project-context.yaml |
| API → ENT | api | project-context.yaml |
| API → SC | design | project-context.yaml |

## エラー時の復旧パターン

### 前提スキル未完了

```
エラー: 前提ファイルが見つかりません

対応:
1. 不足しているフェーズを特定
2. 該当スキルを先に実行
3. 元のスキルを再実行
```

### ID衝突

```
エラー: ID が既に使用されています

対応:
1. project-context.yaml の id_registry を確認
2. 重複IDを修正
3. 該当スキルを再実行
```

## スキル選択の判断基準

| ユーザーの要求 | 選択スキル |
|---------------|-----------|
| 「〇〇を作成して」（一般的） | オーケストレータ |
| 「ヒアリングして」「要件をまとめて」 | hearing |
| 「機能要件を定義して」「NFRを作成して」 | requirements |
| 「技術スタックを決めて」「ADRを書いて」 | architecture |
| 「エンティティを定義して」「型を作成して」 | database |
| 「APIを設計して」「エンドポイントを定義して」 | api |
| 「画面設計して」「ワイヤーフレームを作成して」 | design |
| 「コーディング規約を作成して」「テスト設計して」 | implementation |
| 「レビューして」「整合性チェックして」 | review |
