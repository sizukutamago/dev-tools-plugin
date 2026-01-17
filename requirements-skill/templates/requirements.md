---
doc_type: requirements
version: "{{VERSION}}"
status: "{{STATUS}}"
updated_at: "{{UPDATED_AT}}"
owners: ["{{OWNER}}"]
tags: [要件定義]
---

# 要件定義書

## システム概要

### 背景と目的

{{BACKGROUND_PURPOSE}}

### システムの位置づけ

{{SYSTEM_POSITIONING}}

### 対象範囲

| 区分 | 内容 |
|------|------|
| スコープ内 | {{SCOPE_IN}} |
| スコープ外 | {{SCOPE_OUT}} |

## 要件サマリー

### 機能要件

詳細: [functional_requirements.md](./functional_requirements.md)

| カテゴリ | 件数 | 必須 | 推奨 | 任意 |
|----------|------|------|------|------|
| {{CATEGORY}} | {{COUNT}} | {{MUST}} | {{SHOULD}} | {{COULD}} |

### 非機能要件

詳細: [non_functional_requirements.md](./non_functional_requirements.md)

| カテゴリ | 件数 | 主要目標値 |
|----------|------|-----------|
| {{CATEGORY}} | {{COUNT}} | {{TARGET}} |

## 制約条件

| 種別 | 内容 | 理由 |
|------|------|------|
| {{CONSTRAINT_TYPE}} | {{CONSTRAINT}} | {{REASON}} |

## 前提条件

{{ASSUMPTIONS}}

## 関連ドキュメント

| ドキュメント | リンク |
|-------------|--------|
| {{DOC_NAME}} | {{DOC_LINK}} |

## 変更履歴

| 日付 | Ver | 変更者 | 内容 |
|------|-----|--------|------|
| {{DATE}} | {{VERSION}} | {{AUTHOR}} | {{CHANGE}} |
