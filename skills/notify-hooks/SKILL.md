---
name: notify-hooks
description: "[AUTO-HOOK] macOS notifications for task completion and permission requests. NOT user-invocable - always active via Stop and Notification hooks."
version: 1.0.0
---

# macOS 通知 Hook

> **注意**: これは通常のスキルではありません。`Stop` および `Notification` hook により**常時自動で動作**します。
> ユーザーが明示的に呼び出すものではなく、タスク完了時や許可リクエスト時に自動で通知を送信します。

## 目的

- **タスク完了通知**: Claude Code のタスクが完了したら macOS 通知を送信
- **許可リクエスト通知**: 許可が必要な操作があった場合に通知
- **クリックでフォーカス**: 通知クリックでターミナルウィンドウを前面化

## 参考

- https://qiita.com/take8/items/28bae27208580f0a2e44
- https://zenn.dev/yuru_log/articles/claude-code-hooks-terminal-notifier-guide

## 前提条件

```bash
# terminal-notifier インストール（推奨）
brew install terminal-notifier
```

※ 未インストールでも `osascript` で通知は出ます（機能制限あり）

## 動作仕様

### トリガー

| イベント | 説明 | マッチャー |
|----------|------|-----------|
| `Stop` | タスク完了時 | `*` |
| `Notification` | 許可リクエスト時 | `*` |

### 通知バックエンド（優先順）

1. `terminal-notifier`（PATH 内）
2. `/opt/homebrew/bin/terminal-notifier`（Apple Silicon）
3. `/usr/local/bin/terminal-notifier`（Intel Mac）
4. `osascript`（フォールバック）

### クリック時の動作

1. ターミナルアプリをアクティベート
2. 対象ウィンドウを前面化（Terminal.app / iTerm2）
3. tmux セッション内の場合、対象ペインを選択

## ファイル構成

```
skills/notify-hooks/
├── SKILL.md                           # この仕様書
└── scripts/
    ├── notify.sh                      # 共通: バックエンド選択・通知送信
    ├── focus-terminal.sh              # クリック時: ターミナルフォーカス
    ├── notify_stop.sh                 # Stop 用: タスク完了通知
    └── notify_notification.sh         # Notification 用: 許可リクエスト通知
```

## 環境変数

| 変数 | 説明 | デフォルト |
|------|------|-----------|
| `CLAUDE_NOTIFY` | 通知の有効/無効 | `1`（有効） |
| `CLAUDE_NOTIFY_SOUND` | 通知音 | `default` |

## 制限事項

| ターミナル | ウィンドウ指定 | 備考 |
|------------|----------------|------|
| Terminal.app | ✅ | AppleScript 対応 |
| iTerm2 | ✅ | AppleScript 対応 |
| Warp | ❌ | アプリ前面化のみ |
| tmux 複数クライアント | ⚠️ | 最初のクライアントにフォーカス |

## 無効化方法

```bash
# 環境変数で無効化
export CLAUDE_NOTIFY=0

# または hooks.json から該当 hook を削除
```
