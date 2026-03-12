---
description: "Fetch daily AI news and research papers digest with sub-agent parallel crawling"
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

# /ai-news

`skills/ai-news/SKILL.md` のワークフローに従って実行すること。

## クイックリファレンス

1. ソースレジストリ読み込み（`~/.claude/projects/-Users-sizukutamago-workspace/memory/ai-news-sources.md`）
2. サブエージェント3並列起動（Paper Crawler / News Crawler / Discovery Agent）
3. 結果集約 → ダイジェスト生成 → Obsidian 保存
4. ユーザーに深掘り確認 → Deep Dive Agent 起動（必要に応じて）

## 引数

- `--quick`: 深掘りなし
- `--topic <keyword>`: トピック絞り込み
- `--papers-only`: 論文のみ
- `--news-only`: ニュースのみ
- `--no-save`: 保存なし
- `--discover`: 新ソース発見重点
- `--sources`: ソースリスト表示のみ
