# hurikaeri（振り返り）

セッション単位で AI の行動・判断を振り返り、学びを永続化するスキル。

## 概要

prompt-improver が**複数セッション横断の統計分析**でプロンプト品質を改善するのに対し、
hurikaeri は**単一セッションの深掘り分析**で AI の行動品質を振り返ります。

### AI-KPT フレームワーク

アジャイルの KPT を AI 行動分析向けに拡張:

| セクション | 意味 | 例 |
|-----------|------|-----|
| **Keep** | うまくいったパターン | 段階的調査で正確にバグ特定 |
| **Problem** | 問題があった行動 | テスト未実行でデプロイ |
| **Try** | 次回の改善アクション | 変更後は必ずテスト実行 |
| **Omission** | やるべきだったがやらなかった | セキュリティ観点の検討漏れ |

## 使い方

```
/hurikaeri
```

## 3フェーズ

1. **Trace**: JSONL トランスクリプト解析 + git diff + AI 記憶から行動データ収集
2. **Reflect**: AI-KPT 分析 + 反事実推論で不作為を検出
3. **Crystallize**: レポート永続化 + CLAUDE.md/SKILL.md 改善提案

## Stop Hook

複雑なセッション終了時に自動で `/hurikaeri` を提案します。

判定基準:
- JSONL 行数 >= 50 かつ ツール使用 >= 10
- OR コード変更 >= 5
- OR エラー >= 3

## ファイル構成

```
skills/hurikaeri/
├── SKILL.md                              # スキル定義
├── README.md                             # このファイル
├── references/
│   ├── kpt_schema.md                     # AI-KPT 出力スキーマ
│   └── counterfactual_prompts.md         # 反事実推論プロンプト集
├── scripts/
│   ├── extract_session_trace.py          # JSONL → セッショントレース抽出
│   ├── suggest_hurikaeri.sh              # Stop hook（振り返り提案）
│   └── persist_learnings.sh              # KPT レポート永続化
└── assets/
    └── hooks/
        └── hurikaeri_hook.json           # Hook 設定例
```

## 関連

- [prompt-improver](../prompt-improver/) — 複数セッション横断のプロンプト改善
- [commands/hurikaeri.md](../../commands/hurikaeri.md) — コマンド定義
