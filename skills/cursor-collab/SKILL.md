---
name: cursor-collab
description: Chat with Cursor Agent via tmux for pair programming. Use when user wants to collaborate with Cursor, get second opinion, design consultation, or code review.
version: 1.2.0
---

# Cursor Agent Chat

Claude Code と Cursor Agent が tmux でチャットするスキル。

## 前提条件（実行前に確認）

- **tmux セッション内**で実行すること（`tmux` コマンドが動作する環境）
- `cursor-agent` CLI がインストール済み
- Cursor Agent 認証済み

## 役割分担（重要）

| AI | 役割 | 担当タスク |
|----|------|-----------|
| **Claude Code** | 実装担当 | コード作成・編集・ファイル操作・テスト実行 |
| **Cursor Agent** | 相談役 | 設計相談・レビュー・セカンドオピニオン・質問回答 |

**Cursor Agent に実装を依頼しないこと。** Cursor Agent から設計提案やレビューを受けて、Claude Code が実装する。

## セットアップ

### Cursor Agent ペイン作成

現在のウィンドウを水平分割し、右側ペインで Cursor Agent を起動:

```bash
# 3つの Bash コマンドを順番に実行（send-keys は && で連結しないこと）
tmux split-window -h
tmux send-keys "cursor-agent"
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

通常、Claude Code が pane 0 または 1、Cursor Agent が pane 1 または 2 になる。

**注意**: 以降の例では `:.1` を使用しているが、実際のペイン番号は `list-panes` の結果に合わせて置換すること。

## チャット

### Cursor Agent に質問

```bash
# 2つの Bash コマンドを順番に実行（&& で連結しないこと）
tmux send-keys -t :.1 "質問内容"
tmux send-keys -t :.1 Enter
```

- `-t :.1`: 現在のウィンドウのペイン 1 を指定（環境に応じて変更）
- **重要**: テキスト送信と Enter 送信は別々の Bash コマンドとして実行
- `&&` で連結すると Enter が送信されないことがある

### Cursor Agent の返信を確認（待機付き）

```bash
sleep 30 && tmux capture-pane -t :.1 -p -S -100
```

- `-S -100`: スクロールバッファから過去100行を取得
- 応答が長い場合は `sleep` の秒数を増やす
- 処理中表示がある場合は追加で待機する

### Cursor Agent ペイン終了

```bash
tmux kill-pane -t :.1
```

## ワークフロー

1. `/cursor-collab` でペイン作成・Cursor Agent 起動
2. Cursor Agent に**相談・質問**を送信
3. 返信を確認（sleep で待機）
4. Cursor Agent の提案を受けて **Claude Code が実装**
5. 必要に応じて Cursor Agent にレビュー依頼
6. ペイン終了

## 使用例

### 設計相談 → Claude Code が実装

```
User: "Cursor Agent と認証機能について相談したい"

Claude:
1. Cursor Agent ペイン作成（3つの Bash コマンドを順番に実行）
   Bash(tmux split-window -h)
   Bash(tmux send-keys "cursor-agent")
   Bash(tmux send-keys Enter)
   Bash(sleep 5)  # Cursor Agent 起動待ち

2. Cursor Agent に設計相談（2つの Bash コマンドを順番に実行）
   Bash(tmux send-keys -t :.1 "JWT vs セッションベース認証、どちらを推奨しますか？理由も教えて")
   Bash(tmux send-keys -t :.1 Enter)

3. 返信を確認（待機後にキャプチャ）
   Bash(sleep 30)
   Bash(tmux capture-pane -t :.1 -p -S -100)

4. Cursor Agent の提案を受けて Claude Code が実装
   Write/Edit ツールでコード作成

5. 実装後、Cursor Agent にレビュー依頼（2つの Bash コマンドを順番に実行）
   Bash(tmux send-keys -t :.1 "この実装をレビューして: [コード概要]")
   Bash(tmux send-keys -t :.1 Enter)

6. 終了（ペインのみ閉じる）
   Bash(tmux kill-pane -t :.1)
```

### Cursor Agent への適切な質問例

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

- 非対話モード（ヘッドレス）は使わない。対話 UI で運用すること
- **ペイン**でインタラクティブモードを使用（バックグラウンドではない）
- 処理中表示がある場合は追加で待機が必要
- **`tmux send-keys` は `&&` で連結しないこと**:
  - 各 `tmux send-keys` は個別の Bash コマンドとして実行する
  - 注: `sleep && tmux capture-pane` のような非 send-keys コマンドの連結は問題ない

### 長い質問をファイル経由で送信

```bash
# 質問をファイルに保存
cat > /tmp/question.txt << 'EOF'
ここに長い質問を書く。
複数行でも可。
EOF

# tmux 名前付きバッファ経由で送信（既存バッファを上書きしない）
tmux load-buffer -b cursor_q /tmp/question.txt
tmux paste-buffer -t :.1 -b cursor_q -d  # -d でバッファ削除
tmux send-keys -t :.1 Enter
```

## 待機時間・リカバリー

待機時間の目安、ポーリング戦略、タイムアウト時の対応、リカバリー手順は共通ガイドを参照:

> **参照**: `skills/tmux-ai-chat/references/recovery-guide.md`
