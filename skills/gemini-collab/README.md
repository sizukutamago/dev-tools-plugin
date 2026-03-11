# AI Research

Claude Code と Gemini が tmux でチャットするスキル。Web 検索・ドキュメント調査に使用。

## 概要

このスキルは、Claude Code が Gemini と連携して情報収集を行うためのものです。Gemini は調査役として Web 検索やドキュメント調査を担当し、Claude Code が実装を担当します。

**主なユースケース:**
- 公式ドキュメントの調査
- ライブラリ/フレームワークの比較
- RFC や仕様の確認
- セキュリティベストプラクティスの調査
- 最新バージョンの変更点確認

## 前提条件

| 条件 | 必須 | 説明 |
|------|------|------|
| `gemini` CLI | ○ | `npm install -g @anthropic-ai/gemini` または公式インストール |
| Gemini 認証 | ○ | `gemini login` または API キー設定済み |
| `tmux` | ○ | `brew install tmux` |
| tmux セッション | ○ | tmux セッション内で実行すること |

## アーキテクチャ

Gemini はバックグラウンドプロセスではなく、**別ペイン**で起動します。

```
┌─────────────────────┬─────────────────────┐
│                     │                     │
│   Claude Code       │   Gemini            │
│   (メインペイン)    │   (サブペイン)      │
│                     │                     │
│   実装作業          │   調査・リサーチ    │
│                     │                     │
└─────────────────────┴─────────────────────┘
```

### なぜペインを使うのか

- 両方の出力をリアルタイムで確認可能
- ユーザーが手動で Gemini とやり取りすることも可能
- セッション終了時にペインを閉じるだけで済む

## 成果物: RESEARCH MEMO

Gemini の調査結果は以下のフォーマットでまとめます:

```markdown
# RESEARCH MEMO: <テーマ>

- Date: YYYY-MM-DD
- Researcher: Gemini CLI
- Goal: <調査目的>

## TL;DR
- <結論1>
- <結論2>
- <結論3>

## Findings
### 1) <要点>
- <主張/観察>
- Evidence: <根拠>
- Confidence: High | Medium | Low

## Trade-offs / Risks
- <注意点>

## Recommended Action
- <推奨方針>

## Open Questions
- <未解決点>

## Sources
- <Title> — <URL> (accessed: YYYY-MM-DD)
```

詳細テンプレートは `references/memo_template.md` を参照。

## 関連スキル

| スキル | 用途 | 使い分け |
|--------|------|----------|
| **tmux-ai-chat** | tmux 操作の共通基盤 | 全ての AI 連携で使用可能 |
| **ai-research** | Web 検索・調査 | 情報収集・出典確認が必要な場合 |
| **codex-collab** | 設計相談・レビュー | アーキテクチャ・実装方針の相談 |

### codex-collab との連携

調査結果を受けて設計相談する場合:

1. `ai-research` で Gemini に調査依頼 → RESEARCH MEMO 作成
2. `codex-collab` で Codex に設計相談（RESEARCH MEMO を引用）

```
User: "JWT vs セッション認証について調査して、その後設計相談したい"

Claude:
1. ai-research で Gemini に調査依頼
2. RESEARCH MEMO を受け取る
3. codex-collab で Codex に「この調査結果を踏まえて、どちらを採用すべき？」
4. Codex のアドバイスを受けて実装
```

## トラブルシューティング

| 状況 | 症状 |
|------|------|
| タイムアウト | capture 出力が空/変化なし |
| Gemini 未応答 | プロンプトが表示されたまま |
| ペイン消失 | `can't find pane` エラー |
| 接続エラー | API エラーメッセージ |

詳細な対応手順・リカバリーコマンドは [SKILL.md](./SKILL.md) の「エラーハンドリング」「自動リカバリーフロー」セクションを参照。

## 関連ドキュメント

- [SKILL.md](./SKILL.md) - AI 向け実行手順
- [references/memo_template.md](./references/memo_template.md) - RESEARCH MEMO テンプレート
