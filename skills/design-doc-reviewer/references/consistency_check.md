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
