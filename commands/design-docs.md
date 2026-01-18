---
name: design-docs
description: Run the full design document workflow from hearing to review. Use when creating complete system design documentation for new projects.
---

# Design Docs Command

システム設計書一式を生成するコマンド。
design-doc-orchestrator スキルを起動し、8フェーズの設計プロセスを実行する。

## 使用方法

```
/design-docs
```

## ワークフロー

1. **Phase 1: Hearing** - プロジェクト要件のヒアリング
2. **Phase 2: Requirements** - 機能要件・非機能要件の定義 ★承認必須★
3. **Phase 3: Architecture** - システムアーキテクチャ・キャッシュ戦略設計
4. **Phase 4: Database** - データ構造・エンティティ定義
5. **Phase 5: API** - RESTful API設計
6. **Phase 6: Design** - 画面設計
7. **Phase 7: Implementation** - 実装準備ドキュメント作成
8. **Phase 8: Review** - 整合性チェック・完了サマリー

## 出力先

すべてのドキュメントは `docs/` ディレクトリに生成される。

## オプション

- 単独フェーズの実行: 各スキルを直接呼び出す
  - `/hearing` - ヒアリングのみ
  - `/requirements` - 要件定義のみ
  - 等

## 関連

- design-doc-orchestrator スキル
- hearing, requirements, architecture, database, api, design, implementation, review エージェント
