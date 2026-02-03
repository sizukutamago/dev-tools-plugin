# dev-tools-plugin

Claude Code プラグインとして、開発効率化ツール集を提供するリポジトリ。TDD、コード品質、UI/UXガイドライン、プロンプト改善などを含む。

## プロジェクト構造

```
dev-tools-plugin/
├── .claude-plugin/          # プラグインメタデータ
├── agents/                  # エージェント定義（3種）
│   ├── tdd-test-writer.md
│   ├── tdd-implementer.md
│   └── tdd-refactorer.md
├── commands/                # コマンド定義（2種）
│   ├── dig.md
│   └── improve.md
├── skills/                  # スキル実装（12種）
│   ├── agent-browser/      # ブラウザ自動化
│   ├── biome/              # Linting/Formatting設定
│   ├── dependency-cruiser/ # アーキテクチャ検証
│   ├── subagent-driven-development/ # サブエージェント開発
│   ├── web-design-guidelines/ # Webデザインガイドライン
│   ├── software-architecture/ # ソフトウェアアーキテクチャ
│   ├── vercel-react-best-practices/ # React/Vercelベストプラクティス
│   ├── prompt-engineering/ # プロンプトエンジニアリング
│   ├── kaizen/             # 継続的改善
│   ├── brainstorming/      # ブレインストーミング
│   ├── tdd-integration/    # TDD統合
│   ├── codex-collab/       # Codex連携
│   └── prompt-improver/    # プロンプト改善
├── biome/                   # ルートBiome設定テンプレート
├── dependency-cruiser/      # ルートdep-cruiser設定テンプレート
└── install.sh               # インストールスクリプト
```

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

**エージェント:**

```markdown
---
name: agent-name
description: English trigger description
model: inherit
color: blue
tools: [list]
---

## Core Responsibilities
## Process Description
## Output Format
```

## コマンド

### インストール

```bash
./install.sh                      # ~/.claude にインストール
./install.sh -t /custom/path      # カスタムパス指定
```

### スキル呼び出し

```bash
/dig              # コードベース調査
/improve          # プロンプト改善分析
/setup-biome      # Biome設定
/setup-depcruise  # dependency-cruiser設定
```

### TDDエージェント

TDDワークフローは3つのエージェントで構成:

1. **tdd-test-writer**: RED フェーズ - 失敗するテストを書く
2. **tdd-implementer**: GREEN フェーズ - テストを通す最小実装
3. **tdd-refactorer**: REFACTOR フェーズ - コード改善

## 変更時の注意

### スキル編集時

1. `SKILL.md` の frontmatter description は英語で記述
2. バージョン番号を適切に更新（セマンティックバージョニング）
3. `references/` 配下のテンプレートとの整合性を確認

### エージェント編集時

1. `tools` リストは実際に使用可能なツールのみ記載
2. `color` は他エージェントと重複しないよう設定
3. `model: inherit` を基本とし、特別な理由がある場合のみ変更

## prompt-improver について

Stop hook でタスク完了時のフィードバックを自動収集し、CLAUDE.md/SKILL の継続的改善を支援。

```bash
# フィードバック分析
./scripts/analyze_feedback.sh --stats

# 改善提案生成
./scripts/generate_improvements.sh
```

## 品質基準

- Biome でコードスタイル統一
- dependency-cruiser でアーキテクチャ検証
- TDD でテスト駆動開発

## 技術スタック

- **コア**: Claude Code プラグインシステム
- **リンター**: Biome（Rust製、ESLint+Prettier代替）
- **依存関係検証**: dependency-cruiser
- **ブラウザ自動化**: Playwright
- **ドキュメント参照**: Context7 MCP
