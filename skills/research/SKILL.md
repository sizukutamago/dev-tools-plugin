---
name: research
description: This skill should be used when the user asks to "research technology", "investigate best practices", "analyze external dependencies", "evaluate architecture patterns", or "gather technical information". Conducts comprehensive technology research using WebSearch/WebFetch.
version: 1.0.0
---

# Research Skill

技術調査プロセスを実行するスキル。
WebSearch/WebFetchを活用して最新情報を調査し、research.mdに記録する。
技術選定、外部依存調査、アーキテクチャパターン評価に使用する。

## 前提条件

| 条件 | 必須 | 説明 |
|------|------|------|
| 調査対象の明確化 | ○ | 調査すべき技術/パターン/依存関係 |
| docs/02_requirements/ | △ | 要件がある場合は参照 |

## 出力ファイル

| ファイル | テンプレート | 説明 |
|---------|-------------|------|
| docs/00_analysis/research.md | {baseDir}/references/research.md | 調査結果 |

## 依存関係

| 種別 | 対象 |
|------|------|
| 前提スキル | hearing（任意）, requirements（任意） |
| 後続スキル | architecture, gap-analysis |

## ワークフロー

```
1. 調査目的の明確化
   - 調査対象の特定
   - 調査スコープの定義

2. 要件分析（Requirements Analysis）
   - 機能要件からの技術要件抽出
   - 非機能要件（パフォーマンス、セキュリティ、スケーラビリティ）
   - 技術的制約と依存関係

3. 技術調査（Technology Research）
   - WebSearchで最新情報を検索
   - WebFetchで公式ドキュメントを取得
   - ベストプラクティスと業界標準の調査

4. 外部依存調査（External Dependencies Investigation）
   - 公式ドキュメント・GitHubリポジトリ確認
   - API仕様・認証方式の検証
   - バージョン互換性確認
   - レート制限・使用制約の調査
   - セキュリティ考慮事項

5. アーキテクチャパターン分析
   - 関連パターンの比較（MVC, Clean, Hexagonal等）
   - 既存アーキテクチャとの適合性評価
   - ドメイン境界とチーム責務の特定

6. リスク評価
   - パフォーマンスボトルネック
   - セキュリティ脆弱性
   - 統合複雑性
   - 技術的負債

7. 調査結果のまとめ
```

## 調査ガイドライン

### 常に検索すべき項目

| 項目 | 調査内容 |
|------|---------|
| 外部API | ドキュメント、更新情報 |
| セキュリティ | 認証/認可のベストプラクティス |
| パフォーマンス | ボトルネック対策、最適化手法 |
| 依存関係 | 最新バージョン、マイグレーションパス |

### 不明確な場合に検索すべき項目

| 項目 | 調査内容 |
|------|---------|
| アーキテクチャ | 特定ユースケースのパターン |
| 業界標準 | データフォーマット/プロトコル |
| コンプライアンス | GDPR, HIPAA等の要件 |
| スケーラビリティ | 想定負荷への対応方法 |

### 検索戦略

```
1. 公式ソース優先（ドキュメント、GitHub）
2. 最近の記事・ブログ（直近6ヶ月）
3. Stack Overflowで一般的な問題確認
4. 類似のOSS実装を調査
```

## ツール

| ツール | 用途 | 必須 |
|--------|------|------|
| WebSearch | 最新情報検索、ベストプラクティス調査 | ○ |
| WebFetch | 公式ドキュメント、API仕様取得 | ○ |
| Grep | 既存コードベースのパターン検索 | △ |
| Glob | プロジェクト構造調査 | △ |
| Read | ファイル内容確認 | △ |

## 調査結果の記録

### 記録すべき項目

| 項目 | 説明 |
|------|------|
| Key Insights | アーキテクチャ、技術選定、契約に影響する洞察 |
| Constraints | 調査中に発見した制約 |
| Recommended Approaches | 推奨アプローチと選択したアーキテクチャパターン |
| Rejected Alternatives | 却下した代替案とトレードオフ |
| Domain Boundaries | コンポーネント・インターフェース契約に影響するドメイン境界 |
| Risks & Mitigations | リスクと軽減策 |
| Gaps | 実装時に追加調査が必要な項目 |

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| WebSearch失敗 | 代替キーワードで再検索 |
| WebFetch失敗 | URLの正確性確認、キャッシュ版を試行 |
| 情報が古い | 公式ソースの最新版を確認 |
| 矛盾する情報 | 複数ソースでクロスチェック |

## コンテキスト更新

```yaml
phases:
  research:
    status: completed
    files:
      - docs/00_analysis/research.md
research_summary:
  key_technologies: [...]
  architecture_pattern: "..."
  identified_risks: [...]
```
