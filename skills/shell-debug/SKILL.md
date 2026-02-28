---
name: shell-debug
description: Debug shell scripts and one-liners systematically (repro, isolate, observe, fix, verify). Use when the user is troubleshooting a broken shell script, pipeline, or one-liner that produces unexpected output or errors. Covers pipelines, quoting/expansion, tmux automation, git/CI scripting, and awk/sed text processing. Do NOT trigger for normal shell command usage or when simply writing new scripts without debugging issues.
version: 1.0.0
---

# shell-debug

シェルの不具合を「再現→分解→観測→修正→検証」で最短特定するための手順集。

## 期待するアウトプット（この順で出す）

1. 再現コマンド（最小入力つき）
2. 期待出力 / 実際出力（差分が分かる形）
3. 失敗点の切り分け結果（どの段/どの展開で壊れるか）
4. 修正案（最小変更）
5. 検証手順（quick / full）
6. 再発防止（必要なら kaizen へ引き渡し）

## ワークフロー（基本）

### Step 1: 環境確認（30秒）

- shell種別（bash/zsh/sh）、バージョン
- 対話/非対話、CIかローカルか
- `set -euo pipefail` 有無
- `PATH`、`LC_ALL`、`IFS` の値
- 外部依存（`command -v ...`）とバージョン差

```bash
# 環境確認コマンド
echo "Shell: $SHELL ($BASH_VERSION)"
echo "Interactive: $-"
echo "PATH: $PATH"
echo "LC_ALL: $LC_ALL"
command -v awk sed grep tmux git
```

### Step 2: 最小再現（入力縮小）

- 入力サンプルを here-doc 等で固定
- 期待出力（golden）を1回書いて `diff` 可能にする

```bash
# 最小入力テンプレート
input=$(cat <<'EOF'
サンプル入力をここに
EOF
)

expected=$(cat <<'EOF'
期待出力をここに
EOF
)

# 実行と比較
actual=$(echo "$input" | your_command_here)
diff <(echo "$expected") <(echo "$actual")
```

### Step 3: パイプライン分解（観測点を作る）

- 各段を単独実行し、段ごとの出力を保存
- "どの段で壊れたか" を確定してから修正

```bash
# パイプライン分解テンプレート
echo "$input" | awk '...' > /tmp/stage1.txt
cat /tmp/stage1.txt | sed '...' > /tmp/stage2.txt
cat /tmp/stage2.txt | grep '...' > /tmp/stage3.txt

# または tee で観測
echo "$input" | awk '...' | tee /tmp/stage1.txt | sed '...' | tee /tmp/stage2.txt
```

### Step 4: 変数展開/クォート診断

- 値の可視化
- word-splitting / glob / 改行 / NUL / CRLF を疑う

```bash
# 変数の可視化
declare -p var           # 型と値を表示
printf '%q\n' "$var"     # エスケープ形式で表示
echo "$var" | cat -A     # 特殊文字を可視化
echo "$var" | xxd        # バイナリダンプ

# デバッグモード
set -x                   # コマンド実行をトレース
PS4='+ ${BASH_SOURCE}:${LINENO}: '  # 行番号付きトレース
```

### Step 5: 修正→検証

- **quick**: 構文チェック + 最小サンプル golden diff
- **full**: 実データ/CI入口で回す

```bash
# quick検証
bash -n script.sh                    # 構文チェック
shellcheck script.sh                 # 静的解析（あれば）
diff <(echo "$expected") <(echo "$actual")

# full検証
./script.sh < real_input.txt > actual_output.txt
diff expected_output.txt actual_output.txt
```

## Playbooks（よくある系）

### A) awk/sed/grep混在で二度手間になる

**症状**: 複数のフィルタを組み合わせたパイプラインが期待通り動かない

**対処**:
1. まず単独フィルタ化（awk単独、sed単独で動くか確認）
2. 段階テスト（各段の出力を保存して確認）
3. 最後に統合（「同じgoldenが通る」ことが条件）

