# 応答フォーマット定義

Codex が Claude Code に返す構造化応答のフォーマット詳細。

## フォーマット原則

1. **マーカー必須**: 各応答は必ず `[RESPONSE:...]` マーカーで開始
2. **セクション構造**: Markdown のヘッダー（##, ###）でセクションを区切る
3. **テーブル活用**: 比較や一覧はテーブル形式で見やすく
4. **コード例**: 可能な限り具体的なコード例を含める
5. **アクション指向**: 何をすべきかを明確に示す

## 1. RESPONSE:REQUIREMENTS

```markdown
[RESPONSE:REQUIREMENTS]

## CLARIFICATION_QUESTIONS

### High Priority
1. [最も重要な質問 - これがないと進められない]
2. [次に重要な質問]

### Medium Priority
3. [あると良い情報の質問]
4. [スコープ明確化の質問]

### Nice to Have
5. [将来的な拡張に関する質問]

## CONSIDERATIONS

### Non-Functional Requirements
| Category | Consideration | Priority |
|----------|---------------|----------|
| Performance | [パフォーマンス要件] | [High/Medium/Low] |
| Security | [セキュリティ要件] | [High/Medium/Low] |
| Scalability | [スケーラビリティ要件] | [High/Medium/Low] |
| Maintainability | [保守性要件] | [High/Medium/Low] |
| Accessibility | [アクセシビリティ要件] | [High/Medium/Low] |

### Edge Cases
- [エッジケース1]: [なぜ重要か]
- [エッジケース2]: [なぜ重要か]

### Constraints
- [制約1]: [影響]
- [制約2]: [影響]

### Risks
| Risk | Likelihood | Impact | Notes |
|------|------------|--------|-------|
| [リスク1] | [高/中/低] | [高/中/低] | [詳細] |
| [リスク2] | [高/中/低] | [高/中/低] | [詳細] |
```

## 2. RESPONSE:DESIGN

```markdown
[RESPONSE:DESIGN]

## ASSESSMENT

### Overall Evaluation
**Rating**: [Excellent/Good/Acceptable/Needs Work]

### Strengths
- ✅ [強み1]
- ✅ [強み2]
- ✅ [強み3]

### Concerns
- ⚠️ [懸念点1]
- ⚠️ [懸念点2]

### Fit for Requirements
| Requirement | Addressed | Notes |
|-------------|-----------|-------|
| [要件1] | ✅/⚠️/❌ | [コメント] |
| [要件2] | ✅/⚠️/❌ | [コメント] |

## RISKS

### Technical Risks
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| [技術リスク1] | [高/中/低] | [高/中/低] | [軽減策] |
| [技術リスク2] | [高/中/低] | [高/中/低] | [軽減策] |

### Operational Risks
| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| [運用リスク1] | [高/中/低] | [高/中/低] | [軽減策] |

### Business Risks
- [ビジネスリスク1]: [影響と軽減策]

## ALTERNATIVES

### Alternative 1: [名前]
| Aspect | Details |
|--------|---------|
| Description | [説明] |
| Pros | [利点1], [利点2] |
| Cons | [欠点1], [欠点2] |
| When to choose | [選択すべき状況] |
| Effort | [High/Medium/Low] |

### Alternative 2: [名前]
| Aspect | Details |
|--------|---------|
| Description | [説明] |
| Pros | [利点1], [利点2] |
| Cons | [欠点1], [欠点2] |
| When to choose | [選択すべき状況] |
| Effort | [High/Medium/Low] |

## RECOMMENDATION

### Final Recommendation
[推奨事項の明確な記述]

### Rationale
1. [理由1]
2. [理由2]
3. [理由3]

### Suggested Modifications
1. **[修正1]**: [詳細]
2. **[修正2]**: [詳細]

### Implementation Priority
1. [優先事項1] - [理由]
2. [優先事項2] - [理由]
3. [優先事項3] - [理由]
```

