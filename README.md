# dev-tools-plugin

Claude Code プラグイン - 開発効率化ツール集

AI連携（Codex/Cursor/Gemini）、コード品質（Biome/dependency-cruiser）、プロンプト改善機能を提供します。

## インストール

### マーケットプレイス経由

```bash
# マーケットプレイスを追加
/plugin marketplace add sizukutamago/dev-tools-plugin

# プラグインをインストール
/plugin install dev-tools-plugin@dev-tools-plugin
```

### ローカル開発

```bash
claude --plugin-dir /path/to/dev-tools-plugin
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

## コマンド

| コマンド | 説明 |
|----------|------|
| `/improve` | プロンプト改善分析を実行 |

## セットアップ

AI CLI（Codex/Cursor/Gemini）との連携機能を使う場合：

```bash
./scripts/setup-ai-collab.sh
```

## ライセンス

MIT License - 詳細は [LICENSE](./LICENSE) を参照
