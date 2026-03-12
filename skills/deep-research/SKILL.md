---
name: deep-research
description: "Comprehensive deep research that produces structured, multi-section reports with source citations. Only use when user explicitly requests deep/thorough research via '/deep-research' command or says '徹底調査', 'deep research', '調査レポート作成', '包括的なレポート'. Do NOT trigger for simple lookups like '調べて' or 'リサーチして' — use WebSearch or gemini-collab for those."
version: 2.1.0
---

# Deep Research — 自律型深層調査

反復ループ（計画→並列検索→振り返り分析→改善→再検索）で体系的な調査レポートを自律生成する。

## 前提条件

- WebSearch / WebFetch ツールが利用可能であること
- 外部依存なし（tmux 不要、CLI 不要）

## gemini-collab との使い分け

| 調査の規模 | 手段 |
|-----------|------|
| ピンポイント（「〜について調べて」） | WebSearch/WebFetch 直接 |
| 対話型調査（「Gemini と相談」） | gemini-collab |
| **体系的な深い調査**（`/deep-research`） | **このスキル** |

## 出力ファイル

- Obsidian（デフォルト）: `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Obsidian/note/YYYY-MM-DD-research-{slug}.md`
- CWD: `./deep-research-{slug}-YYYYMMDD.md`

slug はテーマから英語キーワードを抽出して短くしたもの。

## ワークフロー

```
Phase 0: Configuration（ユーザー対話）
    ↓
Phase 1: Planning（メインエージェントが直接実行）
    ↓
Phase 2: Research Loop（反復）
    ├─ 2a. Search（Researcher サブエージェント × N 並列）
    ├─ 2b. Reflect（メインエージェントが分析）
    └─ 2c. 収束判定 → 不十分なら 2a に戻る
    ↓
Phase 3: Synthesis（Writer サブエージェント × 1）
    ↓
Phase 4: Output（保存・要約表示）
```

### Phase 0: Configuration

1. **テーマ確定**: 引数があればテーマとして使用。なければ AskUserQuestion で確認
2. **深さ決定**: 以下から選択（デフォルト: standard）

| 深さ | queriesPerSection | maxIterations | 想定所要時間 |
|------|-------------------|---------------|-------------|
| quick | 2 | 1 | 2-3分 |
| standard | 3 | 3 | 5-10分 |
| deep | 5 | 5 | 10-20分 |

3. **スコープ確認**（任意）: 調査対象の範囲と除外事項

**進捗表示**: 「テーマ: 〇〇 / 深さ: standard / スコープ: 〇〇」を表示

### Phase 1: Planning（メインエージェント）

メインエージェントが直接実行する。サブエージェントは使わない。

1. **予備調査**: WebSearch でテーマの概観を 2-3 クエリで把握
2. **情報プロファイル決定**: テーマの性質に応じて、レポートが主に伝えるべき知識の種類を決める

| テーマの性質 | 主軸となる知識 | 補足にとどめる知識 |
|-------------|--------------|-----------------|
| 技術ツール・プラットフォーム | architecture, comparison, fact, warning | procedure, example（必要最小限） |
| 市場動向・ビジネス | data, timeline, framework, fact | procedure は原則不要 |
| 新技術トレンド | timeline, comparison, data, architecture | example（代表的なもの1-2個のみ） |
| 戦略・方法論 | framework, comparison, warning, fact | checklist（実行時の参考として） |
| 制度・政策 | fact, timeline, data, taxonomy | procedure（申請手順等は補足） |

**重要**: deep-research の出力は**調査レポート**であり、チュートリアルやハウツーガイドではない。読者が状況を理解し判断できることが目的であり、手順を逐一案内することが目的ではない。

3. **セクション分割**: テーマを **3-7 セクション**（調査軸）に分解
4. **クエリ生成**: 各セクションに `queriesPerSection` 個の検索クエリを生成
   - 日本語テーマでも英語クエリを 1 つ含める
   - 同義語・別の切り口を含める
   - クエリはセクションの調査軸に沿った分析的な問いを優先する（「〇〇の現状」「〇〇 vs △△」「〇〇の課題」など）

**進捗表示**: 情報プロファイル + セクション一覧と各クエリをユーザーに表示

例:
```
情報プロファイル: 技術ツール調査
  → 主軸: architecture, comparison, fact, warning
  → 補足: procedure, example

調査計画:
1. [基本概念と設計思想] クエリ: "〇〇 architecture", "〇〇 design principles"
2. [エコシステムと選択肢] クエリ: "〇〇 vs △△ comparison", "〇〇 alternatives 2026"
3. [課題と制約] クエリ: "〇〇 limitations", "〇〇 security concerns"
...
```

