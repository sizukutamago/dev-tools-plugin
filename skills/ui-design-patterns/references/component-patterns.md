# コンポーネント設計パターン詳細

## Button コンポーネント

### バリアント

| バリアント | 用途 | 視覚的特徴 |
|-----------|------|-----------|
| `primary` | メインアクション | 塗りつぶし、ブランドカラー |
| `secondary` | サブアクション | アウトライン |
| `danger` | 破壊的操作 | 赤系 |
| `ghost` | テキストリンク風 | 背景なし |

### Props 設計例

```tsx
interface ButtonProps {
  variant?: 'primary' | 'secondary' | 'danger' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
  disabled?: boolean;
  loading?: boolean;
  fullWidth?: boolean;
  leftIcon?: React.ReactNode;
  rightIcon?: React.ReactNode;
  children: React.ReactNode;
  onClick?: () => void;
}
```

### アクセシビリティ

```tsx
<button
  type="button"
  disabled={disabled || loading}
  aria-disabled={disabled || loading}
  aria-busy={loading}
>
  {loading && <Spinner aria-hidden="true" />}
  {children}
</button>
```

---

## Input コンポーネント

### バリアント

| 状態 | スタイル |
|------|---------|
| default | 通常ボーダー |
| focus | ブランドカラーボーダー |
| error | 赤ボーダー |
| disabled | グレーアウト |

### Props 設計例

```tsx
interface InputProps {
  type?: 'text' | 'email' | 'password' | 'number' | 'tel';
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  label?: string;
  helperText?: string;
  errorMessage?: string;
  disabled?: boolean;
  required?: boolean;
}
```

### アクセシビリティ

```tsx
<div>
  <label htmlFor={id}>{label}</label>
  <input
    id={id}
    aria-describedby={helperText ? helperId : undefined}
    aria-invalid={!!errorMessage}
    aria-errormessage={errorMessage ? errorId : undefined}
    required={required}
  />
  {helperText && <span id={helperId}>{helperText}</span>}
  {errorMessage && <span id={errorId} role="alert">{errorMessage}</span>}
</div>
```

---

## Modal コンポーネント

### 構造

```
Modal
├── Overlay (背景)
├── Container
│   ├── Header (タイトル + 閉じるボタン)
│   ├── Body (コンテンツ)
│   └── Footer (アクションボタン)
```

### フォーカス管理

1. 開いたら最初のフォーカス可能要素にフォーカス
2. Tab で循環（モーダル内のみ）
3. Escape で閉じる
4. 閉じたらトリガー要素にフォーカスを戻す

### 実装例

```tsx
function Modal({ isOpen, onClose, title, children }) {
  const modalRef = useRef<HTMLDivElement>(null);
  const previousFocus = useRef<HTMLElement | null>(null);

  useEffect(() => {
    if (isOpen) {
      previousFocus.current = document.activeElement as HTMLElement;
      modalRef.current?.focus();
    } else {
      previousFocus.current?.focus();
    }
  }, [isOpen]);

  // Escape キーで閉じる
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
    };
    if (isOpen) document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  return (
    <div role="dialog" aria-modal="true" aria-labelledby="modal-title">
      <div className="overlay" onClick={onClose} />
      <div className="modal" ref={modalRef} tabIndex={-1}>
        <h2 id="modal-title">{title}</h2>
        {children}
        <button onClick={onClose}>閉じる</button>
      </div>
    </div>
  );
}
```

---

## Navigation コンポーネント

### Tab ナビゲーション

```tsx
function Tabs({ tabs, activeIndex, onChange }) {
  return (
    <div role="tablist">
      {tabs.map((tab, index) => (
        <button
          key={tab.id}
          role="tab"
          aria-selected={index === activeIndex}
          aria-controls={`panel-${tab.id}`}
          id={`tab-${tab.id}`}
          tabIndex={index === activeIndex ? 0 : -1}
          onClick={() => onChange(index)}
        >
          {tab.label}
        </button>
      ))}
    </div>
  );
}

function TabPanel({ id, activeTabId, children }) {
  const isActive = id === activeTabId;
  return (
    <div
      role="tabpanel"
      id={`panel-${id}`}
      aria-labelledby={`tab-${id}`}
      hidden={!isActive}
    >
      {children}
    </div>
  );
}
```

### Breadcrumb

```tsx
function Breadcrumb({ items }) {
  return (
    <nav aria-label="パンくずリスト">
      <ol>
        {items.map((item, index) => (
          <li key={item.href}>
            {index === items.length - 1 ? (
              <span aria-current="page">{item.label}</span>
            ) : (
              <a href={item.href}>{item.label}</a>
            )}
          </li>
        ))}
      </ol>
    </nav>
  );
}
```

---

## Form Field コンポーネント（Molecule）

Atoms（Label, Input, HelperText, ErrorMessage）を組み合わせた Molecule。

```tsx
interface FormFieldProps {
  label: string;
  name: string;
  type?: string;
  value: string;
  onChange: (value: string) => void;
  helperText?: string;
  error?: string;
  required?: boolean;
}

function FormField({
  label,
  name,
  type = 'text',
  value,
  onChange,
  helperText,
  error,
  required,
}: FormFieldProps) {
  const id = `field-${name}`;
  const helperId = `helper-${name}`;
  const errorId = `error-${name}`;

  return (
    <div className="form-field">
      <Label htmlFor={id} required={required}>
        {label}
      </Label>
      <Input
        id={id}
        type={type}
        value={value}
        onChange={onChange}
        aria-describedby={helperText ? helperId : undefined}
        aria-invalid={!!error}
        aria-errormessage={error ? errorId : undefined}
      />
      {helperText && !error && (
        <HelperText id={helperId}>{helperText}</HelperText>
      )}
      {error && (
        <ErrorMessage id={errorId}>{error}</ErrorMessage>
      )}
    </div>
  );
}
```
