---
description: "Session retrospective - review AI behavior with AI-KPT framework and counterfactual reasoning"
version: "1.0.0"
allowed-tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Bash
  - AskUserQuestion
context: fork
agent: General-purpose
---

# /hurikaeri - セッション振り返り

現在のセッションを振り返り、AIの行動・判断を AI-KPT フレームワークで分析する。

## ワークフロー

### Phase 1: Trace（データ収集）

3つのデータソースからセッションの事実を収集する。

#### 1a. トランスクリプト JSONL 解析

```bash
# 最新セッションのトランスクリプトを探索
TRANSCRIPT=$(ls -t ~/.claude/projects/*/sessions/*/*.jsonl 2>/dev/null | head -1)

# トレース抽出
python3 "${CLAUDE_PLUGIN_ROOT}/skills/hurikaeri/scripts/extract_session_trace.py" "$TRANSCRIPT"
```

結果を読み込み、セッションメトリクス・ツール使用タイムライン・変更ファイル・エラー・修正指示を把握する。

#### 1b. git diff 解析

```bash
git diff --stat HEAD~5..HEAD 2>/dev/null || echo "git diff unavailable"
```

セッション中に行われたコード変更の全体像を把握する。

#### 1c. AI 記憶ベースの回想

AIの記憶（コンテキストウィンドウ）を元に以下を自問する:

- このセッションで行った判断とその理由は何か？
- 迷った点や方針変更した箇所はあったか？
- 暗黙に置いた前提条件は何か？
- ユーザーに確認せずに進めたことはあったか？

### Phase 2: Reflect（AI-KPT + 反事実推論）

Phase 1 のデータを入力として、4つの観点で分析する。

#### 2a. Keep（継続すべき行動）

成功パターンを特定し、根拠を付与する。
- エラーなく完了したタスク
- ユーザーの修正指示が不要だった領域
- 効率的なツール使用パターン

#### 2b. Problem（問題のあった行動）

以下のデータから問題を特定:
- `errors` に記録されたエラーとその原因
- `user_corrections` で検出された修正指示
- `backtrack_events` で見つかったやり直し
- 非効率なツール使用
- ユーザー確認なしの影響の大きい判断

各 Problem には `category`（error/inefficiency/misunderstanding/oversight/wrong_approach）と `root_cause` を付与する。

#### 2c. Omission（不作為 — 反事実推論）

`references/counterfactual_prompts.md` を参照し、以下を必ず実施:

**必須（3つ）:**
1. ベテランエンジニア視点
2. テスト観点
3. 代替案検討（別の3つのアプローチを検討）

**条件付き（変更内容に応じて選択）:**
- セキュリティ / パフォーマンス / 保守性 / エラーハンドリング / 互換性 / コミュニケーション

「検討済みで意図的にスキップ」と「検討せず見落とし」を区別する。

#### 2d. Try（次回の改善アクション）

Problem と Omission から改善アクションを生成。各アクションには:
- 対応する Problem/Omission の ID
- スコープ（immediate / session / project / global）
- 永続化先の提案

#### 2e. ユーザー確認

AskUserQuestion で振り返り結果を確認:
- 分析結果の正確性
- 追加の気づき
- 永続化の要否

### Phase 3: Crystallize（知見の永続化）

#### 3a. KPT レポート保存

```bash
# kpt_schema.md に準拠した YAML を生成し保存
echo "$KPT_YAML" | bash "${CLAUDE_PLUGIN_ROOT}/skills/hurikaeri/scripts/persist_learnings.sh"
```

#### 3b. CLAUDE.md / SKILL.md への改善追記

Try で `global` スコープのアクションがあれば提案。AskUserQuestion で承認を得てから適用。

#### 3c. prompt-improver 連携（オプション）

AskUserQuestion で確認:
- 「prompt-improver にもフィードバックを送りますか？」
- Yes: Problem を feedback YAML に変換して `~/.claude/feedback/` に保存

#### 3d. 振り返りサマリー表示

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

## 参照

- スキーマ: `skills/hurikaeri/references/kpt_schema.md`
- 反事実プロンプト: `skills/hurikaeri/references/counterfactual_prompts.md`
- スクリプト: `skills/hurikaeri/scripts/`
