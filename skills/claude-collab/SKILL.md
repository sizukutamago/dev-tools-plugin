---
name: claude-collab
description: Autonomous multi-round debate between two Claude Code instances via tmux. Supports advocate/devil's-advocate, expert perspectives, and custom roles for design decisions, code review, debugging, and brainstorming. Use when user wants "Claude同士で議論", "ディベート", "多角的に検討", "debate", "pros and cons".
version: 1.1.0
---

# Claude Collab（Claude 対話ディベート）

2つの Claude Code インスタンスが tmux 経由で自律的に N ラウンドの議論を行うスキル。
メイン Claude は中立的なオーケストレーターとして進行を管理し、Role A / Role B は両方 `claude -p` で実行する。

## 概要

| 項目 | 値 |
|------|---|
| メイン Claude | 中立オーケストレーター（進行管理・論点台帳管理・収束判定） |
| Role A | tmux ペインの `claude -p`（ワンショット） |
| Role B | tmux ペインの `claude -p`（ワンショット） |
| Judge | tmux ペインの `claude -p`（最終要約） |
| デフォルトラウンド数 | 3（範囲: 2-7） |
| 1ラウンド文字数上限 | 1000文字 |

## 前提条件（実行前に確認）

以下をすべて確認してから開始すること:

1. **tmux セッション内**で実行していること
2. `claude` CLI がインストール済み・認証済みであること
3. `claude -p "hello"` が正常に応答を返すこと

確認コマンド:
```bash
echo $TMUX                              # 空でなければ tmux 内
env -u CLAUDECODE claude -p "hello"     # 応答が返れば OK
```

**重要**: Claude Code セッション内から `claude -p` を実行するには `CLAUDECODE` 環境変数をアンセットする必要がある。
すべての `claude -p` 実行は `env -u CLAUDECODE claude -p ...` の形式で行うこと。

いずれかが失敗した場合は、ユーザーに案内して中断する。

## ワークフロー

### Phase 0: Configuration（設定）

**AskUserQuestion ツール**を使って以下を確認する:

1. **議論テーマ**: ユーザーが指定したテーマを確認。引数があればそれを使用
2. **ロールモード**: 以下から選択（デフォルト: advocate-vs-devils-advocate）
   - `advocate-vs-devils-advocate`: 賛成 vs 反対
   - `expert-perspectives`: 専門家視点ペア（`references/role_presets.md` から選択）
   - `custom`: ユーザーが Role A/B を自由定義
3. **ラウンド数**: デフォルト 3（範囲: 2-7）
4. **コンテキスト**（任意）: 議論に含めるコードファイルやドキュメント

### Phase 1: Setup（セットアップ）

tmux ペインを作成する。Role A と Role B は同じペインで順番に実行する。

```bash
# プラグインルートの特定（tmux_ai.sh のパス解決）
PLUGIN_ROOT=$(dirname "$(claude skill show claude-collab 2>/dev/null | grep -m1 'path:' | awk '{print $2}')" 2>/dev/null)
if [ -z "$PLUGIN_ROOT" ]; then
  # フォールバック: よく使われるパスを順に探索
  for dir in \
    "$HOME/.claude/plugins/dev-tools-plugin" \
    "$HOME/workspace/claude-plugins/dev-tools-plugin" \
    "$(pwd)"; do
    if [ -f "$dir/skills/tmux-ai-chat/scripts/tmux_ai.sh" ]; then
      PLUGIN_ROOT="$dir"
      break
    fi
  done
fi
SCRIPT_DIR="${PLUGIN_ROOT}/skills/tmux-ai-chat/scripts"

# tmux_ai.sh でシェルペインを作成
pane=$("${SCRIPT_DIR}/tmux_ai.sh" split --direction h --percent 40 --name "Claude-Debate" --print-pane-id)
```

**注意**: `tmux_ai.sh` が見つからない場合は直接 tmux コマンドでフォールバックする:
```bash
tmux split-window -h
pane=$(tmux list-panes -F "#{pane_id}" | tail -1)
```

**セッション固有の一時ディレクトリ**: 並列実行時のファイル名衝突を防ぐため、セッション固有のディレクトリを使用する:
```bash
COLLAB_TMPDIR="/tmp/claude-collab-$$"
mkdir -p "$COLLAB_TMPDIR" && chmod 700 "$COLLAB_TMPDIR"
```
以降の一時ファイルはすべて `$COLLAB_TMPDIR/` 配下に作成する。

### Phase 2: Discussion Loop（議論ループ）

**論点台帳（Issue Ledger）** をオーケストレーターが管理する。

#### 論点台帳の形式

```
| issue_id | topic | status | evidence_a | evidence_b |
|----------|-------|--------|------------|------------|
```

- `status`: `open`（未解決）/ `resolved`（合意済）/ `dropped`（除外）
- 各ラウンドのプロンプトには**台帳全体 + 直近2ラウンドの発言**を含める

