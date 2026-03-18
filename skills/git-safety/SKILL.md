---
name: git-safety
description: "Git workflow safety procedures: diagnose why git add fails (3-layer gitignore system), recover from pre-commit hook failures (NEVER amend after hook failure), validate git add -A risks, and manage auto-generated directories. Use when git add fails, pre-commit hook fails, user attempts broad git add, gitignore issues arise, or git commit workflow encounters errors."
version: 1.0.0
---

# Git Safety Guide

Git 操作時の安全手順ガイド。

> **高頻度エラー注意**: 「hook 失敗後の --amend 使用」と「git add -A の無差別使用」に特に注意。

## コミット前チェック（必須）

1. **`git status` で状態確認**
   - 必ず `-uall` フラグは使わない（大規模リポジトリでメモリ問題の原因）
   - untracked files と staged files を確認

2. **`.gitignore` 対象ファイルの確認**
   - `git add` 前に対象ファイルが無視されていないか確認
   - 無視設定は3箇所に存在する（優先度順）:
     1. `.gitignore`（リポジトリ内、コミット対象）
     2. `.git/info/exclude`（リポジトリ内、コミット対象外）
     3. `~/.config/git/ignore`（グローバル設定）
   - 確認コマンド: `git check-ignore -v <filepath>`
   - 出力例: `.gitignore:3:*.log    debug.log` → `.gitignore` の3行目のルールでマッチ

3. **無視されたファイルを追加する必要がある場合**
   - ユーザーに確認を取る
   - **`git add -f` は原則禁止**（秘密情報や生成物の誤コミット防止）
   - 正当な理由がある場合のみ `.gitignore` の修正を提案する
   - 生成物（`node_modules`、`dist`、`build`）は基本コミットしない

4. **`git add -A` / `git add .` のリスク**
   - 意図しないファイル（`.env`、`node_modules`、ビルド成果物等）を追加する恐れ
   - 可能な限り `git add <specific-files>` で明示的に追加
   - 使用する場合は `git status` で追加対象を事前確認

## エラー時の対応

| エラーメッセージ | 原因 | 対応 |
|----------------|------|------|
| `The following paths are ignored by one of your .gitignore files` | 無視設定で除外 | 下記の診断手順を実行 |
| `fatal: pathspec did not match any files` | ファイルが存在しない | パスを再確認 |
| `Changes not staged for commit` | add 忘れ | `git add` してから commit |

## 「なぜ add できないか」診断手順

```bash
# Step 1: どの設定で無視されているか確認
git check-ignore -v <filepath>
# 出力例: .gitignore:5:*.log    app.log

# Step 2: 出力を読んで対応
# - .gitignore:N:PATTERN → リポジトリの .gitignore N行目
# - .git/info/exclude:N:PATTERN → ローカル専用の除外設定
# - ~/.config/git/ignore:N:PATTERN → グローバル設定

# Step 3: 修正（ユーザー確認後）
# - パターンが広すぎる → .gitignore を修正
# - 例外的に追加が必要 → !pattern で除外解除を提案
# - git add -f は最終手段（秘密情報でないことを確認）
```

## pre-commit hook 失敗時の対応

| 状況 | 正しい対応 | 禁止事項 |
|------|-----------|---------|
| hook 失敗後 | 修正 → `git add` → **新規 commit** | `--amend` は絶対禁止 |
| lint エラー | 自動修正可能なら `--fix` | 手動修正後に再 add 忘れ |
| test 失敗 | テスト修正 or 実装修正 | `--no-verify` でスキップ |

**重要**: hook 失敗時、コミットは**実行されていない**。`--amend` すると**直前の別コミット**を破壊する。

**リカバリー手順**:
1. hook のエラー出力を確認
2. 指摘された問題を修正
3. `git status` で状態確認
4. `git add <修正したファイル>`
5. **新しいコミット**を作成（同じメッセージでも可）

## 自動生成ディレクトリの扱い

以下のパターンは**コミット対象外**（.gitignore に追加推奨）:

| ディレクトリ | 用途 | 対応 |
|------------|------|------|
| `.codex-collab/` | Codex 連携ログ | `.gitignore` に追加 |
| `docs/requirements/.work/` | 要件定義中間成果物 | すでに gitignore 対象 |
| `node_modules/`, `dist/`, `build/` | ビルド成果物 | `.gitignore` に追加 |

**確認コマンド**:
```bash
# 新規ディレクトリが gitignore されているか確認
git check-ignore -v <directory>
```
