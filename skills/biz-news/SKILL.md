---
name: biz-news
description: "Fetch daily business and tech industry news with self-evolving source registry. Use when user says 'ビジネスニュース', 'biz-news', 'テックニュース', 'スタートアップ', 'business news', 'tech news', '資金調達', 'M&A', '業界ニュース', or wants business/tech industry digest. Use proactively when the user mentions startup funding, tech acquisitions, industry trends, or wants to stay updated on business developments."
version: 1.0.0
---

# ビジネス & テックニュース ダイジェスト

最新のビジネス・テック業界ニュースをサブエージェント並列実行で収集し、Obsidian にまとめて保存する。
ソースリストは固定＋動的発見の2層構造で、実行ごとに成長する。

## 前提条件

- Agent ツールが利用可能

## 定数

```
OBSIDIAN_VAULT=~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Obsidian
OUTPUT_DIR=$OBSIDIAN_VAULT/note
DATE=$(date +%Y-%m-%d)
OUTPUT_FILE=$OUTPUT_DIR/$DATE-biz-news.md
SOURCE_REGISTRY=~/.claude/projects/-Users-sizukutamago-workspace/memory/biz-news-sources.md
```

## サブエージェント構成

| エージェント | subagent_type | model | 役割 |
|-------------|---------------|-------|------|
| Biz Crawler | `biz-news-crawler` | sonnet | ビジネスニュースソース巡回 |
| Discovery | `biz-news-discovery` | sonnet | 新ソース発見 |
| Deep Dive | `biz-news-deep-dive` | opus | 記事深掘り解説 |

## アーキテクチャ

```
Orchestrator（メイン Claude）
├─ Phase 0: Read SOURCE_REGISTRY + 過去記事除外リスト作成
├─ Phase 1: Agent tool × 2 並列
│   ├─ biz-news-crawler     ─→ ニュースリスト
│   └─ biz-news-discovery   ─→ 新ソース候補
├─ Phase 2: 結果集約 & キュレーション
├─ Phase 3: Edit SOURCE_REGISTRY（新ソース追記）
├─ Phase 4: Write OUTPUT_FILE（ダイジェスト生成）
├─ Phase 5: AskUserQuestion → biz-news-deep-dive（任意）
└─ Phase 6: 完了報告
```

## ワークフロー

### Phase 0: 準備

1. Bash で `date +%Y-%m-%d` と `date +%Y-%m` を実行 → `DATE`, `YEAR_MONTH`
2. `SOURCE_REGISTRY` を Read で読み込む → 固定ソースと動的発見ソース（`active` なもののみ）
3. オプション引数をパース
4. **過去記事の重複排除リスト作成**: Obsidian `OUTPUT_DIR` から直近7日分の `*-biz-news.md` を Glob で取得し、URL を抽出 → `SEEN_URLS`

### Phase 1: サブエージェント並列ディスパッチ

**1つのメッセージ内で Agent tool を並列発行する。**

#### Biz Crawler の起動

```
Agent tool:
  subagent_type: "biz-news-crawler"
  name: "biz-crawler"
  description: "Crawl business news sources"
  prompt: |
    最新のビジネス・テック業界ニュースを収集してください。

    ## 実行日
    date: {DATE}
    year_month: {YEAR_MONTH}

    ## 動的発見ソース
    {SOURCE_REGISTRY の動的発見ソースからURLを展開}

    ## 除外URL（過去7日間に収集済み）
    {SEEN_URLS を展開}

    ## オプション
    topic: {--topic の値 or "なし"}

    エージェント定義の手順に従って収集・出力してください。
    除外URLに含まれる記事はスキップすること。
    WebSearch クエリの {YYYY-MM} には year_month の値を使用。
```

#### Discovery Agent の起動

```
Agent tool:
  subagent_type: "biz-news-discovery"
  name: "biz-source-discovery"
  description: "Discover new biz news sources"
  prompt: |
    既存のソースリストに無い新しい情報源を探してください。

    ## 実行日
    year: {YYYY}

    ## 既存ソース（除外対象）
    {SOURCE_REGISTRY の全URLを展開}

    ## モード
    discover_mode: {--discover なら "heavy" そうでなければ "normal"}

    エージェント定義の手順に従って検索・評価してください。
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

**選定基準**: インパクト → 新規性 → 日本との関連性 → 話題性

**収集目安**: 合計 10〜20 件。重複排除。

### Phase 3: ソースレジストリ更新

#### 3a. 新ソース追加

Discovery Agent の結果から `SOURCE_REGISTRY` の動的発見ソーステーブルに Edit で追記。
**1回の実行で最大3件まで。**

#### 3b. 失敗ソースのライフサイクル管理

Biz Crawler の結果に含まれる「失敗ソース」情報を確認し、動的発見ソースの status を遷移させる:

```
active  ──(失敗)──→  warn  ──(再度失敗)──→  inactive ⚠
  ↑                   │
  └──(成功)───────────┘
```

- `active`: 正常にクロール対象
- `warn`: 前回失敗。次回も失敗すれば inactive に降格。成功すれば active に復帰
- `inactive ⚠`: クロール対象外。Phase 1 で除外される

### Phase 4: ダイジェスト生成 & 保存

`references/digest_template.md` のテンプレートに従って生成。Write で `OUTPUT_FILE` に保存。

### Phase 5: 深掘り（インタラクティブ）

```
📋 Business & Tech Digest を生成しました！

気になる項目があれば番号で教えてください。深掘り解説します。
（例: "1, 3" / "全部OK" / "M&Aの件を詳しく"）
```

`--quick` 時はスキップ。

Deep Dive Agent:
```
Agent tool:
  subagent_type: "biz-news-deep-dive"
  name: "biz-deep-dive-{N}"
  description: "Deep dive on news N"
  prompt: |
    以下の記事について詳細なビジネス分析を作成してください。

    ## 対象
    タイトル: {title}
    URL: {url}
    既知の要約: {summary}

    エージェント定義の手順に従って解説を作成してください。
```

### Phase 6: 完了報告

```
✅ Business & Tech Digest を保存しました
📁 {OUTPUT_FILE}
📊 ニュース X件
📡 ソース Y箇所（新規発見: Z件）
🔍 深掘り D件
```

## オプション

| 引数 | 説明 |
|------|------|
| `--quick` | 深掘りなし |
| `--topic <keyword>` | トピック絞り込み |
| `--no-save` | 保存しない |
| `--discover` | 新ソース発見重点 |
| `--sources` | ソースリスト表示のみ |
| `--jp-only` | 日本語ソースのみ |

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| サブエージェント失敗 | 他の結果で補完 |
| ペイウォール | タイトル＋概要のみ収集 |
| Obsidian Vault 不在 | `--no-save` で続行 |
| ソースレジストリ不在 | 固定ソースのみ。レジストリ自動再作成 |
