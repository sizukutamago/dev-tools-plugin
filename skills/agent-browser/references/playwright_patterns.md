# Playwright Patterns

ブラウザ自動化でよく使うパターン集。

## 基本パターン

### ページナビゲーション

```bash
# 基本的なナビゲーション
agent-browser open https://example.com

# 戻る・進む
agent-browser back
agent-browser forward

# リロード
agent-browser reload
```

### スナップショット取得

```bash
# インタラクティブ要素のみ（推奨）
agent-browser snapshot -i

# 全要素
agent-browser snapshot

# コンパクト表示
agent-browser snapshot -c

# 深さ制限
agent-browser snapshot -d 3
```

## フォーム操作

### 基本的なフォーム入力

```bash
# スナップショットで要素参照を取得
agent-browser snapshot -i
# Output: textbox "Email" [ref=e1], textbox "Password" [ref=e2], button "Submit" [ref=e3]

# フィールド入力
agent-browser fill @e1 "user@example.com"
agent-browser fill @e2 "password123"

# 送信
agent-browser click @e3
```

### セレクトボックス

```bash
# ドロップダウン選択
agent-browser select @e1 "option-value"
```

### チェックボックス・ラジオボタン

```bash
# チェック
agent-browser check @e1

# チェック解除
agent-browser uncheck @e1
```

## 待機パターン

### 要素の出現を待つ

```bash
# 特定の要素を待つ
agent-browser wait @e1

# テキストの出現を待つ
agent-browser wait --text "Success"

# テキストの消失を待つ
agent-browser wait --text-gone "Loading..."
```

### ページ状態を待つ

```bash
# ネットワークが落ち着くまで待つ
agent-browser wait --load networkidle

# DOMContentLoaded
agent-browser wait --load domcontentloaded

# 固定時間待機（ミリ秒）
agent-browser wait 2000
```

### URL変化を待つ

```bash
# 特定のURLパターンを待つ
agent-browser wait --url "**/dashboard"
agent-browser wait --url "**/success"
```

## 認証パターン

### ログインフロー

```bash
# ログインページに移動
agent-browser open https://app.example.com/login

# フォーム要素を取得
agent-browser snapshot -i

# ログイン情報入力
agent-browser fill @e1 "username"
agent-browser fill @e2 "password"
agent-browser click @e3

# ダッシュボードへの遷移を待つ
agent-browser wait --url "**/dashboard"
```

### セッション状態の保存・復元

```bash
# ログイン後、状態を保存
agent-browser state save auth.json

# 別のセッションで状態を復元
agent-browser state load auth.json
agent-browser open https://app.example.com/dashboard
```

## スクリーンショット

### 基本的なスクリーンショット

```bash
# 現在のビューポート
agent-browser screenshot

# ファイルに保存
agent-browser screenshot screenshot.png

# フルページ
agent-browser screenshot --full fullpage.png
```

### 要素のスクリーンショット

```bash
# 特定の要素
agent-browser screenshot @e1 element.png
```

## テーブル・リスト操作

### テーブルデータの取得

```bash
# テーブルの各行を処理
agent-browser snapshot -i
# テーブル行の ref を特定

# 各セルのテキストを取得
agent-browser get text @e1
agent-browser get text @e2
```

### リストのスクロール

```bash
# ページをスクロール
agent-browser scroll down 500

# 要素が見えるまでスクロール
agent-browser scrollintoview @e1
```

## 複数タブ・ウィンドウ

### 新しいタブを開く

```bash
# 新しいタブを作成
agent-browser tab new

# タブ一覧
agent-browser tab list

# タブを切り替え
agent-browser tab switch 1

# タブを閉じる
agent-browser tab close
```

## エラーハンドリング

### よくあるエラーと対処

| エラー | 原因 | 対処 |
|--------|------|------|
| Element not found | 要素が存在しない | snapshot で ref を再確認 |
| Timeout | 要素が表示されない | wait で明示的に待機 |
| Navigation failed | ページ読み込み失敗 | URL を確認、リトライ |
| Session expired | セッション切れ | 再ログイン |

### リトライパターン

```bash
# 要素が見つからない場合
agent-browser wait @e1
# ↓ タイムアウトしたら
agent-browser snapshot -i  # 再取得
# ↓ 新しい ref で再試行
agent-browser click @e2
```

## デバッグ

### ヘッドフルモード

```bash
# ブラウザウィンドウを表示
agent-browser open example.com --headed
```

### コンソールログ確認

```bash
# コンソールメッセージを表示
agent-browser console

# エラーのみ表示
agent-browser errors
```

### ネットワークリクエスト確認

```bash
# ネットワークリクエストを確認
agent-browser network
```

## 複数セッション（並列実行）

```bash
# セッション1: サイトA
agent-browser --session s1 open site-a.com
agent-browser --session s1 snapshot -i

# セッション2: サイトB（並列）
agent-browser --session s2 open site-b.com
agent-browser --session s2 snapshot -i

# セッション一覧
agent-browser session list
```

## JSON出力（自動化用）

```bash
# スナップショットをJSON形式で
agent-browser snapshot -i --json

# テキスト取得をJSON形式で
agent-browser get text @e1 --json

# パース例（jq使用）
agent-browser snapshot -i --json | jq '.elements[] | select(.role == "button")'
```
