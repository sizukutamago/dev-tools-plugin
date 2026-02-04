#!/usr/bin/env bash
# tmux_ai.sh - tmux を使った AI チャット連携の共通操作スクリプト
# 使用法: tmux_ai.sh <subcommand> [options...]
#
# サブコマンド:
#   split   - ペイン作成
#   send    - テキスト送信（マーカー付き）
#   capture - 出力取得（マーカー間抽出）
#   kill    - ペイン終了
#
# エラーコード:
#   0   - 成功
#   64  - 使い方エラー（不正引数）
#   69  - 外部要因（tmux未起動等）
#   72  - I/Oエラー（ファイル読み込み失敗等）
#   124 - タイムアウト

set -euo pipefail

# 定数
readonly VERSION="1.0.0"
readonly MARKER_PREFIX="__TMUX_AI_"
readonly EX_OK=0
readonly EX_USAGE=64
readonly EX_UNAVAILABLE=69
readonly EX_OSFILE=72
readonly EX_TIMEOUT=124

# エラー出力
err() {
    printf '%s\n' "$*" >&2
}

# 使用法エラー
usage_error() {
    err "エラー: $1"
    err "詳細は 'tmux_ai.sh --help' を参照してください。"
    exit $EX_USAGE
}

# tmux が利用可能か確認
check_tmux() {
    if ! command -v tmux &>/dev/null; then
        err "エラー: tmux がインストールされていません。"
        exit $EX_UNAVAILABLE
    fi
    if [[ -z "${TMUX:-}" ]]; then
        err "エラー: tmux セッション内で実行してください。"
        exit $EX_UNAVAILABLE
    fi
}

# マーカーID生成（タイムスタンプ + ランダム）
generate_marker_id() {
    local timestamp random_hex
    timestamp="$(date +%Y%m%dT%H%M%S)"
    random_hex="$(head -c 4 /dev/urandom | od -An -tx1 | tr -d ' \n')"
    printf '%s-%s' "$timestamp" "$random_hex"
}

# マーカー文字列生成
marker_start() {
    printf '%sSTART__:%s__' "$MARKER_PREFIX" "$1"
}

marker_end() {
    printf '%sEND__:%s__' "$MARKER_PREFIX" "$1"
}

# ========================================
# split サブコマンド
# ========================================
cmd_split() {
    local direction="h"
    local percent=50
    local name=""
    local cmd=""
    local print_pane_id=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --direction|-d)
                [[ -n "${2:-}" ]] || usage_error "--direction には値が必要です"
                direction="$2"
                shift 2
                ;;
            --percent|-p)
                [[ -n "${2:-}" ]] || usage_error "--percent には値が必要です"
                percent="$2"
                shift 2
                ;;
            --name|-n)
                [[ -n "${2:-}" ]] || usage_error "--name には値が必要です"
                name="$2"
                shift 2
                ;;
            --cmd|-c)
                [[ -n "${2:-}" ]] || usage_error "--cmd には値が必要です"
                cmd="$2"
                shift 2
                ;;
            --print-pane-id)
                print_pane_id=1
                shift
                ;;
            --)
                shift
                break
                ;;
            -*)
                usage_error "不明なオプション: $1"
                ;;
            *)
                break
                ;;
        esac
    done

    # direction の検証
    if [[ "$direction" != "h" && "$direction" != "v" ]]; then
        usage_error "--direction は 'h'（水平）または 'v'（垂直）を指定してください"
    fi

    # tmux フラグ設定
    local split_flag="-v"
    [[ "$direction" == "h" ]] && split_flag="-h"

    # ペイン作成
    local pane_id
    if [[ -n "$cmd" ]]; then
        pane_id="$(tmux split-window $split_flag -p "$percent" -P -F '#{pane_id}' -- bash -lc "$cmd")"
    else
        pane_id="$(tmux split-window $split_flag -p "$percent" -P -F '#{pane_id}')"
    fi

    # タイトル設定（指定された場合）
    if [[ -n "$name" ]]; then
        tmux select-pane -t "$pane_id" -T "$name"
    fi

    # ペインID出力
    if (( print_pane_id )); then
        printf '%s\n' "$pane_id"
    fi
}

