# claude -p 実行パターン

Discussion Loop（Phase 2）と Judge（Phase 3）で繰り返し使うファイルベースの実行パターン。

## 基本パターン

出力をファイルにリダイレクトし、完了を exit ファイルで検出する（マーカー方式は `claude -p` のような長時間コマンドでは不安定なため非推奨）。

### Step 1: プロンプトファイル作成

```bash
# Write ツールで $COLLAB_TMPDIR/<role>-round-<N>.txt を作成
```

### Step 2: tmux ペインで実行

```bash
# 出力はファイルにリダイレクト、終了コードも記録
tmux send-keys -t "$pane" "env -u CLAUDECODE claude -p < \"$COLLAB_TMPDIR/<role>-round-<N>.txt\" > \"$COLLAB_TMPDIR/<role>-out-<N>.txt\" 2>&1; echo \$? > \"$COLLAB_TMPDIR/<role>-exit-<N>.txt\""
```
```bash
tmux send-keys -t "$pane" Enter
```

**重要**: `tmux send-keys` と Enter は別々の Bash 呼び出しで実行すること。

### Step 3: 完了待機

```bash
# 最大120秒、2秒間隔でポーリング（Judge は180秒、3秒間隔）
for i in $(seq 1 60); do
  [ -f "$COLLAB_TMPDIR/<role>-exit-<N>.txt" ] && break
  sleep 2
done
```

### Step 4: タイムアウト判定

```bash
if [ ! -f "$COLLAB_TMPDIR/<role>-exit-<N>.txt" ]; then
  echo "TIMEOUT: <role> round <N>"
  # → リトライ1回（同じコマンドを再送信）。2回目も失敗なら "(タイムアウト)" として記録し次ラウンドへ
fi
```

### Step 5: 終了コード判定 + 出力取得

```bash
exit_code=$(cat "$COLLAB_TMPDIR/<role>-exit-<N>.txt" 2>/dev/null || echo "1")
if [ "$exit_code" != "0" ]; then
  response="(エラー: claude -p が終了コード ${exit_code} で失敗。出力: $(head -5 "$COLLAB_TMPDIR/<role>-out-<N>.txt" 2>/dev/null))"
  # → リトライ1回。2回目も失敗なら上記のエラー内容をユーザーに表示し次ラウンドへ
else
  response=$(cat "$COLLAB_TMPDIR/<role>-out-<N>.txt" 2>/dev/null || echo "(応答なし)")
fi
rm -f "$COLLAB_TMPDIR/<role>-exit-<N>.txt"
```

## Role A / Role B / Judge の違い

| パラメータ | Role A/B | Judge |
|-----------|----------|-------|
| ポーリング間隔 | 2秒 | 3秒 |
| 最大待機時間 | 120秒 | 180秒 |
| リトライ | 1回 | 1回 |
| プロンプトファイル | `role{A,B}-round-<N>.txt` | `judge.txt` |
| 出力ファイル | `role{A,B}-out-<N>.txt` | `judge-out.txt` |

## CLAUDECODE 環境変数

Claude Code セッション内から `claude -p` を実行するには `CLAUDECODE` 環境変数をアンセットする必要がある。
すべての `claude -p` 実行は `env -u CLAUDECODE claude -p ...` の形式で行うこと。
