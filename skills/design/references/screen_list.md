---
doc_type: screen_list
version: "{{VERSION}}"
status: "{{STATUS}}"
updated_at: "{{UPDATED_AT}}"
owners: ["{{OWNER}}"]
tags: [画面設計]
coverage:
  screens: []
  fr: []
---

# 画面一覧

## 設計スコープ

### Goals

- {{GOAL_1}}
- {{GOAL_2}}
- {{GOAL_3}}

### Non-Goals

- {{NON_GOAL_1}}
- {{NON_GOAL_2}}

## ID採番ルール

| 項目 | ルール |
|------|--------|
| 形式 | SC-XXX（3桁） |
| 開始 | 001 |
| 欠番 | 再利用しない |

## 画面一覧

| SC ID | 画面名 | 画面名(EN) | カテゴリ | 目的 | 関連FR | 認証 |
|-------|--------|-----------|----------|------|--------|------|
| SC-{{ID}} | {{NAME_JP}} | {{NAME_EN}} | {{CATEGORY}} | {{PURPOSE}} | {{FR_IDS}} | {{AUTH}} |

## カテゴリ別一覧

### {{カテゴリ名}}

| SC ID | 画面名 | 概要 |
|-------|--------|------|
| SC-{{ID}} | {{NAME}} | {{OVERVIEW}} |

## 共通要素

### ヘッダー

{{HEADER_SPEC}}

### フッター

{{FOOTER_SPEC}}

### 共通コンポーネント

| コンポーネント | 使用画面 | 説明 |
|---------------|----------|------|
| {{COMPONENT}} | {{SCREENS}} | {{DESC}} |

## デザインリンク

| 種別 | リンク |
|------|--------|
| {{TYPE}} | {{LINK}} |

## 変更履歴

| 日付 | Ver | 変更者 | 内容 |
|------|-----|--------|------|
| {{DATE}} | {{VERSION}} | {{AUTHOR}} | {{CHANGE}} |
