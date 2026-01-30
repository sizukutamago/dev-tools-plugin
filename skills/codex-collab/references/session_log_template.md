# セッションログテンプレート

ペアプログラミングセッションの記録用テンプレート。

## 使用方法

1. セッション開始時にファイル作成
2. 各フェーズ完了時に記録を追加
3. セッション終了時にサマリーを追加

## テンプレート

```markdown
# Codex Collaboration Session: {{SESSION_ID}}

## Metadata
| Key | Value |
|-----|-------|
| Date | {{DATE}} |
| Project | {{PROJECT_NAME}} |
| Feature | {{FEATURE_NAME}} |
| Duration | {{DURATION}} |
| Status | {{STATUS: In Progress / Completed / Paused}} |

---

## Phase 1: Requirements Analysis

### User Request
```
{{USER_REQUEST_VERBATIM}}
```

### Claude's Initial Analysis
{{INITIAL_ANALYSIS}}

### Codex Consultation
#### Prompt Sent
```
{{REQUIREMENTS_CONSULTATION_PROMPT}}
```

#### Codex Response
```
{{CODEX_REQUIREMENTS_RESPONSE}}
```

### Clarifications from User
| Question | Answer |
|----------|--------|
| {{QUESTION_1}} | {{ANSWER_1}} |
| {{QUESTION_2}} | {{ANSWER_2}} |

### Final Requirements
{{FINAL_REQUIREMENTS}}

---

## Phase 2: Design & Approach

### Initial Design Proposal
{{INITIAL_DESIGN}}

### Codex Consultation
#### Prompt Sent
```
{{DESIGN_CONSULTATION_PROMPT}}
```

#### Codex Response
```
{{CODEX_DESIGN_RESPONSE}}
```

### Design Decisions
| Aspect | Decision | Rationale | Codex Influence |
|--------|----------|-----------|-----------------|
| {{ASPECT_1}} | {{DECISION_1}} | {{RATIONALE_1}} | {{INFLUENCE_1}} |
| {{ASPECT_2}} | {{DECISION_2}} | {{RATIONALE_2}} | {{INFLUENCE_2}} |

### Final Approved Design
{{FINAL_DESIGN}}

---

## Phase 3: Implementation

### Implementation Plan
1. {{STEP_1}}
2. {{STEP_2}}
3. {{STEP_3}}

### Progress Log
| Time | Action | Files | Notes |
|------|--------|-------|-------|
| {{TIME_1}} | {{ACTION_1}} | {{FILES_1}} | {{NOTES_1}} |
| {{TIME_2}} | {{ACTION_2}} | {{FILES_2}} | {{NOTES_2}} |

### Codex Consultations (if any)
#### Consultation {{N}}
**Question**: {{IMPLEMENTATION_QUESTION}}

**Prompt Sent**:
```
{{IMPLEMENTATION_CONSULTATION_PROMPT}}
```

**Codex Response**:
```
{{CODEX_IMPLEMENTATION_RESPONSE}}
```

**Action Taken**: {{ACTION_TAKEN}}

### Commits Made
| Hash | Message | Files |
|------|---------|-------|
| {{HASH_1}} | {{MESSAGE_1}} | {{FILES_1}} |
| {{HASH_2}} | {{MESSAGE_2}} | {{FILES_2}} |

---

## Phase 4-5: Review Cycles

### Review Cycle {{N}}

#### Review Request
**Date**: {{REVIEW_DATE}}
**Files Changed**: {{FILES_COUNT}}

#### Prompt Sent
```
{{REVIEW_PROMPT}}
```

#### Codex Review
```
{{CODEX_REVIEW_RESPONSE}}
```

#### Issues Summary
| Severity | Count | Addressed |
|----------|-------|-----------|
| Critical | {{CRITICAL_COUNT}} | {{CRITICAL_ADDRESSED}} |
| Important | {{IMPORTANT_COUNT}} | {{IMPORTANT_ADDRESSED}} |
| Minor | {{MINOR_COUNT}} | {{MINOR_ADDRESSED}} |

#### Issues Detail
| # | Severity | Issue | Status | Resolution |
|---|----------|-------|--------|------------|
| 1 | {{SEVERITY}} | {{ISSUE}} | {{STATUS}} | {{RESOLUTION}} |

#### Modifications Made
{{MODIFICATIONS_DESCRIPTION}}

#### User Decision
- [ ] Request another review
- [x] Accept and complete

---

## Summary

### Final Status
**Outcome**: {{OUTCOME: Success / Partial / Failed}}
**Completion**: {{COMPLETION_PERCENTAGE}}%

### Statistics
| Metric | Value |
|--------|-------|
| Total Codex Consultations | {{CONSULTATION_COUNT}} |
| Review Cycles | {{REVIEW_CYCLE_COUNT}} |
| Issues Found | {{TOTAL_ISSUES}} |
| Issues Resolved | {{RESOLVED_ISSUES}} |
| Files Created | {{FILES_CREATED}} |
| Files Modified | {{FILES_MODIFIED}} |
| Lines Added | {{LINES_ADDED}} |
| Lines Removed | {{LINES_REMOVED}} |

### Key Decisions Made
| Decision | Rationale | Codex Input |
|----------|-----------|-------------|
| {{DECISION_1}} | {{RATIONALE_1}} | {{INPUT_1}} |
| {{DECISION_2}} | {{RATIONALE_2}} | {{INPUT_2}} |

### Codex Contribution Summary
{{CODEX_CONTRIBUTION_NARRATIVE}}

### Lessons Learned
- {{LESSON_1}}
- {{LESSON_2}}

### Future Considerations
- {{FUTURE_1}}
- {{FUTURE_2}}

---

## Appendix

### Full Diff
```diff
{{FULL_GIT_DIFF}}
```

### Test Results
```
{{FINAL_TEST_RESULTS}}
```

### Raw Codex Responses
<details>
<summary>Click to expand all Codex responses</summary>

#### Response 1: Requirements
```
{{RAW_RESPONSE_1}}
```

#### Response 2: Design
```
{{RAW_RESPONSE_2}}
```

#### Response N: Review
```
{{RAW_RESPONSE_N}}
```

</details>
```

## ファイル命名規則

```
.codex-collab/logs/YYYY-MM-DD-{feature-name}-session.md
```

例:
- `2026-01-31-user-auth-session.md`
- `2026-01-31-api-refactor-session.md`
- `2026-02-01-bugfix-login-session.md`

## 自動記録項目

以下は Claude Code が自動的に記録すべき項目:

| 項目 | タイミング | 取得方法 |
|------|----------|----------|
| SESSION_ID | セッション開始時 | tmux セッション名 |
| DATE | セッション開始時 | `date +%Y-%m-%d` |
| DURATION | セッション終了時 | 開始時刻との差分 |
| GIT_DIFF | 各コミット時 | `git diff` |
| CONSULTATION_PROMPT | Codex 送信時 | プロンプトファイル内容 |
| CODEX_RESPONSE | Codex 受信時 | 出力ファイル内容 |
| COMMIT_INFO | コミット時 | `git log` |
