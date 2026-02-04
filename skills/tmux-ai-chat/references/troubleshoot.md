# tmux-ai-chat トラブルシュート

## よくある問題と解決策

### 1. "tmux セッション内で実行してください" エラー

**原因**: tmux セッション外でスクリプトを実行している

**解決策**:
```bash
# tmux セッションを開始
tmux new-session -s ai

# または既存セッションにアタッチ
tmux attach-session -t ai
```

### 2. マーカーが見つからない（タイムアウト）

**原因**:
- AI の応答が遅い
- マーカーが出力に含まれていない

**解決策**:
```bash
# タイムアウト時間を延長
tmux_ai.sh capture --pane "$pane" --between "$id" --wait-ms 180000

# フォールバック: 最後の行を取得
tmux_ai.sh capture --pane "$pane" --last-lines 200
```

### 3. ペインが見つからない

**原因**: ペインID が無効、またはペインが既に終了している

**解決策**:
```bash
# 現在のペイン一覧を確認
tmux list-panes -F "#{pane_id}: #{pane_title} (#{pane_current_command})"

# ペインを再作成
pane=$(tmux_ai.sh split --direction h --percent 50 --name codex --print-pane-id)
```

### 4. 長文送信が失敗する

**原因**: テキストが長すぎて引数長制限に達した

**解決策**:
```bash
# ファイル経由で送信
echo "$long_text" > /tmp/prompt.txt
tmux_ai.sh send --pane "$pane" --wrap --file /tmp/prompt.txt --enter
```

### 5. マーカーが出力されない

**原因**: ペインがシェルではなく、printf が実行できない

**解決策**:
- ペインでシェル（bash）が動作していることを確認
- `--wrap` なしで送信し、手動でマーカーを確認

```bash
# wrap なしで送信
tmux_ai.sh send --pane "$pane" --text "テスト" --enter

# 全体をキャプチャして確認
tmux_ai.sh capture --pane "$pane" --last-lines 50
```

### 6. AI が応答しない

**原因**:
- AI CLI が起動していない
- API 認証エラー
- レート制限

**解決策**:
```bash
# ペインの内容を確認
tmux_ai.sh capture --pane "$pane" --last-lines 30

# エラーメッセージがあれば対応
# 例: API エラーの場合は再認証
# 例: レート制限の場合は待機
```

### 7. ペインが自動的に閉じる

**原因**: `--cmd` で指定したコマンドが終了した

**解決策**:
```bash
# シェルを残すようにコマンドをラップ
tmux_ai.sh split --direction h --percent 50 --name test --cmd "your_command; exec bash"
```

## デバッグ方法

### ペイン状態の確認

```bash
# 全ペイン情報
tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index} #{pane_id} #{pane_title} #{pane_current_command}"

# 特定ペインの詳細
tmux display-message -t "$pane" -p "PID: #{pane_pid}, Title: #{pane_title}"
```

### バッファの確認

```bash
# tmux バッファ一覧
tmux list-buffers

# 特定バッファの内容
tmux show-buffer -b buffer_name
```

### 詳細ログ

```bash
# スクリプト実行時にデバッグ出力
bash -x /path/to/tmux_ai.sh split --direction h --print-pane-id
```

## 環境固有の問題

### macOS

- `date +%N` はサポートされない（スクリプトは対応済み）
- Homebrew の tmux を使用: `brew install tmux`

### Linux

- tmux が古い場合は更新: `sudo apt update && sudo apt install tmux`
- tmux 3.0 以上が必要

## マーカー仕様

### フォーマット

```
開始: __TMUX_AI_START__:<id>__
終了: __TMUX_AI_END__:<id>__
```

### ID 生成ルール

- フォーマット: `YYYYMMDDTHHMMSS-xxxxxxxx`
- 例: `20260204T120102-a1b2c3d4`
- タイムスタンプ + ランダム8文字（衝突回避）

### 抽出ロジック

1. ペイン全体をキャプチャ（-S -50000 で十分な行数）
2. END マーカーを探す（grep -F）
3. 見つかったら awk で START〜END 間を抽出
4. 見つからなければ interval_ms 待機してリトライ
5. wait_ms 経過でタイムアウト（exit 124）
