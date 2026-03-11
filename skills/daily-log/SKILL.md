---
name: daily-log
description: "End-of-day retrospective: review accomplishments, update task state, and prepare for tomorrow. Use when the user says '振り返り', '今日の成果', '帰る前に', 'daily log', 'wrap up', '1日の終わり', or wants to review what they accomplished today."
version: 1.0.0
---

# Daily Log — 振り返り

一日の終わりの振り返り。成果を記録し、明日の準備をする。

## Obsidian Vault

パス: `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Obsidian`

## 手順

### 1. 今日の成果確認

対話形式でユーザーに確認する:
- 「今日は何を達成しましたか？」
- 「予定と違ったことはありますか？」
- 「明日に持ち越すタスクはありますか？」

### 2. daily note に書き込み

Write ツールまたは Edit ツールで Obsidian vault の `daily/YYYY-MM-DD.md` に記録する。
ファイルが既に存在する場合は Read → Edit で追記。存在しない場合は Write で新規作成。

フォーマット:
```markdown
# YYYY-MM-DD (曜日)

## 今日の成果
- 完了タスク1
- 完了タスク2
- 進行中タスク

## 学び
- 今日学んだこと

## 明日のアクション
- 最初にやること
```

### 3. タスク更新

Edit ツールで `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Obsidian/tasks.md` を更新:
- 完了タスクを DONE セクションに移動（日付付き）
- 新しいタスクがあれば NEXT に追加
- ブロッカーがあれば BLOCKED に移動

### 4. 明日の準備

ユーザーと対話して明日のタスクを確認:
- NEXT タスクの確認
- ブロッカーの特定
- 明日の最初のアクションを提案
