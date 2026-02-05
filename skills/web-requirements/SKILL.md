---
name: web-requirements
description: Generate user stories with Gherkin acceptance criteria using Swarm pattern for comprehensive requirements analysis. Triggers on "requirements", "user stories", "define requirements", "requirement analysis"
version: 1.0.0
---

# Web 要件定義スキル

Web 開発の要件定義を支援する。**Swarm パターン**（並列エージェント実行）で網羅性を高め、ユーザーストーリー＋受け入れ基準（Gherkin 形式）を生成。

## 概要

| 項目 | 内容 |
|------|------|
| **対象** | 新規開発（greenfield）・既存改修（brownfield）の両方 |
| **出力形式** | ユーザーストーリー（As a...）+ Gherkin 形式 AC（Given/When/Then） |
| **中間成果物** | `docs/requirements/.work/` に保存（`.gitignore` 対象） |
| **最終成果物** | `docs/requirements/user-stories.md` |

## アーキテクチャ

```
┌─────────────────────────────────────────────────────────────────┐
│                    Orchestrator (SKILL.md)                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Phase 1: Explorer Swarm (並列)                                │
│  ┌─────────┬─────────┬─────────┬─────────┬─────────┐           │
│  │  tech   │ domain  │   ui    │integrat.│   nfr   │           │
│  │ (sonnet)│ (opus)  │(sonnet) │ (opus)  │(sonnet) │           │
│  └────┬────┴────┬────┴────┬────┴────┬────┴────┬────┘           │
│       └─────────┴─────────┼─────────┴─────────┘                │
│                           ▼                                     │
│                    Aggregator (opus)                            │
│                    Two-step Reduce                              │
│                           │                                     │
│  Phase 2: Interviewer     │                                     │
│  (AskUserQuestion 直接)   │                                     │
│                           ▼                                     │
│  Phase 3: Planner (opus)                                       │
│                           │                                     │
│  Phase 4: Writer (sonnet) │                                     │
│                           ▼                                     │
│  Phase 5: Reviewer Swarm (並列)                                │
│  ┌─────────┬─────────┬─────────┬─────────┬─────────┐           │
│  │complete.│consist. │ quality │testabil.│   nfr   │           │
│  │ (haiku) │ (opus)  │ (haiku) │ (haiku) │ (haiku) │           │
│  └────┬────┴────┬────┴────┬────┴────┬────┴────┬────┘           │
│       └─────────┴─────────┼─────────┴─────────┘                │
│                           ▼                                     │
│                    Aggregator (opus)                            │
│                    統合レビュー                                 │
│                           │                                     │
│  Phase 6: Gate 判定       │                                     │
│                           ▼                                     │
│                    user-stories.md                              │
└─────────────────────────────────────────────────────────────────┘
```

## ワークフロー

### Phase 0: モード判定 + スコープ推定

**目的**: greenfield/brownfield 判定、大規模リポジトリの分割判断

**手順**:
1. `git log --oneline -1` でリポジトリ状態確認
2. `scripts/estimate_scope.sh` でファイル数/LOC 計算
3. スコープ分割が必要か判定（閾値: 150 ファイル or 20,000 LOC）
4. `.work/00_scope_manifest.json` に ScopeManifest 出力

**出力**: `docs/requirements/.work/00_scope_manifest.json`

**Done 条件**: ScopeManifest が作成され、mode (greenfield/brownfield) と shards が定義されている

**差し戻し条件**: なし（Phase 0 は常に成功）

---

### Phase 1: Explorer Swarm（既存コード分析）

**目的**: 現状のコードベースを多角的に分析し、要件定義の土台を作る

**入力**: ScopeManifest、ユーザーの要望概要

**手順**:
1. **並列実行**: 5 つの Explorer エージェントを Task ツールで同時起動
   ```
   Task(webreq-explorer-tech, shard=X)  ──┐
   Task(webreq-explorer-domain, shard=X) ─┼─→ 並列
   Task(webreq-explorer-ui, shard=X)     ─┤
   Task(webreq-explorer-integration, shard=X)
   Task(webreq-explorer-nfr, shard=X)   ──┘
   ```
