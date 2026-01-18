---
name: requirements
description: This skill should be used when the user asks to "define requirements", "create functional requirements", "document non-functional requirements", "write requirement specifications", "establish acceptance criteria", or "create feature list". Defines functional requirements (FR) and non-functional requirements (NFR) for software projects.
version: 1.0.0
---

# Requirements Skill

機能要件（FR）・非機能要件（NFR）を定義するスキル。
要件仕様の作成、機能一覧の文書化、パフォーマンス・セキュリティ制約の定義、
受入基準の策定に使用する。

**重要**: このスキル完了後、ユーザーレビュー・承認が必須。

## 前提条件

| 条件 | 必須 | 説明 |
|------|------|------|
| docs/01_hearing/hearing_result.md | ○ | ヒアリング結果 |
| docs/01_hearing/glossary.md | △ | 用語統一に使用 |

## 出力ファイル

| ファイル | テンプレート | 説明 |
|---------|-------------|------|
| docs/02_requirements/requirements.md | {baseDir}/references/requirements.md | 要件定義概要 |
| docs/02_requirements/functional_requirements.md | {baseDir}/references/functional_requirements.md | 機能要件一覧 |
| docs/02_requirements/non_functional_requirements.md | {baseDir}/references/non_functional_requirements.md | 非機能要件一覧 |

## 依存関係

| 種別 | 対象 |
|------|------|
| 前提スキル | hearing |
| 後続スキル | architecture, database |

## ID採番ルール

### 機能要件（FR）

| 項目 | ルール |
|------|--------|
| 形式 | FR-XXX（3桁ゼロパディング） |
| 開始 | 001 |

### 非機能要件（NFR）

| 項目 | ルール |
|------|--------|
| 形式 | NFR-[CAT]-XXX |
| カテゴリ | PERF/SEC/AVL/SCL/MNT/OPR/CMP/ACC |

#### カテゴリ定義

| コード | カテゴリ |
|--------|----------|
| PERF | パフォーマンス |
| SEC | セキュリティ |
| AVL | 可用性 |
| SCL | スケーラビリティ |
| MNT | 保守性 |
| OPR | 運用性 |
| CMP | 互換性 |
| ACC | アクセシビリティ |

## ワークフロー

```
1. ヒアリング結果を読み込み
2. 機能を抽出・整理
3. 各機能にFR-IDを採番
4. 優先度を設定（Must/Should/Could/Won't）
5. 詳細仕様・受入基準を定義
6. 非機能要件を抽出
7. 各NFRにIDを採番
8. 目標値・測定方法を定義
```

## 優先度定義

| 優先度 | 説明 |
|--------|------|
| Must | リリース必須（60-70%） |
| Should | 可能な限り実装（20-30%） |
| Could | 余裕があれば（10%） |
| Won't | 今回スコープ外 |

## ユーザーストーリー形式

```
{{USER_TYPE}}として、{{PURPOSE}}のために、{{ACTION}}したい。
```

## コンテキスト更新

```yaml
phases:
  requirements:
    status: review  # 承認後に completed
    files:
      - docs/02_requirements/requirements.md
      - docs/02_requirements/functional_requirements.md
      - docs/02_requirements/non_functional_requirements.md
id_registry:
  fr: [FR-001, FR-002, ...]
  nfr: [NFR-PERF-001, NFR-SEC-001, ...]
```

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| hearing_result.md 不在 | Phase 1 の実行を促す |
| ID採番衝突 | project-context.yaml の id_registry を確認 |
| 承認タイムアウト | 状態を review で保存、次回再開可能 |