#### 各ラウンドの手順

以下を `round = 1` から `max_rounds` まで繰り返す:

**Step 1: Role A のプロンプト作成**

以下の内容を `$COLLAB_TMPDIR/roleA-round-{round}.txt` に書き出す:

```
あなたは「{Role A の名前と説明}」として議論に参加しています。

## 議論テーマ
{topic}

## コンテキスト
{context_if_any}

## 論点台帳（現在の状態）
{issue_ledger}

## 直近の議論（最大2ラウンド分）
{recent_history}

## 指示
- これはラウンド {round}/{max_rounds} です
- 前の発言者の主張に対して、あなたの立場から応答してください
- 具体的な根拠やコード例を含めてください
- 新しい論点があれば提起してください
- 必ず反論や別の視点を含めてください（安易に同意しないでください）
- 1000文字以内で回答してください
- 出力はプレーンテキストで、余計なマークアップや装飾は含めないでください
```

**Step 2: Role A の実行**

ファイルベースの実行パターンで `claude -p` を実行する。

> **参照**: `references/execution_pattern.md` の基本パターン（Step 2〜5）

- プロンプト: `$COLLAB_TMPDIR/roleA-round-${round}.txt`
- 出力: `$COLLAB_TMPDIR/roleA-out-${round}.txt`
- 待機: 最大120秒、2秒間隔ポーリング
- タイムアウト時: リトライ1回、失敗なら "(タイムアウト)" として記録

**Step 3: Role A の応答をユーザーに表示**

```
── Round {round}/{max_rounds} ──

🔵 Role A（{role_a_name}）:
{response_a}
```

**Step 4: Role B のプロンプト作成**

Role A の応答を含めて `$COLLAB_TMPDIR/roleB-round-{round}.txt` に書き出す。
構造は Role A と同じだが、Role B の説明と「Role A の直前の発言」を追加する。

**Step 5: Role B の実行**

Step 2 と同じ実行パターン（ファイル名は `roleB-*` に置換）。

**Step 6: Role B の応答をユーザーに表示**

```
🔴 Role B（{role_b_name}）:
{response_b}
```

**Step 7: 論点台帳の更新**

オーケストレーター（メイン Claude）が以下を行う:
- Role A と Role B の応答から**新しい論点**を抽出 → 台帳に追加（status: `open`）
- 両者が合意した論点 → status を `resolved` に更新
- evidence_a / evidence_b に各発言の要約を記録

**Step 8: 収束チェック**

以下のいずれかが成立したら早期終了（終了理由を記録すること）:
1. `new_points == 0` が2ラウンド連続 → 終了理由: `converged-early`
2. 全論点が `resolved` または `dropped` → 終了理由: `converged-early`
3. `max_rounds` に到達 → 終了理由: `max-rounds`

堂々巡りの検出:
- 3ラウンド以上で同じ論点の evidence が実質的に変わっていない
- → 対処: 新しい切り口を注入して続行。注入しても改善しない場合 → 終了理由: `circular-break`

### Phase 3: Judge（中立要約）

議論終了後、別の `claude -p` で中立的な Judge を実行する。

**Judge プロンプトの作成**:

以下の内容を `$COLLAB_TMPDIR/judge.txt` に書き出す:

```
あなたは中立的な Judge として、以下のディベートの最終要約を作成してください。
どちらの立場にも偏らず、両方の論点を公平に扱ってください。

## 議論テーマ
{topic}

## ロール
- Role A: {role_a_name}（{role_a_description}）
- Role B: {role_b_name}（{role_b_description}）

## 論点台帳（最終状態）
{final_issue_ledger}

## 全ラウンド記録
{all_rounds_history}

## 出力形式
以下のテンプレートに従って要約を作成してください:

1. TL;DR（3点以内の箇条書き）
2. 合意点（両者が同意した点）
3. 対立点（解消されなかった対立、各側の立場とトレードオフ）
4. トレードオフ分析（表形式）
5. 推奨アクション（中立的な提案）
6. 全ラウンド記録（details タグで折りたたみ）

1000文字以内の制約はありません。網羅的に要約してください。
出力はプレーンテキストで、余計なマークアップや装飾は含めないでください。
```

**Judge の実行**:

同じファイルベースの実行パターン（`references/execution_pattern.md` 参照）。

- プロンプト: `$COLLAB_TMPDIR/judge.txt`
- 出力: `$COLLAB_TMPDIR/judge-out.txt`
- 待機: 最大180秒、3秒間隔ポーリング
- タイムアウト時: リトライ1回、失敗なら "(Judge タイムアウト)" としてユーザーに報告

Judge の出力をユーザーに表示する。

### Phase 4: Cleanup（後片付け）