# ========================================
# send サブコマンド
# ========================================
cmd_send() {
    local pane=""
    local text=""
    local file=""
    local wrap=0
    local enter=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --pane)
                [[ -n "${2:-}" ]] || usage_error "--pane には値が必要です"
                pane="$2"
                shift 2
                ;;
            --text|-t)
                [[ -n "${2:-}" ]] || usage_error "--text には値が必要です"
                text="$2"
                shift 2
                ;;
            --file|-f)
                [[ -n "${2:-}" ]] || usage_error "--file には値が必要です"
                file="$2"
                shift 2
                ;;
            --wrap|-w)
                wrap=1
                shift
                ;;
            --enter|-e)
                enter=1
                shift
                ;;
            --)
                shift
                break
                ;;
            -*)
                usage_error "不明なオプション: $1"
                ;;
            *)
                break
                ;;
        esac
    done

    # 必須パラメータ検証
    [[ -n "$pane" ]] || usage_error "--pane は必須です"
    [[ -n "$text" || -n "$file" ]] || usage_error "--text または --file のどちらかを指定してください"
    [[ -z "$text" || -z "$file" ]] || usage_error "--text と --file は同時に指定できません"

    # ファイル存在確認
    if [[ -n "$file" && ! -r "$file" ]]; then
        err "エラー: ファイル '$file' が読み込めません"
        exit $EX_OSFILE
    fi

    # マーカーID生成（wrap時のみ）
    local marker_id=""
    if (( wrap )); then
        marker_id="$(generate_marker_id)"
        local start_marker
        start_marker="$(marker_start "$marker_id")"
        # STARTマーカーを出力
        tmux send-keys -t "$pane" -l "printf '%s\\n' '$start_marker'"
        tmux send-keys -t "$pane" Enter
    fi

    # テキスト送信
    if [[ -n "$text" ]]; then
        # 短いテキストは直接送信
        tmux send-keys -t "$pane" -l -- "$text"
    else
        # ファイルはバッファ経由で送信
        local buf_name="tmux_ai_buf_$$"
        tmux load-buffer -b "$buf_name" "$file"
        tmux paste-buffer -t "$pane" -b "$buf_name" -d
    fi

    # Enter送信
    if (( enter )); then
        tmux send-keys -t "$pane" Enter
    fi

    # ENDマーカー出力（wrap時のみ）
    if (( wrap )); then
        local end_marker
        end_marker="$(marker_end "$marker_id")"
        tmux send-keys -t "$pane" -l "printf '%s\\n' '$end_marker'"
        tmux send-keys -t "$pane" Enter
        # マーカーIDを出力
        printf '%s\n' "$marker_id"
    fi
}

# ========================================
# capture サブコマンド
# ========================================
cmd_capture() {
    local pane=""
    local between=""
    local last_lines=0
    local wait_ms=8000
    local interval_ms=200

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --pane)
                [[ -n "${2:-}" ]] || usage_error "--pane には値が必要です"
                pane="$2"
                shift 2
                ;;
            --between|-b)
                [[ -n "${2:-}" ]] || usage_error "--between には値が必要です"
                between="$2"
                shift 2
                ;;
            --last-lines|-l)
                [[ -n "${2:-}" ]] || usage_error "--last-lines には値が必要です"
                last_lines="$2"
                shift 2
                ;;
            --wait-ms)
                [[ -n "${2:-}" ]] || usage_error "--wait-ms には値が必要です"
                wait_ms="$2"
                shift 2
                ;;
            --interval-ms)
                [[ -n "${2:-}" ]] || usage_error "--interval-ms には値が必要です"
                interval_ms="$2"
                shift 2
                ;;
            --)
                shift
                break
                ;;
            -*)
                usage_error "不明なオプション: $1"
                ;;
            *)
                break
                ;;
        esac
    done

    # 必須パラメータ検証
    [[ -n "$pane" ]] || usage_error "--pane は必須です"

    # 単純なキャプチャ（--last-lines指定時）
    if (( last_lines > 0 )); then
        tmux capture-pane -p -t "$pane" -S "-$last_lines"
        return $EX_OK
    fi

    # マーカー間キャプチャ（--between指定時）
    if [[ -n "$between" ]]; then
        local start_marker end_marker
        start_marker="$(marker_start "$between")"
        end_marker="$(marker_end "$between")"
        local loops=$(( (wait_ms + interval_ms - 1) / interval_ms ))
        local interval_sec
        interval_sec="$(awk "BEGIN{printf \"%.2f\", $interval_ms/1000}")"

        for ((i=0; i<loops; i++)); do
            local out
            out="$(tmux capture-pane -p -t "$pane" -S -50000 2>/dev/null || true)"

            if printf '%s\n' "$out" | grep -Fq "$end_marker"; then
                # STARTとENDの間を抽出（部分一致でマーカー行を検出）
                printf '%s\n' "$out" | awk -v s="$start_marker" -v e="$end_marker" '
                    index($0, s) > 0 { capturing = 1; next }
                    index($0, e) > 0 { if (capturing) { printf "%s", buf; found = 1; exit } }
                    capturing { buf = buf $0 ORS }
                    END { exit (found ? 0 : 2) }
                '
                return $?
            fi
            sleep "$interval_sec"
        done
        return $EX_TIMEOUT
    fi

    # デフォルト: 全体キャプチャ
    tmux capture-pane -p -t "$pane" -S -
}

