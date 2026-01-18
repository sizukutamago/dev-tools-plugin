---
name: database
description: This skill should be used when the user asks to "design data model", "create entity definitions", "define TypeScript types", "design database schema", "create data structure", or "model entities". Defines data structures and entity models with TypeScript type definitions.
version: 1.0.0
---

# Database Skill

データ構造・エンティティを定義するスキル。
TypeScript型定義、エンティティ設計、バリデーションルールの作成に使用する。
このフェーズはAPI設計より前に実行し、エンティティはAPIの入出力の基盤となる。

## 前提条件

| 条件 | 必須 | 説明 |
|------|------|------|
| docs/02_requirements/functional_requirements.md | ○ | エンティティ抽出元 |

## 出力ファイル

| ファイル | テンプレート | 説明 |
|---------|-------------|------|
| docs/04_data_structure/data_structure.md | {baseDir}/references/data_structure.md | エンティティ定義 |

## 依存関係

| 種別 | 対象 |
|------|------|
| 前提スキル | requirements |
| 後続スキル | api |

## ID採番ルール

| 項目 | ルール |
|------|--------|
| 形式 | ENT-{EntityName}（PascalCase） |
| 例 | ENT-User, ENT-Product |

## ワークフロー

```
1. 機能要件を読み込み
2. 要件からエンティティを抽出
3. エンティティ間の関係を分析
4. 各エンティティにENT-IDを付与
5. TypeScript型定義を生成
6. フィールド詳細を定義
7. 派生型を定義
```

**重要**: このフェーズはAPI設計より前に実行する。
エンティティはAPIの入出力の基盤となる。

## 命名規則

| 対象 | 規則 |
|------|------|
| 型名 | PascalCase |
| プロパティ | camelCase |
| 定数 | UPPER_SNAKE_CASE |
| ブール型 | is/has/can + Name |

## 型定義の接尾辞

| 接尾辞 | 用途 |
|--------|------|
| (なし) | 基本エンティティ |
| Extended | 関連含む拡張版 |
| Form | フォーム入力用 |
| State | UI状態管理用 |

## エンティティ定義例

```typescript
interface User {
  id: string;
  email: string;
  name: string;
  isActive: boolean;
  createdAt: string;
  updatedAt: string;
}
```

## フィールド詳細

| フィールド | 型 | 必須 | 説明 | 制約 |
|-----------|-----|------|------|------|
| id | string | ○ | ID | UUID形式 |
| email | string | ○ | メール | RFC 5322 |

## コンテキスト更新

```yaml
phases:
  database:
    status: completed
    files:
      - docs/04_data_structure/data_structure.md
id_registry:
  ent: [ENT-User, ENT-Product, ...]
traceability:
  fr_to_ent:
    FR-001: [ENT-Product]
```

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| FR 不在 | Phase 2 の実行を促す |
| エンティティ抽出不可 | ユーザーに主要データを質問 |
| 循環参照検出 | WARNING を記録、設計見直しを提案 |
