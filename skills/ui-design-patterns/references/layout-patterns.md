# レイアウトパターン詳細

## Holy Grail レイアウト

Header + (Sidebar + Main + Sidebar) + Footer の古典的レイアウト。

### CSS Grid 実装

```css
.holy-grail {
  display: grid;
  grid-template-areas:
    "header header header"
    "left   main   right"
    "footer footer footer";
  grid-template-columns: 200px 1fr 200px;
  grid-template-rows: auto 1fr auto;
  min-height: 100vh;
}

.header { grid-area: header; }
.left-sidebar { grid-area: left; }
.main-content { grid-area: main; }
.right-sidebar { grid-area: right; }
.footer { grid-area: footer; }

/* レスポンシブ対応 */
@media (max-width: 768px) {
  .holy-grail {
    grid-template-areas:
      "header"
      "main"
      "left"
      "right"
      "footer";
    grid-template-columns: 1fr;
  }
}
```

---

## Card Grid レイアウト

商品一覧やギャラリーに使用する均等グリッド。

### CSS Grid 実装（自動フィット）

```css
.card-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 1.5rem;
}
```

### 固定カラム数（レスポンシブ）

```css
.card-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 1rem;
}

@media (min-width: 640px) {
  .card-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (min-width: 1024px) {
  .card-grid {
    grid-template-columns: repeat(3, 1fr);
  }
}

@media (min-width: 1280px) {
  .card-grid {
    grid-template-columns: repeat(4, 1fr);
  }
}
```

---

## Sidebar Navigation レイアウト

管理画面・ダッシュボードに使用。

### CSS Grid 実装

```css
.dashboard-layout {
  display: grid;
  grid-template-columns: 240px 1fr;
  min-height: 100vh;
}

.sidebar {
  position: sticky;
  top: 0;
  height: 100vh;
  overflow-y: auto;
}

.main-content {
  overflow-y: auto;
}

/* モバイル: サイドバーを非表示 */
@media (max-width: 768px) {
  .dashboard-layout {
    grid-template-columns: 1fr;
  }

  .sidebar {
    position: fixed;
    transform: translateX(-100%);
    z-index: 50;
    transition: transform 0.3s ease;
  }

  .sidebar.open {
    transform: translateX(0);
  }
}
```

### React 実装例

```tsx
function DashboardLayout({ children }) {
  const [sidebarOpen, setSidebarOpen] = useState(false);

  return (
    <div className="dashboard-layout">
      {/* モバイル用ハンバーガーボタン */}
      <button
        className="mobile-menu-button"
        onClick={() => setSidebarOpen(!sidebarOpen)}
        aria-expanded={sidebarOpen}
        aria-controls="sidebar"
      >
        <span className="sr-only">メニューを開く</span>
        <HamburgerIcon />
      </button>

      <aside
        id="sidebar"
        className={`sidebar ${sidebarOpen ? 'open' : ''}`}
        aria-label="メインナビゲーション"
      >
        <nav>
          <ul>
            <li><a href="/dashboard">ダッシュボード</a></li>
            <li><a href="/users">ユーザー</a></li>
            <li><a href="/settings">設定</a></li>
          </ul>
        </nav>
      </aside>

      <main className="main-content">
        {children}
      </main>
    </div>
  );
}
```

---

## Sticky Header レイアウト

ヘッダーを固定し、コンテンツがその下にスクロール。

```css
.sticky-header-layout {
  display: flex;
  flex-direction: column;
  min-height: 100vh;
}

.header {
  position: sticky;
  top: 0;
  z-index: 10;
  background: white;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
}

.main-content {
  flex: 1;
}

.footer {
  margin-top: auto;
}
```

---

## Split Screen レイアウト

2カラムで左右を均等、または比率指定で分割。

```css
/* 均等分割 */
.split-screen {
  display: grid;
  grid-template-columns: 1fr 1fr;
  min-height: 100vh;
}

/* 比率指定（40:60） */
.split-screen {
  display: grid;
  grid-template-columns: 2fr 3fr;
}

/* モバイル対応 */
@media (max-width: 768px) {
  .split-screen {
    grid-template-columns: 1fr;
  }
}
```

---

## Container パターン

コンテンツの最大幅を制限し、中央揃え。

```css
.container {
  width: 100%;
  max-width: 1200px;
  margin: 0 auto;
  padding: 0 1rem;
}

/* サイズバリエーション */
.container-sm { max-width: 640px; }
.container-md { max-width: 768px; }
.container-lg { max-width: 1024px; }
.container-xl { max-width: 1280px; }
```

---

## Stack パターン

縦方向に要素を積み重ねる。

```css
.stack {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

/* gap サイズバリエーション */
.stack-xs { gap: 0.25rem; }
.stack-sm { gap: 0.5rem; }
.stack-md { gap: 1rem; }
.stack-lg { gap: 1.5rem; }
.stack-xl { gap: 2rem; }
```

---

## Cluster パターン

横方向に要素を並べ、折り返しを許可。

```css
.cluster {
  display: flex;
  flex-wrap: wrap;
  gap: 1rem;
  align-items: center;
}
```

---

## Responsive Breakpoints

| 名前 | 幅 | デバイス |
|------|-----|---------|
| xs | 0px | スマートフォン（縦） |
| sm | 640px | スマートフォン（横） |
| md | 768px | タブレット |
| lg | 1024px | 小型デスクトップ |
| xl | 1280px | デスクトップ |
| 2xl | 1536px | 大型デスクトップ |

### Mobile-first アプローチ

```css
/* ベース（モバイル） */
.element { padding: 1rem; }

/* タブレット以上 */
@media (min-width: 768px) {
  .element { padding: 2rem; }
}

/* デスクトップ以上 */
@media (min-width: 1024px) {
  .element { padding: 3rem; }
}
```