```bash
# NG: 一気に書いて壊れる
cat log | awk '/ERROR/' | sed 's/.*://' | grep -v DEBUG

# OK: 段階的に確認
cat log | awk '/ERROR/' > /tmp/step1.txt       # まず確認
cat /tmp/step1.txt | sed 's/.*://' > /tmp/step2.txt  # 次を確認
cat /tmp/step2.txt | grep -v DEBUG             # 最後に確認
```

### B) tmux操作スクリプトが不安定

**症状**: `tmux send-keys` が期待通り動かない、ペインが見つからない

**対処**:
1. 送信内容をログ化（trace）
2. `tmux list-panes` で対象paneが正しいか確認
3. 文字列は配列/引数で渡す（クォート崩壊を避ける）

```bash
# ペイン確認
tmux list-panes -F "#{pane_index}: #{pane_current_command}"

# 送信前にログ出力（trace）
echo "[TRACE] Sending to pane $pane: $message" >&2
tmux send-keys -t "$pane" "$message"
tmux send-keys -t "$pane" Enter

# 待機と確認
sleep 2
tmux capture-pane -t "$pane" -p -S -50
```

### C) git自動化が環境差で壊れる

**症状**: ローカルでは動くがCI/別環境で失敗する

**対処**:
1. `--global` 変更を避け、repo/local設定に寄せる
2. 権限/制限環境を想定したフォールバック方針を用意

```bash
# NG: global設定に依存
git config --global user.name "Bot"

# OK: repo-local設定を使用
git config user.name "Bot"

# 制限環境でのフォールバック
GIT_CONFIG_GLOBAL=/dev/null git status
git -c user.name="Bot" -c user.email="bot@example.com" commit -m "msg"
```

### D) CIだけ落ちる（ローカルでは通る）

**症状**: 同じコマンドなのにCIでのみ失敗する

**確認ポイント**:
1. `LC_ALL` / `LANG` の違い
2. `PATH` の違い
3. `set -euo pipefail` の有無
4. 実行シェル（bash vs sh vs dash）

```bash
# CI環境を模倣
LC_ALL=C LANG=C bash -euo pipefail -c 'your_command'

# シェル差の確認
sh -c 'your_command'    # POSIX sh
bash -c 'your_command'  # bash
```

## テンプレ（コピー用）

### 最小入力 here-doc テンプレ

```bash
#!/usr/bin/env bash
set -euo pipefail

input=$(cat <<'EOF'
入力データをここに
EOF
)

expected=$(cat <<'EOF'
期待出力をここに
EOF
)

actual=$(echo "$input" | your_command)

if diff -q <(echo "$expected") <(echo "$actual") > /dev/null; then
  echo "✅ PASS"
else
  echo "❌ FAIL"
  diff <(echo "$expected") <(echo "$actual")
  exit 1
fi
```

### 段階化テンプレ

```bash
#!/usr/bin/env bash
set -euo pipefail

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

echo "$input" > "$TMPDIR/input.txt"

# Stage 1: awk
awk '/pattern/' "$TMPDIR/input.txt" > "$TMPDIR/stage1.txt"
echo "Stage 1: $(wc -l < "$TMPDIR/stage1.txt") lines"

# Stage 2: sed
sed 's/old/new/g' "$TMPDIR/stage1.txt" > "$TMPDIR/stage2.txt"
echo "Stage 2: $(wc -l < "$TMPDIR/stage2.txt") lines"

# Stage 3: grep
grep -v 'exclude' "$TMPDIR/stage2.txt" > "$TMPDIR/output.txt"
echo "Stage 3: $(wc -l < "$TMPDIR/output.txt") lines"

cat "$TMPDIR/output.txt"
```

### 値の可視化テンプレ（安全なtrace方針）

```bash
# 秘密情報をマスクしたトレース
debug_var() {
  local name=$1
  local value=${!name:-}
  # パスワード/トークンをマスク
  if [[ $name =~ (PASSWORD|TOKEN|SECRET|KEY) ]]; then
    echo "[DEBUG] $name=***MASKED***" >&2
  else
    echo "[DEBUG] $name=$(printf '%q' "$value")" >&2
  fi
}

debug_var PATH
debug_var API_TOKEN  # マスクされる
```

