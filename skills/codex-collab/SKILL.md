---
name: codex-collab
description: Chat with Codex via tmux for pair programming. Use when user wants to collaborate with Codex, get second opinion, design consultation, code review, or pair program with AI.
version: 3.13.0
---

# Codex Chat

Claude Code と Codex が tmux でチャットするスキル。

## 前提条件（実行前に確認）

- **tmux セッション内**で実行すること（`tmux` コマンドが動作する環境）
- `codex` CLI がインストール済み
- Codex 認証済み（`codex login` または `OPENAI_API_KEY`）

## 役割分担（重要）

| AI | 役割 | 担当タスク |
|----|------|-----------|
| **Claude Code** | 実装担当 | コード作成・編集・ファイル操作・テスト実行 |
| **Codex** | 相談役 | 設計相談・レビュー・セカンドオピニオン・質問回答 |

**Codex に実装を依頼しないこと。** Codex から設計提案やレビューを受けて、Claude Code が実装する。

## セットアップ

### Codex ペイン作成

現在のウィンドウを水平分割し、右側ペインで Codex を起動:

```bash
# 3つの Bash コマンドを順番に実行（send-keys は && で連結しないこと）
tmux split-window -h
tmux send-keys "codex"
tmux send-keys Enter
```

- `split-window -h`: 水平分割（左右に分かれる）
- 新しいペインがアクティブになるが、Claude Code は元のペインで継続
- **重要**: `tmux send-keys` は `&&` で連結せず、別々の Bash コマンドとして実行すること
  - `sleep && tmux capture-pane` のような組み合わせは OK

### ペイン番号の確認

```bash
tmux list-panes -F "#{pane_index}: #{pane_current_command}"
```

通常、Claude Code が pane 0 または 1、Codex が pane 1 または 2 になる。

**重要**: 以降のコマンド例では `:.1` を使用しているが、**実際のペイン番号に置き換えること**。`list-panes` の結果で Codex が動作しているペイン番号を確認し、`:.1` → `:.2` などに適宜変更する。

## チャット

### Codex に質問

```bash
# 2つの Bash コマンドを順番に実行（&& で連結しないこと）
tmux send-keys -t :.1 "質問内容"
tmux send-keys -t :.1 Enter
```

- `-t :.1`: 現在のウィンドウのペイン 1 を指定
- **重要**: テキスト送信と Enter 送信は別々の Bash コマンドとして実行
- `&&` で連結すると Enter が送信されないことがある

### Codex の返信を確認（待機付き）

```bash
sleep 30 && tmux capture-pane -t :.1 -p -S -100
```

- `-S -100`: スクロールバッファから過去100行を取得
- 応答が長い場合は `sleep` の秒数を増やす
- 「Working」表示中は処理中なので追加で待機する

### Codex ペイン終了

```bash
tmux kill-pane -t :.1
```

## ワークフロー

1. `/codex-collab` でペイン作成・Codex 起動
2. Codex に**相談・質問**を送信
3. 返信を確認（sleep で待機）
4. Codex の提案を受けて **Claude Code が実装**
5. 必要に応じて Codex にレビュー依頼
6. ペイン終了

## 使用例

### 設計相談 → Claude Code が実装

```
User: "Codex と認証機能について相談したい"

Claude:
1. Codex ペイン作成（3つの Bash コマンドを順番に実行）
   Bash(tmux split-window -h)
   Bash(tmux send-keys "codex")
   Bash(tmux send-keys Enter)
   Bash(sleep 5)  # Codex 起動待ち

2. Codex に設計相談（2つの Bash コマンドを順番に実行）
   Bash(tmux send-keys -t :.1 "JWT vs セッションベース認証、どちらを推奨しますか？理由も教えて")
   Bash(tmux send-keys -t :.1 Enter)

3. 返信を確認（待機後にキャプチャ）
   Bash(sleep 30)
   Bash(tmux capture-pane -t :.1 -p -S -100)

4. Codex の提案を受けて Claude Code が実装
   Write/Edit ツールでコード作成

5. 実装後、Codex にレビュー依頼（2つの Bash コマンドを順番に実行）
   Bash(tmux send-keys -t :.1 "この実装をレビューして: [コード概要]")
   Bash(tmux send-keys -t :.1 Enter)

6. 終了（ペインのみ閉じる）
   Bash(tmux kill-pane -t :.1)
```

### Codex への適切な質問例

- 「この設計アプローチについてどう思う？」
- 「AとBどちらのパターンを推奨する？」
- 「この実装のセキュリティリスクは？」
- 「パフォーマンス改善のアイデアある？」
- 「このコードをレビューして」

### 不適切な依頼例（避けること）

- 「このコードを実装して」
- 「ファイルを作成して」
- 「テストを書いて」

## 注意事項

- `codex exec` は使わないこと（MCP サーバー起動オーバーヘッド回避）
- **ペイン**でインタラクティブモードを使用（バックグラウンドではない）
- 長い質問はファイル経由で送信可能
- 「Working」表示中は追加で待機が必要
- **`&&` で連結しないこと**: tmux コマンドは別々の Bash 呼び出しで実行

## Codex 固有の環境変数

| 環境変数 | 説明 | デフォルト |
|---------|------|-----------|
| `CODEX_WAIT_SHORT` | 短い質問の待機時間（秒） | 30 |
| `CODEX_WAIT_LONG` | 複雑な分析の待機時間（秒） | 120 |
| `CODEX_POLL_INTERVAL` | ポーリング間隔（秒） | 30 |
| `CODEX_MAX_RETRIES` | 最大リトライ回数 | 5 |

## 待機時間・リカバリー

待機時間の目安、ポーリング戦略、タイムアウト時の対応、自動リカバリーフロー（サーキットブレーカー含む）は共通ガイドを参照:

> **参照**: `skills/tmux-ai-chat/references/recovery-guide.md`

Codex 固有の完了判定: プロンプト `›` が最終行に表示されたら応答完了。
