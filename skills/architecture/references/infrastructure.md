---
doc_type: infrastructure
version: "{{VERSION}}"
status: "{{STATUS}}"
updated_at: "{{UPDATED_AT}}"
owners: ["{{OWNER}}"]
tags: [インフラ]
coverage:
  nfr: []
---

# インフラストラクチャ設計書

## 概要

| 項目 | 内容 |
|------|------|
| 設計方針 | {{DESIGN_POLICY}} |
| クラウドプロバイダー | {{CLOUD_PROVIDER}} |
| リージョン | {{REGION}} |

## ネットワーク構成

```mermaid
{{NETWORK_DIAGRAM}}
```

| 項目 | 内容 |
|------|------|
| DNS | {{DNS_CONFIG}} |
| CDN | {{CDN_CONFIG}} |
| ロードバランサー | {{LB_CONFIG}} |

## コンピューティング

### フロントエンド

| 項目 | 値 |
|------|-----|
| サービス | {{SERVICE}} |
| リージョン | {{REGION}} |
| スケーリング | {{SCALING}} |

### バックエンド

| 項目 | 値 |
|------|-----|
| サービス | {{SERVICE}} |
| リージョン | {{REGION}} |
| スケーリング | {{SCALING}} |

## データストア

### データベース

| 項目 | 値 |
|------|-----|
| サービス | {{SERVICE}} |
| インスタンス | {{INSTANCE}} |
| ストレージ | {{STORAGE}} |
| バックアップ | {{BACKUP}} |

### オブジェクトストレージ

| 項目 | 値 |
|------|-----|
| サービス | {{SERVICE}} |
| バケット構成 | {{BUCKET_CONFIG}} |

## スケーリング

| 項目 | 値 |
|------|-----|
| 最小インスタンス | {{MIN}} |
| 最大インスタンス | {{MAX}} |
| スケールアウト条件 | {{SCALE_OUT}} |
| スケールイン条件 | {{SCALE_IN}} |

## 可用性

| 項目 | 目標値 |
|------|--------|
| 稼働率 | {{AVAILABILITY}} |
| 最大停止時間 | {{MAX_DOWNTIME}} |

## バックアップ・リカバリ

| 項目 | 値 |
|------|-----|
| 対象 | {{TARGET}} |
| 頻度 | {{FREQUENCY}} |
| 保持期間 | {{RETENTION}} |
| RTO | {{RTO}} |
| RPO | {{RPO}} |

## 監視・アラート

| メトリクス | 閾値 | 通知先 |
|-----------|------|--------|
| {{METRIC}} | {{THRESHOLD}} | {{NOTIFICATION}} |

## コスト

| サービス | 月額 |
|---------|------|
| {{SERVICE}} | {{COST}} |
| 合計 | {{TOTAL}} |

## 変更履歴

| 日付 | Ver | 変更者 | 内容 |
|------|-----|--------|------|
| {{DATE}} | {{VERSION}} | {{AUTHOR}} | {{CHANGE}} |
