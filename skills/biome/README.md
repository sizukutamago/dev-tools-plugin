# Biome Linting & Formatting

TypeScript/JavaScript プロジェクトの Linting・Formatting 設定スキル。

## 概要

Biome は高速な Linter/Formatter で、ESLint + Prettier の代替として使用できます。

**利点:**
- 高速（Rust製）
- 設定が簡単
- ESLint + Prettier の統合不要
- import 自動整理

## セットアップコマンド

新規プロジェクトでの設定:

```
/setup-biome
```

このコマンドで：
1. 既存設定の確認
2. ベース設定の適用
3. プロジェクト構成に応じた調整
4. VSCode 設定の生成（オプション）

## VSCode 連携

`.vscode/settings.json`:

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

## lefthook 連携

`lefthook.yml`:

```yaml
pre-commit:
  commands:
    lint-fix:
      glob: "*.{js,ts,tsx,json}"
      run: bunx biome check --write {staged_files}
      stage_fixed: true
```

## トラブルシューティング

### "Cannot format" エラー

構文エラーがある場合、フォーマットに失敗する。まず構文エラーを修正。

### 特定ファイルを除外したい

```json
{
  "files": {
    "ignore": ["path/to/exclude/**"]
  }
}
```

### ルールを部分的に無効化

```typescript
// biome-ignore lint/suspicious/noExplicitAny: 外部ライブラリの型定義が不十分
const data: any = externalLib.getData();
```

## 関連ドキュメント

- [SKILL.md](./SKILL.md) - AI 向け実行手順・ルール解説
