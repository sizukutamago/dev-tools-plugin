---
name: codex-collab
description: Chat with Codex via tmux for pair programming. Use when user wants to collaborate with Codex, get second opinion, design consultation, code review, or pair program with AI.
version: 3.12.0
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

### 待機時間のカスタマイズ

環境変数で待機時間を調整可能:

| 環境変数 | 説明 | デフォルト |
|---------|------|-----------|
| `CODEX_WAIT_SHORT` | 短い質問の待機時間（秒） | 30 |
| `CODEX_WAIT_LONG` | 複雑な分析の待機時間（秒） | 120 |
| `CODEX_POLL_INTERVAL` | ポーリング間隔（秒） | 30 |
| `CODEX_MAX_RETRIES` | 最大リトライ回数 | 5 |

```bash
# 例: 長い分析タスクでタイムアウトを延長
export CODEX_WAIT_LONG=180
```

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

### 出力抽出パターン

#### 完了判定マーカー

| パターン | 説明 | 判定 |
|---------|------|------|
| `›` プロンプト表示 | 入力待ち状態 | 完了 |
| `Working...` 表示 | 処理中 | 未完了 |
| コードフェンス閉じなし | 出力途中 | 未完了 |
| 文章が途切れている | 出力途中 | 未完了 |

#### 出力抽出コード例

```bash
# プロンプト復帰を待つパターン
wait_for_prompt() {
    local pane=$1
    local timeout=${2:-60}
    local elapsed=0

    while [ $elapsed -lt $timeout ]; do
        local output=$(tmux capture-pane -t "$pane" -p -S -10)

        # プロンプト（›）が最終行にあれば完了
        if echo "$output" | tail -1 | grep -q '›'; then
            return 0
        fi

        sleep 5
        elapsed=$((elapsed + 5))
    done

    return 124  # タイムアウト
}
```

> **参照**: より高度なマーカーベース抽出は `tmux-ai-chat` スキルを参照

## 自動リカバリーフロー

タイムアウト検出時の体系的なリカバリー手順。
**副作用が小さい順**（read-only確認→再試行→再起動）に実行する。

### タイムアウトの種類

| 種類 | 症状 | 主な原因 |
|------|------|----------|
| LLM応答待ち | "Working" 表示のまま | 長いプロンプト、API遅延 |
| プロセス停止 | 出力が途中で止まる | メモリ不足、クラッシュ |
| IPC不通 | capture-pane が空を返す | tmux セッション切断 |
| ネットワーク遮断 | API エラーメッセージ | 接続切れ、認証失効 |

### リトライ制限（サーキットブレーカー）

| 項目 | 上限 | 超過時の対応 |
|------|------|-------------|
| 同一ステップの再試行 | 最大 2 回 | 次のステップへ進む |
| 総リトライ回数 | 最大 5 回 | エスカレーション |
| 総タイムアウト | 5 分 | エスカレーション |

### Step 1: 出力確認（read-only）

```bash
tmux capture-pane -t :.1 -p -S -100
```

### Step 2: 状態判定と対応

| 状態 | 判定条件 | 自動リカバリーコマンド | 副作用 |
|------|----------|----------------------|--------|
| 出力空/プロンプト待ち | 末尾が `›` または出力なし | `tmux send-keys -t :.1 Enter` → `sleep 30` | 低 |
| Working表示固まり | "Working" が30秒以上変化なし | `tmux send-keys -t :.1 C-c` → `sleep 2` → `tmux send-keys -t :.1 Enter` | 中 |
| 完全無応答 | 上記両方失敗 | ペイン再作成（下記参照） | 高 |

### Step 3: ペイン再作成（完全無応答時）

**事前確認**: ペインが存在するか確認してから kill する

```bash
# 1. ペイン存在確認（エラー回避）
if tmux list-panes -F "#{pane_index}" | grep -q "^1$"; then
    tmux kill-pane -t :.1
else
    echo "Pane not found, skipping kill" >&2
fi

# 2. 新しいペインを作成
tmux split-window -h

# 3. Codex を起動
tmux send-keys "codex"
tmux send-keys Enter

# 4. 起動待機
sleep 5

# 5. 元の質問を再送信
tmux send-keys -t :.1 "元の質問内容"
tmux send-keys -t :.1 Enter
```

**エラーハンドリング**: `can't find pane` エラーは無視して続行

### リカバリー判断フローチャート

```
タイムアウト発生
      │
      ▼
  capture-pane で確認
      │
      ├─ 出力空 or プロンプト待ち（›）
      │     │
      │     ▼
      │   Enter 送信 → 30秒待機 → 再確認
      │     │
      │     ├─ 応答あり → 完了
      │     └─ 応答なし → "Working" 表示継続へ
      │
      ├─ "Working" 表示継続
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
      ペイン再作成（Step 3）
            │
            ├─ 成功 → 完了
            └─ 失敗（リトライ上限超過）→ エスカレーション
```

### 復旧できないケース（エスカレーション）

以下の場合は自動リカバリーを中止し、ユーザーに報告する:

| 条件 | 報告内容 | ユーザーへの提案 |
|------|----------|-----------------|
| 総リトライ 5 回超過 | 試行した手順と結果 | Codex CLI の再インストール/認証確認 |
| 総タイムアウト 5 分超過 | 最後の capture 出力 | ネットワーク/API状態の確認 |
| API認証エラー連続 | エラーメッセージ | `codex login` の再実行 |
| tmux セッション消失 | `can't find session` | 新しい tmux セッションで再開 |

**ログ採取項目（トラブルシューティング用）:**
- 最後の `tmux capture-pane` 出力
- 発生時刻とリトライ回数
- 実行した質問内容（機密情報は除く）

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

