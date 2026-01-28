---
name: setup-depcruise
description: プロジェクトにdependency-cruiserをセットアップする
---

# dependency-cruiser セットアップコマンド

このコマンドは、プロジェクトにdependency-cruiserのアーキテクチャ検証設定を適用します。

## 実行手順

### 1. 既存設定の確認

まず、プロジェクトに既存の設定があるか確認してください：

```bash
ls -la .dependency-cruiser.js 2>/dev/null || echo ".dependency-cruiser.js not found"
```

既存設定がある場合は、ユーザーに上書きするか確認してください。

### 2. プロジェクト構成の分析

`src/` ディレクトリ構造を確認して、プロジェクトの種類を判定：

```bash
ls -la src/ 2>/dev/null
```

以下を確認：
- `routes/` が存在するか（バックエンド）
- `services/` が存在するか（バックエンド）
- `usecases/` が存在するか（DDD）
- `components/` が存在するか（フロントエンド）
- `hooks/` が存在するか（フロントエンド）
- `pages/` が存在するか（フロントエンド）

### 3. プリセット選択

分析結果に基づいてプリセットを選択：

| 条件 | プリセット |
|-----|-----------|
| usecases/ あり | `base` + `ddd` |
| components/ + hooks/ あり | `base` + `frontend` |
| routes/ + services/ のみ | `base` のみ |

ユーザーに確認して最終決定。

### 4. 設定ファイル作成

#### ベース設定のみの場合

`~/.claude/skills/dependency-cruiser/templates/.dependency-cruiser.base.js` の内容をコピー。

#### プリセット併用の場合

以下のようなマージ設定を作成：

```javascript
/** @type {import('dependency-cruiser').IConfiguration} */
const baseConfig = {
  // .dependency-cruiser.base.js の内容をインライン展開
  // ...
};

// DDDプリセットを使用する場合
const dddRules = [
  // presets/ddd.js の forbidden 配列をインライン展開
  // ...
];

// フロントエンドプリセットを使用する場合
const frontendRules = [
  // presets/frontend.js の forbidden 配列をインライン展開
  // ...
];

module.exports = {
  ...baseConfig,
  forbidden: [
    ...baseConfig.forbidden,
    // 選択したプリセットのルールを追加
    // ...dddRules,
    // ...frontendRules,
  ],
};
```

**重要**: テンプレートファイルを参照するのではなく、内容をインライン展開してください。これにより、スキルがインストールされていない環境でも設定が動作します。

### 5. package.json スクリプト追加

package.json に以下のスクリプトを追加：

```json
{
  "scripts": {
    "depcruise": "depcruise src --config",
    "depcruise:graph": "depcruise src --config --output-type dot | dot -T svg > dependency-graph.svg"
  }
}
```

### 6. 依存パッケージの確認

dependency-cruiser がインストールされていない場合：

```bash
bun add -D dependency-cruiser
```

グラフ出力を使用する場合、graphviz のインストールも案内：

```bash
# macOS
brew install graphviz

# Ubuntu
sudo apt install graphviz
```

### 7. lefthook連携（オプション）

ユーザーがpre-commit hookを希望する場合、`lefthook.yml` に追加：

```yaml
pre-commit:
  commands:
    depcruise:
      glob: "*.{js,ts,tsx}"
      run: bunx depcruise src --config --output-type err-long
```

### 8. 初回実行・検証

設定完了後、初回実行して結果を確認：

```bash
bun run depcruise
```

違反がある場合は、ユーザーに対処方法を説明：
- 依存方向を修正する
- ルールの severity を warn に緩和する（移行期間）
- 特定パスを除外する

## プリセット詳細

### base（Clean Architecture基本）

適用ルール：
- `no-infrastructure-to-services`: repositories → services 禁止
- `no-services-to-routes`: services → routes 禁止
- `no-circular`: 循環依存禁止
- `no-utils-to-business-logic`: utils → ビジネスロジック禁止

### ddd（DDD + UseCase層）

base に追加されるルール：
- `no-routes-to-services-directly`: routes は usecases 経由でのみ services にアクセス
- `no-usecases-to-repositories`: usecases → repositories 直接依存禁止
- `no-services-to-usecases`: 逆方向依存禁止
- `no-domain-to-infrastructure`: ドメイン層の純粋性保護

### frontend（フロントエンド向け）

適用ルール：
- `no-hooks-to-components`: hooks → components 禁止
- `no-utils-to-components`: utils → components 禁止
- `no-api-to-components`: api → components 禁止
- `no-store-to-components`: store → components 禁止

## 完了メッセージ

セットアップ完了後、以下を伝える：
- `bun run depcruise` でアーキテクチャ検証を実行可能
- `bun run depcruise:graph` で依存グラフを SVG 出力可能
- 違反が検出された場合の対処法
