# アクセシビリティガイド（WCAG 2.1 AA）

## WCAG 2.1 AA チェックリスト

### 知覚可能（Perceivable）

| 項目 | 要件 | 確認方法 |
|------|------|---------|
| 代替テキスト | 画像に alt 属性 | HTMLソース確認 |
| 動画字幕 | 音声コンテンツに字幕 | 字幕表示確認 |
| コントラスト比 | 通常テキスト 4.5:1、大テキスト 3:1 | Chrome DevTools |
| リサイズ | 200%拡大で情報損失なし | ブラウザズーム |

### 操作可能（Operable）

| 項目 | 要件 | 確認方法 |
|------|------|---------|
| キーボード操作 | すべての機能がキーボードで操作可能 | Tab/Enter/Space |
| フォーカス表示 | フォーカス位置が視覚的に明確 | Tab で確認 |
| タイムアウト | 時間制限の調整または解除が可能 | 設定画面確認 |
| スキップリンク | メインコンテンツへのスキップ | Tab で最初に確認 |

### 理解可能（Understandable）

| 項目 | 要件 | 確認方法 |
|------|------|---------|
| 言語指定 | html に lang 属性 | HTMLソース確認 |
| エラー特定 | エラー箇所と内容を明示 | フォーム送信 |
| ラベル | フォーム要素に関連ラベル | label for 確認 |
| 一貫したナビ | ナビゲーションの一貫性 | ページ間比較 |

### 堅牢（Robust）

| 項目 | 要件 | 確認方法 |
|------|------|---------|
| HTML妥当性 | 正しいHTML構文 | W3C Validator |
| 名前と役割 | カスタムUIに role/name | スクリーンリーダー |

---

## aria-* 属性完全ガイド

### 状態属性

| 属性 | 値 | 用途 | 例 |
|------|-----|------|-----|
| `aria-expanded` | true/false | 展開/折りたたみ状態 | アコーディオン、ドロップダウン |
| `aria-selected` | true/false | 選択状態 | タブ、リストアイテム |
| `aria-checked` | true/false/mixed | チェック状態 | チェックボックス |
| `aria-pressed` | true/false/mixed | 押下状態 | トグルボタン |
| `aria-disabled` | true/false | 無効状態 | ボタン、入力フィールド |
| `aria-hidden` | true/false | 非表示（スクリーンリーダー） | 装飾アイコン |
| `aria-invalid` | true/false | エラー状態 | フォームフィールド |
| `aria-busy` | true/false | 処理中状態 | ローディング |

### 関係属性

| 属性 | 用途 | 例 |
|------|------|-----|
| `aria-labelledby` | ラベル要素を参照 | `aria-labelledby="title"` |
| `aria-describedby` | 説明要素を参照 | `aria-describedby="helper"` |
| `aria-errormessage` | エラーメッセージを参照 | `aria-errormessage="error"` |
| `aria-controls` | 制御対象を参照 | `aria-controls="panel"` |
| `aria-owns` | 所有関係を定義 | ツリービュー |
| `aria-flowto` | 読み上げ順序を指定 | 複雑なレイアウト |

### プロパティ属性

| 属性 | 用途 | 例 |
|------|------|-----|
| `aria-label` | アクセシブルな名前を直接指定 | `aria-label="閉じる"` |
| `aria-live` | ライブリージョン | `aria-live="polite"` |
| `aria-atomic` | 更新時に全体を読み上げ | `aria-atomic="true"` |
| `aria-relevant` | 更新通知の種類 | `aria-relevant="additions"` |
| `aria-haspopup` | ポップアップの存在 | `aria-haspopup="menu"` |
| `aria-modal` | モーダル状態 | `aria-modal="true"` |

---

## role 属性

### ランドマーク role

