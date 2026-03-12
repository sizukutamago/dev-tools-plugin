---
description: "Fetch daily business and tech industry news digest with sub-agent parallel crawling"
version: "1.0.0"
allowed-tools:
  - WebSearch
  - WebFetch
  - Write
  - Read
  - Edit
  - Glob
  - Grep
  - Bash
  - Agent
  - AskUserQuestion
context: fork
agent: General-purpose
---

# /biz-news

`skills/biz-news/SKILL.md` のワークフローに従って実行すること。

## クイックリファレンス

1. ソースレジストリ読み込み（`~/.claude/projects/-Users-sizukutamago-workspace/memory/biz-news-sources.md`）
2. サブエージェント2並列起動（Biz Crawler / Discovery Agent）
3. 結果集約 → ダイジェスト生成 → Obsidian 保存
4. ユーザーに深掘り確認 → Deep Dive Agent（必要に応じて）

## 引数

- `--quick`: 深掘りなし
- `--topic <keyword>`: トピック絞り込み
- `--no-save`: 保存なし
- `--discover`: 新ソース発見重点
- `--sources`: ソースリスト表示のみ
- `--jp-only`: 日本語ソースのみ
