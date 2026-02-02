# Prompt Improver

Claude Code の設定（CLAUDE.md / スキル / hooks）を継続的に改善するための自己学習スキル。

## 概要

タスク完了時に自動でフィードバックを収集し、蓄積されたデータからパターンを分析して改善提案を生成します。

```
┌─────────────────────────────────────────────────────────────┐
│                    自己改善ループ                            │
│                                                             │
│   タスク実行 → Stop hook → フィードバック収集 → 保存         │
│                                ↓                            │
│   改善適用 ← 改善提案生成 ← パターン分析 ← 蓄積データ        │
└─────────────────────────────────────────────────────────────┘
```

## クイックスタート

### 1. インストール

```bash
cd ai-skills
./install.sh
```

これにより `~/.claude/skills/prompt-improver/` にスキルがコピーされます。

また Stop hook 用スクリプトもインストールされます（`install.sh` 管理 / `--delete` 対象）:

- managed: `~/.claude/scripts/ai-skills/prompt-improver/`
- 互換ラッパー: `~/.claude/scripts/collect_feedback.sh`（Stop hook はこれを呼ぶ想定）
- 互換ラッパー: `~/.claude/scripts/extract_transcript.py`

既存の `~/.claude/scripts/collect_feedback.sh` / `extract_transcript.py` がある場合は、上書き前に `*.bak` へ退避します。

### 2. Stop hook の設定

`~/.claude/settings.json` に以下を追加:

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

### 2.1 自動通知（未処理フィードバック閾値）

未処理フィードバック（`triage.status: open`）が一定数以上たまると、タスク終了時に 1 行だけ通知を表示します。

```bash
export FEEDBACK_THRESHOLD=10  # 10件以上で通知（デフォルト: 5）
```

### 3. 使い方

```bash
# フィードバック統計を表示
/improve --stats

# 分析と改善提案を実行
/improve
```

## コマンド一覧

| コマンド | 説明 |
|---------|------|
| `/improve` | フィードバック分析と改善提案をインタラクティブに実行 |
| `/improve --stats` | 統計情報のみ表示 |
| `/improve --target <path>` | 特定ファイルに関する改善のみ |

## スクリプト一覧

### Stop hook（自動収集）

Stop hook は `~/.claude/scripts/collect_feedback.sh` を実行します（このファイルは `install.sh` が生成する互換ラッパーです）。

実体（managed scripts）は以下に置かれ、`install.sh` により上書き・削除管理されます:

- `~/.claude/scripts/ai-skills/prompt-improver/collect_feedback.sh`
- `~/.claude/scripts/ai-skills/prompt-improver/extract_transcript.py`

### analyze_feedback.sh

フィードバックのパターン分析を実行。

```bash
# 統計表示
./scripts/analyze_feedback.sh --stats

# パターン分析
./scripts/analyze_feedback.sh

# 特定ファイルにフィルタ
./scripts/analyze_feedback.sh --target CLAUDE.md
```

### update_triage.sh

フィードバックのステータスを更新。

```bash
# fixedに変更
./scripts/update_triage.sh fb-20260201-001 --status fixed

# fix-ref付きでfixedに変更
./scripts/update_triage.sh fb-20260201-001 --status fixed --fix-ref "commit:abc123"

# 検証済みに変更
./scripts/update_triage.sh fb-20260201-001 --status verified
```

**ステータス一覧:**
- `open`: 新規（未処理）
- `triaged`: トリアージ済み
- `in_progress`: 対応中
- `fixed`: 修正済み
- `verified`: 検証済み
- `wont_fix`: 対応しない

### archive_feedback.sh

改善済みや古いフィードバックをアーカイブ。

```bash
# fixed/verified/wont_fix をすべてアーカイブ
./scripts/archive_feedback.sh --all-fixed

# verified のみアーカイブ
./scripts/archive_feedback.sh --status verified

# 30日以上古いログをアーカイブ
./scripts/archive_feedback.sh --older-than 30

# ドライラン（確認のみ）
./scripts/archive_feedback.sh --all-fixed --dry-run
```

アーカイブ先: `~/.claude/feedback/archive/`

### generate_improvements.sh

分析結果から改善提案を生成。

```bash
./scripts/generate_improvements.sh
```

## 処理フロー

### フィードバック収集（自動）

1. **タスク完了** → Stop hook 発火
2. **収集条件判定** → 以下のいずれかに該当する場合のみ収集:
   - Write/Edit/Bash でコード変更があった
   - ツール使用が3回以上
   - メッセージが10件以上（実質的なセッション）
   - ただしメッセージが6件未満の場合はスキップ
3. **YAML生成** → `~/.claude/feedback/fb-YYYYMMDD-NNN.yaml` に保存
4. **閾値通知（任意）** → 未処理が `FEEDBACK_THRESHOLD` 以上なら 1 行通知

### 改善分析（手動: /improve）

1. **Phase 1**: フィードバック収集
   - `~/.claude/feedback/` からYAMLファイルを読み込み

