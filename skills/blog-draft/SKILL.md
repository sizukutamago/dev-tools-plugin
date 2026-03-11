---
name: blog-draft
description: "Blog drafting workflow: create a structured blog post draft from recent work, decisions, and learnings. Use when the user says 'ブログ', 'blog', '記事', 'アウトプット', '書きたい', or wants to turn recent work or learnings into a blog post."
version: 1.0.0
---

# Blog Draft — ブログ記事下書き

最近の作業・学び・設計判断をもとにブログ記事の下書きを作成する。

## Obsidian Vault

パス: `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Obsidian`

## 使い方

`/blog-draft <テーマ>` で下書き作成を開始する。
テーマ省略時は直近の daily note やメモから候補を提案する。

## 手順

### 1. テーマの決定

引数があればそれをテーマとする。なければ:
- Read ツールで直近の daily note（3日分）を読む
- Glob ツールで直近のメモを確認
- 候補を3つ提案し、ユーザーに選択してもらう

### 2. 素材の収集

- Read ツールで関連する daily note やメモを読む
- WebSearch ツールで参考情報を検索（必要に応じて）
- Grep ツールでコードベースから関連コードを検索

### 3. 構成の提案

以下の構成案をユーザーに提示:
- **タイトル案**（3つ）
- **想定読者**: 誰に向けた記事か
- **記事構成**: 見出しレベルのアウトライン
- **推定文字数**

ユーザーの承認を得てから次に進む。

### 4. 下書き作成

承認された構成に沿って下書きを作成する:
- 技術的正確性を重視
- コード例は実際のプロジェクトから引用
- 「なぜその判断をしたか」を含める
- 図やダイアグラムの挿入箇所を `[図: ...]` で示す

### 5. 保存

Write ツールで `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Obsidian/blog/YYYY-MM-DD-{slug}.md` を作成。

## 注意事項

- 「やってみた」系ではなく「考えた結果こうなった」系を目指す
- 読者が再現できるレベルの具体性を保つ
- 社外秘情報が含まれていないか最終確認する
