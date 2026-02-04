# dev-tools-plugin

Claude Code プラグインとして、開発効率化ツール集を提供するリポジトリ。AI連携、コード品質ツール、プロンプト改善を含む。

## プロジェクト構造

```
dev-tools-plugin/
├── .claude-plugin/          # プラグインメタデータ
├── commands/                # コマンド定義（1種）
│   └── improve.md
├── skills/                  # スキル実装（7種）
│   ├── tmux-ai-chat/       # tmux AI チャット基盤
│   ├── ai-research/        # Gemini との調査連携
│   ├── codex-collab/       # Codex との設計相談
│   ├── cursor-collab/      # Cursor Agent との設計相談
│   ├── biome/              # Linting/Formatting 設定
│   ├── dependency-cruiser/ # アーキテクチャ検証
│   └── prompt-improver/    # プロンプト改善
├── scripts/                 # セットアップスクリプト
│   └── setup-ai-collab.sh  # AI CLI 設定インストール
├── biome/                   # Biome 設定テンプレート
├── dependency-cruiser/      # dep-cruiser 設定テンプレート
├── AGENTS.md                # Codex/Cursor Agent 用設定
└── GEMINI.md                # Gemini CLI 用設定
```

## スキル一覧

### AI 連携

| スキル | 説明 | トリガー例 |
|--------|------|-----------|
| tmux-ai-chat | tmux ペイン経由の AI チャット基盤 | - |
| ai-research | Gemini との調査・リサーチ | 「調査して」「リサーチして」 |
| codex-collab | Codex との設計相談・レビュー | 「Codex と相談」「Codex にレビュー」 |
| cursor-collab | Cursor Agent との設計相談・レビュー | 「Cursor と相談」「Cursor にレビュー」 |

### コード品質

| スキル | 説明 | トリガー例 |
|--------|------|-----------|
| biome | Biome (Linter/Formatter) 設定 | 「Biome 設定」「リンター設定」 |
| dependency-cruiser | 依存関係・アーキテクチャ検証 | 「依存関係チェック」 |

### プロンプト改善

| スキル | 説明 | トリガー例 |
|--------|------|-----------|
| prompt-improver | フィードバック収集・改善提案 | `/improve` |

## コーディング規約

### 言語ポリシー

- **frontmatter description**: 英語（Claude のトリガー検出用）
- **本文**: 日本語（開発者向け）
- **コード例**: コンテキストに応じて混在可

### ファイル構造

**スキル（SKILL.md）:**

```markdown
---
name: skill-name
description: English description for Claude's trigger detection
version: X.Y.Z
---

# スキル名（日本語）

## 前提条件
## 出力ファイル
## 依存関係
## ワークフロー
## ツール使用ルール
## エラーハンドリング
```

## セットアップ

### プラグインとして使用

```bash
# ローカル開発時
claude --plugin-dir /path/to/dev-tools-plugin

# または marketplace 経由
claude plugin install dev-tools-plugin@your-marketplace
```

### AI CLI 設定のインストール

Codex/Cursor/Gemini CLI が設定ファイルを読み込めるようにする:

```bash
./scripts/setup-ai-collab.sh         # ~/.codex/, ~/.gemini/ にインストール
./scripts/setup-ai-collab.sh --force # 既存ファイルを上書き
```

## コマンド

```bash
/improve          # プロンプト改善分析
```

## 変更時の注意

### スキル編集時

1. `SKILL.md` の frontmatter description は英語で記述
2. バージョン番号を適切に更新（セマンティックバージョニング）
3. `references/` 配下のテンプレートとの整合性を確認

## prompt-improver について

Stop hook でタスク完了時のフィードバックを自動収集し、CLAUDE.md/SKILL の継続的改善を支援。

```bash
# フィードバック分析
./scripts/analyze_feedback.sh --stats

# 改善提案生成
./scripts/generate_improvements.sh
```

## 技術スタック

- **コア**: Claude Code プラグインシステム
- **AI 連携**: tmux ペイン経由（Codex/Cursor/Gemini CLI）
- **リンター**: Biome（Rust製、ESLint+Prettier代替）
- **依存関係検証**: dependency-cruiser
