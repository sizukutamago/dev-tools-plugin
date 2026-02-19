# カスタムエージェント作成ガイド

monkey-test スキルに独自のテスターエージェントを追加する手順。

## 概要

デフォルトの6種（**workflow**, explorer, naive-user, chaos-input, security-hunter, spec-aware）に加えて、
独自の「性格」を持つテスターエージェントを追加できる。

> **Note**: `tester-workflow` は組み込みエージェントで、Phase 2a/3a で先行実行される特別な役割を持つ。他のエージェントと異なり、複数ページにまたがる E2E ワークフローを計画し、テストデータ（`created_data.json`）を生成する。

## 手順

1. `templates/custom-agent-template.md` をコピー
2. `agents/swarm/tester-{your-name}.md` として保存
3. 各セクションを記入
4. Phase 0 の Configuration でエージェント名を指定して有効化

## 必須セクション

### 1. Frontmatter

```yaml
---
name: monkey-test-tester-{your-name}
description: English description of what this agent tests and when to use it.
tools: Read, Glob, Grep
model: sonnet
---
```

- `name`: `monkey-test-tester-` プレフィックス必須
- `description`: **英語**（Claude のトリガー検出用）
- `tools`: 常に `Read, Glob, Grep`（Planning エージェントは Playwright にアクセスできない）
- `model`: `sonnet`（通常）、`opus`（深い推論が必要な場合）

### 2. 性格・行動パターン

このエージェントがどういう「人」としてテストするか。
具体的な行動パターンを列挙する。

**良い例**:
> せっかちなモバイルユーザー。読み込みが遅いとすぐ戻るボタンを押す。
> スクロールせずに見える範囲だけ操作する。フォームは途中で離脱する。

**悪い例**:
> テストする人。

### 3. 戦略

Recon データからどのようにテストシーケンスを組み立てるかの方針。

考慮すべき項目:
- どのページを優先するか（全ページ？フォームがあるページだけ？）
- どの要素を操作するか（全要素？特定タイプだけ？）
- 入力値の選択基準
- シーケンスの構成パターン（ページ単位？機能単位？）

### 4. 入力

エージェントが読む情報源:

| 入力 | 必須 | 説明 |
|------|------|------|
| `01_recon_data.md` | Yes | ページ構造・要素カタログ |
| `01b_spec_context.md` | No | 仕様・コード分析結果 |
| `shared/issue_registry.md` | No | 先行エージェントの発見 |

### 5. 出力

`test_plan_schema.md` に準拠したテストプランを出力する。

### 6. 制約

- アクション予算を守ること（config の action_budget）
- Priority（high/medium/low）を適切に割り当てること
- Handoff Envelope を含めること

### 7. テストプラン生成ルール

このエージェント固有の生成ルール。

例（アクセシビリティテスター）:
- Tab キーのみでフォームを完了できるシーケンスを生成
- 各入力フィールドに aria-label があるか検証
- カラーコントラスト比を evaluate で計算

## テストプランの品質チェックリスト

- [ ] 全シーケンスに Starting URL がある
- [ ] 全シーケンスに Priority がある
- [ ] TargetRef は Recon カタログの要素 ID を正しく参照している
- [ ] アクション総数が予算内に収まっている
- [ ] Assertion が具体的で検証可能である
- [ ] Handoff Envelope が含まれている

## 組み込みエージェント

| エージェント名 | モデル | 予算 | 実行フェーズ | 説明 |
|-------------|--------|------|------------|------|
| `tester-workflow` | opus | 45 | 2a/3a（先行） | E2E ワークフロー。CRUD ライフサイクル、クロスリソーステスト |
| `tester-explorer` | sonnet | 30 | 2b/3b | 系統的カバレッジ最大化。全ページ・全要素を正常値で操作 |
| `tester-naive-user` | sonnet | 30 | 2b/3b | 初回訪問ユーザー。空送信、誤入力、連打 |
| `tester-chaos-input` | sonnet | 30 | 2b/3b | カオス入力。極端な長さ、Unicode 異常、NaN |
| `tester-security-hunter` | opus | 40 | 2b/3b | セキュリティ。XSS、SQLi、CSRF、ヘッダー検証 |
| `tester-spec-aware` | opus | 30 | 2b/3b | 仕様ベース。ビジネスルール、境界値、状態遷移 |

## ワークフローテストの概念

`tester-workflow` は他のエージェントと根本的に異なるテスト戦略を持つ:

| 観点 | 他のエージェント | tester-workflow |
|------|----------------|----------------|
| スコープ | 1ページ内の操作 | 複数ページにまたがるジャーニー |
| データ | 入力→バリデーション | 作成→表示→編集→削除 |
| 依存関係 | 独立した操作 | リソース間の依存を辿る |
| 検証 | Assertion でその場確認 | データフロー全体の整合性 |
| 実行順 | Phase 3b（後追い） | Phase 3a（先行、データ生成） |

## 追加エージェントの候補例

| エージェント名 | 性格 | 主なテスト観点 |
|-------------|------|-------------|
| `tester-accessibility` | スクリーンリーダーユーザー | Tab 操作、aria 属性、コントラスト |
| `tester-mobile` | スマホユーザー | タッチ操作、ビューポート、横スクロール |
| `tester-impatient` | せっかちなユーザー | 読み込み中の操作、連打、途中離脱 |
| `tester-i18n` | 多言語ユーザー | RTL テキスト、CJK 文字、タイムゾーン |
| `tester-state-integrity` | 状態管理テスター | 戻る/進む、タブ切替、セッション期限 |
| `tester-performance` | 負荷テスター | 大量データ入力、高速連打、同時操作 |
