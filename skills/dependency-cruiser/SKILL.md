---
name: dependency-cruiser
description: Use when setting up architecture dependency validation for TypeScript/JavaScript projects. Provides Clean Architecture and DDD dependency direction rules.
version: 1.0.0
---

# dependency-cruiser アーキテクチャ検証

TypeScript/JavaScript プロジェクトの依存方向ルールを検証するためのガイドライン。

## 前提条件

- `dependency-cruiser` がインストール済み（`bun add -D dependency-cruiser` または `npm install -D dependency-cruiser`）
- TypeScript/JavaScript プロジェクト

## ワークフロー

1. **設定ファイル作成**: プロジェクトルートに `.dependency-cruiser.cjs` を作成
2. **ルール定義**: 下記の推奨設定をベースにカスタマイズ
3. **実行**: `bunx depcruise src` で検証（設定ファイルは自動検出）
4. **CI 連携**: package.json に `"lint:deps": "depcruise src"` 追加

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

## エラーハンドリング

| エラー | 原因 | 対応 |
|--------|------|------|
| `no-circular` 誤検出 | 型のみのインポート | `import type` に変更 |
| パスが見つからない | 設定のパスパターン不一致 | `from.path`/`to.path` を確認 |
| モジュール解決エラー | TypeScript パス設定 | `tsPreCompilationDeps: true` を確認 |

## 使用例

```bash
# 依存関係を検証（設定ファイル自動検出）
bunx depcruise src

# 設定ファイルを明示指定
bunx depcruise src --config .dependency-cruiser.cjs

# HTML レポート生成
bunx depcruise src --output-type html > dependency-report.html

# 違反のみ表示
bunx depcruise src --output-type err
```

