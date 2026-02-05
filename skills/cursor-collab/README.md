# Cursor Collab

Claude Code と Cursor Agent が tmux でチャットするスキル。設計相談やコードレビューに使用。

## 概要

このスキルは、Claude Code が Cursor Agent とペアプログラミング的に連携するためのものです。Cursor Agent は設計相談役として機能し、Claude Code が実装を担当します。

**主なユースケース:**
- 設計アプローチの相談
- パターン選択のアドバイス
- コードレビュー
- セキュリティリスクの検討
- パフォーマンス改善のアイデア出し

## 前提条件

| 条件 | 必須 | 説明 |
|------|------|------|
| `cursor-agent` CLI | ○ | Cursor Agent CLI（Cursor に付属） |
| Cursor 認証 | ○ | `cursor-agent login` または Cursor アカウント |
| `tmux` | ○ | `brew install tmux` |
| tmux セッション | ○ | tmux セッション内で実行すること |

### 動作確認

```bash
# cursor-agent がインストールされているか確認
which cursor-agent || echo "cursor-agent not found"
cursor-agent --version
```

## セキュリティ注意

**Cursor Agent は外部 AI サービスです。以下を送信しないこと:**
- API キー、パスワード、認証情報
- 社外秘・機密情報
- 個人情報（PII）

## アーキテクチャ

Cursor Agent はバックグラウンドプロセスではなく、**別ペイン**で起動します。

```
┌─────────────────────┬─────────────────────┐
│                     │                     │
│   Claude Code       │   Cursor Agent      │
│   (メインペイン)    │   (サブペイン)      │
│                     │                     │
│   実装作業          │   相談・レビュー    │
│                     │                     │
└─────────────────────┴─────────────────────┘
```

### なぜペインを使うのか

- 両方の出力をリアルタイムで確認可能
- ユーザーが手動で Cursor Agent とやり取りすることも可能
- セッション終了時にペインを閉じるだけで済む

## 関連スキル

| スキル | 用途 | 使い分け |
|--------|------|----------|
| **tmux-ai-chat** | tmux 操作の共通基盤 | 全ての AI 連携で使用可能 |
| **ai-research** | Web 検索・調査 | 情報収集・出典確認が必要な場合 |
| **codex-collab** | Codex との設計相談 | OpenAI Codex を使いたい場合 |
| **cursor-collab** | Cursor Agent との設計相談 | Cursor Agent を使いたい場合 |

### 他スキルとの連携

調査結果を受けて設計相談する場合:

1. `ai-research` で Gemini に調査依頼 → RESEARCH MEMO 作成
2. `cursor-collab` で Cursor Agent に設計相談（RESEARCH MEMO を引用）

```
User: "JWT vs セッション認証について調査して、その後 Cursor Agent と設計相談したい"

Claude:
1. ai-research で Gemini に調査依頼
2. RESEARCH MEMO を受け取る
3. cursor-collab で Cursor Agent に「この調査結果を踏まえて、どちらを採用すべき？」
4. Cursor Agent のアドバイスを受けて実装
```

## トラブルシューティング

| 状況 | 症状 |
|------|------|
| タイムアウト | capture 出力が空/変化なし |
| Cursor Agent 未応答 | プロンプトが表示されたまま |
| ペイン消失 | `can't find pane` エラー |
| 接続エラー | API エラーメッセージ |

詳細な対応手順・リカバリーコマンドは [SKILL.md](./SKILL.md) の「エラーハンドリング」「自動リカバリーフロー」セクションを参照。

## 関連ドキュメント

- [SKILL.md](./SKILL.md) - AI 向け実行手順
