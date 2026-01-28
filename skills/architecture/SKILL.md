---
name: architecture
description: This skill should be used when the user asks to "design system architecture", "create ADR", "plan infrastructure", "design security", "define caching strategy", "select technology stack", or "document architecture decisions". Designs system architecture, security controls, infrastructure, and caching strategies.
version: 1.0.0
---

# Architecture Skill

システムアーキテクチャ・セキュリティ・インフラ・キャッシュを設計するスキル。
システム構成設計、技術選定、セキュリティ対策、キャッシュレイヤー定義、
インフラ構成の文書化に使用する。技術選定はADRとして記録する。

## 前提条件

| 条件 | 必須 | 説明 |
|------|------|------|
| docs/02_requirements/non_functional_requirements.md | ○ | NFR（パフォーマンス要件等） |
| docs/02_requirements/functional_requirements.md | △ | 機能規模の把握 |

## 出力ファイル

| ファイル | テンプレート | 説明 |
|---------|-------------|------|
| docs/03_architecture/architecture.md | {baseDir}/references/architecture.md | システム構成 |
| docs/03_architecture/adr.md | {baseDir}/references/adr.md | 技術選定記録 |
| docs/03_architecture/security.md | {baseDir}/references/security.md | セキュリティ設計 |
| docs/03_architecture/infrastructure.md | {baseDir}/references/infrastructure.md | インフラ構成 |
| docs/03_architecture/cache_strategy.md | {baseDir}/references/cache_strategy.md | キャッシュ戦略 |

## 依存関係

| 種別 | 対象 |
|------|------|
| 前提スキル | requirements |
| 後続スキル | implementation |

## ADR ID採番ルール

| 項目 | ルール |
|------|--------|
| 形式 | ADR-XXXX（4桁ゼロパディング） |
| 開始 | 0001 |

## ワークフロー

```
1. 非機能要件・技術制約を読み込み
2. アーキテクチャパターンを選定
3. 技術スタックを決定（ADRとして記録）
4. システム構成図を作成（Mermaid）
5. セキュリティ設計
6. キャッシュ戦略設計
7. インフラ設計
```

## アーキテクチャパターン

| タイプ | パターン |
|--------|---------|
| webapp | SPA + BFF |
| mobile | Client-Server |
| api | Microservices / Modular Monolith |
| batch | Event-Driven |

## ADRテンプレート

```markdown
### ADR-0001: [タイトル]

#### コンテキスト
[背景・課題]

#### 決定
[決定内容]

#### 理由
[決定理由]

#### 代替案
| 代替案 | 却下理由 |
|--------|----------|

#### 影響
[影響・トレードオフ]
```

## セキュリティ設計

### 認証

| 項目 | 推奨 |
|------|------|
| 方式 | JWT (RS256) |
| アクセストークン | 15分 |
| リフレッシュトークン | 7日 |

### 脆弱性対策

| 脅威 | 対策 |
|------|------|
| XSS | CSP, サニタイズ |
| CSRF | SameSite Cookie |
| SQL Injection | パラメータ化クエリ |

## キャッシュ戦略設計

### レイヤー別キャッシュ

| レイヤー | 技術 | 用途 |
|---------|------|------|
| ブラウザ | Cache-Control, ETag | 静的アセット |
| CDN | CloudFront, Cloudflare | 静的ファイル、API応答 |
| アプリケーション | Redis, Memcached | セッション、APIレスポンス |
| データベース | クエリキャッシュ | 頻繁なクエリ結果 |

### キャッシュ無効化戦略

| 戦略 | 用途 |
|------|------|
| TTL（時間ベース） | 定期更新データ |
| イベント駆動 | データ変更時の即時反映 |
| バージョニング | 静的アセットの更新 |

## インフラ設計

| 項目 | 目標 |
|------|------|
| 稼働率 | 99.9% |
| RTO | 1時間 |
| RPO | 5分 |

## エラーハンドリング設計

システム全体のエラーハンドリング戦略を定義する。
UIレイヤー（design/error_patterns.md）と整合させる。

### HTTPエラーレスポンス戦略

| エラー種別 | HTTPステータス | レスポンス戦略 | UI表示パターン |
|-----------|---------------|---------------|---------------|
| 入力エラー | 400 Bad Request | フィールド別エラー詳細返却 | インラインバリデーション |
| 認証エラー | 401 Unauthorized | リフレッシュトークンフロー | 再認証誘導 |
| 権限エラー | 403 Forbidden | 権限不足の詳細メッセージ | エラーページ/モーダル |
| リソース不在 | 404 Not Found | リソース種別の明示 | 代替候補の提示 |
| 業務ルール違反 | 422 Unprocessable Entity | ルール違反詳細 | ガイダンス表示 |
| サーバーエラー | 5xx | エラーID + 簡潔メッセージ | リトライ誘導 |

### リトライ戦略

| 対象 | 戦略 | 設定 |
|------|------|------|
| 冪等操作（GET, PUT, DELETE） | 自動リトライ | 最大3回、Exponential Backoff |
| 非冪等操作（POST） | 手動リトライ | ユーザー確認後のみ |
| ネットワークエラー | 自動リトライ | 最大3回、指数バックオフ |
| タイムアウト | 条件付きリトライ | 冪等性に応じて判断 |

### エラーロギング・監視

| 項目 | 内容 |
|------|------|
| エラーID | UUID形式でリクエストを一意に識別 |
| ログレベル | 4xx: WARN, 5xx: ERROR |
| アラート | 5xxエラー率が閾値超過時 |

## コンテキスト更新

```yaml
phases:
  architecture:
    status: completed
    files:
      - docs/03_architecture/architecture.md
      - docs/03_architecture/adr.md
      - docs/03_architecture/security.md
      - docs/03_architecture/infrastructure.md
      - docs/03_architecture/cache_strategy.md
id_registry:
  adr: [ADR-0001, ADR-0002, ...]
```

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| NFR 不在 | デフォルト推奨値で設計、WARNING を記録 |
| 技術スタック未定義 | ヒアリング結果から推測、ADR で記録 |
| 矛盾するNFR | トレードオフを ADR に記録 |
