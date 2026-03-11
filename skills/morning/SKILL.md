---
name: morning
description: "Start your work day with a briefing: restore yesterday's context, review tasks, and set today's goals. Use when the user says 'おはよう', '朝', 'morning', '今日のタスク', '昨日の続き', or starts a new day of work."
version: 1.0.0
---

# Morning Briefing

朝のブリーフィング。前日の文脈を復元し、今日の目標を設定する。

## Obsidian Vault

パス: `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Obsidian`

## 手順

### 1. データ収集（並列実行）

以下を Read ツールで**並列**で読み取る:

#### 1a. タスク一覧
Read ツールで `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Obsidian/tasks.md` を読む。

#### 1b. 昨日の daily note
Read ツールで `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Obsidian/daily/{昨日の日付}.md` を読む。
今日の daily note があればそれも読む。

#### 1c. 直近のメモ
Glob ツールで `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Obsidian/note/*.md` の最新5件を取得し、必要なら Read で内容確認。

### 2. 中断作業の検出

タスク一覧の NOW セクションから現在進行中のタスクを抽出。
昨日の daily note から未完了の作業を検出。

### 3. 出力の生成

## 出力フォーマット

```markdown
# ☀️ Morning Briefing — YYYY-MM-DD (曜日)

## 📋 タスク状況

### NOW（進行中）
- [ ] project: task

### NEXT（次にやる）
- [ ] project: task

## 🔄 昨日の作業
（昨日の daily note から抽出）

## 📝 最近のメモ
（直近のメモファイル一覧）

## 🎯 今日の目標
> ここに目標を一緒に決めましょう。
> 上記の情報を見て、今日やりたいことはありますか？
```

### 4. 今日の目標設定

ユーザーと対話して今日の目標を設定する:
- NOW タスクの確認・変更
- 新しいタスクの追加
- tasks.md を Edit ツールで更新
