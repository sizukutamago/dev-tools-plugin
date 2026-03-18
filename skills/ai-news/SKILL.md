---
name: ai-news
description: "Fetch daily AI news, research papers, and deep dive analysis with self-evolving source registry. Use when user says 'AIニュース', 'ai-news', '論文', 'papers', '最新AI', 'daily digest', '最新の論文', 'arxiv', 'AI最新動向', 'papers today', '今日のAI', '研究動向', 'AI news', '論文まとめ', 'AI業界ニュース', or wants any kind of AI research or industry news digest. Make sure to use this skill proactively when the user mentions AI papers, research trends, or wants to stay updated on AI developments."
version: 2.0.0
---

# AI デイリーニュース & 論文ダイジェスト

最新のAIニュース・研究論文をサブエージェント並列実行で収集し、Obsidian に保存する。

## 設計方針

- **速度最優先**: Phase 0 は1回の Bash + 1回の Read で完了させる
- **Discovery はオプトイン**: `--discover` 時のみ実行（デフォルトは Crawler 2本のみ）
- **Deep Dive はオプトイン**: `--deep-dive` 時のみ質問する（デフォルトはスキップ）

## 定数

```
OBSIDIAN_VAULT=~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Obsidian
OUTPUT_DIR=$OBSIDIAN_VAULT/news
DATE=$(date +%Y-%m-%d)
OUTPUT_FILE=$OUTPUT_DIR/$DATE-ai-news.md
SOURCE_REGISTRY=~/.claude/projects/-Users-sizukutamago-workspace/memory/ai-news-sources.md
```

## サブエージェント構成

| エージェント | subagent_type | model | 起動条件 |
|-------------|---------------|-------|----------|
| Paper Crawler | `dev-tools-plugin:ai-news-paper-crawler` | sonnet | 常時（`--news-only` 以外） |
| News Crawler | `dev-tools-plugin:ai-news-news-crawler` | sonnet | 常時（`--papers-only` 以外） |
| Discovery | `dev-tools-plugin:ai-news-discovery` | sonnet | `--discover` 時のみ |
| Deep Dive | `dev-tools-plugin:ai-news-deep-dive` | opus | `--deep-dive` 時のみ |

## ワークフロー

### Phase 0: 準備（ツール呼び出し最大2回）

**1回目（並列）:**
- `Bash`: 日付取得 + 過去7日分の SEEN_URLS を1コマンドで抽出（zsh glob 問題回避のため `bash -c` を使用）
  ```bash
  bash -c 'echo "DATE=$(date +%Y-%m-%d)" && echo "YEAR_MONTH=$(date +%Y-%m)" && echo "---SEEN_URLS---" && grep -rohE "https?://[^ )]+" "/Users/sizukutamago/Library/Mobile Documents/iCloud~md~obsidian/Documents/Obsidian/news/"*-ai-news.md 2>/dev/null | sort -u'
  ```
- `Read`: SOURCE_REGISTRY を読み込む

これで DATE, YEAR_MONTH, SEEN_URLS, 動的ソースリストが全て揃う。

### Phase 1: サブエージェント並列ディスパッチ

**1つのメッセージ内で Agent tool を並列発行する。**

#### プロンプト構成（共通ルール）

- SEEN_URLS は **arxiv ID / HF paper ID のみ** を渡す（`2603.12345` 形式、フル URL 不要）
- 動的発見ソースは **active のみ** を URL リストで渡す
- プロンプトは簡潔に。不要なセクションは省略

#### Paper Crawler

```
prompt: |
  date: {DATE}, year_month: {YEAR_MONTH}
  動的ソース: {active な論文系 URL を改行区切り}
  除外ID: {SEEN_URLS から抽出した arxiv/HF ID を改行区切り}
  topic: {--topic の値 or "なし"}
```

#### News Crawler

```
prompt: |
  date: {DATE}, year_month: {YEAR_MONTH}
  動的ソース: {active なニュース系 URL を改行区切り}
  除外URL: {SEEN_URLS からニュース系 URL を改行区切り}
  topic: {--topic の値 or "なし"}
```

#### Discovery（`--discover` 時のみ）

```
prompt: |
  year: {YYYY}
  既存ソース: {SOURCE_REGISTRY の全 URL を改行区切り}
  discover_mode: {--discover なら "heavy" そうでなければ "normal"}
```

### Phase 2: 結果集約 & キュレーション

サブエージェントの結果を集約し、重複排除・分類する。

**分類カテゴリ**:
| カテゴリ | 内容 |
|---------|------|
| 🔬 注目論文 | 革新的手法、SOTA更新、理論的貢献 |
| 🚀 新モデル・リリース | モデル、ツール、フレームワーク公開 |
| 🏢 業界動向 | 企業発表、提携、規制、資金調達 |
| 🧪 科学×AI | AI for Science |
| 💡 技術トレンド | アーキテクチャ、学習手法の新潮流 |
| 🌏 日本語圏 | Zenn、日本企業、日本語ブログ |

**選定基準**: 影響度 → 新規性 → 実用性 → 話題性
**収集目安**: 合計 10〜20 件。

### Phase 3: ソースレジストリ更新

- `--discover` 時: Discovery Agent の結果から最大3件を追記
- Crawler の失敗ソース情報で動的ソースの status を遷移: `active → warn → inactive ⚠`

### Phase 4: ダイジェスト生成 & 保存

`references/digest_template.md` に従って Write で保存。`--no-save` 時はチャットに直接表示。

### Phase 5: 完了報告（1行）

```
✅ AI Daily Digest: 論文 X件 / ニュース Y件 → {OUTPUT_FILE}
```

`--deep-dive` 指定時のみ AskUserQuestion で深掘り対象を確認し、`dev-tools-plugin:ai-news-deep-dive` を起動。

## オプション

| 引数 | 説明 |
|------|------|
| `--quick` | `--deep-dive` なしと同等（後方互換） |
| `--deep-dive` | 深掘り質問を表示 |
| `--discover` | Discovery Agent を実行 |
| `--topic <keyword>` | 特定トピックに絞って収集 |
| `--papers-only` | 論文のみ |
| `--news-only` | ニュースのみ |
| `--no-save` | Obsidian に保存しない |
| `--sources` | ソースレジストリを表示するだけ |

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| サブエージェント失敗 | 他の結果で補完 |
| Obsidian Vault 不在 | `--no-save` で続行 |
| ソースレジストリ不在 | 固定ソースのみで実行 |
| 全エージェント失敗 | Orchestrator が WebSearch で最低限生成 |

## 注意事項

- 論文の要約は原文に忠実に
- 未検証の情報には「(未確認)」を付ける
- ソース URL は必ず記載
