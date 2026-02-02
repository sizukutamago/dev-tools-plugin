---
name: codex-collab
description: Chat with Codex via tmux for pair programming. Use when user wants to collaborate with Codex, get second opinion, or pair program with AI.
version: 3.10.0
---

# Codex Chat

Claude Code と Codex が tmux でチャットするスキル。

## 役割分担（重要）

| AI | 役割 | 担当タスク |
|----|------|-----------|
| **Claude Code** | 実装担当 | コード作成・編集・ファイル操作・テスト実行 |
| **Codex** | 相談役 | 設計相談・レビュー・セカンドオピニオン・質問回答 |

**Codex に実装を依頼しないこと。** Codex から設計提案やレビューを受けて、Claude Code が実装する。

## 前提条件

| 条件 | 必須 | 説明 |
|------|------|------|
| `codex` CLI | ○ | `npm install -g @openai/codex` |
| Codex 認証 | ○ | `codex login` または `OPENAI_API_KEY` |
| `tmux` | ○ | `brew install tmux` |
| tmux セッション | ○ | tmux セッション内で実行すること |

## アーキテクチャ

**重要**: Codex はバックグラウンドプロセスではなく、**別ペイン**で起動する。

```
┌─────────────────────┬─────────────────────┐
│                     │                     │
│   Claude Code       │   Codex             │
│   (メインペイン)    │   (サブペイン)      │
│                     │                     │
│   実装作業          │   相談・レビュー    │
│                     │                     │
└─────────────────────┴─────────────────────┘
```

これにより:
- 両方の出力をリアルタイムで確認可能
- ユーザーが手動で Codex とやり取りすることも可能
- セッション終了時にペインを閉じるだけで済む

## セットアップ

### Codex ペイン作成

現在のウィンドウを水平分割し、右側ペインで Codex を起動:

```bash
# 3つの Bash コマンドを順番に実行（&& で連結しないこと）
tmux split-window -h
tmux send-keys "codex"
tmux send-keys Enter
```

- `split-window -h`: 水平分割（左右に分かれる）
- 新しいペインがアクティブになるが、Claude Code は元のペインで継続
- **重要**: `&&` で連結せず、別々の Bash コマンドとして実行すること

### ペイン番号の確認

```bash
tmux list-panes -F "#{pane_index}: #{pane_current_command}"
```

通常、Claude Code が pane 0 または 1、Codex が pane 1 または 2 になる。

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
- 応答が長い場合は `sleep` の秒数を増やす（最大待機時間は下表参照）
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

- ❌「このコードを実装して」
- ❌「ファイルを作成して」
- ❌「テストを書いて」

## 注意事項

- `codex exec` は使わないこと（MCP サーバー起動オーバーヘッド回避）
- **ペイン**でインタラクティブモードを使用（バックグラウンドではない）
- 長い質問はファイル経由で送信可能
- 「Working」表示中は追加で待機が必要
- **`&&` で連結しないこと**: tmux コマンドは別々の Bash 呼び出しで実行
  - `&&` で連結すると Enter が送信されないことがある
  - 各 `tmux send-keys` は個別の Bash コマンドとして実行する

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
   - 「Working」やスピナー表示中
   - 出力が途中で終わっている（閉じ括弧・コードフェンス未完、文章が途切れている）
   - プロンプト（`›`）に戻っていない
4. 最大待機時間を超えたらタイムアウトとして処理

**タイムアウト時の対応**:

| 状態 | 判定方法 | 対応 |
|------|----------|------|
| capture出力が空 | `tmux capture-pane` の結果が空 | Enter で再プロンプト |
| プロンプト待ち | 末尾が `›` で止まっている | Enter で再プロンプト |
| 処理中のまま固まった | Working表示が変化しない | C-c で中断 → Enter |
| 完全に無応答 | 上記すべて失敗 | Codex 再起動（ペイン終了→再作成） |

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
| Codex 未応答 | プロンプトが表示されたまま | `tmux send-keys -t :.1 Enter` で再送信 |
| ペイン消失 | `can't find pane` エラー | セットアップを再実行 |
| 接続エラー | API エラーメッセージ | `codex` を再起動（ペイン終了→再作成） |

### リカバリー手順

```bash
# ペインが消失した場合
tmux split-window -h
tmux send-keys "codex"
tmux send-keys Enter
sleep 5

# Codex が固まった場合
tmux send-keys -t :.1 C-c  # Ctrl+C で中断
sleep 2
tmux send-keys -t :.1 Enter  # 新しいプロンプト待ち
```