2. 各エージェントは担当範囲のみを分析し、ハンドオフ封筒形式で出力
3. **Aggregator 呼び出し**: Two-step Reduce で統合
   - Step 1: JSON 正規化（各エージェントの findings をマージ）
   - Step 2: Adjudication Pass（矛盾解消、重複排除）

**出力**:
- `docs/requirements/.work/01_explorer/*.md`（各エージェントの生出力）
- `docs/requirements/.work/02_context_unified.md`（統合済みコンテキスト）

**Done 条件**:
- 5 エージェントすべてが status: ok で完了
- context_unified.md が生成され、open_questions が明記されている

**差し戻し条件**:
- いずれかのエージェントが status: blocked
- ファイル読み取りエラーが 3 件以上

**greenfield の場合**: Phase 1 をスキップし、Phase 2 へ直接進む

---

### Phase 2: Interviewer（ヒアリング）

**目的**: ユーザーから要件の詳細をヒアリングし、不明点を解消

**入力**: context_unified.md（brownfield の場合）、ユーザーの初期要望

**方式**: AskUserQuestion ツールを直接使用（サブエージェントではない）

**ヒアリング設計（Double Diamond パターン）**:

```
発散（Discover）     収束（Define）      発散（Develop）     収束（Deliver）
     ↓                   ↓                   ↓                   ↓
自由回答で全体像  →  選択肢で優先度  →  提案を提示して  →  最終確認
を把握               を確定              フィードバック      要約→承認
```

**質問のソフト制限**:
- 1 回あたり 2〜4 問 × 2〜3 サイクル（合計 6〜12 問が目安）
- 各サイクル末尾で要約（Paraphrasing）→ 確認
- 認知負荷が高い場合は早期終了

**確認項目（要件以外も含む）**:

| カテゴリ | 確認内容 |
|---------|---------|
| **ペルソナ** | 誰が使うのか、役割、権限レベル |
| **ユースケース** | 主要フロー、代替フロー、例外フロー |
| **非目標** | 明示的にスコープ外とするもの |
| **成功指標** | KPI、完了の定義 |
| **影響範囲** | 関連する既存機能、他チームへの影響 |
| **削除・廃止** | 不要になる機能、削除すべき要件 |
| **間接的影響** | 直接関係しないが影響があるかもしれない件 |
| **リファクタ必要性** | 技術的負債、構造改善の必要性 |
| **依存関係** | 他機能・外部サービスへの依存 |
| **非機能要件** | パフォーマンス、セキュリティ、運用への波及 |

**停止条件**:
- 意思決定に足る粒度が揃った
- ユーザーが疲労サインを出した
- 情報利得が低下した（同じ回答の繰り返し）

**出力**: `docs/requirements/.work/03_questions.md`

**Done 条件**:
- ペルソナ、主要ユースケース、非目標、成功指標が定義されている
- open_questions が解消されている

**差し戻し条件**: なし（Interviewer は常に何らかの出力を生成）

---

### Phase 3: Planner（構造化）

**目的**: ヒアリング結果をストーリーマップとして構造化

**入力**: questions.md、context_unified.md

**手順**:
1. Task ツールで `webreq-planner` エージェントを起動（model: opus）
2. Epic → Feature → Story の階層構造を設計
3. 依存関係と優先度を判断
4. MVP スコープを定義

**出力**: `docs/requirements/.work/04_story_map.md`

**Done 条件**:
- Epic/Feature/Story の階層が定義されている
- 各 Story に優先度（MVP / Next）が付与されている
- 依存関係が明記されている

**差し戻し条件**:
- Story 数が 0
- 優先度が未定義の Story が 50% 以上

---

### Phase 4: Writer（文書化）

**目的**: ストーリーマップをユーザーストーリー形式に変換

**入力**: story_map.md、context_unified.md

