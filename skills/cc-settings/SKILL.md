---
name: cc-settings
description: "Claude Code settings catalog — discover what you can customize. Fetches latest settings and env vars from 3 sources (JSON Schema + official docs + official env-vars docs) to show all available options. Use when user says '設定', 'settings', '設定一覧', '設定カタログ', 'what can I configure', '何が設定できる', 'Claude Code設定', '設定項目', '環境変数', 'env vars', or wants to discover available Claude Code configuration options."
version: 3.0.0
---

# Claude Code Settings — 設定カタログ

Claude Code で **何がカスタマイズできるのか** を能動的に発見するためのスキル。
3つのデータソースから最新情報を取得し、settings.json プロパティ + 環境変数の両方をカテゴリ別に一覧表示する。

## 設計思想

このスキルの目的は「設定の代行」ではなく「**設定の発見**」。
ユーザーは「何ができるか」を知りたい。設定作業自体は自分でやれる。

## データソース（3点セット）

単一ソースでは漏れがあるため、3つを並列取得して統合する。

| # | ソース | URL | カバー範囲 |
|---|--------|-----|-----------|
| 1 | JSON Schema | `https://json.schemastore.org/claude-code-settings.json` | settings.json の構造化プロパティ |
| 2 | 公式設定ドキュメント | `https://code.claude.com/docs/en/settings` | settings.json + ファイルスコープ + 未ドキュメント設定 |
| 3 | 公式環境変数ドキュメント | `https://code.claude.com/docs/en/env-vars` | env 内で使える全環境変数 |

**なぜ3つ必要か**: Schema はコミュニティ管理で遅れがち。公式ドキュメントには Schema にない設定（`modelOverrides`, `worktree.*`, `allowedHttpHookUrls` 等）が含まれる。環境変数は settings.json とは別体系で 90+ 個ある。

## 定数

```
SCHEMA_URL=https://json.schemastore.org/claude-code-settings.json
SETTINGS_DOC_URL=https://code.claude.com/docs/en/settings
ENV_VARS_DOC_URL=https://code.claude.com/docs/en/env-vars
GLOBAL_SETTINGS=~/.claude/settings.json
PROJECT_SETTINGS={cwd}/.claude/settings.json
```

## 設定ファイルのスコープ（ユーザーに説明する際の参考）

| 優先度 | ファイル | パス | 影響範囲 | チーム共有 |
|--------|---------|------|---------|----------|
| 1 (最高) | managed-settings.json | `~/.config/claude/managed-settings.json` | マシン上の全ユーザー | IT 配布 |
| 2 | settings.json | `~/.claude/settings.json` | 全プロジェクトの自分 | いいえ |
| 3 | settings.json | `{project}/.claude/settings.json` | リポジトリの全コラボレーター | はい (git) |
| 4 (最低) | settings.local.json | `{project}/.claude/settings.local.json` | 特定リポジトリの自分のみ | いいえ (.gitignore) |

その他のファイル:
- `~/.claude.json` — MCP サーバー設定（user/local）
- `.mcp.json` — プロジェクトスコープの MCP サーバー
- `CLAUDE.md` / `.claude/CLAUDE.md` / `~/.claude/CLAUDE.md` — 指示・コンテキスト
- `~/.claude/agents/` / `.claude/agents/` — サブエージェント定義

## ワークフロー

### Phase 1: データ取得（並列）

3つのソースを **Agent サブエージェント3並列** で取得する。

#### Agent 1: Schema 取得
```
WebFetch: SCHEMA_URL
prompt: 「全プロパティの名前、型、description、デフォルト値を漏れなくリストしてください」
```
- リダイレクト発生時はリダイレクト先を再フェッチ

#### Agent 2: 公式設定ドキュメント取得
```
WebFetch: SETTINGS_DOC_URL
prompt: 「settings.json の全設定キーを抽出してください。キー名、説明、デフォルト値、設定例、対象スコープを含めてください」
```

