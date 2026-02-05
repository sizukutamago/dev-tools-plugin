# verified-commit

検証付きコミットワークフロー。コミット前に適切な検証を行い、品質を担保する。

## 概要

このスキルは、コミット前に lint、型チェック、テストなどの検証を自動実行し、品質を担保するためのワークフローを提供します。

## コンセプト

**2段階の検証モード**:
- **quick**: 軽量検証（lint + 型チェック）- デフォルト
- **full**: 完全検証（lint + 型チェック + テスト）- 重要な変更時

## 関連スキル

| スキル | 用途 | 連携 |
|--------|------|------|
| `/verified-commit` | 検証付きコミット | メイン |
| `/shell-debug` | シェルスクリプト検証失敗時 | shellcheck 警告の詳細調査 |
| `/tdd-integration` | テスト駆動開発 | full 検証モードと連携 |

## カスタマイズ

プロジェクトごとに検証コマンドをカスタマイズする場合は、プロジェクトの `CLAUDE.md` に記載:

```markdown
## Commit検証設定

### quick検証
- `npm run lint`
- `npm run typecheck`

### full検証
- `npm run lint`
- `npm run typecheck`
- `npm run test:unit`
```

## 関連ドキュメント

- [SKILL.md](./SKILL.md) - AI 向け実行手順・検証フロー
