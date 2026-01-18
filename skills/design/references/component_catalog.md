---
doc_type: component_catalog
version: "{{VERSION}}"
status: "{{STATUS}}"
updated_at: "{{UPDATED_AT}}"
owners: ["{{OWNER}}"]
tags: [画面設計, コンポーネント]
---

# UIコンポーネントカタログ

## 基本コンポーネント

### {{コンポーネント名}}

#### バリエーション

| バリエーション | 説明 | 使用場面 |
|---------------|------|----------|
| {{VARIANT}} | {{DESC}} | {{USAGE}} |

#### サイズ

| サイズ | 値 |
|--------|-----|
| {{SIZE}} | {{VALUE}} |

#### 状態

| 状態 | 説明 |
|------|------|
| {{STATE}} | {{DESC}} |

#### Props

```typescript
interface {{ComponentName}}Props {
  {{PROP}}: {{TYPE}};
}
```

## レイアウトコンポーネント

### {{コンポーネント名}}

{{COMPONENT_SPEC}}

## フォームコンポーネント

### {{コンポーネント名}}

{{COMPONENT_SPEC}}

## フィードバックコンポーネント

### {{コンポーネント名}}

{{COMPONENT_SPEC}}

## デザイントークン

### カラー

| トークン | 値 | 用途 |
|---------|-----|------|
| {{TOKEN}} | {{VALUE}} | {{USAGE}} |

### タイポグラフィ

| トークン | サイズ | 行高 | 用途 |
|---------|--------|------|------|
| {{TOKEN}} | {{SIZE}} | {{LINE_HEIGHT}} | {{USAGE}} |

### スペーシング

| トークン | 値 |
|---------|-----|
| {{TOKEN}} | {{VALUE}} |

## 変更履歴

| 日付 | Ver | 変更者 | 内容 |
|------|-----|--------|------|
| {{DATE}} | {{VERSION}} | {{AUTHOR}} | {{CHANGE}} |
