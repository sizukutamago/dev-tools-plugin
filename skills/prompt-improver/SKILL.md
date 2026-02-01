---
name: prompt-improver
description: Collect feedback on task completion to improve prompts, CLAUDE.md, and skills. Use when the user says "improve prompts", "analyze feedback", "reflect on task", "/improve", or when Stop hook triggers for feedback collection. Enables continuous improvement loop for Claude Code configurations.
---

# Prompt Improver

タスク完了時のフィードバックを収集・分析し、CLAUDE.md/SKILL/hooksの継続的改善を支援するスキル。

## 概要

```
┌─────────────────────────────────────────────────────────────┐
│                    自己改善ループ                            │
│                                                             │
│   タスク実行 → Stop hook → フィードバック収集 → 保存         │
│                                ↓                            │
│   改善適用 ← 改善提案生成 ← パターン分析 ← 蓄積データ        │
└─────────────────────────────────────────────────────────────┘
```

## ワークフロー

### Step 1: フィードバック収集（条件付き自動）

Stop hookでタスク完了時に**条件を判断して**収集。

#### 収集条件（いずれかに該当する場合のみ）

- Write/Edit/Bashで実質的なコード変更を行った
- スキル（/hearing, /architecture, /api等）を使用した
- ユーザーから修正指示・不満・指摘があった
- エラーや予期しない失敗が発生した
- 3ステップ以上の複雑なタスクを実行した

#### スキップ条件（以下のみの場合は収集しない）

- 質問への回答・説明のみ
- git status/Read/Glob等の閲覧操作のみ
- 1-2ターンの軽微な対話
- 設定確認や情報表示のみ

#### 収集する情報

1. タスクの要約と結果（成功/部分成功/失敗）
2. 問題点と関連するプロンプト/SKILLへの紐付け
3. ユーザーからの指摘（あれば）
4. 改善の示唆

### Step 2: フィードバック分析（/improve）

蓄積されたフィードバックを分析:

```bash
# 統計表示
./scripts/analyze_feedback.sh --stats

# パターン分析
./scripts/analyze_feedback.sh

# 特定ファイルにフィルタ
./scripts/analyze_feedback.sh --target CLAUDE.md
```

### Step 3: 改善提案・適用

分析結果から具体的な改善案を生成:

```bash
# 改善提案生成
./scripts/generate_improvements.sh

# トリアージ更新
./scripts/update_triage.sh fb-20260201-001 --status fixed --fix-ref "commit:abc123"
```

## フィードバックデータ構造

`~/.claude/feedback/` に YAML 形式で保存。詳細は [references/feedback_schema.md](references/feedback_schema.md) 参照。

### 必須フィールド

```yaml
id: fb-20260201-001
created_at: 2026-02-01T12:00:00Z
task_summary: "認証機能の実装"
outcome:
  success: false
  score: 0.6
  rationale: "基本機能は動作するがエッジケース未対応"
issues:
  - issue_id: issue-001
    type: prompt_unclear        # prompt_unclear | skill_incomplete | skill_incorrect | hook_missing | hook_incorrect | example_missing | pattern_missing | context_lost | misunderstanding | other
    description: "CLAUDE.mdの指示が曖昧で誤解した"
    target:
      type: claude_md           # claude_md | skill | hook | command | agent | other
      path: ~/.claude/CLAUDE.md
      section: "## コーディング規約"
    severity: high              # critical | high | medium | low
```

### 推奨フィールド

```yaml
context:
  skill_name: architecture
  skill_version: 1.2.0
  prompt_hash: abc123
  model: claude-opus-4-5-20251101

source: user                    # user | self | eval
user_feedback: "もっと具体的な例が欲しかった"

proposed_actions:
  - scope: skill
    change_summary: "architectureスキルにコード例を追加"
    expected_impact: high
    effort: low

triage:
  status: open                  # open | triaged | in_progress | fixed | verified
  priority: high
  labels: [documentation, example]
```

## hooks設定

### Stop hook（タスク完了時フィードバック収集）

`type: "command"` を使用してシェルスクリプトで確実に収集。

#### 1. スクリプト配置

`~/.claude/scripts/collect_feedback.sh` を作成（実行権限付与必須）。
スクリプトは以下を行う:
- 標準入力からトランスクリプト情報を受け取る
- 収集条件を判定（コード変更数、ツール使用数、メッセージ数）
- 条件を満たす場合のみフィードバックファイルを生成

#### 2. settings.json に追加

```json
{
  "hooks": {
    "Stop": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/scripts/collect_feedback.sh"
          }
        ]
      }
    ]
  }
}
```

#### 収集条件（スクリプト内で判定）

- Write/Edit/Bash ツール使用（コード変更）があった
- ツール使用が3回以上（複雑なタスク）
- メッセージ交換が6回以上（実質的なセッション）
- ただしメッセージ4回未満はスキップ

> **Note**: 事前に以下を実行:
> ```bash
> mkdir -p ~/.claude/feedback ~/.claude/scripts
> chmod +x ~/.claude/scripts/collect_feedback.sh
> ```

## 使用例

### フィードバック収集の流れ（収集される場合）

```
User: "認証機能を実装して"

Claude: [実装作業... Write/Edit で複数ファイル変更]

[タスク完了 → Stop hook発火 → 収集条件に該当]

Claude: 振り返りを実行します...
- 結果: 部分成功（基本機能OK、エッジケース未対応）
- 問題: architectureスキルにJWT認証の具体例がなかった
- 改善案: skills/architecture/SKILL.md に認証パターン例を追加

フィードバックを保存しました: ~/.claude/feedback/fb-20260201-001.yaml
```

### スキップされる場合

```
User: "git status 見せて"

Claude: [git status 実行、結果表示]

[タスク完了 → Stop hook発火 → スキップ条件に該当]

（何も出力せず終了）
```

### 改善分析の実行

```
User: "/improve"

Claude: フィードバックを分析します...

【頻出パターン】
1. "具体例不足" - 5件（architecture, api, database）
2. "曖昧な指示" - 3件（CLAUDE.md）

【優先改善対象】
1. skills/architecture/SKILL.md
   - 問題: 認証・セキュリティパターンの例が不足
   - 提案: JWT/OAuth2の実装例を追加
   - 影響度: high / 工数: low

2. ~/.claude/CLAUDE.md
   - 問題: "適切に処理"などの曖昧表現
   - 提案: 具体的な判断基準を明記
   - 影響度: medium / 工数: medium
```

## コマンド

| コマンド | 説明 |
|---------|------|
| `/improve` | フィードバック分析と改善提案を実行 |
| `/improve --stats` | フィードバック統計を表示 |

> Note: 改善適用は AskUserQuestion を使用してインタラクティブに実施

## 依存関係

標準Unixツールのみ（追加インストール不要）:
- bash, grep, awk, sed, date

## プライバシー注意

⚠️ フィードバック記録時の注意:
- APIキー、パスワード等の秘密情報は記録しない
- 必要に応じて `privacy.redacted: true` を設定
- 個人情報は伏せ字にする

## リソース

### scripts/

- `collect_feedback.sh`: フィードバック収集・保存（原子的ID生成）
- `analyze_feedback.sh`: パターン分析（--stats, --target対応）
- `generate_improvements.sh`: 改善提案生成
- `update_triage.sh`: トリアージステータス更新

### references/

- `feedback_schema.md`: フィードバックデータの完全スキーマ定義

### assets/

- `hooks/stop_hook.json`: Stop hook設定例
