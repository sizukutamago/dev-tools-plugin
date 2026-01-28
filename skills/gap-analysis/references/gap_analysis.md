---
doc_type: gap_analysis
version: "{{VERSION}}"
status: "{{STATUS}}"
updated_at: "{{UPDATED_AT}}"
owners: ["{{OWNER}}"]
tags: [分析, ギャップ分析]
---

# ギャップ分析

## サマリー

| 項目 | 内容 |
|------|------|
| 分析対象 | {{TARGET_FEATURE}} |
| 分析日 | {{ANALYSIS_DATE}} |
| 推奨アプローチ | {{RECOMMENDED_APPROACH}} |
| 工数見積 | {{EFFORT_ESTIMATE}} |
| リスクレベル | {{RISK_LEVEL}} |

### 主要な発見

- {{FINDING_1}}
- {{FINDING_2}}
- {{FINDING_3}}

---

## 1. 現状調査（Current State Investigation）

### 1.1 ドメイン関連資産

| カテゴリ | ファイル/モジュール | 説明 |
|----------|-------------------|------|
| 主要ファイル | {{FILE_PATH}} | {{FILE_DESC}} |
| 再利用可能コンポーネント | {{COMPONENT}} | {{COMPONENT_DESC}} |
| サービス/ユーティリティ | {{SERVICE}} | {{SERVICE_DESC}} |

### 1.2 アーキテクチャパターン

| パターン | 採用状況 | 備考 |
|----------|---------|------|
| {{PATTERN_NAME}} | 採用/未採用 | {{PATTERN_NOTES}} |

### 1.3 規約・慣習

| 項目 | 現状 |
|------|------|
| 命名規則 | {{NAMING_CONVENTION}} |
| レイヤリング | {{LAYERING}} |
| 依存方向 | {{DEPENDENCY_DIRECTION}} |
| テスト配置 | {{TEST_PLACEMENT}} |

### 1.4 統合ポイント

| 種別 | 詳細 |
|------|------|
| データモデル/スキーマ | {{DATA_MODEL}} |
| APIクライアント | {{API_CLIENT}} |
| 認証機構 | {{AUTH_MECHANISM}} |

---

## 2. 要件実現可能性分析（Requirements Feasibility Analysis）

### 2.1 技術要件の抽出

| 要件ID | 技術要件 | 分類 |
|--------|---------|------|
| {{REQ_ID}} | {{TECH_REQUIREMENT}} | データモデル/API/UI/ビジネスルール |

### 2.2 ギャップ・制約

| 項目 | ステータス | 詳細 |
|------|-----------|------|
| {{GAP_ITEM}} | Missing/Unknown/Constraint | {{GAP_DETAIL}} |

### 2.3 複雑性シグナル

| 項目 | 評価 |
|------|------|
| 単純CRUD | Yes/No |
| アルゴリズムロジック | Yes/No |
| ワークフロー | Yes/No |
| 外部統合 | Yes/No |

### 2.4 Research Needed（要調査項目）

| 項目 | 調査内容 | 優先度 |
|------|---------|--------|
| {{RESEARCH_ITEM}} | {{RESEARCH_DETAIL}} | High/Medium/Low |

---

## 3. 実装アプローチ検討

### 3.1 Option A: 既存コンポーネント拡張

**概要**: {{OPTION_A_SUMMARY}}

#### 変更対象ファイル

| ファイル | 変更内容 | 影響範囲 |
|---------|---------|---------|
| {{FILE_PATH}} | {{CHANGE_DESC}} | {{IMPACT}} |

#### 互換性評価

| 項目 | 評価 | 備考 |
|------|------|------|
| 既存インターフェース | 互換/非互換 | {{NOTES}} |
| 既存テスト | 影響あり/なし | {{NOTES}} |

#### Trade-offs

| メリット | デメリット |
|----------|-----------|
| {{PRO}} | {{CON}} |

### 3.2 Option B: 新規コンポーネント作成

**概要**: {{OPTION_B_SUMMARY}}

#### 新規作成ファイル

| ファイル | 責務 |
|---------|------|
| {{NEW_FILE_PATH}} | {{RESPONSIBILITY}} |

#### 統合ポイント

| 既存コンポーネント | 統合方法 |
|------------------|---------|
| {{EXISTING_COMPONENT}} | {{INTEGRATION_METHOD}} |

#### Trade-offs

| メリット | デメリット |
|----------|-----------|
| {{PRO}} | {{CON}} |

### 3.3 Option C: ハイブリッドアプローチ

**概要**: {{OPTION_C_SUMMARY}}

#### フェーズ分け

| フェーズ | 内容 | アプローチ |
|---------|------|-----------|
| Phase 1 | {{PHASE1_CONTENT}} | 拡張/新規 |
| Phase 2 | {{PHASE2_CONTENT}} | 拡張/新規 |

#### リスク軽減策

| リスク | 軽減策 |
|--------|--------|
| {{RISK}} | {{MITIGATION}} |

---

## 4. 複雑性・リスク評価

### 4.1 工数見積

| アプローチ | 工数 | 根拠 |
|-----------|------|------|
| Option A | S/M/L/XL | {{EFFORT_REASON_A}} |
| Option B | S/M/L/XL | {{EFFORT_REASON_B}} |
| Option C | S/M/L/XL | {{EFFORT_REASON_C}} |

### 4.2 リスク評価

| アプローチ | リスク | 根拠 |
|-----------|--------|------|
| Option A | High/Medium/Low | {{RISK_REASON_A}} |
| Option B | High/Medium/Low | {{RISK_REASON_B}} |
| Option C | High/Medium/Low | {{RISK_REASON_C}} |

---

## 5. 推奨事項

### 推奨アプローチ

**{{RECOMMENDED_OPTION}}** を推奨

#### 理由

- {{RECOMMENDATION_REASON_1}}
- {{RECOMMENDATION_REASON_2}}

### 設計フェーズへの引き継ぎ事項

| 項目 | 内容 |
|------|------|
| 重要な設計決定 | {{KEY_DECISION}} |
| 追加調査項目 | {{RESEARCH_ITEM}} |
| 注意点 | {{CAUTION}} |

---

## 変更履歴

| 日付 | Ver | 変更者 | 内容 |
|------|-----|--------|------|
| {{DATE}} | {{VERSION}} | {{AUTHOR}} | {{CHANGE}} |
