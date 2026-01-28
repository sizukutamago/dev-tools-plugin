---
name: dependency-cruiser
description: Use when setting up architecture dependency validation for TypeScript/JavaScript projects. Provides Clean Architecture and DDD dependency direction rules.
---

# dependency-cruiser アーキテクチャ検証

TypeScript/JavaScript プロジェクトの依存方向ルールを検証するためのガイドライン。

## Overview

dependency-cruiser は、コードベースの依存関係を分析し、アーキテクチャルールへの違反を検出するツール。

**利点:**
- Clean Architecture/DDD の依存方向を自動検証
- 循環依存の検出
- 不正な依存パターンの早期発見
- CI/CD での継続的なアーキテクチャ検証

## 基本概念: 依存方向

Clean Architecture では、依存は **外側から内側** に向かう：

```
┌────────────────────────────────────────────────────────┐
│  Presentation (routes)                                  │
│    ↓ 依存OK                                            │
│  ┌────────────────────────────────────────────────┐    │
│  │  Application (usecases)                         │    │
│  │    ↓ 依存OK                                    │    │
│  │  ┌────────────────────────────────────────┐    │    │
│  │  │  Domain (services)                      │    │    │
│  │  │    ↓ 依存OK                            │    │    │
│  │  │  ┌────────────────────────────────┐    │    │    │
│  │  │  │  Infrastructure (repositories) │    │    │    │
│  │  │  └────────────────────────────────┘    │    │    │
│  │  └────────────────────────────────────────┘    │    │
│  └────────────────────────────────────────────────┘    │
└────────────────────────────────────────────────────────┘
```

**禁止される依存:**
- `repositories` → `services` (内側から外側への依存)
- `services` → `routes` (内側から外側への依存)
- 循環依存

## 推奨設定

### ベース設定（Clean Architecture）

```javascript
/** @type {import('dependency-cruiser').IConfiguration} */
module.exports = {
  extends: 'dependency-cruiser/configs/recommended',
  forbidden: [
    {
      name: 'no-infrastructure-to-services',
      comment: 'repositories/db は services に依存してはいけない',
      severity: 'error',
      from: { path: 'src/(repositories|db)' },
      to: { path: 'src/services' },
    },
    {
      name: 'no-services-to-routes',
      comment: 'services は routes に依存してはいけない',
      severity: 'error',
      from: { path: 'src/services' },
      to: { path: 'src/routes' },
    },
    {
      name: 'no-circular',
      severity: 'error',
      from: {},
      to: { circular: true },
    },
  ],
  options: {
    tsPreCompilationDeps: true,
    doNotFollow: { path: 'node_modules' },
  },
};
```

## ルール解説

### no-infrastructure-to-services

インフラ層（repositories, db）からドメイン層（services）への依存を禁止。

<Bad>
```typescript
// repositories/userRepository.ts
import { validateUser } from '../services/userService'; // ❌ 違反

export function findUser(id: string) {
  const user = db.query(...);
  return validateUser(user); // services のロジックを呼んでいる
}
```
</Bad>

<Good>
```typescript
// repositories/userRepository.ts
export function findUser(id: string) {
  return db.query(...); // ✅ データ取得のみ
}

// services/userService.ts
import { findUser } from '../repositories/userRepository';

export function getValidatedUser(id: string) {
  const user = findUser(id);
  return validateUser(user); // services 内でバリデーション
}
```
</Good>

### no-services-to-routes

ドメイン層（services）からプレゼンテーション層（routes）への依存を禁止。

<Bad>
```typescript
// services/chatService.ts
import { chatRouter } from '../routes/chat'; // ❌ 違反
```
</Bad>

<Good>
```typescript
// routes/chat.ts
import { chatService } from '../services/chatService'; // ✅ routes → services はOK
```
</Good>

### no-circular

循環依存を禁止。A → B → C → A のような依存は検出される。

## DDD拡張ルール（UseCase層あり）

DDD + Clean Architecture で UseCase 層を使う場合の追加ルール：

```javascript
// routes → usecases → services → repositories
{
  name: 'no-routes-to-services-directly',
  comment: 'routes は services に直接依存せず usecases を経由すること',
  severity: 'error',
  from: { path: 'src/routes' },
  to: { path: 'src/services' },
},
{
  name: 'no-usecases-to-repositories',
  comment: 'usecases は repositories に直接依存してはいけない',
  severity: 'error',
  from: { path: 'src/usecases' },
  to: { path: 'src/repositories' },
},
```

## フロントエンド用ルール

React/Vue 等のフロントエンドプロジェクト向け：

```javascript
{
  name: 'no-hooks-to-components',
  comment: 'hooks は components に依存してはいけない',
  severity: 'error',
  from: { path: 'src/hooks' },
  to: { path: 'src/components' },
},
{
  name: 'no-utils-to-components',
  comment: 'utils は components に依存してはいけない',
  severity: 'error',
  from: { path: 'src/(utils|lib)' },
  to: { path: 'src/components' },
},
```

## トラブルシューティング

### "no-circular" が誤検出される

型のみのインポートは `import type` を使うことで循環を回避できる場合がある：

```typescript
// ❌ 循環の原因になりうる
import { User } from './user';

// ✅ 型のみなら循環しない
import type { User } from './user';
```

### 特定のパスを除外したい

`pathNot` で除外パターンを指定：

```javascript
{
  name: 'no-services-to-routes',
  from: {
    path: 'src/services',
    pathNot: 'src/services/shared/' // shared は除外
  },
  to: { path: 'src/routes' },
},
```

### 重要度の調整

移行期間中は `severity: 'warn'` に緩和可能：

```javascript
{
  name: 'no-routes-to-services-directly',
  severity: 'warn', // error → warn に緩和
  // ...
}
```

## セットアップコマンド

新規プロジェクトでの設定:

```
/setup-depcruise
```

このコマンドで：
1. 既存設定の確認
2. プロジェクト構成の分析（routes, services, repositories 等の検出）
3. 適切なプリセット選択（base / ddd / frontend）
4. package.json にスクリプト追加
5. lefthook への統合（オプション）
