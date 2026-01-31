---
name: codex-collab
description: Use when the user asks to "pair program with Codex", "get Codex review", "collaborate with Codex", "consult Codex on approach", "second opinion from Codex", "AI pair programming", or any development task that would benefit from a second AI perspective. Integrates with OpenAI Codex CLI (interactive mode in tmux pane) for AI pair programming. Enables Claude Code as primary implementer with Codex as consultant and code reviewer using tmux split-pane visualization. Consults Codex at ALL phases: requirements, design, implementation, and review. IMPORTANT: Never use "codex exec" - always use interactive Codex in tmux pane to avoid MCP server startup overhead.
version: 2.0.5
---

# Codex Collaboration

Claude Code と **OpenAI Codex CLI** による双方向ペアプログラミングスキル。

## 概要

このスキルは **OpenAI Codex CLI** （tmux ペインでインタラクティブ起動）と連携し、Claude Code と Codex が協調してペアプログラミングを行う。

- **Claude Code**: 実装担当（主導）
- **Codex CLI**: アプローチ相談 + コードレビュー担当（tmux ペインでインタラクティブ通信）
- **tmux**: 視覚的分離（左: Claude、右: Codex）
- **相談タイミング**: 全フェーズ（要件分析、設計、実装、レビュー）

## v2.0.0 アーキテクチャ

```
skills/codex-collab/
├── SKILL.md                    # このファイル
├── lib/                        # コアライブラリ（純粋関数層）
│   ├── protocol.sh             # プロトコル検証・正規化・ルーティング判定
│   ├── session_state.sh        # セッション状態管理（JSON + mkdir ロック）
│   └── retry.sh                # 指数バックオフ付きリトライ
├── scripts/                    # 実行層（I/O層）
│   ├── collab.sh               # 統合エントリポイント（推奨）
│   ├── tmux_manager.sh         # tmux操作
│   ├── parse_response.sh       # 生テキスト→構造化変換（jq使用）
│   ├── setup_pair_env.sh       # ブートストラップ
│   ├── send_to_codex.sh        # [非推奨] → collab.sh send
│   ├── invoke_codex.sh         # [非推奨] → collab.sh send (非推奨)
│   ├── visual_collab.sh        # [非推奨] → collab.sh interactive
│   └── capture_codex_output.sh # [非推奨] → collab.sh recv
├── deprecated/                 # 非推奨スクリプトのバックアップ
├── references/                 # テンプレート＆プロトコル仕様
│   ├── session_schema.json     # セッション状態スキーマ
│   └── *.md                    # 各フェーズテンプレート
└── tests/                      # テストスイート
```

## 前提条件

| 条件 | 必須 | 説明 |
|------|------|------|
| `codex` CLI | ○ | `npm install -g @openai/codex` (OpenAI Codex CLI) |
| Codex 認証 | ○ | `codex login` で ChatGPT 認証、または `OPENAI_API_KEY` 環境変数 |
| `tmux` | ○ | `brew install tmux` / `apt install tmux` |
| `jq` | ○ | `brew install jq` / `apt install jq` (レスポンス解析用) |
| `git` | ○ | 差分生成用 |

## 出力ファイル

| ファイル | 説明 |
|---------|------|
| `.codex-collab/sessions/{session_id}/state.json` | セッション状態 |
| `.codex-collab/sessions/{session_id}/transcript.log` | やり取りログ |
| `.codex-collab/logs/YYYY-MM-DD-feature-session.md` | セッションログ（詳細） |

## クイックスタート

### 統合エントリポイント（推奨）

```bash
# セッション初期化
./scripts/collab.sh init --feature "認証機能"

# プロンプト送信（DESIGNフェーズ）
./scripts/collab.sh send /tmp/prompt.txt --phase DESIGN

# レスポンス受信
./scripts/collab.sh recv

# セッション状態確認
./scripts/collab.sh status

# インタラクティブモード
./scripts/collab.sh interactive

# セッション再開
./scripts/collab.sh resume

# セッション終了
./scripts/collab.sh end
```

### ペアプログラミング環境起動

