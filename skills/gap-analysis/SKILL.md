---
name: gap-analysis
description: This skill should be used when the user asks to "analyze implementation gap", "evaluate feasibility", "assess codebase compatibility", "compare requirements with existing code", or "plan implementation approach". Analyzes gaps between requirements and existing codebase to inform implementation strategy.
version: 1.0.0
---

# Gap Analysis Skill

要件と既存コードベースのギャップを分析し、実装戦略を策定するスキル。
既存プロジェクトへの機能追加、リファクタリング計画策定に使用する。

## 前提条件

| 条件 | 必須 | 説明 |
|------|------|------|
| docs/02_requirements/functional_requirements.md | ○ | 分析対象の要件 |
| 既存ソースコード | ○ | ギャップ分析対象 |

## 出力ファイル

| ファイル | テンプレート | 説明 |
|---------|-------------|------|
| docs/00_analysis/gap_analysis.md | {baseDir}/references/gap_analysis.md | ギャップ分析結果 |

## 依存関係

| 種別 | 対象 |
|------|------|
| 前提スキル | requirements |
| 後続スキル | architecture, design |

## ワークフロー

```
1. 要件ドキュメント読み込み
2. 現状調査（Current State Investigation）
   - ディレクトリ構造・主要モジュール分析
   - 再利用可能なコンポーネント特定
   - アーキテクチャパターン・制約把握
   - 統合ポイント（データモデル、API、認証）特定
3. 要件実現可能性分析（Requirements Feasibility Analysis）
   - 技術要件の抽出（データモデル、API、UI、ビジネスルール）
   - ギャップ・制約の特定
   - 複雑性シグナルの評価
4. 実装アプローチ検討（Implementation Approach Options）
   - Option A: 既存コンポーネント拡張
   - Option B: 新規コンポーネント作成
   - Option C: ハイブリッドアプローチ
5. 複雑性・リスク評価
6. 推奨事項まとめ
```

## 分析フレームワーク

### 現状調査項目

| 調査項目 | 内容 |
|----------|------|
| ドメイン関連資産 | 主要ファイル/モジュール、ディレクトリ構成 |
| 規約 | 命名規則、レイヤリング、依存方向 |
| 統合ポイント | データモデル/スキーマ、APIクライアント、認証機構 |

### 実装アプローチ評価

#### Option A: 既存コンポーネント拡張

| 評価項目 | 内容 |
|----------|------|
| 対象ファイル | 変更が必要なファイル特定 |
| 互換性 | 既存インターフェースとの整合性 |
| 複雑性 | 認知負荷、単一責任原則の維持 |

**Trade-offs**:
- 新規ファイル最小限、既存パターン活用
- 既存コンポーネント肥大化リスク

#### Option B: 新規コンポーネント作成

| 評価項目 | 内容 |
|----------|------|
| 作成理由 | 責務分離、既存の複雑性、独立ライフサイクル |
| 統合ポイント | 既存システムとの接続方法 |
| 責務境界 | 新規コンポーネントの所有範囲 |

**Trade-offs**:
- クリーンな責務分離、テスト容易性
- ファイル増加、インターフェース設計必要

#### Option C: ハイブリッドアプローチ

| 評価項目 | 内容 |
|----------|------|
| 組み合わせ戦略 | 拡張部分と新規部分の分担 |
| フェーズ分け | 段階的実装計画 |
| リスク軽減 | インクリメンタルロールアウト、Feature Flag |

### 複雑性・リスク評価

#### 工数（Effort）

| レベル | 目安 | 条件 |
|--------|------|------|
| S | 1-3日 | 既存パターン、最小依存、単純統合 |
| M | 3-7日 | 新パターン/統合あり、中程度複雑性 |
| L | 1-2週 | 大きな機能、複数統合/ワークフロー |
| XL | 2週以上 | アーキテクチャ変更、未知技術、広範影響 |

#### リスク（Risk）

| レベル | 条件 |
|--------|------|
| High | 未知技術、複雑な統合、アーキテクチャ変更、不明確なパフォーマンス/セキュリティ |
| Medium | ガイダンス付き新パターン、管理可能な統合、既知のパフォーマンス解決策 |
| Low | 確立パターンの拡張、馴染みの技術、明確なスコープ、最小統合 |

## ツール

| ツール | 用途 |
|--------|------|
| Grep | コードベース内パターン検索 |
| Glob | ファイル構造調査 |
| Read | ファイル内容分析 |
| WebSearch | 外部依存調査（必要時） |
| WebFetch | ドキュメント参照（必要時） |

## 原則

| 原則 | 説明 |
|------|------|
| 情報提供優先 | 決定ではなく分析とオプションを提供 |
| 複数オプション | 実現可能な複数の選択肢を提示 |
| 明示的なギャップ | 不明点と制約を明確にフラグ |
| コンテキスト考慮 | 既存パターンとアーキテクチャ制限に沿う |
| 透明な見積り | 工数とリスクを簡潔に根拠付け |

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| 要件不在 | requirements スキルの実行を促す |
| ソースコードなし | 対象ディレクトリ確認を促す |
| 複雑な統合が不明確 | "Research Needed" としてフラグ、設計フェーズで詳細調査 |

## コンテキスト更新

```yaml
phases:
  gap_analysis:
    status: completed
    files:
      - docs/00_analysis/gap_analysis.md
analysis:
  effort: S/M/L/XL
  risk: High/Medium/Low
  recommended_approach: A/B/C
```
