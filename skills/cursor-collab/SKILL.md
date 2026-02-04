---
name: cursor-collab
description: Chat with Cursor Agent via tmux for pair programming. Use when user wants to collaborate with Cursor, get second opinion, design consultation, or code review.
version: 1.1.0
---

# Cursor Agent Chat

Claude Code と Cursor Agent が tmux でチャットするスキル。

## 役割分担（重要）

| AI | 役割 | 担当タスク |
|----|------|-----------|
| **Claude Code** | 実装担当 | コード作成・編集・ファイル操作・テスト実行 |
| **Cursor Agent** | 相談役 | 設計相談・レビュー・セカンドオピニオン・質問回答 |

**Cursor Agent に実装を依頼しないこと。** Cursor Agent から設計提案やレビューを受けて、Claude Code が実装する。

## 前提条件

| 条件 | 必須 | 説明 |
|------|------|------|
| `cursor-agent` CLI | ○ | Cursor Agent CLI（Cursor に付属） |
| Cursor 認証 | ○ | `cursor-agent login` または Cursor アカウント |
| `tmux` | ○ | `brew install tmux` |
| tmux セッション | ○ | tmux セッション内で実行すること |

### 動作確認

```bash
# cursor-agent がインストールされているか確認
which cursor-agent || echo "cursor-agent not found"
cursor-agent --version
```

## ⚠️ セキュリティ注意

**Cursor Agent は外部 AI サービスです。以下を送信しないこと:**
- API キー、パスワード、認証情報
- 社外秘・機密情報
- 個人情報（PII）

## アーキテクチャ

**重要**: Cursor Agent はバックグラウンドプロセスではなく、**別ペイン**で起動する。

```
┌─────────────────────┬─────────────────────┐
│                     │                     │
│   Claude Code       │   Cursor Agent      │
│   (メインペイン)    │   (サブペイン)      │
│                     │                     │
│   実装作業          │   相談・レビュー    │
│                     │                     │
└─────────────────────┴─────────────────────┘
```

これにより:
- 両方の出力をリアルタイムで確認可能
- ユーザーが手動で Cursor Agent とやり取りすることも可能
- セッション終了時にペインを閉じるだけで済む

## セットアップ

### Cursor Agent ペイン作成

現在のウィンドウを水平分割し、右側ペインで Cursor Agent を起動:

```bash
# 3つの Bash コマンドを順番に実行（&& で連結しないこと）
tmux split-window -h
tmux send-keys "cursor-agent"
tmux send-keys Enter
```

- `split-window -h`: 水平分割（左右に分かれる）
- 新しいペインがアクティブになるが、Claude Code は元のペインで継続
- **重要**: `&&` で連結せず、別々の Bash コマンドとして実行すること

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
- 応答が長い場合は `sleep` の秒数を増やす（最大待機時間は下表参照）
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

- ❌「このコードを実装して」
- ❌「ファイルを作成して」
- ❌「テストを書いて」

## 注意事項

- 非対話モード（ヘッドレス）は使わない。対話 UI で運用すること
- **ペイン**でインタラクティブモードを使用（バックグラウンドではない）
- 処理中表示がある場合は追加で待機が必要
- **`tmux send-keys` は `&&` で連結しないこと**:
  - 特に Enter 送信（`tmux send-keys Enter`）を `&&` で連結すると送信されないことがある
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

## 待機時間の目安

| 質問の種類 | 推奨待機時間 | 最大待機時間 | 備考 |
|-----------|-------------|-------------|------|
| 短い質問 | 30秒 | 60秒 | Yes/No、簡単な確認 |
| コードレビュー | 60秒 | 120秒 | 小〜中規模のコード |
| 設計相談 | 90秒 | 180秒 | アーキテクチャ、パターン選択 |
| 複雑な分析 | 120秒 | 240秒 | 大規模コード、詳細な比較 |

**ポーリング戦略**:
1. 初回待機（上記の推奨待機時間）
2. `tmux capture-pane` で出力確認
3. 以下の場合は追加30秒待機（最大待機時間に達するまで繰り返し）:
   - 処理中やスピナー表示中
   - 出力が途中で終わっている（閉じ括弧・コードフェンス未完、文章が途切れている）
   - プロンプトに戻っていない（記号は環境により異なる）
4. 最大待機時間を超えたらタイムアウトとして処理

**タイムアウト時の対応**:

| 状態 | 判定方法 | 対応 |
|------|----------|------|
| capture出力が空 | `tmux capture-pane` の結果が空 | Enter で再プロンプト |
| プロンプト待ち | プロンプト記号で止まっている | Enter で再プロンプト |
| 処理中のまま固まった | 表示が変化しない | C-c で中断 → Enter |
| 完全に無応答 | 上記すべて失敗 | Cursor Agent 再起動（ペイン終了→再作成） |

```bash
# 出力が空/プロンプト待ちの場合
tmux send-keys -t :.1 Enter
sleep 30
tmux capture-pane -t :.1 -p -S -100

# それでも応答がない場合（C-c で中断）
tmux send-keys -t :.1 C-c
sleep 2
tmux send-keys -t :.1 Enter
```

## エラーハンドリング

| 状況 | 症状 | 対応 |
|------|------|------|
| タイムアウト | capture出力が空/変化なし | 追加30-60秒待機、または `tmux send-keys -t :.1 Enter` で再プロンプト |
| Cursor Agent 未応答 | プロンプトが表示されたまま | `tmux send-keys -t :.1 Enter` で再送信 |
| ペイン消失 | `can't find pane` エラー | セットアップを再実行 |
| 接続エラー | API エラーメッセージ | `cursor-agent` を再起動（ペイン終了→再作成） |

### リカバリー手順

```bash
# ペインが消失した場合
tmux split-window -h
tmux send-keys "cursor-agent"
tmux send-keys Enter
sleep 5

# Cursor Agent が固まった場合
tmux send-keys -t :.1 C-c  # Ctrl+C で中断
sleep 2
tmux send-keys -t :.1 Enter  # 新しいプロンプト待ち
```

## 関連スキル

| スキル | 用途 | 使い分け |
|--------|------|----------|
| **tmux-ai-chat** | tmux 操作の共通基盤 | 全ての AI 連携で使用可能 |
| **ai-research** | Web 検索・調査 | 情報収集・出典確認が必要な場合 |
| **codex-collab** | Codex との設計相談 | OpenAI Codex を使いたい場合 |
| **cursor-collab** | Cursor Agent との設計相談 | Cursor Agent を使いたい場合 |

### 他スキルとの連携

調査結果を受けて設計相談する場合:

1. `ai-research` で Gemini に調査依頼 → RESEARCH MEMO 作成
2. `cursor-collab` で Cursor Agent に設計相談（RESEARCH MEMO を引用）

```
User: "JWT vs セッション認証について調査して、その後 Cursor Agent と設計相談したい"

Claude:
1. ai-research で Gemini に調査依頼
2. RESEARCH MEMO を受け取る
3. cursor-collab で Cursor Agent に「この調査結果を踏まえて、どちらを採用すべき？」
4. Cursor Agent のアドバイスを受けて実装
```