**手順**:
1. Task ツールで `webreq-writer` エージェントを起動（model: sonnet）
2. 各 Story を「As a / I want / So that」形式に変換
3. Acceptance Criteria を Gherkin 形式（Given/When/Then）で記述
4. 失敗系 AC を各 Story に最低 1 つ追加

**出力**: `docs/requirements/user-stories.md`

**Done 条件**:
- すべての Story が正しい形式で記述されている
- 各 Story に AC が 2 つ以上ある
- 各 Story に失敗系 AC が 1 つ以上ある

**差し戻し条件**:
- 形式エラー（As a/I want/So that の欠落）
- AC が Given/When/Then 形式でない

---

### Phase 5: Reviewer Swarm（品質チェック）

**目的**: 生成されたユーザーストーリーを多角的にレビュー

**入力**: user-stories.md

**手順**:
1. **並列実行**: 5 つの Reviewer エージェントを Task ツールで同時起動
   ```
   Task(webreq-reviewer-completeness) ──┐
   Task(webreq-reviewer-consistency)  ──┼─→ 並列
   Task(webreq-reviewer-quality)      ──┤
   Task(webreq-reviewer-testability)  ──┤
   Task(webreq-reviewer-nfr)          ──┘
   ```
2. 各 Reviewer は担当観点のみをチェックし、指摘を重大度（P0/P1/P2）で分類
3. **Aggregator 呼び出し**: 指摘を統合し、重複を排除

**出力**:
- `docs/requirements/.work/06_reviewer/*.md`（各 Reviewer の生出力）
- `docs/requirements/.work/07_review_unified.md`（統合レビュー）

**Done 条件**:
- 5 Reviewer すべてが完了
- review_unified.md が生成されている

**差し戻し条件**: なし（Phase 6 で判定）

---

### Phase 6: Gate 判定

**目的**: レビュー結果に基づき、差し戻しか完了かを判定

**入力**: review_unified.md

**判定ルール**:

| 重大度 | 条件 | 判定 |
|--------|------|------|
| **P0 (Blocker)** | 1 つでもあり | veto（即差し戻し） |
| **P1 (Major)** | 2 つ以上 | 差し戻し |
| **P2 (Minor)** | 任意 | 通過（要対応リストとして記録） |

**P0 判定条件（各 Reviewer）**:

| Reviewer | P0 条件 |
|----------|---------|
| completeness | ペルソナ未定義、AC 欠落 |
| consistency | ID 重複、参照切れ |
| quality | 曖昧語 >3 件、INVEST 違反 |
| testability | テスト不可能な AC |
| nfr | セキュリティ脆弱性、a11y 重大違反 |

**差し戻し先の決定**（Gemini レビュー反映）:

指摘内容に応じて最適な Phase に戻る:

| 指摘カテゴリ | 差し戻し先 | 例 |
|-------------|-----------|-----|
| NFR 不足、要件不明確 | Phase 2 (Interviewer) | セキュリティ要件の追加ヒアリングが必要 |
| ストーリー構造、依存関係 | Phase 3 (Planner) | 巨大ストーリーの分割、依存関係の見直し |
| AC 記述、フォーマット | Phase 4 (Writer) | Gherkin 形式の修正、曖昧語の置き換え |

**出力**:
- 通過の場合: `docs/requirements/user-stories.md`（最終版）
- 差し戻しの場合: 適切な Phase へ戻り、指摘事項を修正

**Done 条件**:
- P0 = 0、P1 < 2
- user-stories.md に「ステータス: Approved」が記載されている

**トレーサビリティ**（Gemini レビュー反映）:

各ストーリーは元となった情報源を記録:
- `Traceability: Q-003, context:auth` の形式で参照元を明記
- これにより、後の変更管理や影響分析が容易になる

---

## スコープ分割

### 判定基準

| 基準 | 閾値 | アクション |
|------|------|-----------|
| ファイル数 | > 150 | shard 分割必須 |
| LOC | > 20,000 | shard 分割必須 |
| 自然境界 | bounded context あり | 境界で分割 |
| 依存密度 | 強結合クラスタ | 同一 shard に |

