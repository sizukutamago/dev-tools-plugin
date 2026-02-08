---
name: hurikaeri
description: Session retrospective with AI-KPT framework. Reviews AI autonomous actions, detects omissions via counterfactual reasoning, persists learnings. Use when user says "振り返り", "retrospective", "KPT", "session review", "/hurikaeri".
version: 1.0.0
---

# hurikaeri（振り返り）

セッション単位でAIの行動・判断を振り返り、学びを永続化するスキル。

## 概要

```
┌─────────────────────────────────────────────────────────────┐
│                    hurikaeri パイプライン                     │
│                                                             │
│  Phase 1: Trace (データ収集)                                │
│  ┌──────────┬──────────┬──────────┐                         │
│  │ JSONL    │ git diff │ AI memory│                         │
│  │ 解析     │ 解析     │ 回想     │                         │
│  └────┬─────┴────┬─────┴────┬─────┘                         │
│       └──────────┼──────────┘                               │
│                  ▼                                           │
│  Phase 2: Reflect (分析)                                    │
│  ┌──────────────────────────────┐                           │
│  │ AI-KPT + 反事実推論          │                           │
│  │ (Keep/Problem/Try + Omission)│                           │
│  └──────────────┬───────────────┘                           │
│                  ▼                                           │
│  Phase 3: Crystallize (永続化)                              │
│  ┌──────────────────────────────┐                           │
│  │ 学習メモ保存                  │                           │
│  │ + CLAUDE.md/SKILL.md 更新     │                           │
│  │ + prompt-improver 連携(任意)  │                           │
│  └──────────────────────────────┘                           │
└─────────────────────────────────────────────────────────────┘
```

## prompt-improver との差別化

| 観点 | prompt-improver | hurikaeri |
|------|----------------|-----------|
| 対象 | 複数セッションの蓄積 | 今のセッション |
| 視点 | 指示（入力）の改善 | 行動（プロセス）の改善 |
| 分析手法 | 統計パターン | AI-KPT + 反事実推論 |
| 不作為検出 | なし | あり（「何をしなかったか」） |
| 出力 | ファイルパッチ | 振り返りレポート + 改善提案 |

---

## Phase 1: Trace（データ収集）

3つのデータソースからセッションの事実を抽出する。

### 1a. トランスクリプト JSONL 解析

`extract_session_trace.py` を使い、セッションログから構造化データを抽出。

```bash
# 最新セッションのトランスクリプトを探索
TRANSCRIPT=$(ls -t ~/.claude/projects/*/sessions/*/*.jsonl 2>/dev/null | head -1)

# トレース抽出
python3 "${SKILL_DIR}/scripts/extract_session_trace.py" "$TRANSCRIPT"
```

**抽出する情報:**

| カテゴリ | 内容 |
|---------|------|
| `session_metrics` | ターン数、ツール使用数、変更ファイル数 |
| `tool_timeline` | ツール使用の時系列（ターン、ツール名、入力サマリー、成功/失敗） |
| `search_paths` | 検索・探索の軌跡（Grep/Glob/Read の対象パス） |
| `changed_files` | 変更ファイル一覧（Write/Edit経由） |
| `backtrack_events` | やり直し検出（同一ファイルの複数回編集） |
| `errors` | ツール実行エラー |
| `user_corrections` | ユーザーの修正指示 |

### 1b. git diff 解析

セッション中のコード変更を取得。

```bash
# セッション開始時の HEAD からの差分
git diff --stat HEAD~5..HEAD  # 直近の変更概要
git diff HEAD~5..HEAD         # 詳細な変更内容
```

### 1c. AI 記憶ベースの回想

AI 自身がコンテキストウィンドウ内の記憶を元に以下を列挙:

- セッションで行った判断とその理由
- 迷った点や方針変更した箇所
- 暗黙に置いた前提条件
- ユーザーに確認せずに進めたこと

---

## Phase 2: Reflect（AI-KPT + 反事実推論）

Phase 1 のデータを入力として、4つの観点で分析。

### 2a. Keep（継続すべき行動）

成功パターンを特定し、根拠とともに記録。

**分析観点:**
- エラーなく完了したタスク
- ユーザーの修正指示が不要だった領域
- 効率的なツール使用パターン
- 適切な判断が行われた箇所

### 2b. Problem（問題のあった行動）

AI の行動に問題があった箇所を特定。