```bash
# ワンコマンド起動
./scripts/setup_pair_env.sh

# セッション名を指定する場合
./scripts/setup_pair_env.sh my-feature ~/projects/app
```

## ワークフロー

### Phase 1: 要件分析（Claude ⇔ Codex）

```
1. ユーザー要求の分析
2. [CONSULT:REQUIREMENTS] → Codex に要件明確化を相談
   - 不明点の特定
   - 考慮すべき観点の確認
3. Codex から [RESPONSE:REQUIREMENTS] 受信
   - CLARIFICATION_QUESTIONS: 追加で確認すべき質問
   - CONSIDERATIONS: 考慮すべき非機能要件等
4. AskUserQuestion: 追加確認（Codex の質問含む）
5. 要件の最終確定
6. セッションログに記録
```

### Phase 2: 設計・アプローチ（Claude ⇔ Codex）

```
1. 初期設計案の作成
2. [CONSULT:DESIGN] → Codex に設計レビューを依頼
   - アーキテクチャ選択
   - 技術スタック
   - 実装戦略
3. Codex から [RESPONSE:DESIGN] 受信
   - ASSESSMENT: 設計の妥当性評価
   - RISKS: リスクと課題
   - ALTERNATIVES: 代替案
   - RECOMMENDATION: 推奨事項
4. 設計の調整・決定
5. AskUserQuestion: 最終アプローチ承認
6. セッションログに記録
```

### Phase 3: 実装（Claude ⇔ Codex）

```
1. 合意アプローチに基づく実装開始
2. 実装中の疑問発生時:
   [CONSULT:IMPLEMENTATION] → Codex に技術相談
   - 実装パターンの選択
   - ライブラリの使用方法
   - エッジケースの処理
3. Codex から [RESPONSE:IMPLEMENTATION] 受信
   - ADVICE: 技術的アドバイス
   - PATTERNS: 推奨パターン
   - CAVEATS: 注意点
4. 実装継続
5. インクリメンタルコミット
6. セッションログに進捗記録
```

### Phase 4: コードレビュー（Claude → Codex）

```
1. git diff で変更内容取得
2. [REQUEST:REVIEW] → Codex にコードレビュー依頼
   - 変更ファイル一覧
   - 実装サマリー
   - 特に見てほしい点
3. Codex から [RESPONSE:REVIEW] 受信
   - STRENGTHS: 良い点
   - ISSUES: 問題点（Critical/Important/Minor）
   - SUGGESTIONS: 改善提案
4. レビュー結果の整理
5. セッションログに記録
```

### Phase 5: 修正と繰り返し（Claude ⇔ ユーザー）

```
1. Critical/Important issues を修正
2. 修正内容の確認
3. AskUserQuestion: 再レビュー必要か?
4. 必要なら Phase 4 へ戻る（無制限）
5. 完了ならセッションサマリー生成
6. 最終ログ記録
```

## 通信プロトコル

### Claude → Codex

| タグ | 用途 | 応答フォーマット |
|------|------|------------------|
| `[CONSULT:REQUIREMENTS]` | 要件明確化相談 | CLARIFICATION_QUESTIONS, CONSIDERATIONS |
| `[CONSULT:DESIGN]` | 設計レビュー依頼 | ASSESSMENT, RISKS, ALTERNATIVES, RECOMMENDATION |
| `[CONSULT:IMPLEMENTATION]` | 実装中の技術相談 | ADVICE, PATTERNS, CAVEATS |
| `[REQUEST:REVIEW]` | コードレビュー依頼 | STRENGTHS, ISSUES, SUGGESTIONS |

### Codex → Claude（双方向）

| タグ | 用途 |
|------|------|
| `[CONSULT:CLAUDE:VERIFICATION]` | 実装方針の確認 |
| `[CONSULT:CLAUDE:CONTEXT]` | 追加コンテキスト要求 |

## コアライブラリ (lib/)

### protocol.sh

プロトコル検証・正規化を行う純粋関数（副作用なし）。
**注意**: 引数はファイルパスで渡す（文字列直接ではない）。

