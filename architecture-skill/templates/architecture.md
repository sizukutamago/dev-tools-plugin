---
doc_type: architecture
version: "{{VERSION}}"
status: "{{STATUS}}"
updated_at: "{{UPDATED_AT}}"
owners: ["{{OWNER}}"]
tags: [アーキテクチャ]
coverage:
  fr: []
  nfr: []
  adr: []
---

# システムアーキテクチャ設計書

## 設計方針

| 項目 | 内容 |
|------|------|
| 基本方針 | {{BASIC_POLICY}} |
| パターン | {{ARCH_PATTERN}} |
| 設計原則 | {{DESIGN_PRINCIPLE}} |

## システム構成

### 構成図

```mermaid
graph TB
    subgraph {{LAYER}}
        {{COMPONENT}}[{{COMPONENT_NAME}}]
    end
    
    {{COMPONENT_FROM}} --> {{COMPONENT_TO}}
```

### コンポーネント一覧

| コンポーネント | 種別 | 説明 |
|---------------|------|------|
| {{COMPONENT}} | {{TYPE}} | {{DESC}} |

### コンポーネント詳細

#### {{コンポーネント名}}

| 項目 | 内容 |
|------|------|
| 役割 | {{ROLE}} |
| 技術 | {{TECHNOLOGY}} |
| 責務 | {{RESPONSIBILITY}} |

## 技術スタック

### フロントエンド

| 技術 | バージョン | 選定理由 |
|------|-----------|----------|
| {{TECH}} | {{VERSION}} | {{REASON}} |

### バックエンド

| 技術 | バージョン | 選定理由 |
|------|-----------|----------|
| {{TECH}} | {{VERSION}} | {{REASON}} |

### インフラ

| 技術 | 用途 | 選定理由 |
|------|------|----------|
| {{TECH}} | {{PURPOSE}} | {{REASON}} |

## 関連ドキュメント

| ドキュメント | リンク |
|-------------|--------|
| ADR | [adr.md](./adr.md) |
| セキュリティ設計書 | [security.md](./security.md) |
| インフラ設計書 | [infrastructure.md](./infrastructure.md) |

## 変更履歴

| 日付 | Ver | 変更者 | 内容 |
|------|-----|--------|------|
| {{DATE}} | {{VERSION}} | {{AUTHOR}} | {{CHANGE}} |
