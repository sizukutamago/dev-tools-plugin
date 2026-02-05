# tmux-ai-chat

tmux を使った AI チャット連携の共通基盤スキル。

## 概要

このスキルは、Claude Code と外部 AI（Codex、Gemini など）が tmux ペインを介して通信するための共通操作を提供します。他の AI 連携スキル（codex-collab、ai-research など）の基盤として使用されます。

**位置づけ:**
- 他の AI 連携スキルの共通基盤
- `tmux_ai.sh` スクリプトによる統一的な操作
- マーカーベースの出力抽出

## 前提条件

| 条件 | 必須 | 説明 |
|------|------|------|
| `tmux` 3.0+ | ○ | `brew install tmux` または `apt install tmux` |
| tmux セッション | ○ | tmux セッション内で実行すること |
| bash | ○ | スクリプトは bash で動作 |

## 契約（他スキルへの約束）

このスキルを使用する他の AI 連携スキルは、以下の契約に従う必要があります:

1. **出力抽出方式**（用途により選択）:
   - **対話型 AI CLI（codex, gemini 等）**: `capture --last-lines` を使用（`--wrap` は対話型 CLI では使用不可）
   - **シェルスクリプト実行**: `send --wrap` + `capture --between` を使用
2. **マーカーフォーマット**（シェル用）: `__TMUX_AI_START__:<id>__` / `__TMUX_AI_END__:<id>__`
3. **エラーコード統一**: 下記のコードに従う
4. **生 tmux コマンド**: 推奨は `tmux_ai.sh` だが、対話型 AI CLI では直接 tmux コマンドも許容

### エラーコード

| コード | 意味 | 対応 |
|--------|------|------|
| 0 | 成功 | - |
| 64 | 使い方エラー（不正引数） | 引数を確認 |
| 69 | 外部要因（tmux未起動等） | tmux セッション内で実行 |
| 72 | I/Oエラー（ファイル読み込み失敗） | ファイルパスを確認 |
| 124 | タイムアウト | --wait-ms を増やすか、手動確認 |

## 関連スキル

| スキル | 用途 |
|--------|------|
| codex-collab | Codex との設計相談・レビュー |
| ai-research | Gemini との調査・リサーチ |
| cursor-collab | Cursor Agent との設計相談 |

## トラブルシューティング

詳細は `references/troubleshoot.md` を参照。

### よくある問題

| 状況 | 症状 | 対応 |
|------|------|------|
| tmux 未起動 | エラーコード 69 | tmux セッション内で実行 |
| ペインが見つからない | `can't find pane` | ペインID を確認（`tmux list-panes`） |
| タイムアウト | エラーコード 124 | `--wait-ms` を増やす |

## 関連ドキュメント

- [SKILL.md](./SKILL.md) - AI 向け実行手順・スクリプト仕様
- [references/troubleshoot.md](./references/troubleshoot.md) - トラブルシューティング詳細
