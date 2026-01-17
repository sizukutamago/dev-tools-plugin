---
doc_type: functional_requirements
version: "{{VERSION}}"
status: "{{STATUS}}"
updated_at: "{{UPDATED_AT}}"
owners: ["{{OWNER}}"]
tags: [要件定義, 機能要件]
coverage:
  fr: []
---

# 機能要件一覧

## ID採番ルール

| 項目 | ルール |
|------|--------|
| 形式 | FR-XXX（3桁ゼロパディング） |
| 開始 | 001 |
| 欠番 | 再利用しない |

## 優先度・ステータス定義

| 優先度 | 説明 |
|--------|------|
| Must | リリース必須 |
| Should | 可能な限り実装 |
| Could | 余裕があれば |
| Won't | 今回スコープ外 |

| ステータス | 説明 |
|-----------|------|
| Draft | 検討中 |
| Approved | 承認済 |
| Implemented | 実装完了 |
| Deferred | 延期 |
| Cancelled | 取消 |

## 機能一覧

| FR ID | 機能名 | カテゴリ | 優先度 | ステータス | 関連SC | 関連API |
|-------|--------|----------|--------|-----------|--------|---------|
| FR-{{ID}} | {{NAME}} | {{CATEGORY}} | {{PRIORITY}} | {{STATUS}} | {{SC_IDS}} | {{API_IDS}} |

## 機能詳細

### FR-{{ID}}: {{機能名}}

| 項目 | 内容 |
|------|------|
| 機能ID | FR-{{ID}} |
| 機能名 | {{NAME}} |
| カテゴリ | {{CATEGORY}} |
| 優先度 | {{PRIORITY}} |
| ステータス | {{STATUS}} |

#### 概要

{{OVERVIEW}}

#### ユーザーストーリー

> {{USER_TYPE}}として、{{PURPOSE}}のために、{{ACTION}}したい。

#### 詳細仕様

{{SPECIFICATIONS}}

#### 受入基準

- [ ] {{CRITERIA}}

#### ビジネスルール

{{BUSINESS_RULES}}

#### 関連情報

| 項目 | 値 |
|------|-----|
| 関連画面 | {{SC_IDS}} |
| 関連API | {{API_IDS}} |
| 関連エンティティ | {{ENT_IDS}} |
| 依存機能 | {{FR_IDS}} |

#### 備考

{{NOTES}}

## トレーサビリティ

| FR ID | SC | API | ENT | TC |
|-------|-----|-----|-----|-----|
| FR-{{ID}} | {{SC_IDS}} | {{API_IDS}} | {{ENT_IDS}} | {{TC_IDS}} |

## 変更履歴

| 日付 | Ver | 変更者 | 内容 |
|------|-----|--------|------|
| {{DATE}} | {{VERSION}} | {{AUTHOR}} | {{CHANGE}} |