```bash
# メッセージタイプ検出（ファイルパスを指定）
./lib/protocol.sh detect-type /tmp/message.txt
# → TYPE=CONSULT KIND=DESIGN

# リクエスト検証（フェーズ + ファイルパス）
./lib/protocol.sh validate-request REVIEW /tmp/prompt.txt
# → {"valid":true,"type":"REQUEST","kind":"REVIEW","marker":"[REQUEST:REVIEW]"}

# コールバック検出（ファイルパスを指定）
./lib/protocol.sh detect-callbacks /tmp/response.txt
# → [{"type":"VERIFICATION","line":5}]

# マーカー抽出（ファイルパスを指定）
./lib/protocol.sh extract-markers /tmp/response.txt
# → JSON形式でマーカー一覧
```

### session_state.sh

セッション状態管理（mkdir ロック + 原子的書き込み）。
**注意**: 引数はフラグ形式で渡す（位置引数や JSON ではない）。

```bash
# セッション初期化
./lib/session_state.sh init \
  --feature "user-auth" \
  --project "my-app" \
  --tmux-session "pair-prog"

# 状態取得（セッション ID を指定、省略時は現在のセッション）
./lib/session_state.sh get
./lib/session_state.sh get codex-collab-12345

# 状態更新（フラグで指定）
./lib/session_state.sh update \
  --phase IMPLEMENTATION \
  --status in_progress

# 相談記録追加（フラグで指定）
./lib/session_state.sh add-consultation \
  --phase DESIGN \
  --prompt-file /tmp/prompt.txt \
  --response-file /tmp/response.txt

# アクティブセッション一覧
./lib/session_state.sh list-active

# 古いセッションクリーンアップ
./lib/session_state.sh cleanup --older-than 7d
```

### retry.sh

指数バックオフ付きリトライ。

```bash
# リトライ付き実行（tmux 送信コマンド等に使用）
./lib/retry.sh execute_with_retry "./scripts/tmux_manager.sh send session 1 'prompt'" 3

# レート制限チェック
./lib/retry.sh check-rate-limit "rate_limit_exceeded"
# → detected / not_detected
```

## スクリプト (scripts/)

### collab.sh（統合エントリポイント）

全機能を統合したメインスクリプト。

```bash
./scripts/collab.sh <command> [options]

コマンド:
  init         セッション初期化
  send         プロンプト送信
  recv         レスポンス受信
  status       セッション状態表示
  resume       中断セッション再開
  end          セッション終了
  interactive  インタラクティブモード
  help         ヘルプ表示
```

### tmux_manager.sh

tmux セッションの作成・管理・終了を行う。

```bash
# 使用例
./tmux_manager.sh current        # 現在のセッション名を取得
./tmux_manager.sh get-or-create  # 現在のセッション取得または新規作成
./tmux_manager.sh start          # 新規セッション開始
./tmux_manager.sh send $SESSION 1 "command"  # Codexペインにコマンド送信
./tmux_manager.sh capture $SESSION 1         # Codexペインの出力取得
./tmux_manager.sh stop $SESSION  # セッション終了
```

### parse_response.sh

構造化レスポンスを解析する（jq 使用）。

```bash
# JSONフォーマットで全セクション出力
./parse_response.sh /tmp/output.txt --json

# 特定セクション抽出
./parse_response.sh /tmp/output.txt ASSESSMENT
./parse_response.sh /tmp/output.txt ISSUES
```

## 非推奨スクリプトの移行ガイド

v2.0.0 で以下のスクリプトは非推奨になりました。

| 非推奨 | 移行先 |
|--------|--------|
| `send_to_codex.sh` | `collab.sh send <prompt_file> --phase <phase>` |
| `invoke_codex.sh` | `collab.sh send <prompt_file> (非推奨)` |
| `visual_collab.sh` | `collab.sh interactive` |
| `capture_codex_output.sh` | `collab.sh recv` |

### 移行例

```bash
# Before (v1.x)
./send_to_codex.sh $SESSION /tmp/prompt.txt /tmp/output.txt

# After (v2.0)
./collab.sh send /tmp/prompt.txt --phase DESIGN

# Before (v1.x)
./invoke_codex.sh /tmp/prompt.txt /tmp/output.txt --timeout 600

# After (v2.0)
./collab.sh send /tmp/prompt.txt (非推奨) --timeout 600

# Before (v1.x)
./visual_collab.sh start
./visual_collab.sh send "メッセージ"

# After (v2.0)
./collab.sh interactive
```