### ScopeManifest 形式

```json
{
  "mode": "greenfield | brownfield",
  "total_files": 250,
  "total_loc": 35000,
  "shards": [
    {
      "id": "frontend",
      "paths": ["src/frontend/**"],
      "files": 120,
      "loc": 18000
    },
    {
      "id": "backend",
      "paths": ["src/backend/**"],
      "files": 130,
      "loc": 17000
    }
  ]
}
```

---

## ハンドオフ封筒

> **ID 規約の注意**:
> - **Task 呼び出し名**: frontmatter `name`（例: `webreq-explorer-tech`）を使用
> - **封筒 agent_id**: 内部トラッキング用の安定ID（例: `explorer:tech#shard-frontend`）
> - この2つは別物。agent_id は集計互換のため変更しない。

エージェント間の契約として、以下のスキーマで出力を統一:

```yaml
kind: explorer | reviewer | planner | writer | aggregator
agent_id: explorer:tech#shard-frontend
mode: greenfield | brownfield
status: ok | needs_input | conflict | blocked
severity: null | P0 | P1 | P2  # Reviewer のみ
artifacts:
  - path: .work/01_explorer/tech.md
    type: context | finding | question | story | review
open_questions: [...]
blockers: [...]
next: explorer | interviewer | planner | writer | reviewer | aggregator | done
```

---

## ツール使用ルール

### 許可されるツール

| Phase | ツール |
|-------|--------|
| Phase 0 | Bash（estimate_scope.sh）、Write |
| Phase 1 | Task（Explorer Swarm）、Read、Glob、Grep、Write（.work/ への出力） |
| Phase 2 | AskUserQuestion、Write |
| Phase 3 | Task（Planner）、Read、Write |
| Phase 4 | Task（Writer）、Write |
| Phase 5 | Task（Reviewer Swarm）、Read、Write（.work/ への出力） |
| Phase 6 | Read、Write |

### 並列実行パターン

Swarm エージェントは**必ず並列**で起動する:

```markdown
# 正しい例（並列）
Task(webreq-explorer-tech) と Task(webreq-explorer-domain) と ... を同時に呼び出す

# 間違い例（逐次）
Task(webreq-explorer-tech) の完了を待ってから Task(webreq-explorer-domain) を呼び出す
```

---

## エラーハンドリング

| 状況 | 対応 |
|------|------|
| Explorer が blocked | エラー内容を記録し、該当 shard をスキップ。Aggregator で警告を出力 |
| ファイル読み取りエラー | 3 件未満は続行、3 件以上は Phase 中断 |
| Reviewer が矛盾した指摘 | Aggregator が重大度の高い方を採用 |
| Gate 判定で 3 回差し戻し | ユーザーに手動介入を要請 |

---

## 使用例

### 新規機能の要件定義

```
User: 「認証機能の要件を定義して」

Claude:
1. Phase 0: greenfield と判定（既存コードなし）
2. Phase 1: スキップ
3. Phase 2: AskUserQuestion でヒアリング
   - 「どのような認証方式を想定していますか？」
   - 「ユーザーの種類（管理者/一般）はありますか？」
4. Phase 3: Planner でストーリーマップ作成
5. Phase 4: Writer でユーザーストーリー生成
6. Phase 5: Reviewer Swarm でレビュー
7. Phase 6: Gate 通過 → user-stories.md 完成
```

### 既存機能の改修要件

```
User: 「決済機能にクーポン適用を追加したい」

Claude:
1. Phase 0: brownfield と判定、スコープ推定
2. Phase 1: Explorer Swarm で現状分析
   - tech: 決済 API の構造
   - domain: 価格計算ロジック
   - integration: 外部決済サービス連携
3. Phase 2: AskUserQuestion でヒアリング
   - 「クーポンの種類は？（割引率/定額）」
   - 「既存の割引機能との併用は？」
4. Phase 3-6: 同上
```