#### Agent 3: 公式環境変数ドキュメント取得
```
WebFetch: ENV_VARS_DOC_URL
prompt: 「全環境変数を抽出してください。変数名、説明、デフォルト値を含めてください」
```

#### 並行して: 現在の設定を Read
- グローバル: `~/.claude/settings.json`
- プロジェクト（存在すれば）: `{cwd}/.claude/settings.json`

### Phase 2: 統合・カテゴリ分類

3つのソースの結果を統合し、以下のカテゴリに分類する。

#### settings.json カテゴリ（17カテゴリ）

| # | カテゴリ | 対象プロパティ | 一言説明 |
|---|---------|---------------|---------|
| 1 | モデル・推論 | model, modelOverrides, effortLevel, fastMode, fastModePerSessionOptIn, alwaysThinkingEnabled, availableModels | 使用モデルと思考設定 |
| 2 | 権限・セキュリティ | permissions (allow/deny/ask/defaultMode/disableBypassPermissionsMode/additionalDirectories) | ツールの許可/拒否 |
| 3 | サンドボックス | sandbox (enabled, network, filesystem, ignoreViolations, excludedCommands, auto*, enableWeaker*) | Bash 実行の隔離設定 |
| 4 | Hooks | hooks (19イベント), disableAllHooks, allowedHttpHookUrls, httpHookAllowedEnvVars | イベント駆動の自動処理 |
| 5 | MCP サーバー | enableAllProjectMcpServers, enabledMcpjsonServers, disabledMcpjsonServers, allowedMcpServers, deniedMcpServers | 外部ツール連携 |
| 6 | プラグイン | enabledPlugins, extraKnownMarketplaces, skippedMarketplaces, skippedPlugins, pluginConfigs | 拡張機能 |
| 7 | Git・属性 | includeGitInstructions, includeCoAuthoredBy, attribution (commit/pr) | Git 連携と著者表示 |
| 8 | UI・表示 | statusLine, outputStyle, spinnerVerbs, spinnerTipsEnabled, spinnerTipsOverride, terminalProgressBarEnabled, showTurnDuration, prefersReducedMotion, fileSuggestion | 見た目のカスタマイズ |
| 9 | 言語 | language | 応答言語 |
| 10 | 認証 | apiKeyHelper, awsCredentialExport, awsAuthRefresh, forceLoginMethod, forceLoginOrgUUID | API キー・ログイン |
| 11 | ストレージ | cleanupPeriodDays, plansDirectory, respectGitignore, autoMemoryEnabled, autoMemoryDirectory | データ保持と保存先 |
| 12 | 更新 | autoUpdatesChannel | 自動アップデート |
| 13 | エージェントチーム | teammateMode, agent | マルチエージェント |
| 14 | Worktree | worktree.symlinkDirectories, worktree.sparsePaths | ワークツリー設定 |
| 15 | 管理者向け | allowManagedHooksOnly, allowManagedPermissionRulesOnly, allowManagedMcpServersOnly, blockedMarketplaces, strictKnownMarketplaces, companyAnnouncements, pluginTrustMessage, disallowedTools | 組織管理用 |
| 16 | フィードバック | feedbackSurveyRate, skipDangerousModePermissionPrompt | 調査・プロンプト制御 |
| 17 | その他 | skipWebFetchPreflight, otelHeadersHelper, env | テレメトリ等 |

#### 環境変数カテゴリ（12カテゴリ）