### Phase 2: Research Loop

`iteration = 1` から `maxIterations` まで繰り返す。

#### 2a. Search（Researcher サブエージェント × N 並列）

各セクションに対して `deep-research-searcher` サブエージェントを **並列起動** する。

**Agent tool 呼び出しパターン**:

```
# 各セクションを並列で起動（1つの応答で複数の Agent tool を呼び出す）
Agent(
  subagent_type: "deep-research-searcher",
  description: "Research: セクション名",
  prompt: "## 割り当て\n- セクション: {section_name}\n- クエリ: {queries}\n- イテレーション: {iteration}/{maxIterations}\n\n## 情報プロファイル\n- 主軸: {primary_types}\n- 補足: {supplementary_types}\n- レポートの目的: 調査レポート（チュートリアルではない）"
)
```

- `deep-research-searcher` は `agents/researcher.md` で定義（tools: WebSearch, WebFetch のみ、model: sonnet）
- 依存関係のないセクションは全て並列起動する
- 各 Researcher は **Knowledge Blocks** を構造化して返す（11 種の typed blocks）
- **情報プロファイル**を渡すことで、テーマに適した知識収集を誘導する
  - 主軸の block types を優先的に収集し、補足の types は代表的なものだけに絞る

#### 2b. Reflect（メインエージェント）

全 Researcher の結果を統合し、メインエージェントが直接分析する:

1. **カバレッジ評価**: 各セクションが sufficient / insufficient かを判定
   - 判定基準: Knowledge Blocks の数と、**情報プロファイルの主軸 types が収集できているか**
2. **矛盾検出**: セクション間で矛盾する情報がないか確認
3. **ギャップ分析**: Researcher が報告した Gaps を統合
4. **プロファイル適合度チェック**: 主軸 types が不足していれば追加クエリを提案。補足 types が過剰（セクションの半分以上を占める）なら分析的なクエリに修正
5. **改善クエリ提案**: insufficient なセクションに新しいクエリを提案
6. **カバレッジスコア算出**: 0-100%（全セクションの充足度の加重平均）

**進捗表示**: `「イテレーション {N}/{max}: カバレッジ {score}%」` を表示

#### 2c. 収束判定（メインエージェント）

以下のいずれかで収束:
- `coverage_score >= 80` かつ全セクション sufficient → **収束**
- `maxIterations` 到達 → **強制終了**
- カバレッジ増分 < 5% が 2 回連続 → **早期終了**

収束しない場合: insufficient なセクションのみ、改善クエリで 2a に戻る。

### Phase 3: Synthesis（Writer サブエージェント）

`deep-research-writer` サブエージェントを起動する。

**Agent tool 呼び出しパターン**:

```
report_template = Read("skills/deep-research/references/report_template.md")

Agent(
  subagent_type: "deep-research-writer",
  description: "Write research report",
  prompt: "## レポートテンプレート\n{report_template}\n\n## メタデータ\n- テーマ: {topic}\n- Date: {date}\n- Depth: {depth}\n- Iterations: {iterations}\n- Coverage: {coverage_score}%\n- Scope (In): {scope_in}\n- Scope (Out): {scope_out}\n\n## 全セクションの Knowledge Blocks\n{all_knowledge_blocks}\n\n## 分析結果\n{analysis}"
)
```

- `deep-research-writer` は `agents/writer.md` で定義（tools: なし、model: sonnet）
- Writer は Knowledge Blocks の type に応じて適切な Markdown 形式（表・コードブロック・手順リスト等）でレポートを生成する
- Writer はレポートのマークダウンテキストを返す

### Phase 4: Output

1. **保存**: Writer が返したレポートを Write ツールで保存
   - Obsidian: `{vault}/note/YYYY-MM-DD-research-{slug}.md`
   - frontmatter: `date`, `tags: [research, deep-research]`
2. **要約表示**: TL;DR セクションをユーザーに表示
3. **パス案内**: 保存先のファイルパスを表示

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| WebSearch 失敗 | 1回リトライ → 失敗なら該当クエリをスキップ |
| WebFetch 失敗 | スキップして次の結果へ |
| Researcher タイムアウト | 部分結果で続行、該当セクションを insufficient としてマーク |
| 全セクション insufficient | ユーザーにスコープ絞り込みを提案（AskUserQuestion） |
| coverage 収束せず | maxIterations で強制終了、現状スコアを明記してレポート生成 |
| Writer 失敗 | メインエージェントが直接レポートを生成（フォールバック） |
