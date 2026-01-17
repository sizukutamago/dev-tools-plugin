---
doc_type: non_functional_requirements
version: "{{VERSION}}"
status: "{{STATUS}}"
updated_at: "{{UPDATED_AT}}"
owners: ["{{OWNER}}"]
tags: [要件定義, 非機能要件]
coverage:
  nfr: []
---

# 非機能要件定義書

## ID採番ルール

| 項目 | ルール |
|------|--------|
| 形式 | NFR-[CAT]-XXX |
| カテゴリ | PERF/SEC/AVL/SCL/MNT/OPR/CMP/ACC |

## カテゴリ定義

| コード | カテゴリ | 説明 |
|--------|----------|------|
| PERF | パフォーマンス | 応答時間、スループット |
| SEC | セキュリティ | 認証、認可、データ保護 |
| AVL | 可用性 | 稼働率、冗長性 |
| SCL | スケーラビリティ | 拡張性 |
| MNT | 保守性 | コード品質 |
| OPR | 運用性 | 監視、ログ |
| CMP | 互換性 | ブラウザ、デバイス |
| ACC | アクセシビリティ | WCAG準拠 |

## 要件サマリー

| NFR ID | カテゴリ | 要件名 | 目標値 | 優先度 |
|--------|----------|--------|--------|--------|
| NFR-{{CAT}}-{{ID}} | {{CATEGORY}} | {{NAME}} | {{TARGET}} | {{PRIORITY}} |

## 要件詳細

### NFR-{{CAT}}-{{ID}}: {{要件名}}

| 項目 | 内容 |
|------|------|
| 要件ID | NFR-{{CAT}}-{{ID}} |
| 要件名 | {{NAME}} |
| 優先度 | {{PRIORITY}} |

#### 概要

{{OVERVIEW}}

#### 目標値

| 項目 | 目標値 | 測定条件 |
|------|--------|----------|
| {{METRIC}} | {{TARGET}} | {{CONDITION}} |

#### 測定方法

{{MEASUREMENT_METHOD}}

#### 例外条件

{{EXCEPTIONS}}

#### 関連ADR

{{ADR_IDS}}

## 変更履歴

| 日付 | Ver | 変更者 | 内容 |
|------|-----|--------|------|
| {{DATE}} | {{VERSION}} | {{AUTHOR}} | {{CHANGE}} |
