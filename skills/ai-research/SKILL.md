---
name: ai-research
description: Research with Gemini CLI via tmux for web search, official docs/RFC/changelog lookup, compatibility checks, comparisons, or citations. Use when tasks require investigation with sourced information.
version: 1.1.0
---

# ai-research

Claude Code と Gemini が tmux でチャットするスキル。

## 前提条件（実行前に確認）

- **tmux セッション内**で実行すること（`tmux` コマンドが動作する環境）
- `gemini` CLI がインストール済み
- Gemini 認証済み（Google AI API キー設定済み）

## 役割分担（重要）

| AI | 役割 | 担当タスク |
|----|------|------------|
| **Claude Code** | 実装担当 | コード作成・編集・ファイル操作・テスト実行 |
| **Gemini** | 調査役 | Web検索・ドキュメント調査・出典付き情報収集 |
| **Codex** | 設計相談 | RESEARCH MEMO を受けて設計・レビュー（ハンドオフ先） |

**Gemini に実装を依頼しないこと。** Gemini から調査結果を受けて、Claude Code が実装する。

## セットアップ

### Gemini ペイン作成

現在のウィンドウを水平分割し、右側ペインで Gemini を起動:

```bash
# 3つの Bash コマンドを順番に実行（send-keys は && で連結しないこと）
tmux split-window -h
tmux send-keys "gemini"
tmux send-keys Enter
```

- `split-window -h`: 水平分割（左右に分かれる）
- 新しいペインがアクティブになるが、Claude Code は元のペインで継続
- **重要**: `tmux send-keys` は `&&` で連結せず、別々の Bash コマンドとして実行すること
  - `sleep && tmux capture-pane` のような組み合わせは OK

### ペイン番号の確認

```bash
tmux list-panes -F "#{pane_index}: #{pane_current_command}"
```

通常、Claude Code が pane 0 または 1、Gemini が pane 1 または 2 になる。

**重要**: 以降のコマンド例では `:.1` を使用しているが、**実際のペイン番号に置き換えること**。`list-panes` の結果で Gemini が動作しているペイン番号を確認し、`:.1` → `:.2` などに適宜変更する。

## チャット

### Gemini に質問

```bash
# 2つの Bash コマンドを順番に実行（&& で連結しないこと）
tmux send-keys -t :.1 "質問内容"
tmux send-keys -t :.1 Enter
```

- `-t :.1`: 現在のウィンドウのペイン 1 を指定
- **重要**: テキスト送信と Enter 送信は別々の Bash コマンドとして実行
- `&&` で連結すると Enter が送信されないことがある

### Gemini の返信を確認（待機付き）

```bash
sleep 45 && tmux capture-pane -t :.1 -p -S -100
```

- `-S -100`: スクロールバッファから過去100行を取得
- 応答が長い場合は `sleep` の秒数を増やす（最大待機時間は下表参照）
- 「Thinking」や検索中の表示がある場合は追加で待機する

### Gemini ペイン終了

```bash
tmux kill-pane -t :.1
```

## ワークフロー

1. `/ai-research` でペイン作成・Gemini 起動
2. Gemini に**調査・質問**を送信
3. 返信を確認（sleep で待機）
4. Gemini の調査結果を **RESEARCH MEMO** としてまとめる
5. 必要に応じて `codex-collab` にハンドオフ
6. ペイン終了

## 使用例

### 調査 → RESEARCH MEMO 作成

```
User: "React Server Components について調査して"

Claude:
1. Gemini ペイン作成（3つの Bash コマンドを順番に実行）
   Bash(tmux split-window -h)
   Bash(tmux send-keys "gemini")
   Bash(tmux send-keys Enter)
   Bash(sleep 5)  # Gemini 起動待ち

2. Gemini に調査依頼（2つの Bash コマンドを順番に実行）
   Bash(tmux send-keys -t :.1 "React Server Components のキャッシュ戦略について、公式ドキュメントを参照して要点をまとめて。出典URLも付けて")
   Bash(tmux send-keys -t :.1 Enter)

3. 返信を確認（待機後にキャプチャ）
   Bash(sleep 60)
   Bash(tmux capture-pane -t :.1 -p -S -100)

4. RESEARCH MEMO としてまとめる（Claude Code が作成）

5. 終了（ペインのみ閉じる）
   Bash(tmux kill-pane -t :.1)
```

### Gemini への適切な質問例

- 「〇〇について公式ドキュメントを調べて」
- 「AとBの違いを比較して、出典付きで」
- 「〇〇の最新バージョンの変更点は？」
- 「〇〇のセキュリティベストプラクティスを調査して」
- 「〇〇のRFCや仕様を確認して」

### 不適切な依頼例（避けること）

- ❌「このコードを実装して」
- ❌「ファイルを作成して」
- ❌「テストを書いて」

## 成果物: RESEARCH MEMO

Gemini の調査結果は以下のフォーマットでまとめる:

```markdown
# RESEARCH MEMO: <テーマ>

- Date: YYYY-MM-DD
- Researcher: Gemini CLI
- Goal: <調査目的>

## TL;DR
- <結論1>
- <結論2>
- <結論3>

## Findings
### 1) <要点>
- <主張/観察>
- Evidence: <根拠>
- Confidence: High | Medium | Low

## Trade-offs / Risks
- <注意点>

## Recommended Action
- <推奨方針>

## Open Questions
- <未解決点>

## Sources
- <Title> — <URL> (accessed: YYYY-MM-DD)
```

詳細テンプレートは `references/memo_template.md` を参照。

## 待機時間の目安

| 調査の種類 | 推奨待機時間 | 最大待機時間 | 備考 |
|-----------|-------------|-------------|------|
| 単純な確認 | 30秒 | 60秒 | バージョン確認、簡単な検索 |
| ドキュメント調査 | 45秒 | 90秒 | 公式ドキュメント参照 |
| 比較調査 | 60秒 | 120秒 | 複数ライブラリ比較 |
| 詳細リサーチ | 90秒 | 180秒 | RFC、changelog、互換性調査 |

※ Gemini は Web 検索を行うため、Codex より長めに設定

**ポーリング戦略**:
1. 初回待機（上記の推奨待機時間）
2. `tmux capture-pane` で出力確認
3. 以下の場合は追加30秒待機（最大待機時間に達するまで繰り返し）:
   - 「Thinking」や検索中の表示
   - 出力が途中で終わっている
   - プロンプト（`>`）に戻っていない
4. 最大待機時間を超えたらタイムアウトとして処理

## エラーハンドリング

| 状況 | 症状 | 対応 |
|------|------|------|
| タイムアウト | capture出力が空/変化なし | 追加30-60秒待機、または Enter で再プロンプト |
| Gemini 未応答 | プロンプトが表示されたまま | Enter で再送信 |
| ペイン消失 | `can't find pane` エラー | セットアップを再実行 |
| 接続エラー | API エラーメッセージ | `gemini` を再起動（ペイン終了→再作成） |

### リカバリー手順

```bash
# ペインが消失した場合
tmux split-window -h
tmux send-keys "gemini"
tmux send-keys Enter
sleep 5

# Gemini が固まった場合
tmux send-keys -t :.1 C-c  # Ctrl+C で中断
sleep 2
tmux send-keys -t :.1 Enter  # 新しいプロンプト待ち
```