## 3. RESPONSE:IMPLEMENTATION

```markdown
[RESPONSE:IMPLEMENTATION]

## ADVICE

### Direct Answer
[質問への直接的で明確な回答]

### Rationale
[なぜこの回答が適切か]

### Context
[関連するコンテキストや背景情報]

## PATTERNS

### Recommended Pattern
```[language]
// [パターン名]
// [このパターンの説明]

[具体的なコード例]
```

### Why This Pattern
- [理由1]
- [理由2]

### Integration Example
```[language]
// 実際のコードにどう統合するか
[統合例のコード]
```

### Alternative Patterns (if applicable)
| Pattern | Use Case | Trade-offs |
|---------|----------|------------|
| [パターンA] | [ユースケース] | [トレードオフ] |
| [パターンB] | [ユースケース] | [トレードオフ] |

## CAVEATS

### Must Consider
- ⚠️ **[重要な注意点1]**: [詳細]
- ⚠️ **[重要な注意点2]**: [詳細]

### Edge Cases
| Case | Handling |
|------|----------|
| [エッジケース1] | [対処法] |
| [エッジケース2] | [対処法] |

### Common Mistakes
| Mistake | Why It's Wrong | Correct Approach |
|---------|----------------|------------------|
| [ミス1] | [理由] | [正しい方法] |
| [ミス2] | [理由] | [正しい方法] |

### Testing Considerations
- [テスト観点1]
- [テスト観点2]
```

## 4. RESPONSE:REVIEW

```markdown
[RESPONSE:REVIEW]

## REVIEW SUMMARY

| Aspect | Rating | Notes |
|--------|--------|-------|
| Code Quality | [A-F] | [コメント] |
| Security | [A-F] | [コメント] |
| Performance | [A-F] | [コメント] |
| Maintainability | [A-F] | [コメント] |
| Test Coverage | [A-F] | [コメント] |
| Documentation | [A-F] | [コメント] |

**Overall Verdict**: [✅ APPROVE / ⚠️ REQUEST_CHANGES / 💬 NEEDS_DISCUSSION]

## STRENGTHS

### Architecture & Design
- ✅ [設計面での良い点]

### Code Quality
- ✅ [コード品質面での良い点]

### Security
- ✅ [セキュリティ面での良い点]

### Performance
- ✅ [パフォーマンス面での良い点]

### Testing
- ✅ [テスト面での良い点]

## ISSUES

### 🔴 Critical (Must Fix Before Merge)
| # | Location | Issue | Impact | Fix |
|---|----------|-------|--------|-----|
| 1 | `file.ts:42` | [問題の説明] | [影響] | [修正方法] |

### 🟡 Important (Should Fix)
| # | Location | Issue | Impact | Fix |
|---|----------|-------|--------|-----|
| 1 | `file.ts:78` | [問題の説明] | [影響] | [修正方法] |

### 🟢 Minor (Nice to Have)
| # | Location | Issue | Suggestion |
|---|----------|-------|------------|
| 1 | `file.ts:103` | [問題の説明] | [改善案] |

## SUGGESTIONS

### Code Improvements
```[language]
// 📍 file.ts:42
// Before
[現在のコード]

// After (suggested)
[改善されたコード]
```

### Architecture Improvements
[アーキテクチャ改善提案]

### Performance Improvements
[パフォーマンス改善提案]

### Testing Improvements
[テスト改善提案]

## ACTION ITEMS

### ✅ Required Before Merge
1. [ ] [必須アクション1] (Critical #1)
2. [ ] [必須アクション2] (Critical #2)

### 📝 Recommended
1. [ ] [推奨アクション1] (Important #1)
2. [ ] [推奨アクション2] (Important #2)

### 💡 Future Considerations
1. [将来の検討事項1]
2. [将来の検討事項2]

## FINAL NOTES
[レビュー全体を通してのコメントや、特に伝えたいこと]
```
