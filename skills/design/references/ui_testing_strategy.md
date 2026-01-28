---
doc_type: ui_testing_strategy
version: "{{VERSION}}"
status: "{{STATUS}}"
updated_at: "{{UPDATED_AT}}"
owners: ["{{OWNER}}"]
tags: [画面設計, テスト]
---

# 画面テスト戦略

## 1. テストピラミッド（UI観点）

| レベル | 割合目安 | 対象 | ツール例 |
|--------|---------|------|---------|
| Component Tests | 60% | 個別コンポーネント | Testing Library, Storybook |
| Integration Tests | 25% | 画面単位フロー | Testing Library + MSW |
| E2E Tests | 10% | ユーザーシナリオ | Playwright, Cypress |
| Visual Regression | 5% | UIスナップショット | Chromatic, Percy |

## 2. コンポーネントテスト観点

### 基本観点

| 観点 | 説明 | 例 |
|------|------|-----|
| Props variations | 全Propsパターン | disabled, loading, error |
| User interactions | ユーザー操作 | click, input, focus |
| Accessibility | a11y準拠 | aria属性、キーボード操作 |
| Edge cases | 境界値 | 空データ、長文、特殊文字 |

### コンポーネント別テスト項目

| コンポーネント | テスト項目 | 優先度 |
|---------------|-----------|--------|
| {{COMPONENT}} | {{TEST_ITEMS}} | High/Medium/Low |

## 3. 画面単位インテグレーションテスト

### クリティカルパス定義

| SC-ID | 画面名 | クリティカルパス | テストシナリオ |
|-------|--------|-----------------|---------------|
| {{SC_ID}} | {{NAME}} | {{CRITICAL_PATH}} | {{SCENARIO}} |

### テストシナリオ例

```gherkin
Feature: {{FEATURE_NAME}}
  Scenario: {{SCENARIO_NAME}}
    Given {{PRECONDITION}}
    When {{ACTION}}
    Then {{EXPECTED}}
```

## 4. E2Eテストシナリオ

### ユーザージャーニー別

| ジャーニー | 対象画面 | シナリオ | 優先度 |
|-----------|---------|----------|--------|
| {{JOURNEY}} | {{SCREENS}} | {{SCENARIO}} | High/Medium/Low |

### E2Eテスト対象選定基準

| 基準 | 説明 |
|------|------|
| ビジネスインパクト | 収益・コア機能に直結する操作 |
| 利用頻度 | ユーザーが頻繁に使う機能 |
| 複雑性 | 複数画面にまたがるフロー |
| リスク | 失敗時の影響が大きい操作 |

## 5. Visual Regressionテスト対象

| SC-ID | 画面名 | スナップショット取得条件 | 備考 |
|-------|--------|------------------------|------|
| {{SC_ID}} | {{NAME}} | {{CONDITIONS}} | {{NOTES}} |

### スナップショット取得タイミング

| タイミング | 説明 |
|-----------|------|
| 初期表示 | ページロード完了時 |
| データ読み込み後 | API応答後の表示 |
| インタラクション後 | 主要な操作後の状態 |
| エラー状態 | エラー表示時 |

## 6. テストカバレッジ目標

| 対象 | カバレッジ目標 | 優先基準 |
|------|---------------|----------|
| 共通コンポーネント | 90% | 再利用頻度 |
| 画面コンポーネント | 70% | 業務重要度 |
| E2Eシナリオ | 主要フロー100% | ビジネスインパクト |
| Visual Regression | 主要画面100% | UI変更頻度 |

## 7. テストデータ戦略

| データ種別 | 管理方法 | 例 |
|-----------|---------|-----|
| Fixture | JSONファイル | ユーザー情報、商品データ |
| Factory | ファクトリ関数 | 動的なテストデータ生成 |
| Mock API | MSW/Mirage | API応答のモック |

## 8. アクセシビリティテスト

| テスト項目 | ツール | 自動化 |
|-----------|--------|--------|
| WAI-ARIA準拠 | axe-core | 可 |
| キーボード操作 | 手動 + Playwright | 一部可 |
| スクリーンリーダー | NVDA/VoiceOver | 手動 |
| 色コントラスト | axe-core | 可 |

## 変更履歴

| 日付 | Ver | 変更者 | 内容 |
|------|-----|--------|------|
| {{DATE}} | {{VERSION}} | {{AUTHOR}} | {{CHANGE}} |
