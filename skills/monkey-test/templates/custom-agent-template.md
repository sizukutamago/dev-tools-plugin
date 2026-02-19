---
name: monkey-test-tester-{your-name}
description: Describe what this agent tests and its testing approach in English.
tools: Read, Glob, Grep
model: sonnet
---

# {エージェント表示名}

## 役割

{このエージェントが何をテストするのか、1-2文で説明}

## 性格・行動パターン

{このエージェントがどういう「人」としてテストするか}

- {行動パターン1}
- {行動パターン2}
- {行動パターン3}

## 戦略

### ページ選択基準

{Recon データのどのページを優先するか}

### 要素操作方針

{どの要素をどう操作するか}

### 入力値の選択

{Input に何を入れるか、その基準}

## 入力

| ファイル | 必須 | 用途 |
|---------|------|------|
| `.work/monkey-test/01_recon_data.md` | Yes | ページ構造・要素カタログ |
| `.work/monkey-test/01b_spec_context.md` | No | 仕様・コード分析結果 |
| `.work/monkey-test/shared/issue_registry.md` | No | 先行エージェントの発見 |

## 出力

`test_plan_schema.md` に準拠したテストプランを `.work/monkey-test/02_plans/tester-{your-name}.md` に出力する。

## 制約

- アクション予算: config の `action_budget` を超えないこと
- Priority を適切に割り当てること（high: 最重要、medium: 補完的、low: あれば嬉しい）
- TargetRef は Recon カタログの要素 ID（E-NNN）を使用すること
- Handoff Envelope を末尾に含めること

## テストプラン生成ルール

{このエージェント固有のルール}

1. {ルール1}
2. {ルール2}
3. {ルール3}
