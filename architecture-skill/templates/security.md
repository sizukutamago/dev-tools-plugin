---
doc_type: security
version: "{{VERSION}}"
status: "{{STATUS}}"
updated_at: "{{UPDATED_AT}}"
owners: ["{{OWNER}}"]
tags: [セキュリティ]
coverage:
  nfr: []
---

# セキュリティ設計書

## 概要

| 項目 | 内容 |
|------|------|
| セキュリティ方針 | {{SECURITY_POLICY}} |
| 準拠規格 | {{COMPLIANCE}} |

## 認証設計

| 項目 | 内容 |
|------|------|
| 認証方式 | {{AUTH_METHOD}} |
| トークン有効期限（アクセス） | {{ACCESS_TOKEN_EXPIRY}} |
| トークン有効期限（リフレッシュ） | {{REFRESH_TOKEN_EXPIRY}} |
| トークン保存場所 | {{TOKEN_STORAGE}} |

### パスワードポリシー

| 項目 | 要件 |
|------|------|
| 最小文字数 | {{MIN_LENGTH}} |
| 最大文字数 | {{MAX_LENGTH}} |
| 複雑性 | {{COMPLEXITY}} |
| ハッシュ化 | {{HASH_ALGORITHM}} |

## 認可設計

| 項目 | 内容 |
|------|------|
| 認可モデル | {{AUTHZ_MODEL}} |

### ロール定義

| ロール | 説明 | 権限 |
|--------|------|------|
| {{ROLE}} | {{DESC}} | {{PERMISSIONS}} |

### パーミッション

| パーミッション | 説明 | 対象ロール |
|---------------|------|-----------|
| {{PERMISSION}} | {{DESC}} | {{ROLES}} |

## 通信セキュリティ

| 項目 | 値 |
|------|-----|
| TLSバージョン | {{TLS_VERSION}} |
| HSTS | {{HSTS_CONFIG}} |

## データセキュリティ

| データ種別 | 暗号化方式 | 保持期間 |
|-----------|-----------|----------|
| {{DATA_TYPE}} | {{ENCRYPTION}} | {{RETENTION}} |

## 脆弱性対策

| 脅威 | 対策 | 実装箇所 |
|------|------|----------|
| {{THREAT}} | {{COUNTERMEASURE}} | {{LOCATION}} |

## 監査・ログ

| 項目 | 内容 |
|------|------|
| 監査ログ項目 | {{AUDIT_ITEMS}} |
| 保持期間 | {{RETENTION}} |

## インシデント対応

| 項目 | 内容 |
|------|------|
| 検知方法 | {{DETECTION}} |
| 対応フロー | {{RESPONSE_FLOW}} |
| 連絡先 | {{CONTACTS}} |

## 変更履歴

| 日付 | Ver | 変更者 | 内容 |
|------|-----|--------|------|
| {{DATE}} | {{VERSION}} | {{AUTHOR}} | {{CHANGE}} |
