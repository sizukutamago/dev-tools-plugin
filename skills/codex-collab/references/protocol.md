# 通信プロトコル定義

Claude Code と Codex 間の双方向通信プロトコル。

## プロトコル概要

```
┌─────────────┐                              ┌─────────────┐
│ Claude Code │                              │    Codex    │
│ (主導)      │                              │ (相談役)    │
└──────┬──────┘                              └──────┬──────┘
       │                                            │
       │  ──────[CONSULT:REQUIREMENTS]──────▶      │
       │        要件分析の相談                      │
       │  ◀─────[RESPONSE:REQUIREMENTS]─────       │
       │        明確化質問・考慮点                  │
       │                                            │
       │  ──────[CONSULT:DESIGN]────────────▶      │
       │        設計案の相談                        │
       │  ◀─────[RESPONSE:DESIGN]───────────       │
       │        ASSESSMENT/RISKS/RECOMMENDATION    │
       │                                            │
       │  ──────[CONSULT:IMPLEMENTATION]───▶       │
       │        実装中の技術相談                    │
       │  ◀─────[RESPONSE:IMPLEMENTATION]──        │
       │        技術的アドバイス                    │
       │                                            │
       │  ──────[REQUEST:REVIEW]───────────▶       │
       │        コードレビュー依頼                  │
       │  ◀─────[RESPONSE:REVIEW]──────────        │
       │        STRENGTHS/ISSUES/SUGGESTIONS       │
       │                                            │
       ▼                                            ▼
```

## メッセージフォーマット

### 1. 要件相談 (CONSULT:REQUIREMENTS)

**Claude → Codex:**
```
[CONSULT:REQUIREMENTS]

## Context
{{プロジェクトコンテキスト}}

## User Request
{{ユーザーの要求内容}}

## Current Understanding
{{現在の理解}}

## Questions
1. この要件で不明確な点はありますか？
2. 考慮すべき非機能要件は何ですか？
3. スコープの適切性をどう評価しますか？

Please respond with:
- CLARIFICATION_QUESTIONS: List of questions to ask the user
- CONSIDERATIONS: Non-functional requirements, edge cases, constraints to consider
```

**Codex → Claude:**
```
[RESPONSE:REQUIREMENTS]

## CLARIFICATION_QUESTIONS
1. {{質問1}}
2. {{質問2}}
...

## CONSIDERATIONS
- {{考慮点1}}
- {{考慮点2}}
...
```

### 2. 設計相談 (CONSULT:DESIGN)

**Claude → Codex:**
```
[CONSULT:DESIGN]

## Context
{{プロジェクトコンテキスト}}

## Requirements Summary
{{要件サマリー}}

## Proposed Design
### Architecture
{{アーキテクチャ}}

### Technology Stack
{{技術スタック}}

### Implementation Strategy
{{実装戦略}}

## Questions for Review
1. Is this architecture appropriate for the requirements?
2. What risks or challenges do you foresee?
3. Are there better alternatives?
4. What should be prioritized?

Please respond with:
- ASSESSMENT: Overall evaluation of the design
- RISKS: Potential issues and challenges
- ALTERNATIVES: Other approaches to consider
- RECOMMENDATION: Final recommendation with rationale
```

**Codex → Claude:**
```
[RESPONSE:DESIGN]

## ASSESSMENT
{{設計の妥当性評価}}

## RISKS
- {{リスク1}}
- {{リスク2}}
...

## ALTERNATIVES
- {{代替案1}}
- {{代替案2}}
...

## RECOMMENDATION
{{推奨事項と理由}}
```

### 3. 実装相談 (CONSULT:IMPLEMENTATION)

**Claude → Codex:**
```
[CONSULT:IMPLEMENTATION]

## Context
{{コンテキスト}}

## Current Task
{{現在のタスク}}

## Question
{{質問内容}}

## Code Snippet (if applicable)
```{{言語}}
{{コードスニペット}}
```

Please respond with:
- ADVICE: Direct answer to the question
- PATTERNS: Recommended patterns or approaches
- CAVEATS: Things to watch out for
```

**Codex → Claude:**
```
[RESPONSE:IMPLEMENTATION]

## ADVICE
{{質問への直接的な回答}}

## PATTERNS
```{{言語}}
{{推奨パターンのコード例}}
```

## CAVEATS
- {{注意点1}}
- {{注意点2}}
...
```

### 4. コードレビュー依頼 (REQUEST:REVIEW)

**Claude → Codex:**
```
[REQUEST:REVIEW]

## Files Changed
{{git diff の内容}}

## Implementation Summary
{{実装サマリー}}

## Review Focus Areas
- Code quality and readability
- Error handling and edge cases
- Security considerations
- Performance implications
- Test coverage

## Specific Concerns (if any)
{{特に見てほしい点}}

## Issue Severity Guide
- Critical: Must fix before merge (bugs, security issues)
- Important: Should fix (code quality, maintainability)
- Minor: Nice to have (style, minor improvements)

Please respond with:
- STRENGTHS: What's done well
- ISSUES: Problems found (with severity)
- SUGGESTIONS: Improvement recommendations
```

**Codex → Claude:**
```
[RESPONSE:REVIEW]

## STRENGTHS
- {{良い点1}}
- {{良い点2}}
...

## ISSUES
### Critical
- {{クリティカルな問題}}

### Important
- {{重要な問題}}

### Minor
- {{軽微な問題}}

## SUGGESTIONS
- {{改善提案1}}
- {{改善提案2}}
...
```

### 5. 双方向通信: Codex → Claude

**Codex → Claude (実装確認):**
```
[CONSULT:CLAUDE:VERIFICATION]

## Current State
{{現在の状態}}

## Verification Needed
1. {{確認したい点1}}
2. {{確認したい点2}}
```

**Codex → Claude (コンテキスト要求):**
```
[CONSULT:CLAUDE:CONTEXT]

## Additional Context Needed
{{必要な追加コンテキスト}}

## Purpose
{{なぜ必要か}}
```

## 応答の原則

1. **具体的**: 抽象的な助言ではなく、具体的なコード例や手順を示す
2. **批判的**: 問題点は明確に指摘する（遠慮しない）
3. **建設的**: 問題点には代替案や改善提案を添える
4. **簡潔**: 冗長な説明は避け、要点を絞る
5. **構造化**: マーカーを使用して応答を整理する

## エラーハンドリング

| 状況 | 対応 |
|------|------|
| マーカー不在 | 再度構造化出力を依頼 |
| 不完全な応答 | 該当セクションのみ再要求 |
| タイムアウト | 短いプロンプトで再試行 |
| 無関係な応答 | コンテキスト再提供 |
