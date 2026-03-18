---
name: biz-news
description: "Fetch daily business and tech industry news with self-evolving source registry. Use when user says 'ビジネスニュース', 'biz-news', 'テックニュース', 'スタートアップ', 'business news', 'tech news', '資金調達', 'M&A', '業界ニュース', or wants business/tech industry digest. Use proactively when the user mentions startup funding, tech acquisitions, industry trends, or wants to stay updated on business developments."
version: 2.0.0
---

# ビジネス & テックニュース ダイジェスト

最新のビジネス・テック業界ニュースをサブエージェント実行で収集し、Obsidian に保存する。

## 設計方針

- **速度最優先**: Phase 0 は1回の Bash + 1回の Read で完了させる
- **Discovery はオプトイン**: `--discover` 時のみ実行（デフォルトは Crawler のみ）
- **Deep Dive はオプトイン**: `--deep-dive` 時のみ質問する

## 定数

```
OBSIDIAN_VAULT=~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Obsidian
OUTPUT_DIR=$OBSIDIAN_VAULT/news
DATE=$(date +%Y-%m-%d)
OUTPUT_FILE=$OUTPUT_DIR/$DATE-biz-news.md
SOURCE_REGISTRY=~/.claude/projects/-Users-sizukutamago-workspace/memory/biz-news-sources.md
```

## サブエージェント構成

| エージェント | subagent_type | model | 起動条件 |
|-------------|---------------|-------|----------|
| Biz Crawler | `dev-tools-plugin:biz-news-crawler` | sonnet | 常時 |
| Discovery | `dev-tools-plugin:biz-news-discovery` | sonnet | `--discover` 時のみ |
| Deep Dive | `dev-tools-plugin:biz-news-deep-dive` | opus | `--deep-dive` 時のみ |

## ワークフロー

### Phase 0: 準備（ツール呼び出し最大2回）

**1回目（並列）:**
- `Bash`: 日付取得 + 過去7日分の SEEN_URLS を1コマンドで抽出（zsh glob 問題回避のため `bash -c` を使用）
  ```bash
  bash -c 'echo "DATE=$(date +%Y-%m-%d)" && echo "YEAR_MONTH=$(date +%Y-%m)" && echo "---SEEN_URLS---" && grep -rohE "https?://[^ )]+" "/Users/sizukutamago/Library/Mobile Documents/iCloud~md~obsidian/Documents/Obsidian/news/"*-biz-news.md 2>/dev/null | sort -u'
  ```
- `Read`: SOURCE_REGISTRY を読み込む

### Phase 1: サブエージェントディスパッチ

Biz Crawler のみ起動（`--discover` 時は Discovery も並列）。

```
prompt: |
  date: {DATE}, year_month: {YEAR_MONTH}
  動的ソース: {active な URL を改行区切り}
  除外URL: {SEEN_URLS を改行区切り}
  topic: {--topic の値 or "なし"}
```

### Phase 2: 結果集約 & キュレーション

**分類カテゴリ**:
| カテゴリ | 内容 |
|---------|------|
| 🏢 ビッグテック | GAFAM、主要テック企業の動向 |
| 🚀 スタートアップ | 資金調達、新サービス、IPO |
| 💰 M&A・投資 | 買収、合併、大型投資 |
| 📊 市場・業界 | 市場動向、業界レポート、決算 |
| ⚖️ 規制・政策 | テック規制、政策変更 |
| 🌏 日本語圏 | 日本のビジネス・テックニュース |

**選定基準**: インパクト → 新規性 → 日本との関連性
**収集目安**: 合計 10〜15 件。

### Phase 3: ソースレジストリ更新

- `--discover` 時のみ新ソース追記（最大3件）
- Crawler の失敗ソース情報で status 遷移: `active → warn → inactive ⚠`

### Phase 4: ダイジェスト生成 & 保存

`references/digest_template.md` に従って Write で保存。

### Phase 5: 完了報告（1行）

```
✅ Business & Tech Digest: ニュース X件 → {OUTPUT_FILE}
```

`--deep-dive` 時のみ深掘り対象を AskUserQuestion で確認。

## オプション

| 引数 | 説明 |
|------|------|
| `--deep-dive` | 深掘り質問を表示 |
| `--discover` | Discovery Agent を実行 |
| `--topic <keyword>` | トピック絞り込み |
| `--no-save` | 保存しない |
| `--sources` | ソースリスト表示のみ |
| `--jp-only` | 日本語ソースのみ |

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| サブエージェント失敗 | WebSearch で補完 |
| ペイウォール | タイトル＋概要のみ収集 |
| Obsidian Vault 不在 | `--no-save` で続行 |
| ソースレジストリ不在 | 固定ソースのみ。レジストリ自動再作成 |
