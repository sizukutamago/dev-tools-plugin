---
name: setup-biome
description: プロジェクトにBiome linter/formatterをセットアップする
---

# Biome セットアップコマンド

このコマンドは、プロジェクトにBiomeの推奨設定を適用します。

## 実行手順

### 1. 既存設定の確認

まず、プロジェクトに既存のbiome.jsonがあるか確認してください：

```bash
ls -la biome.json 2>/dev/null || echo "biome.json not found"
```

既存設定がある場合は、ユーザーに上書きするか確認してください。

### 2. プロジェクト構成の分析

package.jsonを読んで、以下を確認：
- モノレポか単一パッケージか（workspaces の有無）
- 既存の lint スクリプトの有無
- TypeScript/JavaScript プロジェクトか

### 3. ベース設定の適用

`~/.claude/skills/biome/templates/biome.base.json` の内容をプロジェクトルートの `biome.json` にコピーします。

### 4. プロジェクト固有の調整

#### モノレポの場合

`files.ignore` に以下を追加：
```json
{
  "files": {
    "ignore": [
      "node_modules",
      "dist",
      "*.lockb",
      ".git",
      "**/drizzle/**",
      "**/public/assets/**"
    ]
  }
}
```

#### フロントエンドプロジェクトの場合

ビルド出力ディレクトリを除外に追加：
```json
{
  "files": {
    "ignore": [
      "node_modules",
      "dist",
      "build",
      ".next",
      "out",
      "*.lockb",
      ".git"
    ]
  }
}
```

### 5. package.json スクリプト追加

package.json に以下のスクリプトを追加（既存のものがなければ）：

```json
{
  "scripts": {
    "lint": "biome check .",
    "lint:fix": "biome check --write .",
    "format": "biome format --write ."
  }
}
```

### 6. VSCode設定（オプション）

ユーザーが希望する場合、`.vscode/settings.json` を作成または更新：

```json
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "biomejs.biome",
  "editor.codeActionsOnSave": {
    "quickfix.biome": "explicit",
    "source.organizeImports.biome": "explicit"
  }
}
```

### 7. lefthook連携（オプション）

ユーザーがpre-commit hookを希望する場合、`lefthook.yml` を作成または更新：

```yaml
pre-commit:
  commands:
    lint-fix:
      glob: "*.{js,ts,tsx,json}"
      run: bunx biome check --write {staged_files}
      stage_fixed: true
```

## 完了メッセージ

セットアップ完了後、以下を伝える：
- `bun run lint` で lint 実行可能
- `bun run lint:fix` で自動修正可能
- VSCode拡張「Biome」のインストールを推奨