# ========================================
# kill サブコマンド
# ========================================
cmd_kill() {
    local pane=""
    local force=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --pane)
                [[ -n "${2:-}" ]] || usage_error "--pane には値が必要です"
                pane="$2"
                shift 2
                ;;
            --force|-f)
                force=1
                shift
                ;;
            --)
                shift
                break
                ;;
            -*)
                usage_error "不明なオプション: $1"
                ;;
            *)
                break
                ;;
        esac
    done

    # 必須パラメータ検証
    [[ -n "$pane" ]] || usage_error "--pane は必須です"

    # 自分自身のペインを kill しない（安全策）
    if ! (( force )); then
        local current_pane
        current_pane="$(tmux display-message -p '#{pane_id}')"
        if [[ "$pane" == "$current_pane" ]]; then
            err "警告: 現在のペインは kill できません（--force で強制可能）"
            return 1
        fi
    fi

    tmux kill-pane -t "$pane"
}

# ========================================
# ヘルプ
# ========================================
show_help() {
    cat <<'EOF'
tmux_ai.sh - tmux を使った AI チャット連携の共通操作スクリプト

使用法:
    tmux_ai.sh <subcommand> [options...]

サブコマンド:
    split     ペインを作成
    send      テキストを送信（マーカー付き対応）
    capture   ペインの出力をキャプチャ
    kill      ペインを終了

共通オプション:
    --help, -h     このヘルプを表示
    --version      バージョンを表示

split オプション:
    --direction, -d <h|v>    分割方向（h=水平, v=垂直）[デフォルト: h]
    --percent, -p <N>        新ペインのサイズ（%）[デフォルト: 50]
    --name, -n <name>        ペインタイトル
    --cmd, -c <command>      ペインで実行するコマンド
    --print-pane-id          作成したペインIDを出力

send オプション:
    --pane <pane_id>         送信先ペイン（必須）
    --text, -t <text>        送信するテキスト
    --file, -f <path>        送信するファイル
    --wrap, -w               マーカーで囲む（IDを出力）
    --enter, -e              最後にEnterを送信

capture オプション:
    --pane <pane_id>         キャプチャ元ペイン（必須）
    --between, -b <id>       マーカーID間をキャプチャ
    --last-lines, -l <N>     最後のN行をキャプチャ
    --wait-ms <ms>           タイムアウト時間 [デフォルト: 8000]
    --interval-ms <ms>       ポーリング間隔 [デフォルト: 200]

kill オプション:
    --pane <pane_id>         終了するペイン（必須）
    --force, -f              現在のペインも強制終了

使用例:
    # ペイン作成
    pane=$(tmux_ai.sh split --direction h --percent 50 --name codex --print-pane-id)

    # マーカー付きでテキスト送信
    id=$(tmux_ai.sh send --pane "$pane" --wrap --text "Hello" --enter)

    # マーカー間の出力をキャプチャ
    tmux_ai.sh capture --pane "$pane" --between "$id" --wait-ms 30000

    # ペイン終了
    tmux_ai.sh kill --pane "$pane"

エラーコード:
    0   成功
    64  使い方エラー
    69  外部要因（tmux未起動等）
    72  I/Oエラー
    124 タイムアウト
EOF
}

# ========================================
# メイン
# ========================================
main() {
    # 引数なしの場合
    if [[ $# -eq 0 ]]; then
        show_help
        exit $EX_USAGE
    fi

    # グローバルオプション処理
    case "$1" in
        --help|-h)
            show_help
            exit $EX_OK
            ;;
        --version)
            printf 'tmux_ai.sh version %s\n' "$VERSION"
            exit $EX_OK
            ;;
    esac

    # tmux 確認
    check_tmux

    # サブコマンド実行
    local subcmd="$1"
    shift

    case "$subcmd" in
        split)
            cmd_split "$@"
            ;;
        send)
            cmd_send "$@"
            ;;
        capture)
            cmd_capture "$@"
            ;;
        kill)
            cmd_kill "$@"
            ;;
        *)
            usage_error "不明なサブコマンド: $subcmd"
            ;;
    esac
}

main "$@"
