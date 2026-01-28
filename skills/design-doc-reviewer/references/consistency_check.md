# 整合性チェック結果

---

## チェック情報

| 項目 | 内容 |
|------|------|
| チェック日 | {{CHECK_DATE}} |
| 対象ドキュメント | 全ドキュメント |
| チェック担当者 | {{CHECKER}} |
| 総合判定 | {{OVERALL_RESULT}} |

総合判定の凡例: ✅ PASS / ⚠️ WARNING / ❌ BLOCKER

---

## ID整合性チェック

### 重複ID

| ID | 出現箇所 |
|----|----------|
| {{DUPLICATE_ID}} | {{出現箇所}} |

### 孤児ID（参照されていないID）

| ID | 定義箇所 |
|----|----------|
| {{ORPHAN_ID}} | {{定義箇所}} |

### YAMLフロントマターとの整合性

| ドキュメント | coverage定義 | 本文内ID | 差分 |
|-------------|-------------|---------|------|
| {{DOCUMENT}} | {{YAML_IDS}} | {{BODY_IDS}} | {{DIFF}} |

---

## 出力ファイル完全性チェック

### Phase 0: Analysis（分析）- オプション

既存プロジェクト拡張時のみ使用

| ファイル | 状態 | 備考 |
|---------|------|------|
| docs/00_analysis/research.md | {{P0_FILE1_STATUS}} | 技術調査結果 |
| docs/00_analysis/gap_analysis.md | {{P0_FILE2_STATUS}} | ギャップ分析結果 |

### Phase 1: Hearing（ヒアリング）

| ファイル | 状態 |
|---------|------|
| docs/01_hearing/project_overview.md | {{P1_FILE1_STATUS}} |
| docs/01_hearing/hearing_result.md | {{P1_FILE2_STATUS}} |
| docs/01_hearing/glossary.md | {{P1_FILE3_STATUS}} |

### Phase 2: Requirements（要件定義）

| ファイル | 状態 |
|---------|------|
| docs/02_requirements/requirements.md | {{P2_FILE1_STATUS}} |
| docs/02_requirements/functional_requirements.md | {{P2_FILE2_STATUS}} |
| docs/02_requirements/non_functional_requirements.md | {{P2_FILE3_STATUS}} |

### Phase 3: Architecture（アーキテクチャ）

| ファイル | 状態 |
|---------|------|
| docs/03_architecture/architecture.md | {{P3_FILE1_STATUS}} |
| docs/03_architecture/adr.md | {{P3_FILE2_STATUS}} |
| docs/03_architecture/security.md | {{P3_FILE3_STATUS}} |
| docs/03_architecture/infrastructure.md | {{P3_FILE4_STATUS}} |

### Phase 4: Database（データ構造）

| ファイル | 状態 |
|---------|------|
| docs/04_data_structure/data_structure.md | {{P4_FILE1_STATUS}} |

### Phase 5: API（API設計）

| ファイル | 状態 |
|---------|------|
| docs/05_api_design/api_design.md | {{P5_FILE1_STATUS}} |
| docs/05_api_design/integration.md | {{P5_FILE2_STATUS}} |

### Phase 6: Design（画面設計）

| ファイル | 状態 |
|---------|------|
| docs/06_screen_design/screen_list.md | {{P6_FILE1_STATUS}} |
| docs/06_screen_design/screen_transition.md | {{P6_FILE2_STATUS}} |
| docs/06_screen_design/component_catalog.md | {{P6_FILE3_STATUS}} |
| docs/06_screen_design/error_patterns.md | {{P6_FILE4_STATUS}} |
| docs/06_screen_design/ui_testing_strategy.md | {{P6_FILE5_STATUS}} |
| docs/06_screen_design/details/ (全SC-ID分) | 下記「画面詳細ファイル完全性チェック」参照 |

### Phase 7: Implementation（実装準備）

| ファイル | 状態 |
|---------|------|
| docs/07_implementation/coding_standards.md | {{P7_FILE1_STATUS}} |
| docs/07_implementation/environment.md | {{P7_FILE2_STATUS}} |
| docs/07_implementation/testing.md | {{P7_FILE3_STATUS}} |
| docs/07_implementation/operations.md | {{P7_FILE4_STATUS}} |

### ファイル完全性サマリー

| フェーズ | 必須ファイル数 | 存在数 | 不足数 | 状態 |
|---------|--------------|--------|--------|------|
| Phase 1: Hearing | 3 | {{P1_EXISTS}} | {{P1_MISSING}} | {{P1_STATUS}} |
| Phase 2: Requirements | 3 | {{P2_EXISTS}} | {{P2_MISSING}} | {{P2_STATUS}} |
| Phase 3: Architecture | 4 | {{P3_EXISTS}} | {{P3_MISSING}} | {{P3_STATUS}} |
| Phase 4: Database | 1 | {{P4_EXISTS}} | {{P4_MISSING}} | {{P4_STATUS}} |
| Phase 5: API | 2 | {{P5_EXISTS}} | {{P5_MISSING}} | {{P5_STATUS}} |
| Phase 6: Design | 3+N | {{P6_EXISTS}} | {{P6_MISSING}} | {{P6_STATUS}} |
| Phase 7: Implementation | 4 | {{P7_EXISTS}} | {{P7_MISSING}} | {{P7_STATUS}} |
| **合計** | **{{TOTAL_REQUIRED}}** | **{{TOTAL_EXISTS}}** | **{{TOTAL_MISSING}}** | **{{TOTAL_STATUS}}** |

