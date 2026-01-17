---
doc_type: api_design
version: "{{VERSION}}"
status: "{{STATUS}}"
updated_at: "{{UPDATED_AT}}"
owners: ["{{OWNER}}"]
tags: [API設計]
coverage:
  api: []
  fr: []
  entities: []
---

# API設計書

## 設計方針

| 項目 | 内容 |
|------|------|
| 設計原則 | {{DESIGN_PRINCIPLE}} |
| バージョニング | {{VERSIONING}} |
| ベースURL | {{BASE_URL}} |

## 命名規則

| 対象 | 規則 |
|------|------|
| エンドポイント | {{ENDPOINT_RULE}} |
| クエリパラメータ | {{QUERY_RULE}} |
| JSONフィールド | {{JSON_RULE}} |

## 認証・認可

| 項目 | 内容 |
|------|------|
| 認証方式 | {{AUTH_METHOD}} |
| 認可モデル | {{AUTHZ_MODEL}} |
| ヘッダー | {{AUTH_HEADER}} |

## API一覧

| API ID | メソッド | エンドポイント | 概要 | 認証 |
|--------|----------|---------------|------|------|
| API-{{ID}} | {{METHOD}} | {{ENDPOINT}} | {{OVERVIEW}} | {{AUTH}} |

## API詳細

### API-{{ID}}: {{METHOD}} {{ENDPOINT}}

| 項目 | 内容 |
|------|------|
| API ID | API-{{ID}} |
| 概要 | {{OVERVIEW}} |
| 認証 | {{AUTH}} |
| 関連FR | {{FR_IDS}} |

#### パスパラメータ

| パラメータ | 型 | 必須 | 説明 |
|-----------|-----|------|------|
| {{PARAM}} | {{TYPE}} | {{REQUIRED}} | {{DESC}} |

#### クエリパラメータ

| パラメータ | 型 | 必須 | デフォルト | 説明 |
|-----------|-----|------|-----------|------|
| {{PARAM}} | {{TYPE}} | {{REQUIRED}} | {{DEFAULT}} | {{DESC}} |

#### リクエストボディ

```json
{{REQUEST_BODY}}
```

#### 成功レスポンス（{{STATUS_CODE}}）

```json
{{SUCCESS_RESPONSE}}
```

#### エラーレスポンス

| ステータス | コード | 説明 |
|-----------|--------|------|
| {{STATUS}} | {{ERROR_CODE}} | {{DESC}} |

## 共通仕様

| 項目 | 仕様 |
|------|------|
| 日時形式 | {{DATETIME_FORMAT}} |
| ページネーション | {{PAGINATION}} |
| レート制限 | {{RATE_LIMIT}} |

## エラーコード

| コード | ステータス | 説明 |
|--------|-----------|------|
| {{ERROR_CODE}} | {{STATUS}} | {{DESC}} |

## 変更履歴

| 日付 | Ver | 変更者 | 内容 |
|------|-----|--------|------|
| {{DATE}} | {{VERSION}} | {{AUTHOR}} | {{CHANGE}} |
