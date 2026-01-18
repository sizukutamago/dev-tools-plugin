---
doc_type: adr
version: "{{VERSION}}"
status: "{{STATUS}}"
updated_at: "{{UPDATED_AT}}"
owners: ["{{OWNER}}"]
tags: [ADR]
coverage:
  adr: []
---

# アーキテクチャ決定記録（ADR）

## ID採番ルール

| 項目 | ルール |
|------|--------|
| 形式 | ADR-XXXX（4桁） |
| 開始 | 0001 |

## ステータス定義

| ステータス | 説明 |
|-----------|------|
| Proposed | 提案中 |
| Accepted | 承認済 |
| Deprecated | 非推奨 |
| Superseded | 後継で置換 |

## ADR一覧

| ADR ID | タイトル | ステータス | 日付 | 関連ADR |
|--------|----------|-----------|------|---------|
| ADR-{{ID}} | {{TITLE}} | {{STATUS}} | {{DATE}} | {{RELATED}} |

## ADR詳細

### ADR-{{ID}}: {{タイトル}}

| 項目 | 内容 |
|------|------|
| ADR ID | ADR-{{ID}} |
| ステータス | {{STATUS}} |
| 日付 | {{DATE}} |

#### コンテキスト

{{CONTEXT}}

#### 決定

{{DECISION}}

#### 理由

{{RATIONALE}}

#### 代替案

| 代替案 | 却下理由 |
|--------|----------|
| {{ALTERNATIVE}} | {{REJECTION_REASON}} |

#### 影響

{{IMPACT}}

#### 関連ADR

{{RELATED_ADR}}

## ADRテンプレート

```markdown
### ADR-XXXX: [タイトル]

| 項目 | 内容 |
|------|------|
| ADR ID | ADR-XXXX |
| ステータス | Proposed |
| 日付 | YYYY-MM-DD |

#### コンテキスト
[背景・課題]

#### 決定
[決定内容]

#### 理由
[決定理由]

#### 代替案
| 代替案 | 却下理由 |
|--------|----------|
| [代替案] | [却下理由] |

#### 影響
[影響・トレードオフ]

#### 関連ADR
[関連ADR ID]
```

## 変更履歴

| 日付 | Ver | 変更者 | 内容 |
|------|-----|--------|------|
| {{DATE}} | {{VERSION}} | {{AUTHOR}} | {{CHANGE}} |
