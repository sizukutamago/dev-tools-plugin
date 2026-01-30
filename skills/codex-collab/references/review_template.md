# コードレビューテンプレート

Phase 4: コードレビュー依頼で使用するテンプレート。

## 使用方法

1. 実装完了後、git diff を取得
2. プレースホルダー `{{...}}` を実際の内容に置換
3. Codex に送信
4. RESPONSE:REVIEW を受信
5. Critical/Important issues を修正

## テンプレート

```
[REQUEST:REVIEW]

## Metadata
Project: {{PROJECT_NAME}}
Feature: {{FEATURE_NAME}}
Author: Claude Code
Reviewer: Codex
Date: {{DATE}}

## Files Changed
```diff
{{GIT_DIFF_OUTPUT}}
```

## Implementation Summary
### What was implemented
{{IMPLEMENTATION_DESCRIPTION}}

### Key Decisions Made
1. {{DECISION_1}}: {{RATIONALE_1}}
2. {{DECISION_2}}: {{RATIONALE_2}}

### Changes by Category
| Category | Files | Description |
|----------|-------|-------------|
| New | {{NEW_FILES}} | {{NEW_DESCRIPTION}} |
| Modified | {{MODIFIED_FILES}} | {{MODIFIED_DESCRIPTION}} |
| Deleted | {{DELETED_FILES}} | {{DELETED_DESCRIPTION}} |

## Review Focus Areas
- [ ] Code quality and readability
- [ ] Error handling and edge cases
- [ ] Security considerations
- [ ] Performance implications
- [ ] Test coverage
- [ ] Documentation completeness

## Specific Concerns (if any)
{{SPECIFIC_CONCERNS_OR_NONE}}

## Test Results
```
{{TEST_OUTPUT}}
```

## Issue Severity Guide
- **Critical**: Must fix before merge (bugs, security issues, data loss risks)
- **Important**: Should fix (code quality, maintainability, performance)
- **Minor**: Nice to have (style, minor improvements, suggestions)

Please respond with:
- STRENGTHS: What's done well
- ISSUES: Problems found (with severity)
- SUGGESTIONS: Improvement recommendations
```

## 応答期待フォーマット

```
[RESPONSE:REVIEW]

## REVIEW SUMMARY
| Aspect | Rating | Notes |
|--------|--------|-------|
| Code Quality | {{A-F}} | {{コメント}} |
| Security | {{A-F}} | {{コメント}} |
| Performance | {{A-F}} | {{コメント}} |
| Maintainability | {{A-F}} | {{コメント}} |
| Test Coverage | {{A-F}} | {{コメント}} |

**Overall**: {{APPROVE/REQUEST_CHANGES/NEEDS_DISCUSSION}}

## STRENGTHS
### Architecture & Design
- {{アーキテクチャの強み}}

### Code Quality
- {{コード品質の良い点}}

### Security
- {{セキュリティ面で良い点}}

### Other
- {{その他の良い点}}

## ISSUES

### Critical (Must Fix)
| # | Location | Issue | Recommendation |
|---|----------|-------|----------------|
| 1 | {{FILE:LINE}} | {{問題の説明}} | {{修正方法}} |

### Important (Should Fix)
| # | Location | Issue | Recommendation |
|---|----------|-------|----------------|
| 1 | {{FILE:LINE}} | {{問題の説明}} | {{修正方法}} |

### Minor (Nice to Have)
| # | Location | Issue | Recommendation |
|---|----------|-------|----------------|
| 1 | {{FILE:LINE}} | {{問題の説明}} | {{修正方法}} |

## SUGGESTIONS
### Code Improvements
```{{LANGUAGE}}
// Before
{{CURRENT_CODE}}

// After (suggested)
{{SUGGESTED_CODE}}
```

### Architecture Improvements
{{アーキテクチャ改善提案}}

### Testing Improvements
{{テスト改善提案}}

### Documentation
{{ドキュメント改善提案}}

## ACTION ITEMS
### Required Before Merge
1. [ ] {{必須アクション1}}
2. [ ] {{必須アクション2}}

### Recommended
1. [ ] {{推奨アクション1}}
2. [ ] {{推奨アクション2}}

### Future Considerations
1. {{将来の検討事項1}}
2. {{将来の検討事項2}}
```

## 使用例

### 入力例

```
[REQUEST:REVIEW]

## Metadata
Project: user-management-api
Feature: JWT Authentication
Author: Claude Code
Reviewer: Codex
Date: 2026-01-31

## Files Changed
```diff
diff --git a/src/middleware/auth.middleware.ts b/src/middleware/auth.middleware.ts
new file mode 100644
index 0000000..a1b2c3d
--- /dev/null
+++ b/src/middleware/auth.middleware.ts
@@ -0,0 +1,45 @@
+import { Request, Response, NextFunction } from 'express';
+import jwt from 'jsonwebtoken';
+import { UnauthorizedError } from '../errors/UnauthorizedError';
+
+export const authMiddleware = async (
+  req: Request,
+  res: Response,
+  next: NextFunction
+) => {
+  const authHeader = req.headers.authorization;
+
+  if (!authHeader || !authHeader.startsWith('Bearer ')) {
+    throw new UnauthorizedError('No token provided');
+  }
+
+  const token = authHeader.split(' ')[1];
+
+  try {
+    const decoded = jwt.verify(token, process.env.JWT_SECRET);
+    req.user = decoded;
+    next();
+  } catch (error) {
+    throw new UnauthorizedError('Invalid token');
+  }
+};
```

## Implementation Summary
### What was implemented
- JWT authentication middleware
- Token extraction from Authorization header
- Error handling for missing/invalid tokens

### Key Decisions Made
1. Bearer token format: Standard OAuth2 format for compatibility
2. Synchronous jwt.verify: Acceptable for HS256 algorithm

## Review Focus Areas
- [ ] Code quality and readability
- [ ] Error handling and edge cases
- [ ] Security considerations
- [ ] Performance implications
- [ ] Test coverage

## Specific Concerns
- JWT_SECRET from environment variable - is this secure enough?
- Should we add token expiration check?

## Test Results
```
PASS src/middleware/__tests__/auth.middleware.test.ts
  authMiddleware
    ✓ should authenticate valid token (15ms)
    ✓ should reject missing token (3ms)
    ✓ should reject invalid token (5ms)

Test Suites: 1 passed, 1 total
Tests:       3 passed, 3 total
```

Please respond with:
- STRENGTHS: What's done well
- ISSUES: Problems found (with severity)
- SUGGESTIONS: Improvement recommendations
```
