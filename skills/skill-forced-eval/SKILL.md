---
name: skill-forced-eval
description: "[AUTO-HOOK] Injects skill evaluation reminder on every prompt. NOT user-invocable - always active via UserPromptSubmit hook."
version: 2.0.0
---

# Forced Skill Evaluation Hook

> **注意**: これは通常のスキルではありません。`UserPromptSubmit` hook により**常時自動で動作**します。
> ユーザーが明示的に呼び出すものではなく、プロンプト送信時に自動でスキル評価指示を差し込みます。

## 目的

**全インストール済みプラグインのスキル**を Claude Code に明示的に探索させるため、毎回のプロンプト送信時に「利用可能なスキルを評価し、該当するものがあれば発動せよ」という指示を `<system-reminder>` として差し込みます。

v1.0 では自プラグイン（dev-tools-plugin）のスキルのみ対象でしたが、v2.0 で `~/.claude/plugins/installed_plugins.json` を参照し、全プラグインを対象にしました。

**参考**: [Claude Code の Skills 発動率向上に関する記事](https://zenn.dev/ka888aa/articles/b7fcb48a3b3fa9)

## 動作仕様

### トリガー

- **イベント**: `UserPromptSubmit`（プロンプト送信時）
- **条件**: 常時オン（条件分岐なし）
- **マッチャー**: `*`（全プロンプト）

### データ源

- **Primary**: `~/.claude/plugins/installed_plugins.json`（全プラグインの installPath を取得）
- **Fallback**: `$CLAUDE_PLUGIN_ROOT/skills/`（自プラグインのみ。installed_plugins.json が無い場合）

### 注入内容

```xml
<system-reminder>
SKILL ACTIVATION CHECK:

Before responding to this prompt, check if any skill from the installed plugins matches the user's request.
If a skill clearly applies, invoke it using the Skill tool BEFORE generating your response.

Installed plugins with available skills:
- dev-tools-plugin (ai-research, biome, codex-collab, cursor-collab, dependency-cruiser, ... +6 more)
- document-skills (algorithmic-art, brand-guidelines, canvas-design, doc-coauthoring, docx, ... +11 more)
- cloud-infrastructure (cost-optimization, hybrid-cloud-networking, multi-cloud-architecture, terraform-module-library)
- ...

To invoke: Skill tool with skill name (e.g., skill: "biome", skill: "document-skills:pdf")
</system-reminder>
```

### 設計判断

| 判断 | 選択 | 理由 |
|------|------|------|
| 出力レベル | プラグイン名 + 代表スキル名（最大5個） | 全スキル列挙はトークン肥大。Claude Code 本体がスキル一覧を持つためプラグイン名レベルで十分 |
| データ源 | installed_plugins.json | 正規かつ信頼性が高い。cache ディレクトリの直接走査は旧バージョン等のノイズが多い |
| キャッシュ | mtime ベース | 毎回の JSON パース + ファイル走査を回避 |
| フォールバック | 自プラグインのみ（v1.0 互換） | installed_plugins.json が無い環境でも動作 |

### キャッシュ機構

- キャッシュファイル: `/tmp/claude-skill-eval-cache.txt`
- 有効期限: `installed_plugins.json` の mtime が変わるまで
- 初回実行: 数百 ms（全プラグインの SKILL.md を走査）
- キャッシュヒット時: 約 60 ms

### 影響範囲

| 項目 | 影響 |
|------|------|
| トークン消費 | 微増（プラグイン一覧分、約 200-400 tokens） |
| レイテンシ | 微増（キャッシュヒット時 ~60ms、ミス時 ~500ms） |
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
- `installed_plugins.json` の読み取りのみ（書き込みなし）

## 発動率について

- **期待発動率**: 約 84%（参考記事の実験結果）
- **100% にならない理由**: モデルの確率的ブレは避けられない
- **代替手段**: 100% を求める場合は CLAUDE.md に直接記述