## セッション状態スキーマ

```json
{
  "schema_version": 1,
  "session_id": "codex-collab-12345",
  "status": "in_progress",
  "current_phase": "DESIGN",
  "feature": "認証機能",
  "project": "my-app",
  "working_directory": "/path/to/project",
  "tmux_session": "pair-prog",
  "created_at": "2026-01-31T12:00:00Z",
  "updated_at": "2026-01-31T12:30:00Z",
  "phases": {
    "REQUIREMENTS": {
      "status": "completed",
      "started_at": "2026-01-31T12:00:00Z",
      "completed_at": "2026-01-31T12:15:00Z",
      "consultations": []
    },
    "DESIGN": {
      "status": "in_progress",
      "started_at": "2026-01-31T12:15:00Z",
      "consultations": []
    },
    "IMPLEMENTATION": {"status": "pending", "consultations": []},
    "REVIEW": {"status": "pending", "consultations": []}
  },
  "pending_callbacks": [],
  "error_log": []
}
```

## エラーハンドリング

| エラー | 検出方法 | 対応 |
|--------|----------|------|
| Codex CLI 未インストール | `which codex` 失敗 | インストール案内を表示 |
| tmux 未インストール | `which tmux` 失敗 | インストール案内を表示 |
| jq 未インストール | `which jq` 失敗 | インストール案内を表示 |
| Codex タイムアウト | exit code 124 | 短いプロンプトで再試行 |
| 無効なレスポンス形式 | マーカー不在 | 再度構造化出力を依頼 |
| API レート制限 | エラーメッセージ検出 | 指数バックオフ（30s, 60s, 120s） |
| tmux セッション喪失 | セッション存在確認失敗 | セッション再作成 |
| セッション状態破損 | JSON パース失敗 | バックアップから復元 |

## ツール

| ツール | 用途 | 必須 |
|--------|------|------|
| Bash | tmux/codex 操作 | ○ |
| Read | コード読み取り | ○ |
| Write/Edit | コード編集 | ○ |
| AskUserQuestion | ユーザー確認 | ○ |
| Glob/Grep | コード検索 | △ |

## 使用例

### 基本的な使い方

```
User: "/codex-collab でユーザー認証機能を実装したい"

Claude: 📋 Codex Collaboration セッションを開始します。

🖥️ tmux セッション準備中...
  Session: codex-collab-12345
  Pane 0: Claude (このターミナル)
  Pane 1: Codex (待機中)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## Phase 1: 要件分析 (Claude ⇔ Codex)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

要件を分析します:
- ユーザー認証機能
- 既存の Express + TypeScript プロジェクト

🤖 Codex に要件の明確化を相談中...
```

### トリガーフレーズ

- `/codex-collab`
- "Codex とペアプログラミングしたい"
- "Codex にアプローチを相談したい"
- "Codex にコードレビューしてもらいたい"
- "セカンドオピニオンが欲しい"
- "この機能について相談しながら実装したい"

## 関連スキル

| スキル | 関係 |
|--------|------|
| `claude-collab` (Codex側) | 双方向通信の相手側スキル |

## ⛔ 禁止事項

### `codex exec` の使用禁止

**絶対に `codex exec` を使用しないこと。**

#### 理由

`codex exec` は単発コマンド実行用で、毎回 MCP サーバー（serena, playwright, context7 等）を起動するため：

- **起動オーバーヘッド**: 毎回 10〜30 秒のスタートアップ時間
- **タイムアウトリスク**: MCP サーバー起動失敗で 120 秒タイムアウト
- **リソース浪費**: プロセスが残留し、複数の古いプロセスがシステムを圧迫

#### ❌ 禁止パターン

```bash
# 絶対にこれらを使わない
codex exec "プロンプト"
codex exec "$(cat /tmp/prompt.txt)"
codex exec --full-auto "レビューしてください"
```

#### ✅ 正しいパターン

