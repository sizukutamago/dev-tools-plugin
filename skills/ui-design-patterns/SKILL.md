---
name: ui-design-patterns
description: UI component design patterns, layout best practices, and accessibility guidelines. Use when designing forms, layouts, navigation, or implementing WCAG compliance.
version: 1.0.0
---

# UI Design Patterns

UI コンポーネント設計パターン、レイアウト設計、アクセシビリティガイドライン。

## 前提条件

- React/Vue/Svelte などのコンポーネントベースフレームワーク
- TypeScript 推奨（型安全な Props 定義）

## コンポーネント設計パターン

### Atomic Design 階層

| レベル | 例 | 責務 |
|--------|-----|------|
| Atoms | Button, Input, Label | 単一責任、再利用可能 |
| Molecules | SearchBar, FormField | Atoms の組み合わせ |
| Organisms | Header, ProductCard | ビジネスロジック含む |
| Templates | PageLayout | 構造定義（スロット配置） |
| Pages | HomePage | データ注入・状態管理 |

### フォーム設計パターン

#### 1. Controlled vs Uncontrolled

| パターン | 用途 | 例 |
|---------|------|-----|
| Controlled | リアルタイム検証、動的 UI | `<input value={state} onChange={...} />` |
| Uncontrolled | シンプルなフォーム、パフォーマンス重視 | `<input ref={inputRef} />` |

**推奨**: 大半は Controlled で統一し、パフォーマンスが問題になった場合のみ Uncontrolled を検討。

#### 2. バリデーション戦略

| タイミング | 用途 | UX 特性 |
|-----------|------|--------|
| onChange | リアルタイムフィードバック | 即時性高、CPU負荷あり |
| onBlur | フィールド離脱時検証 | バランス良好 |
| onSubmit | 最終検証 | 遅延フィードバック |

**推奨**: `onBlur` + `onSubmit` の組み合わせ。

#### 3. エラー表示パターン

| パターン | 特徴 | 適用場面 |
|---------|------|---------|
| Inline | フィールド直下にエラー表示 | 個別フィールドエラー |
| Summary | フォーム上部にまとめて表示 | 複数エラーの概要 |
| Toast | 非破壊的通知 | 保存成功/失敗 |

### コンポーネント Props 設計

#### Bad: 曖昧な Props

```tsx
// 何を渡すべきか不明
<Button type="1" size="big" />
```

#### Good: 明確な Union Types

```tsx
interface ButtonProps {
  variant: 'primary' | 'secondary' | 'danger' | 'ghost';
  size: 'sm' | 'md' | 'lg';
  disabled?: boolean;
  loading?: boolean;
}

<Button variant="primary" size="md" loading />
```

---

## レイアウトパターン

### Grid vs Flexbox 使い分け

| パターン | Grid | Flexbox |
|---------|------|---------|
| 2次元レイアウト（行と列） | ✅ | ❌ |
| 1次元並び（横 or 縦） | △ | ✅ |
| 不均等分割 | ✅ | △ |
| 要素サイズが動的 | △ | ✅ |

**経験則**: 「グリッド状」なら Grid、「並び」なら Flexbox。

### レスポンシブ戦略

#### Mobile-first ブレークポイント

```css
/* Base: mobile */
.container { padding: 1rem; }

/* Tablet */
@media (min-width: 768px) {
  .container { padding: 2rem; }
}

/* Desktop */
@media (min-width: 1024px) {
  .container { padding: 3rem; max-width: 1200px; }
}
```

### よく使うレイアウトパターン

| パターン | 構造 | 用途 |
|---------|------|------|
| Holy Grail | Header + (Sidebar + Main + Sidebar) + Footer | ダッシュボード |
| Card Grid | 均等グリッド配置 | 商品一覧、ギャラリー |
| Sticky Header | 固定ヘッダー + スクロールコンテンツ | 一般的な Web サイト |
| Sidebar Navigation | 固定サイドバー + メインコンテンツ | 管理画面 |

詳細は [references/layout-patterns.md](references/layout-patterns.md) を参照。

---

## アクセシビリティ（WCAG 2.1）

### 必須チェックリスト

| 項目 | 実装 | 確認方法 |
|------|------|---------|
| キーボード操作 | `tabIndex`, `onKeyDown` | Tab キーで全要素にアクセス可能 |
| スクリーンリーダー | `aria-label`, `aria-describedby` | VoiceOver/NVDA でテスト |
| コントラスト比 | 4.5:1 (AA), 7:1 (AAA) | Chrome DevTools でチェック |
| フォーカス表示 | `focus-visible` スタイル | 視覚的なフォーカスリング |

### aria-* 属性リファレンス

| 属性 | 用途 | 例 |
|------|------|-----|
| `aria-label` | 視覚的ラベルなしの要素 | アイコンボタン |
| `aria-describedby` | 追加説明の関連付け | フォームヘルプテキスト |
| `aria-expanded` | 展開状態 | アコーディオン、ドロップダウン |
| `aria-hidden` | 装飾要素の非表示 | アイコン（テキストと併用時） |
| `aria-live` | 動的更新の通知 | 通知、ローディング状態 |
| `aria-invalid` | 入力エラー状態 | フォームバリデーション |

詳細は [references/accessibility-guide.md](references/accessibility-guide.md) を参照。

### フォーカス管理

#### モーダルのフォーカストラップ

```tsx
// モーダルを開いたら最初のフォーカス可能要素にフォーカス
// Tab でモーダル内のみ循環
// Escape で閉じる
// 閉じたら元のトリガー要素にフォーカスを戻す
```

#### スキップリンク

```html
<a href="#main-content" class="skip-link">
  メインコンテンツへスキップ
</a>
```

---

## 使用例

### フォーム設計依頼

```
User: "ログインフォームを設計して"

Claude:
1. Controlled パターンで状態管理
2. onBlur + onSubmit バリデーション
3. Inline エラー表示
4. aria-invalid でエラー状態を伝達
5. 送信ボタンに loading 状態
```

### レイアウト設計依頼

```
User: "ダッシュボードのレイアウトを作成して"

Claude:
1. Sidebar Navigation パターンを採用
2. CSS Grid で 2 カラムレイアウト
3. サイドバー: 固定幅 240px
4. メイン: 残り幅（fr 単位）
5. モバイル: ハンバーガーメニューに切り替え
```

### アクセシビリティ改善依頼

```
User: "このコンポーネントを a11y 対応して"

Claude:
1. インタラクティブ要素に role 属性追加
2. aria-label/aria-describedby 設定
3. キーボードナビゲーション実装
4. コントラスト比確認
5. フォーカス表示追加
```

---

## エラーハンドリング

| 状況 | 対応 |
|------|------|
| デザインシステム未定義 | Atomic Design を提案 |
| a11y 要件不明 | WCAG 2.1 AA を基準に |
| ブレークポイント未定義 | 768px / 1024px を提案 |
| コンポーネント粒度の判断 | 3回以上再利用されるなら分離 |

---

## リソース

### references/

- `component-patterns.md`: コンポーネント設計パターン詳細
- `layout-patterns.md`: レイアウトパターン詳細
- `accessibility-guide.md`: WCAG 2.1 AA チェックリスト・aria-* 完全ガイド
