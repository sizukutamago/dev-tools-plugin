---
name: skill-forced-eval
description: "[AUTO-HOOK] Injects skill evaluation reminder on every prompt. NOT user-invocable - always active via UserPromptSubmit hook."
version: 1.0.0
---

# Forced Skill Evaluation Hook

> **注意**: これは通常のスキルではありません。`UserPromptSubmit` hook により**常時自動で動作**します。
> ユーザーが明示的に呼び出すものではなく、プロンプト送信時に自動でスキル評価指示を差し込みます。

## 目的

Skills の発動率を向上させるため、毎回のプロンプト送信時に「利用可能なスキルを評価し、該当するものがあれば発動せよ」という指示を `<system-reminder>` として差し込みます。

**参考**: [Claude Code の Skills 発動率向上に関する記事](https://zenn.dev/ka888aa/articles/b7fcb48a3b3fa9)

## 動作仕様

### トリガー

- **イベント**: `UserPromptSubmit`（プロンプト送信時）
- **条件**: 常時オン（条件分岐なし）
- **マッチャー**: `*`（全プロンプト）

### 注入内容

```xml
<system-reminder>
SKILL ACTIVATION CHECK:

Before responding, evaluate if any available skill matches the user's request.
If a skill applies, invoke it using the Skill tool before proceeding.

Available skills in this plugin:
- skill-name: description...
</system-reminder>
```

### 影響範囲

| 項目 | 影響 |
|------|------|
| トークン消費 | 微増（スキル一覧分、約 200-500 tokens） |
| レイテンシ | 微増（hook スクリプト実行、約 50-100ms） |
| プロンプト変更 | `<system-reminder>` タグで追加（ユーザー入力は変更しない） |

## 無効化方法

このプラグインを使用しつつ Forced Eval を無効化したい場合:

1. `~/.claude/settings.json` から該当 hook を削除
2. または `plugin.json` の hooks 参照を削除

## ファイル構成

```
skills/skill-forced-eval/
├── SKILL.md                    # この仕様書
├── scripts/
│   └── forced_eval_hook.sh     # Hook スクリプト本体
└── assets/
    └── hooks/
        └── forced_eval.json    # Hook 設定
```

## セキュリティ考慮

- ユーザー入力は一切変更しない（追加のみ）
- 個人情報・機密情報は扱わない
- 注入内容は本ファイルで完全に開示

## 発動率について

- **期待発動率**: 約 84%（参考記事の実験結果）
- **100% にならない理由**: モデルの確率的ブレは避けられない
- **代替手段**: 100% を求める場合は CLAUDE.md に直接記述
