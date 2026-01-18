---
doc_type: database
version: "{{VERSION}}"
status: "{{STATUS}}"
updated_at: "{{UPDATED_AT}}"
owners: ["{{OWNER}}"]
tags: [データ構造]
coverage:
  entities: []
  fr: []
---

# データ構造定義

## 命名規則

| 対象 | 規則 |
|------|------|
| 型名 | PascalCase |
| プロパティ | camelCase |
| 定数 | UPPER_SNAKE_CASE |
| ブール型 | is/has/should/can + PascalCase |

## 接尾辞

| 接尾辞 | 用途 |
|--------|------|
| Extended | 拡張版 |
| Form | フォーム入力用 |
| Storage | ストレージ保存用 |
| State | UI状態管理用 |
| Props | コンポーネントProps |

## エンティティ定義

### ENT-{{EntityName}}

| 項目 | 内容 |
|------|------|
| エンティティID | ENT-{{NAME}} |
| 説明 | {{DESCRIPTION}} |

#### 型定義

```typescript
interface {{EntityName}} {
  {{PROP}}: {{TYPE}};
}
```

#### フィールド詳細

| フィールド | 型 | 必須 | 説明 | 制約 |
|-----------|-----|------|------|------|
| {{FIELD}} | {{TYPE}} | {{REQUIRED}} | {{DESC}} | {{CONSTRAINT}} |

## フロントエンド専用型

### フォーム型

```typescript
interface {{FormName}}Form {
  {{PROP}}: {{TYPE}};
}
```

### UI状態型

```typescript
interface {{StateName}}State {
  {{PROP}}: {{TYPE}};
  isLoading: boolean;
  error: string | null;
}
```

## ローカルストレージ

| キー | 型 | 説明 | 有効期限 |
|-----|-----|------|----------|
| {{KEY}} | {{TYPE}} | {{DESC}} | {{EXPIRY}} |

```typescript
interface StorageData<T> {
  version: string;
  data: T;
  expiresAt: string | null;
}
```

## バリデーションルール

```typescript
const VALIDATION_RULES = {
  {{RULE_NAME}}: {
    {{PARAM}}: {{VALUE}},
  },
} as const;
```

## 型定義ファイル配置

| ディレクトリ | 内容 |
|-------------|------|
| /types/entities | エンティティ型 |
| /types/forms | フォーム型 |
| /types/storage | ストレージ型 |
| /types/ui | UI状態型 |

## 変更履歴

| 日付 | Ver | 変更者 | 内容 |
|------|-----|--------|------|
| {{DATE}} | {{VERSION}} | {{AUTHOR}} | {{CHANGE}} |
