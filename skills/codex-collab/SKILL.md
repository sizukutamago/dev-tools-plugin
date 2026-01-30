---
name: codex-collab
description: Use when the user asks to "pair program with Codex", "get Codex review", "collaborate with Codex", "consult Codex on approach", "second opinion from Codex", "AI pair programming", or any development task that would benefit from a second AI perspective. Enables Claude Code as primary implementer with Codex as consultant and code reviewer using tmux split-pane visualization. Consults Codex at ALL phases: requirements, design, implementation, and review.
version: 1.0.0
---

# Codex Collaboration

Claude Code と Codex による双方向ペアプログラミングスキル。

## 概要

- **Claude Code**: 実装担当（主導）
- **Codex**: アプローチ相談 + コードレビュー担当
- **tmux**: 視覚的分離（左: Claude、右: Codex）
- **相談タイミング**: 全フェーズ（要件分析、設計、実装、レビュー）

## 前提条件

| 条件 | 必須 | 説明 |
|------|------|------|
| `codex` CLI | ○ | `npm install -g @openai/codex` |
| `OPENAI_API_KEY` | ○ | 環境変数に設定 |
| `tmux` | ○ | `brew install tmux` / `apt install tmux` |
| `git` | ○ | 差分生成用 |

## 出力ファイル

| ファイル | 説明 |
|---------|------|
| `.codex-collab/session/current_session.json` | 現在のセッション状態 |
| `.codex-collab/logs/YYYY-MM-DD-feature-session.md` | セッションログ（詳細） |

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

## ツール

| ツール | 用途 | 必須 |
|--------|------|------|
| Bash | tmux/codex 操作 | ○ |
| Read | コード読み取り | ○ |
| Write/Edit | コード編集 | ○ |
| AskUserQuestion | ユーザー確認 | ○ |
| Glob/Grep | コード検索 | △ |

## スクリプト

### tmux_manager.sh

tmux セッションの作成・管理・終了を行う。

```bash
# 使用例
./tmux_manager.sh start          # セッション開始、ペイン分割
./tmux_manager.sh send $SESSION 1 "command"  # Codexペインにコマンド送信
./tmux_manager.sh capture $SESSION 1         # Codexペインの出力取得
./tmux_manager.sh stop $SESSION  # セッション終了
```

### send_to_codex.sh

Codex へのプロンプト送信を行う。

```bash
# 使用例
./send_to_codex.sh $SESSION /tmp/prompt.txt /tmp/output.txt
```

### capture_codex_output.sh

Codex の出力を取得する。

```bash
# 使用例
./capture_codex_output.sh /tmp/output.txt 120  # 120秒タイムアウト
```

### invoke_codex.sh

tmux なしで Codex を直接実行する。

```bash
# 使用例
./invoke_codex.sh /tmp/prompt.txt /tmp/output.txt
```

### parse_response.sh

構造化レスポンスを解析する。

```bash
# 使用例
./parse_response.sh /tmp/output.txt ASSESSMENT
./parse_response.sh /tmp/output.txt ISSUES
```

## セッション開始手順

```bash
# 1. 前提条件確認
which tmux && which codex && echo $OPENAI_API_KEY

# 2. tmux セッション開始
SESSION=$(./scripts/tmux_manager.sh start)
echo "Session: $SESSION"

# 3. セッションにアタッチ（別ターミナルで確認したい場合）
tmux attach-session -t $SESSION
```

## エラーハンドリング

| エラー | 検出方法 | 対応 |
|--------|----------|------|
| Codex CLI 未インストール | `which codex` 失敗 | インストール案内を表示 |
| tmux 未インストール | `which tmux` 失敗 | インストール案内を表示 |
| Codex タイムアウト | capture スクリプトの exit code | 短いプロンプトで再試行 |
| 無効なレスポンス形式 | マーカー不在 | 再度構造化出力を依頼 |
| API レート制限 | エラーメッセージ検出 | 指数バックオフ（30s, 60s, 120s） |
| tmux セッション喪失 | セッション存在確認失敗 | セッション再作成 |

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

## 注意事項

- Codex CLI は `codex exec "prompt"` で実行（`-p` はプロファイルフラグ）
- `--full-auto` オプションで低干渉モード
- `--output-last-message` で最終メッセージをファイル出力可能
- レビューサイクルは無制限（ユーザー判断で終了）
- セッションログは詳細（全やり取り記録）
