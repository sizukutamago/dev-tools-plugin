---
name: tmux-ai-chat
description: Common tmux operations for AI chat integration. Provides split, send, capture, kill commands with marker-based output extraction. Use when building AI collaboration skills.
version: 1.0.0
---

# tmux-ai-chat

tmux を使った AI チャット連携の共通基盤スキル。

## 概要

このスキルは、Claude Code と外部 AI（Codex、Gemini など）が tmux ペインを介して通信するための共通操作を提供します。

## 前提条件

| 条件 | 必須 | 説明 |
|------|------|------|
| `tmux` 3.0+ | ○ | `brew install tmux` または `apt install tmux` |
| tmux セッション | ○ | tmux セッション内で実行すること |
| bash | ○ | スクリプトは bash で動作 |

## 契約（他スキルへの約束）

1. **生 tmux コマンド禁止**: AI 連携スキルは `tmux_ai.sh` を使用すること
2. **マーカー方式**: 出力抽出は `send --wrap` + `capture --between` を使用
3. **マーカーフォーマット**: `__TMUX_AI_START__:<id>__` / `__TMUX_AI_END__:<id>__`
4. **エラーコード統一**: 下記のコードに従う

## スクリプト: tmux_ai.sh

### 場所

```
skills/tmux-ai-chat/scripts/tmux_ai.sh
```

### サブコマンド

#### split - ペイン作成

```bash
tmux_ai.sh split --direction h --percent 50 --name <title> [--cmd <command>] --print-pane-id
```

| オプション | 説明 | デフォルト |
|------------|------|-----------|
| `--direction`, `-d` | 分割方向（h=水平, v=垂直） | h |
| `--percent`, `-p` | 新ペインのサイズ（%） | 50 |
| `--name`, `-n` | ペインタイトル | なし |
| `--cmd`, `-c` | 実行するコマンド | なし |
| `--print-pane-id` | ペインIDを出力 | なし |

**出力**: `--print-pane-id` 指定時、新しいペインID（例: `%12`）

#### send - テキスト送信

```bash
tmux_ai.sh send --pane <id> [--wrap] [--text <str> | --file <path>] --enter
```

| オプション | 説明 |
|------------|------|
| `--pane` | 送信先ペイン（必須） |
| `--text`, `-t` | 送信するテキスト |
| `--file`, `-f` | 送信するファイル |
| `--wrap`, `-w` | マーカーで囲む（**シェルプロンプト専用**） |
| `--enter`, `-e` | 最後に Enter を送信 |

**出力**: `--wrap` 指定時、マーカーID（例: `20260204T120102-a1b2c3d4`）

> ⚠️ **重要**: `--wrap` は `printf` コマンドを実行してマーカーを出力するため、
> ペインがシェルプロンプト（bash等）でないと動作しません。
> 対話型 AI CLI（codex, gemini 等）では使用できません。

#### capture - 出力取得

```bash
tmux_ai.sh capture --pane <id> --between <marker_id> --wait-ms 30000
```

| オプション | 説明 | デフォルト |
|------------|------|-----------|
| `--pane` | キャプチャ元ペイン（必須） | |
| `--between`, `-b` | マーカーID間をキャプチャ | |
| `--last-lines`, `-l` | 最後のN行をキャプチャ | |
| `--wait-ms` | タイムアウト時間（ミリ秒） | 8000 |
| `--interval-ms` | ポーリング間隔（ミリ秒） | 200 |

**出力**: キャプチャしたテキスト

#### kill - ペイン終了

```bash
tmux_ai.sh kill --pane <id>
```

| オプション | 説明 |
|------------|------|
| `--pane` | 終了するペイン（必須） |
| `--force`, `-f` | 現在のペインも強制終了 |

## エラーコード

| コード | 意味 | 対応 |
|--------|------|------|
| 0 | 成功 | - |
| 64 | 使い方エラー（不正引数） | 引数を確認 |
| 69 | 外部要因（tmux未起動等） | tmux セッション内で実行 |
| 72 | I/Oエラー（ファイル読み込み失敗） | ファイルパスを確認 |
| 124 | タイムアウト | --wait-ms を増やすか、手動確認 |

## 使用例

### 対話型 AI CLI との連携（推奨）

対話型 AI CLI（codex, gemini 等）では `--wrap` は使用せず、`--last-lines` でキャプチャします。

```bash
# 1. ペイン作成（AI CLI を起動）
pane=$(tmux_ai.sh split --direction h --percent 50 --name codex --cmd "codex" --print-pane-id)

# 2. AI CLI の起動を待機
sleep 5

# 3. 質問送信（wrap なし）
tmux_ai.sh send --pane "$pane" --text "設計について相談したい" --enter

# 4. 応答を待機してキャプチャ
sleep 60
response=$(tmux_ai.sh capture --pane "$pane" --last-lines 100)

# 5. ペイン終了
tmux_ai.sh kill --pane "$pane"
```

### シェルコマンド実行（wrap 使用）

シェルプロンプトでワンショットコマンドを実行する場合は `--wrap` が使用できます。

```bash
# 1. シェルペイン作成（コマンドなし）
pane=$(tmux_ai.sh split --direction h --percent 50 --name shell --print-pane-id)

# 2. コマンド実行（マーカー付き）
id=$(tmux_ai.sh send --pane "$pane" --wrap --text "ls -la" --enter)

# 3. 結果をマーカー間から抽出
result=$(tmux_ai.sh capture --pane "$pane" --between "$id" --wait-ms 5000)

# 4. ペイン終了
tmux_ai.sh kill --pane "$pane"
```

### ファイル経由で長文送信

```bash
# プロンプトをファイルに保存
cat > /tmp/prompt.txt << 'EOF'
以下のコードをレビューしてください:

```python
def calculate(x, y):
    return x + y
```
EOF

# ファイルを送信
id=$(tmux_ai.sh send --pane "$pane" --wrap --file /tmp/prompt.txt --enter)
```

### タイムアウト処理

```bash
if ! response=$(tmux_ai.sh capture --pane "$pane" --between "$id" --wait-ms 60000); then
    case $? in
        124)
            echo "タイムアウト: 追加で待機するか、手動で確認してください"
            # フォールバック: 最後の100行を取得
            tmux_ai.sh capture --pane "$pane" --last-lines 100
            ;;
        *)
            echo "エラーが発生しました"
            ;;
    esac
fi
```

## 関連スキル

| スキル | 用途 |
|--------|------|
| codex-collab | Codex との設計相談・レビュー |
| ai-research | Gemini との調査・リサーチ |

## トラブルシュート

詳細は `references/troubleshoot.md` を参照。
