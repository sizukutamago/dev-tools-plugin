---
doc_type: screen_transition
version: "{{VERSION}}"
status: "{{STATUS}}"
updated_at: "{{UPDATED_AT}}"
owners: ["{{OWNER}}"]
tags: [画面設計, 画面遷移]
coverage:
  screens: []
---

# 画面遷移図

## 全体遷移図

```mermaid
graph TB
    subgraph {{CATEGORY}}
        {{SC_ID}}[{{SCREEN_NAME}}]
    end
    
    {{SC_FROM}} --> {{SC_TO}}
```

## フロー別遷移図

### {{フロー名}}

```mermaid
graph LR
    {{SC_FROM}}[{{NAME_FROM}}] --> {{SC_TO}}[{{NAME_TO}}]
```

## 遷移マトリクス

| 遷移元 \ 遷移先 | {{SC_ID}} | {{SC_ID}} |
|----------------|-----------|-----------|
| {{SC_ID}} | - | {{TRANSITION}} |

## 遷移条件

| # | 遷移元 | 遷移先 | トリガー | 条件 | 備考 |
|---|--------|--------|----------|------|------|
| {{NO}} | {{SC_FROM}} | {{SC_TO}} | {{TRIGGER}} | {{CONDITION}} | {{NOTES}} |

## 特殊遷移

### エラー時

| エラー種別 | 遷移先 | 条件 |
|-----------|--------|------|
| {{ERROR_TYPE}} | {{SC_ID}} | {{CONDITION}} |

### リダイレクト

| 条件 | 遷移元 | 遷移先 |
|------|--------|--------|
| {{CONDITION}} | {{SC_FROM}} | {{SC_TO}} |

## 変更履歴

| 日付 | Ver | 変更者 | 内容 |
|------|-----|--------|------|
| {{DATE}} | {{VERSION}} | {{AUTHOR}} | {{CHANGE}} |
