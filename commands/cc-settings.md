---
description: "Claude Code settings catalog — discover all available settings and env vars from 3 sources (Schema + official docs + env-vars docs)"
version: "3.0.0"
allowed-tools:
  - Read
  - WebFetch
  - Agent
  - AskUserQuestion
context: fork
agent: General-purpose
---

# /cc-settings

`skills/cc-settings/SKILL.md` のワークフローに従って実行すること。

## クイックリファレンス

1. 3つのソースを並列フェッチ（Schema / 公式設定ドキュメント / 公式環境変数ドキュメント）
2. 現在の settings.json を Read で読み込み
3. settings.json プロパティ（17カテゴリ）+ 環境変数（12カテゴリ）を一覧表示
4. ユーザーが興味を持ったカテゴリの詳細を表示

## データソース

| ソース | URL |
|--------|-----|
| JSON Schema | `https://json.schemastore.org/claude-code-settings.json` |
| 公式設定ドキュメント | `https://code.claude.com/docs/en/settings` |
| 公式環境変数ドキュメント | `https://code.claude.com/docs/en/env-vars` |

## 引数

- (なし): カテゴリ一覧を表示
- `<番号>`: 指定カテゴリの詳細（例: `4`, `E5`）
- `<キーワード>`: 設定項目を検索
- `--all`: 全項目を一覧表示
- `--env`: 環境変数のみ表示
- `--diff`: 設定済み vs 未設定の差分
- `--admin`: 管理者向け設定も表示
