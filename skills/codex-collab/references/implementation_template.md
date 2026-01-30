# 実装相談テンプレート

Phase 3: 実装中の技術相談で使用するテンプレート。

## 使用方法

1. 実装中に疑問や判断が必要な場面で使用
2. プレースホルダー `{{...}}` を実際の内容に置換
3. Codex に送信
4. RESPONSE:IMPLEMENTATION を受信して実装に反映

## テンプレート

```
[CONSULT:IMPLEMENTATION]

## Context
Project: {{PROJECT_NAME}}
Current Task: {{CURRENT_TASK_DESCRIPTION}}
File: {{FILE_PATH}}
Phase: Implementation

## Design Context
Architecture: {{ARCHITECTURE_PATTERN}}
Related Components: {{RELATED_COMPONENTS}}

## Question
{{SPECIFIC_QUESTION}}

## Current Implementation (if applicable)
```{{LANGUAGE}}
{{CURRENT_CODE_SNIPPET}}
```

## Options I'm Considering
1. **Option A**: {{OPTION_A_DESCRIPTION}}
   - Pros: {{OPTION_A_PROS}}
   - Cons: {{OPTION_A_CONS}}

2. **Option B**: {{OPTION_B_DESCRIPTION}}
   - Pros: {{OPTION_B_PROS}}
   - Cons: {{OPTION_B_CONS}}

## Constraints
- {{CONSTRAINT_1}}
- {{CONSTRAINT_2}}

Please respond with:
- ADVICE: Direct answer to the question
- PATTERNS: Recommended patterns or approaches
- CAVEATS: Things to watch out for
```

## 応答期待フォーマット

```
[RESPONSE:IMPLEMENTATION]

## ADVICE
### Direct Answer
{{質問への直接的な回答}}

### Rationale
{{理由の説明}}

## PATTERNS
### Recommended Pattern
```{{LANGUAGE}}
{{推奨パターンのコード例}}
```

### Why This Pattern
{{このパターンを推奨する理由}}

### Integration Example
```{{LANGUAGE}}
{{実際の統合例}}
```

## CAVEATS
### Must Consider
- {{必ず考慮すべき点1}}
- {{必ず考慮すべき点2}}

### Edge Cases
- {{エッジケース1}}
- {{エッジケース2}}

### Common Mistakes
- {{よくあるミス1}}
- {{よくあるミス2}}

### Testing Considerations
- {{テスト観点1}}
- {{テスト観点2}}
```

## 使用例

### 入力例1: パターン選択

```
[CONSULT:IMPLEMENTATION]

## Context
Project: user-management-api
Current Task: Implementing refresh token rotation
File: src/services/TokenService.ts
Phase: Implementation

## Design Context
Architecture: Clean Architecture
Related Components: TokenRepository, RedisClient

## Question
リフレッシュトークンローテーション時の競合状態（同時リクエスト）をどう処理すべきか？

## Current Implementation
```typescript
async rotateRefreshToken(oldToken: string): Promise<TokenPair> {
  const tokenData = await this.tokenRepository.findByToken(oldToken);
  if (!tokenData) {
    throw new InvalidTokenError('Refresh token not found');
  }

  // トークン無効化
  await this.tokenRepository.invalidate(oldToken);

  // 新しいトークンペア生成
  const newTokens = await this.generateTokenPair(tokenData.userId);

  return newTokens;
}
```

## Options I'm Considering
1. **Option A**: Optimistic locking with version field
   - Pros: Simple implementation
   - Cons: May cause errors for legitimate concurrent requests

2. **Option B**: Redis distributed lock
   - Pros: Reliable concurrency control
   - Cons: Added complexity, potential deadlock

## Constraints
- Redis available
- Must not block for more than 1 second
- Should handle legitimate concurrent requests gracefully

Please respond with:
- ADVICE: Direct answer to the question
- PATTERNS: Recommended patterns or approaches
- CAVEATS: Things to watch out for
```

### 入力例2: エラーハンドリング

```
[CONSULT:IMPLEMENTATION]

## Context
Project: user-management-api
Current Task: Error handling strategy
File: src/middleware/errorHandler.ts
Phase: Implementation

## Design Context
Architecture: Clean Architecture
Related Components: All controllers

## Question
どのレベルでエラーをキャッチして、どのようなレスポンス形式にすべきか？

## Current Implementation
```typescript
// 現在は各コントローラーで try-catch している
try {
  const result = await useCase.execute(input);
  res.json(result);
} catch (error) {
  res.status(500).json({ error: 'Internal server error' });
}
```

## Options I'm Considering
1. **Option A**: Global error handler middleware
   - Pros: DRY, consistent error format
   - Cons: Less control per endpoint

2. **Option B**: Domain-specific error classes + global handler
   - Pros: Type-safe, semantic errors
   - Cons: More boilerplate

## Constraints
- Must return consistent JSON format
- Must not leak sensitive information
- Must support i18n in the future

Please respond with:
- ADVICE: Direct answer to the question
- PATTERNS: Recommended patterns or approaches
- CAVEATS: Things to watch out for
```
