# ai-skills プロジェクト

Claude Code プラグインとして、日本語開発者向けの8フェーズ設計ドキュメントワークフローを提供するリポジトリ。

## プロジェクト構造

```
ai-skills/
├── .claude-plugin/          # プラグインメタデータ
├── agents/                  # エージェント定義（11種）
├── commands/                # コマンド定義（2種）
├── skills/                  # スキル実装（22種）
│   ├── hearing/            # Phase 1: 要件ヒアリング
│   ├── requirements/       # Phase 2: 要件定義
│   ├── architecture/       # Phase 3: アーキテクチャ設計
│   ├── database/           # Phase 4: データ構造設計
│   ├── api/                # Phase 5: API仕様
│   ├── design/             # Phase 6: 画面設計
│   ├── implementation/     # Phase 7: 実装準備
│   ├── design-doc-reviewer/ # Phase 8: レビュー
│   ├── biome/              # Linting/Formatting設定
│   ├── dependency-cruiser/ # アーキテクチャ検証
│   └── shared/             # 共有テンプレート
├── biome/                   # ルートBiome設定
├── dependency-cruiser/      # ルートdep-cruiser設定
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

**コマンド:**

```markdown
---
name: command-name
description: English description
---

# コマンドタイトル

日本語ドキュメント...
```

### ID体系

| プレフィックス | 用途 | 例 |
|---------------|------|-----|
| FR | 機能要件 | FR-001 |
| NFR | 非機能要件 | NFR-PERF-001 |
| SC | 成功基準 | SC-001 |
| API | API仕様 | API-001 |
| ENT | エンティティ | ENT-User |
| ADR | 設計決定記録 | ADR-0001 |

**NFRカテゴリ:**
- PERF: パフォーマンス
- SEC: セキュリティ
- AVL: 可用性
- SCL: スケーラビリティ
- MNT: 保守性
- OPR: 運用
- CMP: 互換性
- ACC: アクセシビリティ

## コマンド

### インストール

```bash
./install.sh                      # ~/.claude にインストール
./install.sh -t /custom/path      # カスタムパス指定
./install.sh --skip-design-docs   # 設計ドキュメントワークフロースキップ
```

### スキル呼び出し

```bash
/hearing          # Phase 1: 要件ヒアリング開始
/requirements     # Phase 2: 要件定義
/architecture     # Phase 3: アーキテクチャ設計
/database         # Phase 4: データ構造設計
/api              # Phase 5: API仕様作成
/design           # Phase 6: 画面設計
/implementation   # Phase 7: 実装準備
/design-docs      # 全フェーズオーケストレーション
/setup-biome      # Biome設定
/setup-depcruise  # dependency-cruiser設定
```

## 出力規約

設計ドキュメントは `docs/` 配下に生成:

```
docs/
├── project-context.yaml    # プロジェクト状態管理
├── 01_hearing/            # ヒアリング結果
├── 02_requirements/       # 要件定義書
├── 03_architecture/       # アーキテクチャ設計
├── 04_data_structure/     # データ構造定義
├── 05_api_design/         # API仕様書
├── 06_screen_design/      # 画面設計書
├── 07_implementation/     # 実装計画
└── 08_review/             # レビュー結果
```

## 変更時の注意

### スキル編集時

1. `SKILL.md` の frontmatter description は英語で記述
2. バージョン番号を適切に更新（セマンティックバージョニング）
3. `references/` 配下のテンプレートとの整合性を確認
4. 依存する他スキルへの影響を考慮

### エージェント編集時

1. `tools` リストは実際に使用可能なツールのみ記載
2. `color` は他エージェントと重複しないよう設定
3. `model: inherit` を基本とし、特別な理由がある場合のみ変更

### テンプレート編集時

1. プレースホルダーは `{{placeholder}}` 形式
2. 日本語コメントで用途を明記
3. 実際の出力例を `references/` に配置

## 品質基準

- 曖昧な表現（「など」「適切に」）は具体化するか補足説明を追加
- 用語は `glossary.md` で定義し一貫性を保つ
- 各フェーズの依存関係を明確に定義
- dependency-cruiser でアーキテクチャ検証
- Biome でコードスタイル統一

## 技術スタック

- **コア**: Claude Code プラグインシステム
- **リンター**: Biome（Rust製、ESLint+Prettier代替）
- **依存関係検証**: dependency-cruiser
- **ブラウザ自動化**: Playwright
- **ドキュメント参照**: Context7 MCP
