---
name: biome
description: Use when setting up linting and formatting for TypeScript/JavaScript projects. Provides Biome configuration patterns, rule explanations, and best practices.
version: 1.0.0
---

# Biome Linting & Formatting

TypeScript/JavaScript プロジェクトの Linting・Formatting 設定ガイドライン。

## 前提条件

- `biome` CLI がインストール済み（`bun add -D @biomejs/biome` または `npm install -D @biomejs/biome`）
- TypeScript/JavaScript プロジェクト

## ワークフロー

1. **設定ファイル作成**: プロジェクトルートに `biome.json` を作成
2. **ルール適用**: 下記の推奨設定をベースにカスタマイズ
3. **実行**: `bunx biome check --write .` でフォーマット＋リント修正
4. **CI 連携**: `bunx biome check .` で検証（--write なし）

## 推奨設定

### ベース設定

```json
{
  "$schema": "https://biomejs.dev/schemas/1.9.4/schema.json",
  "organizeImports": { "enabled": true },
  "linter": {
    "enabled": true,
    "rules": {
      "recommended": true,
      "complexity": { "noExcessiveCognitiveComplexity": "warn" },
      "correctness": { "noUnusedVariables": "warn", "noUnusedImports": "warn" },
      "style": { "useConst": "error", "noNonNullAssertion": "warn" },
      "suspicious": { "noExplicitAny": "warn" }
    }
  },
  "formatter": {
    "enabled": true,
    "indentStyle": "tab",
    "indentWidth": 2,
    "lineWidth": 100
  },
  "javascript": {
    "formatter": {
      "quoteStyle": "single",
      "semicolons": "always",
      "trailingCommas": "all"
    }
  },
  "files": {
    "ignore": ["node_modules", "dist", "*.lockb", ".git"]
  }
}
```

## ルール解説

### complexity/noExcessiveCognitiveComplexity

関数の認知的複雑度を制限。深いネストや条件分岐が多い関数を検出。

<Bad>
```typescript
function processData(data: Data) {
  if (data.type === 'A') {
    if (data.subtype === '1') {
      if (data.value > 10) {
        if (data.active) {
          // 深いネスト = 高い認知的複雑度
        }
      }
    }
  }
}
```
</Bad>

<Good>
```typescript
function processData(data: Data) {
  if (!isValidData(data)) return;

  const handler = getHandler(data.type, data.subtype);
  return handler(data);
}

function isValidData(data: Data): boolean {
  return data.value > 10 && data.active;
}
```
早期リターンと関数分割で複雑度を下げる
</Good>

### correctness/noUnusedVariables & noUnusedImports

使用されていない変数・インポートを検出。

```typescript
// ❌ 未使用インポート
import { unused } from './module';

// ❌ 未使用変数
const unusedVar = 'value';

// ✅ 意図的に使用しない場合はアンダースコアプレフィックス
const [_first, second] = array;
```

### style/useConst

再代入されない変数には `const` を強制。

```typescript
// ❌ let だが再代入なし
let value = 1;

// ✅ const を使用
const value = 1;
```

### style/noNonNullAssertion

`!` による非null アサーションを警告。型安全性を損なう可能性。

```typescript
// ⚠️ 実行時エラーの可能性
const name = user!.name;

// ✅ 適切なnullチェック
const name = user?.name ?? 'Unknown';

// ✅ または型ガード
if (user) {
  const name = user.name;
}
```

### suspicious/noExplicitAny

`any` 型の使用を警告。型安全性を優先。

```typescript
// ⚠️ any は型チェックを無効化
function process(data: any) { ... }

// ✅ unknown + 型ガード
function process(data: unknown) {
  if (isValidData(data)) {
    // data は型安全
  }
}

// ✅ ジェネリクス
function process<T>(data: T) { ... }
```

## モノレポ設定

複数パッケージがある場合の設定：

```json
{
  "files": {
    "ignore": [
      "node_modules",
      "dist",
      "**/drizzle/**",
      "**/public/assets/**"
    ]
  }
}
```

## エラーハンドリング

| エラー | 原因 | 対応 |
|--------|------|------|
| `Cannot format` | 構文エラーがある | 構文エラーを先に修正 |
| `Configuration file not found` | biome.json がない | `bunx biome init` で作成 |
| `Unknown rule` | 古いバージョン | biome をアップグレード |

## 使用例

```bash
# 全ファイルをチェック＆修正
bunx biome check --write .

# 特定ディレクトリのみ
bunx biome check --write src/

# CI用（修正なし、エラー検出のみ）
bunx biome check .
```

