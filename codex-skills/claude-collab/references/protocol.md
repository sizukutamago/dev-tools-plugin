# 通信プロトコル定義

Claude Code と Codex 間の双方向通信プロトコル。

> このファイルは `skills/codex-collab/references/protocol.md` と同一内容を維持すること。

## プロトコル概要

```
┌─────────────┐                              ┌─────────────┐
│ Claude Code │                              │    Codex    │
│ (主導)      │                              │ (相談役)    │
└──────┬──────┘                              └──────┬──────┘
       │                                            │
       │  ──────[CONSULT:REQUIREMENTS]──────▶      │
       │        要件分析の相談                      │
       │  ◀─────[RESPONSE:REQUIREMENTS]─────       │
       │        明確化質問・考慮点                  │
       │                                            │
       │  ──────[CONSULT:DESIGN]────────────▶      │
       │        設計案の相談                        │
       │  ◀─────[RESPONSE:DESIGN]───────────       │
       │        ASSESSMENT/RISKS/RECOMMENDATION    │
       │                                            │
       │  ──────[CONSULT:IMPLEMENTATION]───▶       │
       │        実装中の技術相談                    │
       │  ◀─────[RESPONSE:IMPLEMENTATION]──        │
       │        技術的アドバイス                    │
       │                                            │
       │  ──────[REQUEST:REVIEW]───────────▶       │
       │        コードレビュー依頼                  │
       │  ◀─────[RESPONSE:REVIEW]──────────        │
       │        STRENGTHS/ISSUES/SUGGESTIONS       │
       │                                            │
       ▼                                            ▼
```

## メッセージタグ一覧

### Claude → Codex

| タグ | 用途 | 応答タグ |
|------|------|----------|
| `[CONSULT:REQUIREMENTS]` | 要件明確化相談 | `[RESPONSE:REQUIREMENTS]` |
| `[CONSULT:DESIGN]` | 設計レビュー依頼 | `[RESPONSE:DESIGN]` |
| `[CONSULT:IMPLEMENTATION]` | 実装中の技術相談 | `[RESPONSE:IMPLEMENTATION]` |
| `[REQUEST:REVIEW]` | コードレビュー依頼 | `[RESPONSE:REVIEW]` |

### Codex → Claude（双方向）

| タグ | 用途 |
|------|------|
| `[CONSULT:CLAUDE:VERIFICATION]` | 実装方針の確認 |
| `[CONSULT:CLAUDE:CONTEXT]` | 追加コンテキスト要求 |

## 応答セクション一覧

### RESPONSE:REQUIREMENTS
- `CLARIFICATION_QUESTIONS`: ユーザーに確認すべき質問
- `CONSIDERATIONS`: 考慮すべき非機能要件・エッジケース・制約

### RESPONSE:DESIGN
- `ASSESSMENT`: 設計の妥当性評価
- `RISKS`: リスクと課題
- `ALTERNATIVES`: 代替案
- `RECOMMENDATION`: 推奨事項

### RESPONSE:IMPLEMENTATION
- `ADVICE`: 質問への直接的な回答
- `PATTERNS`: 推奨パターン
- `CAVEATS`: 注意点

### RESPONSE:REVIEW
- `STRENGTHS`: 良い点
- `ISSUES`: 問題点（Critical/Important/Minor）
- `SUGGESTIONS`: 改善提案

## エラーハンドリング

| 状況 | 対応 |
|------|------|
| マーカー不在 | 再度構造化出力を依頼 |
| 不完全な応答 | 該当セクションのみ再要求 |
| タイムアウト | 短いプロンプトで再試行 |
| 無関係な応答 | コンテキスト再提供 |