**分析観点:**
- `errors` に記録されたエラーとその原因
- `user_corrections` で検出された修正指示
- `backtrack_events` で見つかったやり直し
- 非効率なツール使用（同じ検索の繰り返し等）
- ユーザーへの確認なしで行った影響の大きい判断

**カテゴリ:** error | inefficiency | misunderstanding | oversight | wrong_approach

### 2c. Omission（不作為 — 反事実推論で検出）

`references/counterfactual_prompts.md` のテンプレートを適用して「やらなかったこと」を検出。

**プロセス:**

1. 変更ファイルの種類に応じて関連する反事実プロンプトを選択
2. AI が各プロンプトに回答し、見落としを洗い出す
3. 「このタスクで別の3つのアプローチを挙げ、なぜ採用しなかったか述べよ」

**重要:** 反事実推論は最低3つの観点（セキュリティ/テスト/ベテランエンジニア視点）を必ず実施。

### 2d. Try（次回の改善アクション）

Problem と Omission から具体的な改善アクションを生成。

**各 Try には以下を含める:**
- 対応する Problem/Omission の ID
- スコープ（immediate / session / project / global）
- 永続化先の提案（CLAUDE.md / SKILL.md / メモリ）

### 2e. ユーザー確認

AskUserQuestion を使用して振り返り結果を確認:
- 「この分析結果は正しいですか？ 追加の気づきはありますか？」
- ユーザーのフィードバックを反映して最終化

---

## Phase 3: Crystallize（知見の永続化）

振り返りで得た知見を永続化する。

### 3a. KPT レポート保存

```bash
# ~/.claude/hurikaeri/ に YAML 形式で保存
"${SKILL_DIR}/scripts/persist_learnings.sh"
```

保存先: `~/.claude/hurikaeri/kpt-YYYYMMDD-NNN.yaml`

### 3b. CLAUDE.md / SKILL.md への改善追記

Try で「global」スコープの改善アクションがあれば、該当ファイルへの追記を提案。

**重要:** 自動適用はしない。必ず AskUserQuestion でユーザー承認を得てから適用する。

### 3c. prompt-improver 連携（オプション）

AskUserQuestion で連携するか確認:
- Yes の場合: Problem を `~/.claude/feedback/` の YAML に変換して保存
- No の場合: KPT レポートのみ保存

**変換ルール:**
- `problem` → `issues` （type は problem.category からマッピング）
- `try` → `proposed_actions`
- `session_metrics` → `stats`

### 3d. 振り返りサマリー表示

最終的な振り返りサマリーを出力。

```
【セッション振り返り】
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 タスク: {task_summary}
⏱ {turns}ターン / ツール{tool_count}回

── Keep（継続） ──
✅ {keep_items}

── Problem（問題） ──
⚠️ {problem_items}

── Omission（不作為） ──
🔍 {omission_items}

── Try（次回） ──
💡 {try_items}

📁 保存先: ~/.claude/hurikaeri/kpt-YYYYMMDD-NNN.yaml
```

---

## Stop hook（振り返り提案）

セッション終了時に複雑度を判定し、振り返りを提案する。

### 判定基準

| 条件 | 閾値 |
|------|------|
| JSONL行数 >= 50 かつ ツール使用 >= 10 | 実質的なセッション |
| コード変更（Write/Edit）>= 5 | 多くのファイル変更 |
| エラー >= 3 | 問題の多いセッション |
| JSONL行数 < 20 | 除外（軽微なセッション） |

### 出力

```
🔄 複雑なセッションでした（turns:50, tools:15, changes:8）
   → /hurikaeri で振り返りを実行できます
```

---

## 保存先

```
~/.claude/hurikaeri/
├── kpt-20260208-001.yaml
├── kpt-20260208-002.yaml
└── ...
```

## 依存関係

標準Unixツール + Python 3.x 標準ライブラリ（json, re, sys, os, collections）

## コマンド

| コマンド | 説明 |
|---------|------|
| `/hurikaeri` | セッション振り返りを実行 |

## リソース

### scripts/

- `extract_session_trace.py`: トランスクリプト JSONL からセッショントレースを抽出
- `suggest_hurikaeri.sh`: Stop hook 判定スクリプト
- `persist_learnings.sh`: KPT レポート永続化ヘルパー

### references/

- `kpt_schema.md`: AI-KPT 出力の完全スキーマ定義
- `counterfactual_prompts.md`: 反事実推論プロンプト集

### assets/

- `hooks/hurikaeri_hook.json`: Stop hook 設定例
