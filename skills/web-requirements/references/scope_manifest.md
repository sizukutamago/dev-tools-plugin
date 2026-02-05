# Scope Manifest Specification

スコープ分割仕様・ScopeManifest 形式。

## 概要

ScopeManifest は、大規模リポジトリを分析する際に、Explorer Swarm がどの範囲を担当するかを定義するメタデータ。

## いつスコープ分割が必要か

### 閾値

| 基準 | 閾値 | アクション |
|------|------|-----------|
| ファイル数 | > 150 | shard 分割必須 |
| LOC | > 20,000 | shard 分割必須 |
| 自然境界 | bounded context あり | 境界で分割推奨 |
| 依存密度 | 強結合クラスタ | 同一 shard に |

### 分割しない場合

- ファイル数 ≤ 150 かつ LOC ≤ 20,000
- 自然な境界がない単一アプリケーション

## ScopeManifest スキーマ

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "required": ["mode", "total_files", "total_loc"],
  "properties": {
    "mode": {
      "type": "string",
      "enum": ["greenfield", "brownfield"]
    },
    "total_files": {
      "type": "integer",
      "minimum": 0
    },
    "total_loc": {
      "type": "integer",
      "minimum": 0
    },
    "shards": {
      "type": "array",
      "items": {
        "$ref": "#/$defs/shard"
      }
    },
    "cross_cutting": {
      "type": "object",
      "properties": {
        "glossary": {"type": "string"},
        "contracts": {"type": "string"}
      }
    }
  },
  "$defs": {
    "shard": {
      "type": "object",
      "required": ["id", "paths", "files", "loc"],
      "properties": {
        "id": {
          "type": "string",
          "pattern": "^[a-z][a-z0-9-]*$"
        },
        "paths": {
          "type": "array",
          "items": {"type": "string"}
        },
        "files": {"type": "integer"},
        "loc": {"type": "integer"},
        "description": {"type": "string"},
        "owner": {"type": "string"}
      }
    }
  }
}
```

## 例

### 分割なし（小規模）

```json
{
  "mode": "brownfield",
  "total_files": 80,
  "total_loc": 12000,
  "shards": []
}
```

### モノリス分割

```json
{
  "mode": "brownfield",
  "total_files": 350,
  "total_loc": 55000,
  "shards": [
    {
      "id": "frontend",
      "paths": ["src/frontend/**", "src/components/**"],
      "files": 150,
      "loc": 22000,
      "description": "React フロントエンド",
      "owner": "explorer:*#frontend"
    },
    {
      "id": "backend",
      "paths": ["src/api/**", "src/services/**", "src/domain/**"],
      "files": 120,
      "loc": 20000,
      "description": "Express バックエンド",
      "owner": "explorer:*#backend"
    },
    {
      "id": "shared",
      "paths": ["src/shared/**", "src/types/**"],
      "files": 80,
      "loc": 13000,
      "description": "共有コード・型定義",
      "owner": "explorer:*#shared"
    }
  ],
  "cross_cutting": {
    "glossary": ".work/glossary.md",
    "contracts": ".work/contracts.md"
  }
}
```

### マイクロサービス分割

```json
{
  "mode": "brownfield",
  "total_files": 500,
  "total_loc": 80000,
  "shards": [
    {
      "id": "auth-service",
      "paths": ["services/auth/**"],
      "files": 80,
      "loc": 12000,
      "description": "認証サービス"
    },
    {
      "id": "order-service",
      "paths": ["services/order/**"],
      "files": 100,
      "loc": 18000,
      "description": "注文サービス"
    },
    {
      "id": "payment-service",
      "paths": ["services/payment/**"],
      "files": 70,
      "loc": 10000,
      "description": "決済サービス"
    },
    {
      "id": "notification-service",
      "paths": ["services/notification/**"],
      "files": 50,
      "loc": 8000,
      "description": "通知サービス"
    },
    {
      "id": "gateway",
      "paths": ["gateway/**"],
      "files": 60,
      "loc": 9000,
      "description": "API ゲートウェイ"
    },
    {
      "id": "common",
      "paths": ["packages/common/**", "packages/types/**"],
      "files": 140,
      "loc": 23000,
      "description": "共通ライブラリ"
    }
  ]
}
```

## 分割戦略

### 1. 自然境界による分割

プロジェクト構造から自然な境界を見つける:

| 境界タイプ | 検出方法 | 例 |
|-----------|---------|-----|
| ディレクトリ | トップレベルディレクトリ | `frontend/`, `backend/` |
| パッケージ | monorepo のパッケージ | `packages/*/` |
| サービス | マイクロサービス | `services/*/` |
| モジュール | 機能モジュール | `src/modules/*/` |
| レイヤー | アーキテクチャレイヤー | `domain/`, `application/`, `infrastructure/` |

### 2. 依存密度による調整

強結合なコードは同一 shard に:

```
# 依存関係が強い場合
A ←→ B  → 同一 shard

# 依存関係が弱い場合
A → B  → 別 shard でも可
```

### 3. チーム境界との整合

可能であればチーム境界と一致させる:

```json
{
  "id": "checkout",
  "paths": ["src/checkout/**"],
  "files": 80,
  "loc": 12000,
  "description": "チェックアウト機能",
  "owner": "checkout-team"
}
```

## Explorer への shard 割り当て

各 Explorer エージェントは、shard ごとに起動される:

```
ScopeManifest.shards = [frontend, backend, shared]
↓
Explorer Swarm (frontend):
  - explorer:tech#frontend
  - explorer:domain#frontend
  - explorer:ui#frontend
  - explorer:integration#frontend
  - explorer:nfr#frontend

Explorer Swarm (backend):
  - explorer:tech#backend
  - explorer:domain#backend
  - explorer:ui#backend
  - explorer:integration#backend
  - explorer:nfr#backend

Explorer Swarm (shared):
  - explorer:tech#shared
  - explorer:domain#shared
  - explorer:ui#shared
  - explorer:integration#shared
  - explorer:nfr#shared
```

## Cross-cutting Concerns

複数の shard にまたがる情報:

### glossary（用語集）

```markdown
# Glossary

| Term | Definition | Used In |
|------|-----------|---------|
| User | サービスの利用者 | frontend, backend |
| Order | 注文 | backend, payment |
```

### contracts（API 契約）

```markdown
# API Contracts

## frontend ↔ backend

### GET /api/users/:id
- Request: -
- Response: User object
- Auth: JWT required

## backend ↔ payment

### POST /api/payments
- Request: PaymentRequest
- Response: PaymentResult
```

## スコープ推定スクリプト

`scripts/estimate_scope.sh` で自動推定:

```bash
#!/bin/bash
# ファイル数と LOC を計算
FILES=$(find . -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \) | grep -v node_modules | wc -l)
LOC=$(find . -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \) | grep -v node_modules | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}')

echo "{\"total_files\": $FILES, \"total_loc\": $LOC}"
```

## バリデーションルール

### shard.id

- 小文字英字で始まる
- 小文字英数字とハイフンのみ
- 例: `frontend`, `auth-service`, `api-v2`

### shard.paths

- glob パターンを使用
- プロジェクトルートからの相対パス
- `**` で再帰的にマッチ
- 例: `src/frontend/**`, `packages/*/src/**`

### 重複チェック

- 同じファイルが複数の shard に含まれないこと
- 重複がある場合はより具体的なパスを優先