| role | 用途 | HTML5 相当 |
|------|------|-----------|
| `banner` | ページヘッダー | `<header>` |
| `navigation` | ナビゲーション | `<nav>` |
| `main` | メインコンテンツ | `<main>` |
| `complementary` | 補足コンテンツ | `<aside>` |
| `contentinfo` | ページフッター | `<footer>` |
| `search` | 検索機能 | `<search>` (HTML5.2) |

### ウィジェット role

| role | 用途 |
|------|------|
| `button` | ボタン |
| `link` | リンク |
| `textbox` | テキスト入力 |
| `checkbox` | チェックボックス |
| `radio` | ラジオボタン |
| `combobox` | コンボボックス |
| `listbox` | リストボックス |
| `slider` | スライダー |
| `switch` | スイッチ |
| `tab` | タブ |
| `tabpanel` | タブパネル |
| `tablist` | タブリスト |
| `menu` | メニュー |
| `menuitem` | メニュー項目 |
| `dialog` | ダイアログ |
| `alertdialog` | 警告ダイアログ |

---

## 実装パターン

### アイコンボタン

```tsx
// Bad: スクリーンリーダーで意味不明
<button><CloseIcon /></button>

// Good: aria-label で説明
<button aria-label="閉じる">
  <CloseIcon aria-hidden="true" />
</button>

// Good: visually-hidden テキスト
<button>
  <CloseIcon aria-hidden="true" />
  <span className="sr-only">閉じる</span>
</button>
```

### トグルボタン

```tsx
function ToggleButton({ pressed, onToggle, children }) {
  return (
    <button
      type="button"
      aria-pressed={pressed}
      onClick={onToggle}
    >
      {children}
    </button>
  );
}
```

### アコーディオン

```tsx
function Accordion({ title, children, defaultOpen = false }) {
  const [isOpen, setIsOpen] = useState(defaultOpen);
  const panelId = useId();

  return (
    <div>
      <h3>
        <button
          type="button"
          aria-expanded={isOpen}
          aria-controls={panelId}
          onClick={() => setIsOpen(!isOpen)}
        >
          {title}
          <ChevronIcon aria-hidden="true" />
        </button>
      </h3>
      <div
        id={panelId}
        role="region"
        aria-labelledby={`${panelId}-heading`}
        hidden={!isOpen}
      >
        {children}
      </div>
    </div>
  );
}
```

### ライブリージョン（通知）

```tsx
// 礼儀正しい通知（現在の読み上げ終了後）
<div role="status" aria-live="polite">
  {message}
</div>

// 緊急通知（即座に割り込み）
<div role="alert" aria-live="assertive">
  {errorMessage}
</div>
```

### フォームエラー

```tsx
function FormField({ label, error, ...props }) {
  const inputId = useId();
  const errorId = useId();

  return (
    <div>
      <label htmlFor={inputId}>{label}</label>
      <input
        id={inputId}
        aria-invalid={!!error}
        aria-errormessage={error ? errorId : undefined}
        {...props}
      />
      {error && (
        <span id={errorId} role="alert">
          {error}
        </span>
      )}
    </div>
  );
}
```

---

## スクリーンリーダー専用テキスト

```css
.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;
}

/* フォーカス時に表示（スキップリンク用） */
.sr-only:focus {
  position: static;
  width: auto;
  height: auto;
  padding: 0.5rem 1rem;
  margin: 0;
  overflow: visible;
  clip: auto;
  white-space: normal;
}
```

---

## テストツール

| ツール | 用途 |
|--------|------|
| axe DevTools | 自動アクセシビリティチェック |
| WAVE | ウェブアクセシビリティ評価 |
| Chrome DevTools Lighthouse | パフォーマンス＋a11y監査 |
| VoiceOver (macOS) | スクリーンリーダーテスト |
| NVDA (Windows) | スクリーンリーダーテスト |

### axe-core 自動テスト

```typescript
import { axe, toHaveNoViolations } from 'jest-axe';

expect.extend(toHaveNoViolations);

test('accessible form', async () => {
  const { container } = render(<LoginForm />);
  const results = await axe(container);
  expect(results).toHaveNoViolations();
});
```