### 不足ファイル一覧

| フェーズ | 不足ファイル |
|---------|-------------|
| {{MISSING_PHASE}} | {{MISSING_FILE}} |

---

## 画面詳細ファイル完全性チェック

### 定義済SC-ID一覧

| SC-ID | 画面名 | 詳細ファイル | 状態 |
|-------|--------|-------------|------|
| {{SC_ID}} | {{SCREEN_NAME}} | {{DETAIL_FILE}} | {{FILE_STATUS}} |

### サマリー

| 項目 | 値 |
|------|-----|
| 定義済SC-ID数 | {{SC_DEFINED_COUNT}} |
| 詳細ファイル数 | {{DETAIL_FILE_COUNT}} |
| 不足ファイル数 | {{MISSING_FILE_COUNT}} |
| 完全性 | {{COMPLETENESS_STATUS}} |

### 不足ファイル一覧

| SC-ID | 画面名 | 必要なファイル |
|-------|--------|---------------|
| {{MISSING_SC_ID}} | {{MISSING_SCREEN_NAME}} | screen_detail_{{MISSING_SC_ID}}.md |

---

## 設計スコープ整合性チェック

### Goals/Non-Goals と FR の整合性

| Goals項目 | 対応FR | 整合性 |
|----------|--------|--------|
| {{GOAL}} | {{RELATED_FR}} | ✅/⚠️/❌ |

| Non-Goals項目 | FRに含まれていないか | 整合性 |
|--------------|-------------------|--------|
| {{NON_GOAL}} | {{FR_CHECK}} | ✅/⚠️ |

### エラーパターンと Architecture の整合性

| エラーカテゴリ | Architecture定義 | design定義 | 整合性 |
|--------------|-----------------|-----------|--------|
| User Errors (4xx) | architecture.md エラーハンドリング設計 | error_patterns.md User Errors | ✅/⚠️ |
| System Errors (5xx) | architecture.md リトライ戦略 | error_patterns.md System Errors | ✅/⚠️ |
| Business Logic (422) | architecture.md 業務ルール違反 | error_patterns.md Business Logic | ✅/⚠️ |
| {{ERROR_CATEGORY}} | {{ARCH_ERROR_HANDLING}} | {{DESIGN_ERROR_PATTERN}} | ✅/⚠️ |

### テスト戦略と Implementation の整合性

| 画面テストレベル | 実装テストレベル | チェック内容 | 整合性 |
|---------------|----------------|------------|--------|
| Component Tests | Unit Tests | カバレッジ目標の整合 | ✅/⚠️ |
| Integration Tests | Integration Tests | API統合テスト対応 | ✅/⚠️ |
| E2E Tests | E2E Tests | 業務フロー対応 | ✅/⚠️ |
| Visual Regression | - | UI変更検知 | ✅/⚠️ |
| {{TEST_LEVEL}} | {{IMPL_TEST_STRATEGY}} | {{CHECK_CONTENT}} | ✅/⚠️ |

---

## トレーサビリティマトリクス

| FR ID | FR名 | 関連SC | 関連API | 関連ENT | 状態 |
|-------|------|--------|---------|---------|------|
| {{FR_ID}} | {{FR_NAME}} | {{SC_IDS}} | {{API_IDS}} | {{ENT_IDS}} | {{STATUS}} |

---

## カバレッジサマリー

| ID種別 | 定義数 | 参照数 | カバレッジ |
|--------|--------|--------|-----------|
| FR-XXX | {{FR_COUNT}} | {{FR_REF}} | {{FR_COVERAGE}} |
| SC-XXX | {{SC_COUNT}} | {{SC_REF}} | {{SC_COVERAGE}} |
| API-XXX | {{API_COUNT}} | {{API_REF}} | {{API_COVERAGE}} |
| ENT-XXX | {{ENT_COUNT}} | {{ENT_REF}} | {{ENT_COVERAGE}} |
| NFR-XXX | {{NFR_COUNT}} | {{NFR_REF}} | {{NFR_COVERAGE}} |
| ADR-XXXX | {{ADR_COUNT}} | {{ADR_REF}} | {{ADR_COVERAGE}} |

---

## アクション推奨

### ❌ BLOCKER

| # | 指摘内容 |
|---|----------|
| 1 | {{指摘内容}} |

### ⚠️ WARNING

| # | 指摘内容 |
|---|----------|
| 1 | {{指摘内容}} |

---

## 良い点

{{GOOD_POINTS}}

---

## 統計情報

| 項目 | 値 |
|------|-----|
| 総ドキュメント数 | {{TOTAL_DOCS}} |
| 総ID数 | {{TOTAL_IDS}} |
| 整合性エラー数 | {{ERROR_COUNT}} |
| 警告数 | {{WARNING_COUNT}} |

---

## 結論

{{CONCLUSION}}
