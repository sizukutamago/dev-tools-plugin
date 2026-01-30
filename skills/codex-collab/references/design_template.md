# 設計相談テンプレート

Phase 2: 設計・アプローチで使用するテンプレート。

## 使用方法

1. プレースホルダー `{{...}}` を実際の内容に置換
2. Codex に送信
3. RESPONSE:DESIGN を受信
4. 設計を調整してユーザーに最終承認を求める

## テンプレート

```
[CONSULT:DESIGN]

## Context
Project: {{PROJECT_NAME}}
Phase: Design Review
Previous Phase: Requirements confirmed

## Requirements Summary
### Functional Requirements
{{FUNCTIONAL_REQUIREMENTS_SUMMARY}}

### Non-Functional Requirements
{{NON_FUNCTIONAL_REQUIREMENTS_SUMMARY}}

### Constraints
{{CONSTRAINTS_SUMMARY}}

## Proposed Design

### Architecture
Pattern: {{ARCHITECTURE_PATTERN}} (e.g., Clean Architecture, MVC, Microservices)
```
{{ARCHITECTURE_DIAGRAM_ASCII}}
```

### Technology Stack
| Layer | Technology | Rationale |
|-------|------------|-----------|
| {{LAYER_1}} | {{TECH_1}} | {{RATIONALE_1}} |
| {{LAYER_2}} | {{TECH_2}} | {{RATIONALE_2}} |

### Key Components
1. **{{COMPONENT_1}}**
   - Responsibility: {{RESPONSIBILITY_1}}
   - Interface: {{INTERFACE_1}}

2. **{{COMPONENT_2}}**
   - Responsibility: {{RESPONSIBILITY_2}}
   - Interface: {{INTERFACE_2}}

### Data Flow
```
{{DATA_FLOW_DIAGRAM}}
```

### Implementation Strategy
1. {{PHASE_1}}: {{PHASE_1_DESCRIPTION}}
2. {{PHASE_2}}: {{PHASE_2_DESCRIPTION}}
3. {{PHASE_3}}: {{PHASE_3_DESCRIPTION}}

### Error Handling Strategy
{{ERROR_HANDLING_APPROACH}}

### Security Considerations
{{SECURITY_MEASURES}}

## Questions for Review
1. Is this architecture appropriate for the requirements?
2. What risks or challenges do you foresee?
3. Are there better alternatives to consider?
4. What should be prioritized in implementation?
5. Any concerns about scalability or maintainability?

Please respond with:
- ASSESSMENT: Overall evaluation of the design
- RISKS: Potential issues and challenges
- ALTERNATIVES: Other approaches to consider
- RECOMMENDATION: Final recommendation with rationale
```

## 応答期待フォーマット

```
[RESPONSE:DESIGN]

## ASSESSMENT
### Overall Evaluation
{{全体評価: Excellent/Good/Acceptable/Needs Work}}

### Strengths
- {{強み1}}
- {{強み2}}

### Concerns
- {{懸念点1}}
- {{懸念点2}}

## RISKS
### Technical Risks
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| {{リスク1}} | {{高/中/低}} | {{高/中/低}} | {{軽減策}} |

### Operational Risks
- {{運用リスク1}}

## ALTERNATIVES
### Alternative 1: {{代替案名}}
- **Description**: {{説明}}
- **Pros**: {{利点}}
- **Cons**: {{欠点}}
- **When to choose**: {{選択すべき状況}}

### Alternative 2: {{代替案名}}
- **Description**: {{説明}}
- **Pros**: {{利点}}
- **Cons**: {{欠点}}
- **When to choose**: {{選択すべき状況}}

## RECOMMENDATION
### Final Recommendation
{{最終推奨事項}}

### Rationale
{{理由}}

### Suggested Modifications
1. {{修正提案1}}
2. {{修正提案2}}

### Priority Order
1. {{優先事項1}}
2. {{優先事項2}}
3. {{優先事項3}}
```

## 使用例

### 入力例

```
[CONSULT:DESIGN]

## Context
Project: user-management-api
Phase: Design Review
Previous Phase: Requirements confirmed

## Requirements Summary
### Functional Requirements
- User login with email/password
- JWT access token (15min expiry)
- Refresh token (7 days expiry)
- Token rotation on refresh
- Rate limiting on login attempts

### Non-Functional Requirements
- Response time: <200ms for auth endpoints
- Support 1000+ concurrent users
- Secure token storage
- Audit logging for auth events

### Constraints
- PostgreSQL database (existing)
- Express.js framework (company standard)
- Redis available for caching

## Proposed Design

### Architecture
Pattern: Clean Architecture with Repository Pattern
```
┌──────────────────────────────────────┐
│           Controllers                 │
│  (AuthController, TokenController)   │
└──────────────┬───────────────────────┘
               │
┌──────────────▼───────────────────────┐
│            Use Cases                  │
│  (LoginUseCase, RefreshTokenUseCase) │
└──────────────┬───────────────────────┘
               │
┌──────────────▼───────────────────────┐
│           Repositories               │
│  (UserRepository, TokenRepository)   │
└──────────────┬───────────────────────┘
               │
┌──────────────▼───────────────────────┐
│        Data Sources                   │
│   (PostgreSQL, Redis)                │
└──────────────────────────────────────┘
```

### Technology Stack
| Layer | Technology | Rationale |
|-------|------------|-----------|
| Auth Library | passport-jwt | Mature, well-documented |
| Token Storage | Redis | Fast access, TTL support |
| Password Hash | bcrypt | Industry standard |
| Validation | zod | TypeScript integration |

### Implementation Strategy
1. Phase 1: Core auth (login/logout)
2. Phase 2: Refresh token rotation
3. Phase 3: Rate limiting
4. Phase 4: Audit logging

Please respond with:
- ASSESSMENT: Overall evaluation of the design
- RISKS: Potential issues and challenges
- ALTERNATIVES: Other approaches to consider
- RECOMMENDATION: Final recommendation with rationale
```
