# 要件分析相談テンプレート

Phase 1: 要件分析で使用するテンプレート。

## 使用方法

1. プレースホルダー `{{...}}` を実際の内容に置換
2. Codex に送信
3. RESPONSE:REQUIREMENTS を受信
4. CLARIFICATION_QUESTIONS をユーザーに確認

## テンプレート

```
[CONSULT:REQUIREMENTS]

## Context
Project: {{PROJECT_NAME}}
Type: {{PROJECT_TYPE}} (e.g., Web App, CLI Tool, Library, API)
Language/Framework: {{LANGUAGE_FRAMEWORK}}
Existing Codebase: {{EXISTING_CODEBASE_DESCRIPTION}}

## User Request
{{USER_REQUEST_VERBATIM}}

## Current Understanding
### Functional Requirements
{{FUNCTIONAL_REQUIREMENTS_LIST}}

### Non-Functional Requirements (Initial)
- Performance: {{PERFORMANCE_EXPECTATIONS}}
- Security: {{SECURITY_REQUIREMENTS}}
- Scalability: {{SCALABILITY_NEEDS}}

### Constraints
{{KNOWN_CONSTRAINTS}}

### Assumptions
{{ASSUMPTIONS_MADE}}

## Questions for Clarification
1. この要件で不明確な点はありますか？
2. 考慮すべき非機能要件は何ですか？
3. スコープの適切性をどう評価しますか？
4. 潜在的なリスクや課題はありますか？

Please respond with:
- CLARIFICATION_QUESTIONS: List of questions to ask the user (prioritized)
- CONSIDERATIONS: Non-functional requirements, edge cases, constraints to consider
```

## 応答期待フォーマット

```
[RESPONSE:REQUIREMENTS]

## CLARIFICATION_QUESTIONS
### High Priority
1. {{重要な質問1}}
2. {{重要な質問2}}

### Medium Priority
3. {{中程度の質問}}

### Nice to Have
4. {{あれば良い質問}}

## CONSIDERATIONS
### Non-Functional Requirements
- Performance: {{パフォーマンス考慮点}}
- Security: {{セキュリティ考慮点}}
- Scalability: {{スケーラビリティ考慮点}}
- Maintainability: {{保守性考慮点}}

### Edge Cases
- {{エッジケース1}}
- {{エッジケース2}}

### Constraints
- {{追加の制約1}}
- {{追加の制約2}}

### Risks
- {{リスク1}}
- {{リスク2}}
```

## 使用例

### 入力例

```
[CONSULT:REQUIREMENTS]

## Context
Project: user-management-api
Type: REST API
Language/Framework: TypeScript + Express
Existing Codebase: New project, using internal company boilerplate

## User Request
"ユーザー認証機能を実装したい。JWTを使って、リフレッシュトークンも対応してほしい。"

## Current Understanding
### Functional Requirements
- User login with email/password
- JWT token generation
- Refresh token support
- Token validation middleware

### Non-Functional Requirements (Initial)
- Performance: Standard API response times (<200ms)
- Security: Secure token storage, HTTPS only
- Scalability: Support for 1000+ concurrent users

### Constraints
- Must work with existing PostgreSQL database
- Must follow company coding standards

### Assumptions
- Email-based authentication only (no social login)
- Single tenant application

## Questions for Clarification
1. この要件で不明確な点はありますか？
2. 考慮すべき非機能要件は何ですか？
3. スコープの適切性をどう評価しますか？
4. 潜在的なリスクや課題はありますか？

Please respond with:
- CLARIFICATION_QUESTIONS: List of questions to ask the user (prioritized)
- CONSIDERATIONS: Non-functional requirements, edge cases, constraints to consider
```
