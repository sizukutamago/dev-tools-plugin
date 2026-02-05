---
name: verified-commit
description: Commit with verification steps (lint, type-check, tests) before creating commits. Supports quick and full verification modes.
version: 1.0.0
---

# verified-commit

検証付きコミットワークフロー。コミット前に適切な検証を行い、品質を担保する。

## コンセプト

**2段階の検証モード**:
- **quick**: 軽量検証（lint + 型チェック）- デフォルト
- **full**: 完全検証（lint + 型チェック + テスト）- 重要な変更時

## ワークフロー

### Step 1: 変更ファイルの確認

```bash
# 変更状態の確認（-uallは使わない）
git status

# 変更差分の確認
git diff
git diff --staged
```

### Step 2: ファイル種別の判定

| ファイル種別 | 検証内容 |
|-------------|---------|
| `*.ts`, `*.tsx` | TypeScript型チェック + ESLint |
| `*.js`, `*.jsx` | ESLint |
| `*.sh` | shellcheck + bash -n |
| `*.py` | ruff / flake8 |
| `*.md` | markdownlint（あれば） |

### Step 3: 検証実行

#### quick モード（デフォルト）

```bash
# TypeScript プロジェクト
npx tsc --noEmit 2>&1 | head -20

# Lint
npx eslint --cache . 2>&1 | head -20

# または Biome
npx biome check . 2>&1 | head -20
```

#### full モード

```bash
# quick の内容に加えて...

# テスト実行（変更ファイルに関連するテストのみ）
npm test -- --changedSince=HEAD~1

# または全テスト
npm test
```

### Step 4: コミットメッセージ作成

#### 基本フォーマット

```
<type>: <summary>

[optional body]
```

**type の種類**:
| type | 用途 |
|------|------|
| `feat` | 新機能 |
| `fix` | バグ修正 |
| `refactor` | リファクタリング |
| `docs` | ドキュメント |
| `test` | テスト追加/修正 |
| `chore` | 雑務（依存関係更新等） |

#### 大量ファイル（10+）の場合

カテゴリ別にグループ化:

```
feat: ユーザー認証機能を追加

## Components
- src/components/LoginForm.tsx
- src/components/AuthProvider.tsx

## API
- src/api/auth.ts
- src/api/session.ts

## Tests
- tests/auth.test.ts
```

### Step 5: コミット実行

```bash
# ステージング（具体的なファイルを指定）
git add src/components/LoginForm.tsx src/api/auth.ts

# コミット
git commit -m "$(cat <<'EOF'
feat: ユーザー認証機能を追加

- LoginFormコンポーネント追加
- 認証APIクライアント実装
EOF
)"
```

## 検証フローチャート

```
変更ファイル確認
      │
      ▼
 ファイル種別判定
      │
      ├─ TypeScript → tsc --noEmit + eslint
      ├─ JavaScript → eslint
      ├─ Shell → shellcheck + bash -n
      └─ Python → ruff/flake8
      │
      ▼
 検証モード選択
      │
      ├─ quick（デフォルト）
      │     └─ lint + 型チェックのみ
      │
      └─ full（--full オプション）
            └─ lint + 型チェック + テスト
      │
      ▼
 検証結果
      │
      ├─ PASS → コミット作成
      │
      └─ FAIL → 修正してから再検証
```

## 使用例

### 基本的な使用

```
User: "この変更をコミットして"

Claude:
1. git status で変更確認
2. TypeScriptなので tsc --noEmit 実行（quick）
3. エラーなし → コミットメッセージ作成
4. git add + git commit 実行
```

### full検証が必要な場合

```
User: "この変更をコミットして（テストも実行）"

Claude:
1. git status で変更確認
2. tsc --noEmit + eslint 実行
3. npm test 実行（full）
4. 全てパス → コミット作成
```

### 検証失敗時

```
User: "コミットして"

Claude:
1. git status で変更確認
2. tsc --noEmit 実行 → エラー検出
3. "型エラーがあります。修正しますか？" と報告
4. ユーザー確認後に修正 → 再検証 → コミット
```

## 検証スキップの条件

以下の場合は検証をスキップ可能（ユーザー確認必須）:

- ドキュメントのみの変更（`*.md`, `*.txt`）
- 設定ファイルの軽微な変更
- ユーザーが明示的にスキップを要求

```
User: "検証なしでコミットして"

Claude:
"検証をスキップしてコミットします。よろしいですか？"
→ 確認後にコミット
```

## エラー時の対応

| エラー | 原因 | 対応 |
|--------|------|------|
| 型エラー | TypeScript型不整合 | 型定義を修正 |
| Lintエラー | コードスタイル違反 | `npx eslint --fix` で自動修正 |
| テスト失敗 | 機能の破壊 | テストまたは実装を修正 |
| shellcheck警告 | シェルスクリプト問題 | 警告に従って修正 |

## 関連スキル

| スキル | 用途 | 連携 |
|--------|------|------|
| `/verified-commit` | 検証付きコミット | メイン |
| `/shell-debug` | シェルスクリプト検証失敗時 | shellcheck警告の詳細調査 |
| `/tdd-integration` | テスト駆動開発 | full検証モードと連携 |

## カスタマイズ

プロジェクトごとに検証コマンドをカスタマイズする場合は、プロジェクトの `CLAUDE.md` に記載:

```markdown
## Commit検証設定

### quick検証
- `npm run lint`
- `npm run typecheck`

### full検証
- `npm run lint`
- `npm run typecheck`
- `npm run test:unit`
```