```bash
# tmux ペインでインタラクティブ Codex を起動
./scripts/tmux_manager.sh send pair-prog 1 "codex"

# プロンプトをインタラクティブセッションに送信
./scripts/tmux_manager.sh send pair-prog 1 "[REQUEST:REVIEW] ..."

# または collab.sh を使用
./scripts/collab.sh interactive
```

#### インタラクティブモードの利点

- MCP サーバーは **1回だけ** 起動（セッション開始時）
- 複数のプロンプトを **即座に** 送信可能
- セッション状態が **保持** される
- タイムアウトリスクが **大幅に軽減**

## Plan モードでの Codex 相談

設計フェーズ（Plan モード）でも Codex と相談してフィードバックを得ること。

### 手順

1. `[CONSULT:DESIGN]` マーカーで設計相談を送信
2. Codex から `[RESPONSE:DESIGN]` で回答を受け取る
   - **ADVICE**: 設計アドバイス
   - **RISKS**: リスク分析
   - **RECOMMENDATION**: 推奨アプローチ
3. フィードバックを計画に反映

### 例

```
[CONSULT:DESIGN]

## 設計相談: ファイル削除戦略

### 現状
- rsync で --delete がないため不要ファイルが残る

### 検討している方針
- 方針A: --delete を単純追加
- 方針B: 削除プレビュー表示

### 質問
1. リスクはありますか？
2. 推奨アプローチは？

[RESPONSE:DESIGN] 形式で回答してください。
```

## 注意事項

- tmux ペインで `codex` をインタラクティブに起動すること
- `--full-auto` オプションで低干渉モード
- `--output-last-message` で最終メッセージをファイル出力可能
- レビューサイクルは無制限（ユーザー判断で終了）
- セッションログは詳細（全やり取り記録）
- macOS/Linux 両対応（flock 非依存）

## 変更履歴

### v2.0.5 (2026-01-31)
- **SKILL.md 追加**: Plan モードでの Codex 相談セクションを追加

### v2.0.4 (2026-01-31)
- **SKILL.md 修正**: protocol.sh 出力例の大文字/小文字を実装に合わせて修正
- **SKILL.md 修正**: detect-callbacks の出力例を JSON 配列形式に修正

### v2.0.3 (2026-01-31)
- **collab.sh 修正**: `clear` コマンドではなく `tmux clear-history` で履歴クリア（Codex への入力誤送信を防止）
- **SKILL.md 修正**: protocol.sh / session_state.sh の使用例を実際の CLI 仕様に合わせて修正
- **SKILL.md 修正**: セッション状態スキーマ例を実装と一致するように修正

### v2.0.2 (2026-01-31)
- **collab.sh 修正**: 送信前にマーカー誤検知防止の対策追加（v2.0.3 で改善）
- **session_state.sh 修正**:
  - `VALID_STATUSES` に `initializing`, `paused` を追加
  - `list_active` で `initializing` 状態も認識
  - `cleanup_sessions` でタイムスタンプ解析失敗時の誤削除を防止
- **SKILL.md 修正**: 未実装オプション `--wait`, `--mode direct` を削除

### v2.0.1 (2026-01-31)
- **⛔ codex exec 禁止ルール追加**: MCP サーバー起動オーバーヘッド回避のため
- **collab.sh 修正**: codex exec → tmux インタラクティブ方式に変更
- **session_state.sh 強化**:
  - `validate_phase()` / `validate_status()` バリデーション追加
  - `parse_iso_timestamp()` クロスプラットフォーム日時パース（macOS/Linux/Python フォールバック）
- **SKILL.md 更新**: 禁止事項セクション追加、codex exec 記述を全て修正

### v2.0.0 (2026-01-31)
- アーキテクチャ刷新: lib/（純粋関数）と scripts/（I/O層）の分離
- `collab.sh` 統合エントリポイント追加
- `lib/protocol.sh` プロトコル検証ライブラリ追加
- `lib/session_state.sh` セッション状態管理追加（mkdir ロック）
- `lib/retry.sh` 指数バックオフ付きリトライ追加
- `parse_response.sh` を jq ベースに強化
- 非推奨スクリプトに警告追加
- macOS 互換性改善（flock 非依存、bash 3.x 対応）

### v1.0.0
- 初期リリース
