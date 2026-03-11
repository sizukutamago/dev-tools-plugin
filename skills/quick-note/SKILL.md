---
name: quick-note
description: "Save a quick memo to Obsidian for future recall. Use when the user says 'メモ', 'note', '覚えて', '記録', or wants to jot down a quick thought, tip, or reminder."
version: 1.0.0
---

# Quick Note — クイックメモ

短いメモを Obsidian vault に保存する。

## Obsidian Vault

パス: `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Obsidian`

## 使い方

`/quick-note <メモ内容>`

例:
- `/quick-note pgvectorのインデックスはHNSWが最適`
- `/quick-note 明日のミーティングでAPI設計をレビュー`

## 手順

### 1. メモ内容の取得

引数をそのまま content として使用する。
引数がない場合は、直近の会話内容から要点を抽出してユーザーに提案する。

### 2. Obsidian に保存

Write ツールで `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Obsidian/note/YYYY-MM-DD-{slug}.md` を作成。

slug はメモ内容から日本語キーワードを抽出して短くしたもの（例: `pgvector-index`, `api-review`）。

フォーマット:
```markdown
---
date: YYYY-MM-DD
tags: [note]
---

{メモ内容}
```

### 3. 結果の表示

保存先のファイルパスを表示する。
