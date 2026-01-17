# コーディング規約

## 命名規則

### ファイル名

| 対象 | 規則 |
|------|------|
| コンポーネント | {{COMPONENT_RULE}} |
| ユーティリティ | {{UTIL_RULE}} |
| 定数 | {{CONST_RULE}} |
| 型定義 | {{TYPE_RULE}} |

### 変数・関数

| 対象 | 規則 |
|------|------|
| 変数 | {{VAR_RULE}} |
| 関数 | {{FUNC_RULE}} |
| 定数 | {{CONST_RULE}} |
| 型 | {{TYPE_RULE}} |
| ブール型 | {{BOOL_RULE}} |

## ファイル構成

### ディレクトリ構造

```
{{DIRECTORY_STRUCTURE}}
```

### コンポーネント構成

```typescript
// 1. インポート
// 2. 型定義
// 3. コンポーネント
// 4. フック
// 5. ハンドラー
// 6. レンダリング
```

## TypeScript規約

| 項目 | 規則 |
|------|------|
| interface vs type | {{INTERFACE_TYPE_RULE}} |
| any禁止 | {{ANY_RULE}} |
| strict mode | {{STRICT_RULE}} |

## フレームワーク規約

| 項目 | 規則 |
|------|------|
| コンポーネント | {{COMPONENT_RULE}} |
| Hooks命名 | {{HOOKS_RULE}} |
| イベントハンドラー | {{HANDLER_RULE}} |

## スタイリング規約

| 項目 | 規則 |
|------|------|
| 手法 | {{STYLING_METHOD}} |
| クラス順序 | {{CLASS_ORDER}} |

## コメント規約

### JSDoc

```typescript
/**
 * {{DESCRIPTION}}
 * @param {{PARAM}} - {{PARAM_DESC}}
 * @returns {{RETURN_DESC}}
 */
```

### インラインコメント

| プレフィックス | 用途 |
|---------------|------|
| TODO | {{TODO_USAGE}} |
| FIXME | {{FIXME_USAGE}} |
| NOTE | {{NOTE_USAGE}} |

## Git運用

### ブランチ戦略

| ブランチ | 用途 | 命名規則 |
|---------|------|---------|
| {{BRANCH}} | {{PURPOSE}} | {{NAMING}} |

### コミットメッセージ

```
{{TYPE}}: {{SUMMARY}}
```

| タイプ | 用途 |
|--------|------|
| {{TYPE}} | {{PURPOSE}} |

## 変更履歴

| 日付 | Ver | 変更者 | 内容 |
|------|-----|--------|------|
| {{DATE}} | {{VERSION}} | {{AUTHOR}} | {{CHANGE}} |