2. **Phase 2**: パターン分析
   - 頻出する問題パターンを特定
   - blame_score で優先度をランキング

3. **Phase 3**: 改善提案生成
   - 具体的な改善案をリストアップ
   - 影響度と工数を評価

4. **Phase 4**: 改善適用（インタラクティブ）
   - ユーザーが選択した改善を適用
   - **重要**: 編集先を正しく選択
     - `skills/*` → `ai-skills/skills/` リポジトリ
     - `CLAUDE.md`, `RULES.md` → `~/.claude/` 直接

5. **Phase 5**: フィードバック更新
   - 適用した改善に関連するフィードバックを `fixed` に更新

## データ構造

フィードバックは `~/.claude/feedback/` に YAML 形式で保存されます。

```yaml
# 基本情報
id: fb-20260201-001
created_at: 2026-02-01T12:00:00Z
updated_at: 2026-02-01T15:30:00Z
session_id: abc-123-def

# タスク情報
task_summary: "認証機能の実装"
outcome:
  success: false
  score: 0.6
  rationale: "基本機能は動作するがエッジケース未対応"

# 問題点
issues:
  - issue_id: issue-001
    type: prompt_unclear
    description: "CLAUDE.mdの指示が曖昧で誤解した"
    target:
      type: claude_md
      path: ~/.claude/CLAUDE.md
      section: "## コーディング規約"
    severity: high

# トリアージ
triage:
  status: open
  priority: high

# 解決情報
resolution:
  fix_ref: ""
  verified_at: ""
```

詳細なスキーマは `references/feedback_schema.md` を参照。

## ディレクトリ構成

```
skills/prompt-improver/
├── README.md           # このファイル
├── SKILL.md            # スキル定義
├── scripts/
│   ├── collect_feedback.sh      # フィードバック収集（手動実行用）
│   ├── analyze_feedback.sh      # パターン分析
│   ├── generate_improvements.sh # 改善提案生成
│   ├── update_triage.sh         # ステータス更新
│   └── archive_feedback.sh      # アーカイブ
├── references/
│   └── feedback_schema.md       # YAMLスキーマ定義
└── assets/
    ├── hooks/
    │   └── stop_hook.json       # Stop hook設定例
    └── scripts/
        ├── collect_feedback.sh   # Stop hook 用（自動収集の実体）
        ├── extract_transcript.py # トランスクリプト解析
        └── section_keywords.json # 抽出ルール
```

インストール後（`~/.claude/`）:

```
~/.claude/
├── skills/prompt-improver/                  # install.sh がコピー
├── scripts/
│   ├── collect_feedback.sh                  # 互換ラッパー（install.sh が生成）
│   ├── extract_transcript.py                # 互換ラッパー（install.sh が生成）
│   └── ai-skills/prompt-improver/           # managed（install.sh が --delete 管理）
│       ├── collect_feedback.sh              # Stop hook 実体
│       ├── extract_transcript.py
│       └── section_keywords.json
```

## 注意事項

### 編集先の選択

| ファイル種別 | 編集先 | 理由 |
|-------------|--------|------|
| skills/* | `ai-skills/skills/` | ソース管理、install.sh で反映 |
| CLAUDE.md, RULES.md | `~/.claude/` 直接 | ユーザー設定 |

**⚠️ `~/.claude/skills/` を直接編集しない**: 次の `install.sh` で上書きされます。

**⚠️ `~/.claude/scripts/ai-skills/` を直接編集しない**: `install.sh` が `--delete` で管理します。

Stop hook の挙動を変える場合は、`ai-skills/skills/prompt-improver/assets/scripts/` を編集して `./install.sh` で反映します。

### プライバシー

- APIキー、パスワード等の秘密情報は記録しない
- 必要に応じて `privacy.redacted: true` を設定
- 個人情報は伏せ字にする

## 依存関係

標準Unixツールのみ（追加インストール不要）:
- bash, awk, grep, sed, date, sort, uniq, head, stat, mv, mkdir

## トラブルシューティング

### `/improve` が見つからない

```bash
cd ai-skills
./install.sh
```

### フィードバックが収集されない

1. Stop hook が設定されているか確認:
   ```bash
   cat ~/.claude/settings.json | grep -A10 "Stop"
   ```

2. スクリプトがインストールされているか確認（なければ `./install.sh` を再実行）:
   ```bash
   ls -la ~/.claude/scripts/collect_feedback.sh ~/.claude/scripts/ai-skills/prompt-improver/collect_feedback.sh
   ```

3. デバッグログを確認:
   ```bash
   tail -n 100 ~/.claude/feedback/debug.log
   ```

### update_triage.sh でエラー

triage セクションがない古いYAMLファイルの場合、スクリプトが自動的に追加します。

## 関連ドキュメント

- [SKILL.md](./SKILL.md) - スキル定義の詳細
- [feedback_schema.md](./references/feedback_schema.md) - YAMLスキーマ
- [/improve コマンド](../../commands/improve.md) - コマンド定義
