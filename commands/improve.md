---
description: "Analyze feedback and generate improvement proposals for prompts and skills"
version: "1.0.0"
allowed-tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - Bash
  - AskUserQuestion
context: fork
agent: General-purpose
---

# /improve - フィードバック分析と改善提案

蓄積されたフィードバックを分析し、CLAUDE.md/SKILL/hooksの改善提案を生成する。

## ワークフロー

### Phase 1: フィードバック収集

`~/.claude/feedback/` からフィードバックを読み込む。

```bash
ls -la ~/.claude/feedback/
```

### Phase 2: パターン分析

分析スクリプトを実行:

```bash
# 統計表示
~/.claude/skills/prompt-improver/scripts/analyze_feedback.sh --stats

# パターン分析
~/.claude/skills/prompt-improver/scripts/analyze_feedback.sh
```

### Phase 2.5: 構造改善候補の抽出

フィードバックパターンから新スキル作成・スキル分割の推奨を生成:

```bash
python3 ~/.claude/skills/prompt-improver/scripts/recommend_structure.py
```

**出力例**:
```
【新スキル候補】
1) openapi-lifecycle（6件 / high:3）
   - 根拠: 既存ターゲットに結び付かない指摘が反復（unmapped率: 83%）
   - 代表キーワード: openapi, schema, validation

【スキル分割候補】
1) skills/architecture/SKILL.md（11件）
   - クラスターA: security（6件）: auth, jwt, oauth
   - クラスターB: decisions（5件）: adr, trade-off
```

該当がない場合は「構造改善の推奨はありません」と表示。

### Phase 3: 改善提案生成

改善提案を生成:

```bash
~/.claude/skills/prompt-improver/scripts/generate_improvements.sh
```

### Phase 4: 改善適用（ユーザー確認）

AskUserQuestionを使用して、適用する改善を選択:

- 各改善案について影響度と工数を説明
- ユーザーが選択した改善を適用

**重要: 編集先の選択**

| ファイル種別 | 編集先 | 理由 |
|-------------|--------|------|
| skills/* | `ai-skills/skills/` リポジトリ | ソース管理され、install.sh で反映 |
| CLAUDE.md, RULES.md 等 | `~/.claude/` 直接 | リポジトリ外のユーザー設定 |

- skills を編集した場合は、最後に `cd ai-skills && ./install.sh` で反映する
- `~/.claude/skills/` を直接編集すると、次の install.sh で上書きされるため **禁止**

### Phase 5: フィードバック更新

適用した改善について、関連フィードバックのステータスを更新:

```yaml
triage:
  status: fixed
resolution:
  fix_ref: "適用した変更の説明"
  verified_at: "検証日時"
```

## オプション

| オプション | 説明 |
|-----------|------|
| `--stats` | フィードバック統計のみ表示 |
| `--target <path>` | 特定ファイルの改善のみ |

> **Note**: 改善適用はPhase 4でAskUserQuestionを使用してインタラクティブに実施

## 出力形式

```
【頻出パターン】
1. "具体例不足" - 5件（architecture, api, database）
2. "曖昧な指示" - 3件（CLAUDE.md）

【優先改善対象】
1. skills/architecture/SKILL.md
   - 問題: 認証・セキュリティパターンの例が不足
   - 提案: JWT/OAuth2の実装例を追加
   - 影響度: high / 工数: low
```

## 参照

- スキーマ: `skills/prompt-improver/references/feedback_schema.md`
- スクリプト: `skills/prompt-improver/scripts/`