| # | カテゴリ | 一言説明 |
|---|---------|---------|
| E1 | モデル・API | ANTHROPIC_MODEL, ANTHROPIC_API_KEY 等 |
| E2 | AWS Bedrock | CLAUDE_CODE_USE_BEDROCK 等 |
| E3 | Google Vertex AI | CLAUDE_CODE_USE_VERTEX 等 |
| E4 | Microsoft Foundry | CLAUDE_CODE_USE_FOUNDRY 等 |
| E5 | Bash・シェル | BASH_DEFAULT_TIMEOUT_MS, CLAUDE_CODE_SHELL 等 |
| E6 | コンテキスト・思考 | CLAUDE_CODE_DISABLE_1M_CONTEXT, MAX_THINKING_TOKENS 等 |
| E7 | 機能の有効化/無効化 | CLAUDE_CODE_DISABLE_* 系, CLAUDE_CODE_ENABLE_* 系 |
| E8 | テレメトリ・レポート | DISABLE_TELEMETRY, DISABLE_ERROR_REPORTING 等 |
| E9 | MCP | MAX_MCP_OUTPUT_TOKENS, MCP_TIMEOUT 等 |
| E10 | プロキシ・mTLS | HTTP_PROXY, CLAUDE_CODE_CLIENT_CERT 等 |
| E11 | SDK・エージェント | CLAUDE_CODE_ACCOUNT_UUID, CLAUDE_CODE_TEAM_NAME 等 |
| E12 | その他 | CLAUDE_CONFIG_DIR, USE_BUILTIN_RIPGREP 等 |

**注意**: 3つのソースの結果に含まれるが上記カテゴリに該当しないプロパティは「新着」として別枠で表示する。

### Phase 3: カタログ表示

#### 表示フォーマット（引数なしの場合 = カテゴリ一覧）

```
## Claude Code 設定カタログ

3つのソースから取得しました。

### settings.json（{N} 件）

| # | カテゴリ | 項目数 | 設定済 | 説明 |
|---|---------|-------|-------|------|
| 1 | モデル・推論 | 7 | 3 | 使用モデルと思考設定 |
| 2 | 権限・セキュリティ | 6 | 1 | ツールの許可/拒否 |
| ...

### 環境変数（{M} 件）

| # | カテゴリ | 項目数 | 設定済 | 説明 |
|---|---------|-------|-------|------|
| E1 | モデル・API | 14 | 0 | モデル指定・APIキー |
| E2 | AWS Bedrock | 4 | 0 | Bedrock 連携 |
| ...

詳細を見たいカテゴリの番号を教えてください（例: 4, E5）。
`--all` で全項目、`--env` で環境変数のみ表示。
```

#### 表示フォーマット（カテゴリ指定の場合）

```
## カテゴリ: {カテゴリ名}

| 設定項目 | 型 | デフォルト | 現在値 | 説明 |
|---------|-----|----------|-------|------|
| model | string | - | opus[1m] | 使用モデルの指定 |
| ...

💡 設定方法: ~/.claude/settings.json に追記
```

環境変数カテゴリの場合:
```
## カテゴリ: {カテゴリ名}

| 環境変数 | デフォルト | 現在値 | 説明 |
|---------|----------|-------|------|
| BASH_DEFAULT_TIMEOUT_MS | - | 3600000 | Bash タイムアウト |
| ...

💡 設定方法: settings.json の "env" 内に追記、またはシェル環境変数として設定
```

**現在値の表示ルール**:
- settings.json に値があれば → その値を表示
- env 内に値があれば → その値を表示
- 未設定 → 「-」と表示

#### 表示フォーマット（--all の場合）

全カテゴリを順番に表示。管理者向け（カテゴリ15）はデフォルト省略、末尾に「`--admin` で表示」と注記。

### Phase 4: フォローアップ

カタログ表示後、ユーザーが特定の設定に興味を示したら：
1. その設定の詳細（型、取りうる値、設定例）を説明
2. 現在値との差分を表示
3. 必要ならその場で設定を変更する提案（ただし押し付けない）

## 引数

| 引数 | 説明 |
|------|------|
| (なし) | カテゴリ一覧を表示 |
| `<カテゴリ番号>` | 指定カテゴリの詳細（例: `4`, `E5`） |
| `<キーワード>` | キーワードで設定項目を検索 |
| `--all` | 全項目を一覧表示 |
| `--env` | 環境変数のみ表示 |
| `--diff` | 設定済み vs 未設定の差分を表示 |
| `--admin` | 管理者向け設定も表示 |

## Hooks 一覧（カテゴリ4 の補足）

