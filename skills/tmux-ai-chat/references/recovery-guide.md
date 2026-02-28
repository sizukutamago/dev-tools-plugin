# tmux AI チャット共通リカバリーガイド

codex-collab / cursor-collab / ai-research 等の AI CLI 連携スキルで共通するタイムアウト検出・リカバリー手順。

## 待機時間の目安

| 質問の種類 | 推奨待機時間 | 最大待機時間 | 備考 |
|-----------|-------------|-------------|------|
| 短い質問 | 30秒 | 60秒 | Yes/No、簡単な確認 |
| コードレビュー | 60秒 | 120秒 | 小〜中規模のコード |
| 設計相談 | 90秒 | 180秒 | アーキテクチャ、パターン選択 |
| 複雑な分析 | 120秒 | 240秒 | 大規模コード、詳細な比較 |

## ポーリング戦略

1. 初回待機（上記の推奨待機時間）
2. `tmux capture-pane -t <pane> -p -S -100` で出力確認
3. 以下の場合は追加30秒待機（最大待機時間に達するまで繰り返し）:
   - 処理中表示（"Working"、スピナー等）
   - 出力途中（閉じ括弧・コードフェンス未完、文章途切れ）
   - プロンプトに戻っていない
4. 最大待機時間を超えたらタイムアウトとして処理

## 完了判定マーカー

| パターン | 説明 | 判定 |
|---------|------|------|
| プロンプト記号表示（`›` 等） | 入力待ち状態 | 完了 |
| `Working...` / スピナー表示 | 処理中 | 未完了 |
| コードフェンス閉じなし | 出力途中 | 未完了 |
| 文章が途切れている | 出力途中 | 未完了 |

## タイムアウト時の対応

**副作用が小さい順**（read-only → 再試行 → 再起動）に実行する。

| 状態 | 判定方法 | 対応 | 副作用 |
|------|----------|------|--------|
| 出力空/プロンプト待ち | 末尾がプロンプト記号 or 出力なし | Enter で再プロンプト | 低 |
| 処理中のまま固まった | 表示が30秒以上変化なし | C-c で中断 → Enter | 中 |
| 完全に無応答 | 上記すべて失敗 | ペイン再作成 | 高 |

```bash
# Step 1: 出力確認（read-only）
tmux capture-pane -t <pane> -p -S -100

# Step 2a: 出力空/プロンプト待ちの場合
tmux send-keys -t <pane> Enter
sleep 30
tmux capture-pane -t <pane> -p -S -100

# Step 2b: 処理中のまま固まった場合
tmux send-keys -t <pane> C-c
sleep 2
tmux send-keys -t <pane> Enter
```

## リトライ制限（サーキットブレーカー）

| 項目 | 上限 | 超過時の対応 |
|------|------|-------------|
| 同一ステップの再試行 | 最大 2 回 | 次のステップへ進む |
| 総リトライ回数 | 最大 5 回 | エスカレーション |
| 総タイムアウト | 5 分 | エスカレーション |

## ペイン再作成（完全無応答時）

```bash
# 1. ペイン存在確認
if tmux list-panes -F "#{pane_index}" | grep -q "^<pane_num>$"; then
    tmux kill-pane -t :.<pane_num>
fi

# 2. 新しいペインを作成
tmux split-window -h

# 3. AI CLI を起動（codex / cursor-agent / gemini 等）
tmux send-keys "<cli-command>"
tmux send-keys Enter

# 4. 起動待機
sleep 5

# 5. 元の質問を再送信
tmux send-keys -t :.<pane_num> "元の質問内容"
tmux send-keys -t :.<pane_num> Enter
```

## リカバリー判断フローチャート

```
タイムアウト発生
      │
      ▼
  capture-pane で確認
      │
      ├─ 出力空 or プロンプト待ち
      │     │
      │     ▼
      │   Enter 送信 → 30秒待機 → 再確認
      │     │
      │     ├─ 応答あり → 完了
      │     └─ 応答なし → 処理中表示へ
      │
      ├─ 処理中表示が継続
      │     │
      │     ▼
      │   C-c で中断 → 2秒待機 → Enter
      │     │
      │     ├─ プロンプト復帰 → 質問再送信
      │     └─ 復帰せず → 完全無応答へ
      │
      └─ 完全無応答
            │
            ▼
      ペイン再作成
            │
            ├─ 成功 → 完了
            └─ 失敗（リトライ上限超過）→ エスカレーション
```

## エスカレーション（復旧できないケース）

以下の場合は自動リカバリーを中止し、ユーザーに報告する:

| 条件 | 報告内容 | ユーザーへの提案 |
|------|----------|-----------------|
| 総リトライ 5 回超過 | 試行した手順と結果 | CLI の再インストール/認証確認 |
| 総タイムアウト 5 分超過 | 最後の capture 出力 | ネットワーク/API状態の確認 |
| API認証エラー連続 | エラーメッセージ | CLI の再認証 |
| tmux セッション消失 | `can't find session` | 新しい tmux セッションで再開 |

## 出力抽出コード例

```bash
# プロンプト復帰を待つパターン
wait_for_prompt() {
    local pane=$1
    local timeout=${2:-60}
    local elapsed=0

    while [ $elapsed -lt $timeout ]; do
        local output=$(tmux capture-pane -t "$pane" -p -S -10)

        # プロンプト記号が最終行にあれば完了
        if echo "$output" | tail -1 | grep -qE '[›$#>]'; then
            return 0
        fi

        sleep 5
        elapsed=$((elapsed + 5))
    done

    return 124  # タイムアウト
}
```

> **参照**: スクリプトベースの抽出は `tmux-ai-chat` の `tmux_ai.sh capture` を使用可能
