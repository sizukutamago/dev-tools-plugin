# Web Interface Guidelines (Local Reference)

このファイルは Web Interface Guidelines のローカルキャッシュです。
最新版は https://github.com/vercel-labs/web-interface-guidelines を参照してください。

## Overview

Web Interface Guidelines はモダンなWebインターフェース設計のベストプラクティスを提供します。

## Core Principles

### 1. Responsiveness

- モバイルファーストで設計する
- ブレークポイントを適切に設定する
- タッチターゲットは最小44x44pxを確保する
- フレキシブルレイアウトを使用する

### 2. Accessibility (WCAG)

- 適切なセマンティックHTMLを使用する
- キーボードナビゲーションをサポートする
- 十分なコントラスト比を確保する（4.5:1以上）
- スクリーンリーダー対応のラベルを提供する
- フォーカス状態を明示する

### 3. Performance

- 初期ロードを最適化する（LCP < 2.5s）
- インタラクションの遅延を最小化する（INP < 200ms）
- レイアウトシフトを防ぐ（CLS < 0.1）
- 画像を最適化する（WebP/AVIF、適切なサイズ）
- 不要なJavaScriptを削減する

### 4. Visual Design

- 一貫したスペーシングシステムを使用する
- 適切なタイポグラフィ階層を設定する
- カラーパレットを統一する
- ダークモードをサポートする

## HTML/Semantic Structure

### ランドマーク

```html
<header role="banner">...</header>
<nav role="navigation">...</nav>
<main role="main">...</main>
<aside role="complementary">...</aside>
<footer role="contentinfo">...</footer>
```

### 見出し階層

```html
<h1>ページタイトル</h1>
<h2>セクション</h2>
<h3>サブセクション</h3>
```

見出しレベルをスキップしない（h1 → h3 は NG）

### フォーム

```html
<form>
  <label for="email">メールアドレス</label>
  <input type="email" id="email" name="email" required>
  <span role="alert" aria-live="polite"></span>
</form>
```

## CSS Guidelines

### スペーシングシステム

```css
:root {
  --space-1: 0.25rem;  /* 4px */
  --space-2: 0.5rem;   /* 8px */
  --space-3: 0.75rem;  /* 12px */
  --space-4: 1rem;     /* 16px */
  --space-5: 1.5rem;   /* 24px */
  --space-6: 2rem;     /* 32px */
}
```

### カラーシステム

```css
:root {
  --color-primary: #0070f3;
  --color-secondary: #666;
  --color-success: #0070f3;
  --color-error: #ee0000;
  --color-warning: #f5a623;
}

@media (prefers-color-scheme: dark) {
  :root {
    --color-bg: #000;
    --color-text: #fff;
  }
}
```

### レスポンシブブレークポイント

```css
/* Mobile first */
.container { padding: var(--space-4); }

/* Tablet */
@media (min-width: 768px) {
  .container { padding: var(--space-5); }
}

/* Desktop */
@media (min-width: 1024px) {
  .container { padding: var(--space-6); }
}
```

## JavaScript Guidelines

### Progressive Enhancement

JavaScriptなしでも基本機能が動作するように設計する。

### Event Handling

```javascript
// 良い例: デリゲーション
document.addEventListener('click', (e) => {
  if (e.target.matches('.button')) {
    handleClick(e);
  }
});

// 悪い例: 個別リスナー
buttons.forEach(btn => btn.addEventListener('click', handleClick));
```

### Async/Loading States

```javascript
button.disabled = true;
button.textContent = '送信中...';
try {
  await submitForm();
  showSuccess();
} catch (error) {
  showError(error.message);
} finally {
  button.disabled = false;
  button.textContent = '送信';
}
```

## Common Issues & Fixes

### Issue: Missing alt text

```html
<!-- Bad -->
<img src="hero.jpg">

<!-- Good -->
<img src="hero.jpg" alt="製品のヒーローイメージ">

<!-- Decorative image -->
<img src="decoration.svg" alt="" role="presentation">
```

### Issue: Poor color contrast

```css
/* Bad: 2.5:1 ratio */
.text { color: #999; background: #fff; }

/* Good: 4.5:1+ ratio */
.text { color: #595959; background: #fff; }
```

### Issue: Missing focus styles

```css
/* Bad: focus removed */
button:focus { outline: none; }

/* Good: visible focus */
button:focus {
  outline: 2px solid var(--color-primary);
  outline-offset: 2px;
}

button:focus:not(:focus-visible) {
  outline: none;
}
```

### Issue: Layout shift

```css
/* Bad: no dimensions */
<img src="photo.jpg">

/* Good: explicit dimensions */
<img src="photo.jpg" width="800" height="600" style="aspect-ratio: 4/3">
```

## Review Output Format

レビュー結果は以下の形式で出力:

```
filepath:line - [severity] message
```

例:
```
src/components/Button.tsx:15 - [error] Missing aria-label for icon button
src/pages/index.tsx:42 - [warning] Consider adding loading state
src/styles/global.css:88 - [info] Color contrast ratio is 4.2:1, recommend 4.5:1+
```

### Severity Levels

| Level | 意味 |
|-------|------|
| error | 修正必須（アクセシビリティ違反など） |
| warning | 推奨される改善 |
| info | 参考情報 |

## Checklist

### Accessibility

- [ ] 全画像にalt属性がある
- [ ] フォーム要素にラベルがある
- [ ] 色だけで情報を伝えていない
- [ ] キーボード操作が可能
- [ ] フォーカス状態が可視化されている

### Performance

- [ ] 画像が最適化されている
- [ ] CSSがクリティカルパスを最適化している
- [ ] JavaScriptがコード分割されている
- [ ] フォントがプリロードされている

### Responsive

- [ ] モバイルで正しく表示される
- [ ] タッチターゲットが十分なサイズ
- [ ] テキストが読みやすいサイズ
- [ ] 横スクロールが発生しない

---

**Note**: このファイルはローカルリファレンスです。最新のガイドラインは WebFetch で取得することを推奨します。
オンラインソース: https://raw.githubusercontent.com/vercel-labs/web-interface-guidelines/main/command.md
