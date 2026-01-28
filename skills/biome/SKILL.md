---
name: biome
description: Use when setting up linting and formatting for TypeScript/JavaScript projects. Provides Biome configuration patterns, rule explanations, and best practices.
---

# Biome Linting & Formatting

TypeScript/JavaScript プロジェクトの Linting・Formatting 設定ガイドライン。

## Overview

Biome は高速な Linter/Formatter で、ESLint + Prettier の代替として使用できる。

**利点:**
- 高速（Rust製）
- 設定が簡単
- ESLint + Prettier の統合不要
- import 自動整理

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

## VSCode 連携

`.vscode/settings.json`:

```json
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "biomejs.biome",
  "editor.codeActionsOnSave": {
    "quickfix.biome": "explicit",
    "source.organizeImports.biome": "explicit"
  }
}
```

## lefthook 連携

`lefthook.yml`:

```yaml
pre-commit:
  commands:
    lint-fix:
      glob: "*.{js,ts,tsx,json}"
      run: bunx biome check --write {staged_files}
      stage_fixed: true
```

## トラブルシューティング

### "Cannot format" エラー

構文エラーがある場合、フォーマットに失敗する。まず構文エラーを修正。

### 特定ファイルを除外したい

```json
{
  "files": {
    "ignore": ["path/to/exclude/**"]
  }
}
```

### ルールを部分的に無効化

```typescript
// biome-ignore lint/suspicious/noExplicitAny: 外部ライブラリの型定義が不十分
const data: any = externalLib.getData();
```

## セットアップコマンド

新規プロジェクトでの設定:

```
/setup-biome
```

このコマンドで：
1. 既存設定の確認
2. ベース設定の適用
3. プロジェクト構成に応じた調整
4. VSCode設定の生成（オプション）