```bash
# tmux ペインを終了（tmux_ai.sh があれば使用、なければ直接 tmux コマンド）
if [ -x "$SCRIPT_DIR/tmux_ai.sh" ]; then
  "$SCRIPT_DIR/tmux_ai.sh" kill --pane "$pane"
else
  tmux kill-pane -t "$pane" 2>/dev/null
fi

# セッション固有の一時ディレクトリを削除
rm -rf "$COLLAB_TMPDIR"
```

## ロールモード

### advocate-vs-devils-advocate（デフォルト）

最も汎用的なモード。提案に対する推進と批判的検証。
詳細は `references/role_presets.md` のセクション1を参照。

### expert-perspectives

専門家の視点ペアを選択する。AskUserQuestion で以下から選択:

| ID | ペア名 | 用途 |
|----|--------|------|
| security-vs-performance | セキュリティ vs パフォーマンス | 技術選定、API 設計 |
| security-vs-delivery | セキュリティ vs デリバリー速度 | リリース判断 |
| pragmatist-vs-purist | 実用主義 vs 理想主義 | 設計方針 |
| frontend-vs-backend | フロントエンド vs バックエンド | フルスタック設計 |
| maintainer-vs-innovator | 保守 vs 革新 | 技術刷新判断 |
| user-vs-developer | ユーザー vs 開発者 | UI/UX 設計 |
| simplicity-vs-scalability | シンプルさ vs スケーラビリティ | アーキテクチャ |
| cost-vs-reliability | コスト vs 信頼性 | インフラ設計 |
| product-vs-tech-debt | プロダクト価値 vs 技術的負債 | スプリント計画 |

詳細は `references/role_presets.md` を参照。

### custom

ユーザーが Role A と Role B の説明を自由に定義する。
AskUserQuestion で各ロールの名前と説明を入力してもらう。

## 使用例

### 設計判断のディベート
```
ユーザー: 「認証方式として JWT と セッションベース、どちらが良いか議論して」
→ デフォルトの advocate-vs-devils-advocate で議論
→ Role A が JWT を推進、Role B が批判的に検証
```

### コードレビューの多角的分析
```
ユーザー: 「このリファクタリング方針について、maintainer-vs-innovator で議論して」
→ expert-perspectives モードで指定ペアを使用
→ 保守性と革新性の観点から多角的に検討
```

### 技術選定のトレードオフ分析
```
ユーザー: 「PostgreSQL vs MongoDB の選定を cost-vs-reliability で議論して」
→ コスト最適化と信頼性の両面から分析
```

## 待機時間の目安

| 内容 | `claude -p` 待機時間 | 最大待機時間 |
|------|---------------------|-------------|
| 短い議論（500文字以下） | 30秒 | 60秒 |
| 標準的な議論（1000文字） | 60秒 | 120秒 |
| Judge（全ラウンド要約） | 90秒 | 180秒 |

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| tmux 未起動 | 中断。「tmux セッション内で実行してください」と案内 |
| claude CLI 未認証 | 中断。「claude auth を実行してください」と案内 |
| claude -p タイムアウト（Role: 120秒 / Judge: 180秒） | リトライ1回。失敗なら該当ラウンドをスキップ |
| CLAUDECODE 環境変数エラー | `env -u CLAUDECODE` が適用されているか確認 |
| ペイン消失 | ペイン再作成して続行 |
| 応答が空 | リトライ1回。失敗なら「応答なし」として記録し次ラウンドへ |
| exit ファイル未生成（タイムアウト） | `claude -p` がハングした場合。ポーリング上限到達後にリトライ1回 |
| exit コードが非ゼロ | `claude -p` のエラー。出力先頭5行をユーザーに表示しリトライ1回 |

### リトライ制限

| 項目 | 上限 |
|------|------|
| 同一ステップの再試行 | 最大 1 回 |
| 総タイムアウト | 15 分（全ラウンド + Judge 合計） |

### リカバリー手順

1. エラー内容をユーザーに表示
2. tmux ペインの状態を確認: `tmux list-panes`
3. ペインが存在すれば、一時ファイルの状態を確認
4. 可能なら次のステップから再開、不可能なら Phase 4（Cleanup）へ

## ツール使用ルール

| ツール | 用途 | 注意 |
|--------|------|------|
| AskUserQuestion | Phase 0 の設定確認 | ロールモード・ラウンド数・テーマ |
| Write | プロンプトファイルの書き出し | `$COLLAB_TMPDIR/` に出力（セッション固有） |
| Bash | tmux 操作、claude -p 実行 | `tmux send-keys` と Enter は**別々の Bash 呼び出し**で実行 |
| Read | コンテキストファイルの読み込み | ユーザー指定のファイルのみ |

**重要**: `tmux send-keys` と Enter 送信は `&&` で連結しないこと。
各コマンドは別々の Bash 呼び出しで実行する（codex-collab と同じ制約）。

## 参照ファイル

- `references/role_presets.md` - 10種のプリセットロール定義
- `references/discussion_summary_template.md` - Judge 用サマリーテンプレート
- `references/execution_pattern.md` - `claude -p` のファイルベース実行パターン
