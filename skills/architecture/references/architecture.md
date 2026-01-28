---
doc_type: architecture
version: "{{VERSION}}"
status: "{{STATUS}}"
updated_at: "{{UPDATED_AT}}"
owners: ["{{OWNER}}"]
tags: [アーキテクチャ]
coverage:
  fr: []
  nfr: []
  adr: []
---

# システムアーキテクチャ設計書

## 設計方針

| 項目 | 内容 |
|------|------|
| 基本方針 | {{BASIC_POLICY}} |
| パターン | {{ARCH_PATTERN}} |
| 設計原則 | {{DESIGN_PRINCIPLE}} |

## システム構成

### 構成図

```mermaid
graph TB
    subgraph {{LAYER}}
        {{COMPONENT}}[{{COMPONENT_NAME}}]
    end
    
    {{COMPONENT_FROM}} --> {{COMPONENT_TO}}
```

### コンポーネント一覧

| コンポーネント | 種別 | 説明 |
|---------------|------|------|
| {{COMPONENT}} | {{TYPE}} | {{DESC}} |

### コンポーネント詳細

#### {{コンポーネント名}}

| 項目 | 内容 |
|------|------|
| 役割 | {{ROLE}} |
| 技術 | {{TECHNOLOGY}} |
| 責務 | {{RESPONSIBILITY}} |

## 技術スタック

### フロントエンド

| 技術 | バージョン | 選定理由 |
|------|-----------|----------|
| {{TECH}} | {{VERSION}} | {{REASON}} |

### バックエンド

| 技術 | バージョン | 選定理由 |
|------|-----------|----------|
| {{TECH}} | {{VERSION}} | {{REASON}} |

### インフラ

| 技術 | 用途 | 選定理由 |
|------|------|----------|
| {{TECH}} | {{PURPOSE}} | {{REASON}} |

## エラーハンドリング設計

### HTTPエラーレスポンス戦略

| エラー種別 | HTTPステータス | レスポンス戦略 | UI表示パターン |
|-----------|---------------|---------------|---------------|
| 入力エラー | 400 Bad Request | フィールド別エラー詳細返却 | インラインバリデーション |
| 認証エラー | 401 Unauthorized | リフレッシュトークンフロー | 再認証誘導 |
| 権限エラー | 403 Forbidden | 権限不足の詳細メッセージ | エラーページ/モーダル |
| リソース不在 | 404 Not Found | リソース種別の明示 | 代替候補の提示 |
| 業務ルール違反 | 422 Unprocessable Entity | ルール違反詳細 | ガイダンス表示 |
| サーバーエラー | 5xx | エラーID + 簡潔メッセージ | リトライ誘導 |

### リトライ戦略

| 対象 | 戦略 | 設定 |
|------|------|------|
| 冪等操作（GET, PUT, DELETE） | 自動リトライ | 最大3回、Exponential Backoff |
| 非冪等操作（POST） | 手動リトライ | ユーザー確認後のみ |
| ネットワークエラー | 自動リトライ | 最大3回、指数バックオフ |
| タイムアウト | 条件付きリトライ | 冪等性に応じて判断 |

### エラーロギング・監視

| 項目 | 内容 |
|------|------|
| エラーID形式 | {{ERROR_ID_FORMAT}} |
| ログレベル | 4xx: WARN, 5xx: ERROR |
| アラート条件 | {{ALERT_CONDITION}} |

## 関連ドキュメント

| ドキュメント | リンク |
|-------------|--------|
| ADR | [adr.md](./adr.md) |
| セキュリティ設計書 | [security.md](./security.md) |
| インフラ設計書 | [infrastructure.md](./infrastructure.md) |
| キャッシュ戦略 | [cache_strategy.md](./cache_strategy.md) |

## 変更履歴

| 日付 | Ver | 変更者 | 内容 |
|------|-----|--------|------|
| {{DATE}} | {{VERSION}} | {{AUTHOR}} | {{CHANGE}} |
