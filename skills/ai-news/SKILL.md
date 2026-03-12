---
name: ai-news
description: "Fetch daily AI news, research papers, and deep dive analysis with self-evolving source registry. Use when user says 'AIニュース', 'ai-news', '論文', 'papers', '最新AI', 'daily digest', '最新の論文', 'arxiv', 'AI最新動向', 'papers today', '今日のAI', '研究動向', 'AI news', '論文まとめ', 'AI業界ニュース', or wants any kind of AI research or industry news digest. Make sure to use this skill proactively when the user mentions AI papers, research trends, or wants to stay updated on AI developments."
version: 1.1.0
---

# AI デイリーニュース & 論文ダイジェスト

最新のAIニュース・研究論文を専用サブエージェント並列実行で収集し、Obsidian にまとめて保存する。
ソースリストは固定＋動的発見の2層構造で、実行ごとに成長する。

## 前提条件

- Agent ツールが利用可能

## 定数

```
OBSIDIAN_VAULT=~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Obsidian
OUTPUT_DIR=$OBSIDIAN_VAULT/note
DATE=$(date +%Y-%m-%d)
OUTPUT_FILE=$OUTPUT_DIR/$DATE-ai-news.md
SOURCE_REGISTRY=~/.claude/projects/-Users-sizukutamago-workspace/memory/ai-news-sources.md
```

## サブエージェント構成

| エージェント | subagent_type | model | 役割 |
|-------------|---------------|-------|------|
| Paper Crawler | `ai-news-paper-crawler` | sonnet | 論文ソース巡回 |
| News Crawler | `ai-news-news-crawler` | sonnet | ニュースソース巡回 |
| Discovery | `ai-news-discovery` | sonnet | 新ソース発見 |
| Deep Dive | `ai-news-deep-dive` | opus | 論文深掘り解説 |

## アーキテクチャ

```
Orchestrator（メイン Claude）
├─ Phase 0: Read SOURCE_REGISTRY
├─ Phase 1: Agent tool × 3 並列
│   ├─ ai-news-paper-crawler   ─→ 論文リスト
│   ├─ ai-news-news-crawler    ─→ ニュースリスト
│   └─ ai-news-discovery       ─→ 新ソース候補
├─ Phase 2: 結果集約 & キュレーション
├─ Phase 3: Edit SOURCE_REGISTRY（新ソース追記）
├─ Phase 4: Write OUTPUT_FILE（ダイジェスト生成）
├─ Phase 5: AskUserQuestion → ai-news-deep-dive（任意）
└─ Phase 6: 完了報告
```

## ワークフロー

### Phase 0: 準備

1. Bash で `date +%Y-%m-%d` と `date +%Y-%m` を実行して日付取得 → `DATE`, `YEAR_MONTH`
2. `SOURCE_REGISTRY` を Read で読み込む → 固定ソースと動的発見ソース（`active` なもののみ）の URL リストを把握
3. オプション引数をパース
4. **過去記事の重複排除リスト作成**: Obsidian `OUTPUT_DIR` から直近7日分のダイジェストファイルを Glob で取得し、Read で URL を抽出 → `SEEN_URLS` リストを作成。このリストをサブエージェントに渡して既出記事を除外させる

### Phase 1: サブエージェント並列ディスパッチ

**1つのメッセージ内で Agent tool を並列発行する。**

起動するエージェントはオプションに応じて変わる:

| オプション | Paper Crawler | News Crawler | Discovery |
|-----------|:---:|:---:|:---:|
| (なし) | ✅ | ✅ | ✅ |
| `--papers-only` | ✅ | - | ✅ |
| `--news-only` | - | ✅ | ✅ |
| `--sources` | - | - | - (Read のみ) |

#### Paper Crawler の起動

```
Agent tool:
  subagent_type: "ai-news-paper-crawler"
  name: "paper-crawler"
  description: "Crawl AI paper sources"
  prompt: |
    以下のソースから最新のAI論文情報を収集してください。

    ## 実行日
    date: {DATE}
    year_month: {YEAR_MONTH}

    ## 動的発見ソース（論文系）
    {SOURCE_REGISTRY の動的発見ソースから論文系URLを展開}

    ## 除外URL（過去7日間に収集済み）
    {SEEN_URLS のうち論文系を展開}

    ## オプション
    topic: {--topic の値 or "なし"}

    エージェント定義の手順に従って収集・出力してください。
    除外URLに含まれる記事はスキップすること。
```

#### News Crawler の起動

```
Agent tool:
  subagent_type: "ai-news-news-crawler"
  name: "news-crawler"
  description: "Crawl AI news sources"
  prompt: |
    最新のAI業界ニュースを収集してください。

    ## 実行日
    date: {DATE}
    year_month: {YEAR_MONTH}

    ## 動的発見ソース（ニュース系）
    {SOURCE_REGISTRY の動的発見ソースからニュース系URLを展開}

    ## 除外URL（過去7日間に収集済み）
    {SEEN_URLS のうちニュース系を展開}

    ## オプション
    topic: {--topic の値 or "なし"}

    エージェント定義の手順に従って収集・出力してください。
    除外URLに含まれる記事はスキップすること。
    WebSearch クエリの {YYYY-MM} には year_month の値を使用すること。
```