| イベント | タイミング | ユースケース例 |
|---------|-----------|--------------|
| PreToolUse | ツール呼び出し前 | 危険なコマンドをブロック |
| PostToolUse | ツール完了後 | ログ記録、通知 |
| PostToolUseFailure | ツール失敗後 | エラー通知 |
| PermissionRequest | 権限確認表示時 | 自動承認/拒否 |
| Notification | 通知時 | Slack/Discord 連携 |
| UserPromptSubmit | プロンプト送信時 | 入力バリデーション |
| Stop | 応答完了時 | フィードバック収集 |
| SubagentStart | サブエージェント生成時 | 監視 |
| SubagentStop | サブエージェント完了時 | 結果集約 |
| PreCompact | コンテキスト圧縮前 | 重要情報の保存 |
| TeammateIdle | チームメンバー待機時 | リソース管理 |
| TaskCompleted | タスク完了時 | 進捗通知 |
| Setup | リポジトリ初期化時 | 環境セットアップ |
| InstructionsLoaded | CLAUDE.md ロード時 | 設定検証 |
| ConfigChange | 設定変更時 | 設定同期 |
| WorktreeCreate | ワークツリー生成時 | 環境準備 |
| WorktreeRemove | ワークツリー削除時 | クリーンアップ |
| SessionStart | セッション開始時 | 初期化処理 |
| SessionEnd | セッション終了時 | 終了処理 |

Hook の型:
- **command**: シェルコマンド実行（`command`, `timeout`, `async`, `statusMessage`）
- **prompt**: LLM にプロンプトで判断させる（`prompt`, `model`, `timeout`）
- **agent**: エージェントに検証させる（`prompt`, `model`, `timeout`）
- **http**: HTTP POST リクエスト（`url`, `headers`, `allowedEnvVars`, `timeout`）

## 権限ルールの書式（カテゴリ2 の補足）

```
ToolName                     → ツール全体を許可/拒否
ToolName(pattern)            → パターンマッチ
ToolName(/path/pattern)      → パスパターン
mcp__server                  → MCP サーバー全体
mcp__server__tool            → MCP サーバーの特定ツール
WebFetch(domain:example.com) → ドメイン指定
Agent(Explore)               → 特定エージェント型
```

利用可能なツール名:
`Agent`, `Bash`, `Edit`, `ExitPlanMode`, `Glob`, `Grep`, `KillShell`, `LS`, `LSP`, `MultiEdit`, `NotebookEdit`, `NotebookRead`, `Read`, `Skill`, `Task`, `TaskCreate`, `TaskGet`, `TaskList`, `TaskOutput`, `TaskStop`, `TaskUpdate`, `TodoWrite`, `ToolSearch`, `WebFetch`, `WebSearch`, `Write`, `mcp__*`

## エラーハンドリング

| エラー | 対応 |
|--------|------|
| Schema フェッチ失敗 | 公式ドキュメントのみで表示 |
| 公式ドキュメントフェッチ失敗 | Schema のみで表示（環境変数は非表示） |
| 全ソース失敗 | スキル内のカテゴリ定義をフォールバックとして使用 |
| settings.json が存在しない | 「現在値」欄を全て「-」で表示 |
| ソース間で矛盾する情報 | 公式ドキュメント > Schema の優先度で採用 |
| 未知のプロパティ発見 | 「新着」カテゴリに自動分類 |

## 注意事項

- Schema は SchemaStore コミュニティ管理。公式リリースから遅れる場合がある
- 公式ドキュメントの URL はリダイレクトされることがある（`docs.anthropic.com` → `code.claude.com`）
- 管理者向け設定（managed settings）は組織の IT 管理者が使うもの。個人ユーザーは基本的に触らない
- settings.json と settings.local.json は別物。local は `.gitignore` 向け
- プロジェクト settings.json はグローバルを上書き（マージではなくオーバーライド）
- 環境変数はシェル環境でも settings.json の `env` 内でも設定可能
