---
name: implementation
description: This skill should be used when the user asks to "create coding standards", "setup development environment", "design test strategy", "write operations runbook", "define deployment process", or "document implementation guidelines". Creates implementation preparation documents.
version: 1.0.0
---

# Implementation Skill

実装準備ドキュメントを作成するスキル。
コーディング規約の策定、開発環境のセットアップ、テスト戦略の設計、
運用手順の文書化に使用する。

## 前提条件

| 条件 | 必須 | 説明 |
|------|------|------|
| docs/03_architecture/architecture.md | ○ | 技術スタック情報 |
| docs/03_architecture/adr.md | △ | 技術選定理由 |

## 出力ファイル

| ファイル | テンプレート | 説明 |
|---------|-------------|------|
| docs/07_implementation/coding_standards.md | {baseDir}/references/coding_standards.md | コーディング規約 |
| docs/07_implementation/environment.md | {baseDir}/references/environment.md | 環境設定 |
| docs/07_implementation/testing.md | {baseDir}/references/testing.md | テスト設計 |
| docs/07_implementation/operations.md | {baseDir}/references/operations.md | 運用手順書 |

## 依存関係

| 種別 | 対象 |
|------|------|
| 前提スキル | architecture |
| 後続スキル | review |

## ワークフロー

```
1. 技術スタック・アーキテクチャを読み込み
2. コーディング規約を生成
3. 環境設定・デプロイ手順を生成
4. テスト設計を生成
5. 運用手順書を生成
```

## コーディング規約

### 命名規則

| 対象 | 規則 |
|------|------|
| コンポーネント | PascalCase |
| ユーティリティ | camelCase |
| 定数 | UPPER_SNAKE |
| テスト | *.test.ts |

### Git運用

| type | 用途 |
|------|------|
| feat | 新機能 |
| fix | バグ修正 |
| docs | ドキュメント |
| refactor | リファクタ |
| test | テスト |
| chore | その他 |

## 環境設定

| 環境 | ブランチ |
|------|---------|
| local | - |
| development | develop |
| staging | release/* |
| production | main |

## テスト設計

### テストピラミッド

| レベル | 割合 |
|--------|------|
| Unit | 70% |
| Integration | 20% |
| E2E | 10% |

### カバレッジ目標

| 対象 | 目標 |
|------|------|
| ステートメント | 80% |
| ブランチ | 70% |

## 運用手順書

1. 日常運用 - 日次/週次/月次タスク
2. デプロイ手順 - 通常/ホットフィックス/ロールバック
3. 障害対応 - 検知→初動→復旧→報告
4. メンテナンス - 計画メンテナンス手順

## コンテキスト更新

```yaml
phases:
  implementation:
    status: completed
    files:
      - docs/07_implementation/coding_standards.md
      - docs/07_implementation/environment.md
      - docs/07_implementation/testing.md
      - docs/07_implementation/operations.md
```

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| architecture.md 不在 | Phase 3 の実行を促す |
| 技術スタック未定義 | 一般的な規約を生成、WARNING を記録 |
