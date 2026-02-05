# dependency-cruiser

TypeScript/JavaScript プロジェクトの依存方向ルールを検証するためのスキル。

## 概要

dependency-cruiser は、コードベースの依存関係を分析し、アーキテクチャルールへの違反を検出するツールです。

**利点:**
- Clean Architecture/DDD の依存方向を自動検証
- 循環依存の検出
- 不正な依存パターンの早期発見
- CI/CD での継続的なアーキテクチャ検証

## 基本概念: 依存方向

Clean Architecture では、依存は **外側から内側** に向かう：

```
┌────────────────────────────────────────────────────────┐
│  Presentation (routes)                                  │
│    ↓ 依存OK                                            │
│  ┌────────────────────────────────────────────────┐    │
│  │  Application (usecases)                         │    │
│  │    ↓ 依存OK                                    │    │
│  │  ┌────────────────────────────────────────┐    │    │
│  │  │  Domain (services)                      │    │    │
│  │  │    ↓ 依存OK                            │    │    │
│  │  │  ┌────────────────────────────────┐    │    │    │
│  │  │  │  Infrastructure (repositories) │    │    │    │
│  │  │  └────────────────────────────────┘    │    │    │
│  │  └────────────────────────────────────────┘    │    │
│  └────────────────────────────────────────────────┘    │
└────────────────────────────────────────────────────────┘
```

**禁止される依存:**
- `repositories` → `services` (内側から外側への依存)
- `services` → `routes` (内側から外側への依存)
- 循環依存

## セットアップコマンド

新規プロジェクトでの設定:

```
/setup-depcruise
```

このコマンドで：
1. 既存設定の確認
2. プロジェクト構成の分析（routes, services, repositories 等の検出）
3. 適切なプリセット選択（base / ddd / frontend）
4. package.json にスクリプト追加
5. lefthook への統合（オプション）

## トラブルシューティング

### "no-circular" が誤検出される

型のみのインポートは `import type` を使うことで循環を回避できる場合がある：

```typescript
// ❌ 循環の原因になりうる
import { User } from './user';

// ✅ 型のみなら循環しない
import type { User } from './user';
```

### 特定のパスを除外したい

`pathNot` で除外パターンを指定：

```javascript
{
  name: 'no-services-to-routes',
  from: {
    path: 'src/services',
    pathNot: 'src/services/shared/' // shared は除外
  },
  to: { path: 'src/routes' },
},
```

### 重要度の調整

移行期間中は `severity: 'warn'` に緩和可能：

```javascript
{
  name: 'no-routes-to-services-directly',
  severity: 'warn', // error → warn に緩和
  // ...
}
```

## 関連ドキュメント

- [SKILL.md](./SKILL.md) - AI 向け実行手順・ルール設定