#### Discovery Agent の起動

```
Agent tool:
  subagent_type: "ai-news-discovery"
  name: "source-discovery"
  description: "Discover new AI sources"
  prompt: |
    既存のソースリストに無い新しい情報源を探してください。

    ## 実行日
    year: {YYYY}

    ## 既存ソース（除外対象）
    {SOURCE_REGISTRY の全URLを展開}

    ## モード
    discover_mode: {--discover なら "heavy" そうでなければ "normal"}

    エージェント定義の手順に従って検索・評価してください。
    WebSearch クエリの {YYYY} には実行日の年を使用すること。
```

### Phase 2: 結果集約 & キュレーション

3つのサブエージェントの結果が返ったら、Orchestrator が集約する。

**分類カテゴリ**:

| カテゴリ | 内容 |
|---------|------|
| 🔬 注目論文 | 革新的手法、SOTA更新、理論的貢献 |
| 🚀 新モデル・リリース | モデル、ツール、フレームワーク公開 |
| 🏢 業界動向 | 企業発表、提携、規制、資金調達 |
| 🧪 科学×AI | AI for Science（薬学、材料科学、気候等） |
| 💡 技術トレンド | アーキテクチャ、学習手法の新潮流 |
| 🌏 日本語圏 | Zenn、日本企業、日本語ブログ |

**選定基準**（優先度順）: 影響度 → 新規性 → 実用性 → 話題性

**収集目安**: 合計 15〜25 件。重複排除すること。

### Phase 3: ソースレジストリ更新

#### 3a. 新ソース追加

Discovery Agent の結果から、`SOURCE_REGISTRY` の「動的発見ソース」テーブルに Edit で追記:

```markdown
| {name} | {url} | {type} | {DATE} | active |
```

**1回の実行で最大3件まで。**

#### 3b. 失敗ソースのライフサイクル管理

Paper Crawler / News Crawler の結果に含まれる「失敗ソース」情報を確認し、動的発見ソースの status を遷移させる:

```
active  ──(失敗)──→  warn  ──(再度失敗)──→  inactive ⚠
  ↑                   │
  └──(成功)───────────┘
```

- `active`: 正常にクロール対象
- `warn`: 前回失敗。次回も失敗すれば inactive に降格。成功すれば active に復帰
- `inactive ⚠`: クロール対象外。Phase 1 で除外される

```markdown
| {name} | {url} | {type} | {DATE} | warn |
| {name} | {url} | {type} | {DATE} | inactive ⚠ |
```

### Phase 4: ダイジェスト生成 & 保存

`references/digest_template.md` のテンプレートに従って Obsidian ファイルを生成。
Write ツールで `OUTPUT_FILE` に保存。

`--no-save` の場合はチャットに直接表示。

### Phase 5: 深掘り（インタラクティブ）

ダイジェスト生成後、AskUserQuestion:

```
📋 AI Daily Digest を生成しました！

気になる項目があれば番号で教えてください。深掘り解説します。
（例: "1, 3" / "全部OK" / "論文2を詳しく"）
```

`--quick` 時はスキップ。

ユーザーが項目を指定したら **Deep Dive Agent** を起動:

```
Agent tool:
  subagent_type: "ai-news-deep-dive"
  name: "deep-dive-{N}"
  description: "Deep dive on paper N"
  prompt: |
    以下の論文/記事について詳細な深掘り解説を作成してください。

    ## 対象
    タイトル: {title}
    URL: {url}
    既知の要約: {summary}

    エージェント定義の手順に従って解説を作成してください。
```

複数項目が指定された場合は **並列で** Deep Dive Agent を起動可能。

結果はダイジェストファイルの末尾に `## 🔍 Deep Dive` セクションとして Edit で追記。

### Phase 6: 完了報告

```
✅ AI Daily Digest を保存しました
📁 {OUTPUT_FILE}
📊 論文 X件 / ニュース Y件
📡 ソース Z箇所（固定: A / 動的: B / 新規発見: C件）
🔍 深掘り D件
```

## オプション

| 引数 | 説明 |
|------|------|
| `--quick` | 深掘りなし（Phase 5 スキップ） |
| `--topic <keyword>` | 特定トピックに絞って収集 |
| `--papers-only` | 論文のみ（News Crawler 省略） |
| `--news-only` | ニュースのみ（Paper Crawler 省略） |
| `--no-save` | Obsidian に保存しない |
| `--discover` | Discovery Agent を重点実行 |
| `--sources` | ソースレジストリを表示するだけ |

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| サブエージェント失敗 | 他の結果で補完。失敗エージェント名をログ |
| Obsidian Vault 不在 | `--no-save` で続行 |
| ソースレジストリ不在 | 固定ソースのみで実行。レジストリ自動再作成 |
| 全エージェント失敗 | Orchestrator が WebSearch で最低限のダイジェスト生成 |

## 注意事項

- 論文の要約は原文に忠実に
- 未検証の情報には「(未確認)」を付ける
- ソース URL は必ず記載
- 動的発見ソースの追加は1回最大3件
