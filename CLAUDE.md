# dev-tools-plugin

Claude Code プラグインとして、開発効率化ツール集を提供するリポジトリ。AI連携、コード品質ツール、プロンプト改善を含む。

## プロジェクト構造

```
dev-tools-plugin/
├── .claude-plugin/          # プラグインメタデータ
├── commands/                # コマンド定義（3種）
│   ├── improve.md
│   ├── hurikaeri.md
│   └── claude-collab.md
├── skills/                  # スキル実装（13種）
│   ├── tmux-ai-chat/       # tmux AI チャット基盤
│   ├── ai-research/        # Gemini との調査連携
│   ├── codex-collab/       # Codex との設計相談
│   ├── cursor-collab/      # Cursor Agent との設計相談
│   ├── claude-collab/      # Claude Code 対話ディベート
│   ├── biome/              # Linting/Formatting 設定
│   ├── dependency-cruiser/ # アーキテクチャ検証
│   ├── hurikaeri/          # セッション振り返り（AI-KPT）
│   ├── prompt-improver/    # プロンプト改善
│   ├── shell-debug/        # シェルスクリプトデバッグ
│   ├── ui-design-patterns/ # UI 設計パターン・アクセシビリティ
│   ├── verified-commit/    # 検証付きコミット
│   └── web-requirements/   # 要件定義（Swarm パターン）
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
| claude-collab | Claude Code 同士の自律ディベート | 「Claude同士で議論」「ディベート」「多角的に検討」 |

### コード品質

| スキル | 説明 | トリガー例 |
|--------|------|-----------|
| biome | Biome (Linter/Formatter) 設定 | 「Biome 設定」「リンター設定」 |
| dependency-cruiser | 依存関係・アーキテクチャ検証 | 「依存関係チェック」 |
| shell-debug | シェルスクリプト・ワンライナーのデバッグ | 「シェルデバッグ」「awk エラー」 |
| verified-commit | 検証（lint/test）付きコミット | 「検証コミット」「verified commit」 |

### プロンプト改善

| スキル | 説明 | トリガー例 |
|--------|------|-----------|
| hurikaeri | セッション振り返り（AI-KPT + 反事実推論） | `/hurikaeri` |
| prompt-improver | フィードバック収集・改善提案 | `/improve` |

### 要件定義

| スキル | 説明 | トリガー例 |
|--------|------|-----------|
| web-requirements | Swarm パターンで要件定義・ユーザーストーリー生成 | 「要件定義して」「ユーザーストーリー」 |

### UI/デザイン

| スキル | 説明 | トリガー例 |
|--------|------|-----------|
| ui-design-patterns | コンポーネント設計・レイアウト・アクセシビリティ | 「フォーム設計」「レイアウト作成」「a11y 対応」 |

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

## web-requirements について

### 概要

- Swarm パターン（並列エージェント）で網羅的な要件定義
- 出力: ユーザーストーリー + Gherkin 形式 AC（Given/When/Then）

### ワークフロー

1. **Phase 0**: モード判定（greenfield/brownfield）
2. **Phase 1**: Explorer Swarm（5並列）→ 技術・ドメイン・UI・連携・NFR
3. **Phase 2**: Interviewer（AskUserQuestion ツール直接使用）
4. **Phase 3**: Planner（ストーリーマップ構造化）
5. **Phase 4**: Writer（ユーザーストーリー生成）
6. **Phase 5**: Reviewer Swarm（5並列）→ 品質チェック
7. **Phase 6**: Gate 判定（P0: Blocker / P1: Major / P2: Minor）

### 使用例

```
「認証機能の要件を定義して」
「決済機能にクーポン適用を追加したい」
```

### 出力先

- 中間成果物: `docs/requirements/.work/`（`.gitignore` 設定済み）
- 最終成果物: `docs/requirements/user-stories.md`

※ このリポジトリにサンプルあり（実行時に上書きされる点に注意）

### エージェント構成（推奨モデル）

| カテゴリ | モデル | 役割 |
|---------|--------|------|
| Explorer (5) | sonnet×3, opus×2 | コードベース分析 |
| Planner | opus | ストーリーマップ構造化 |
| Writer | sonnet | ユーザーストーリー生成 |
| Reviewer (5) | haiku×4, opus×1 | 品質チェック |
| Aggregator | opus | Swarm 結果統合 |

※ モデル配分は SKILL.md の設計に基づく推奨値。詳細は `skills/web-requirements/SKILL.md` を参照。

## 技術スタック

- **コア**: Claude Code プラグインシステム
- **AI 連携**: tmux ペイン経由（Codex/Cursor/Gemini CLI）
- **リンター**: Biome（Rust製、ESLint+Prettier代替）
- **依存関係検証**: dependency-cruiser
