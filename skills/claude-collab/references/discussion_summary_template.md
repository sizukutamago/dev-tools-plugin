# ディベートサマリーテンプレート

Judge（中立的な第三者 Claude）が最終要約を生成する際に使用するテンプレート。

---

## テンプレート

```markdown
# ディベートサマリー: {topic}

| 項目 | 値 |
|------|---|
| 日付 | YYYY-MM-DD |
| モード | {advocate-vs-devils-advocate / expert-perspectives / custom} |
| Role A | {role_a_name} |
| Role B | {role_b_name} |
| ラウンド数 | {actual_rounds}/{planned_rounds} |
| 終了理由 | {completed / converged-early / circular-break / max-rounds} |

## TL;DR

- {結論1: 最も重要な発見や合意点}
- {結論2: 主要なトレードオフ}
- {結論3: 推奨される次のアクション}

## 論点台帳（最終状態）

| ID | 論点 | ステータス | Role A の根拠 | Role B の根拠 |
|----|------|-----------|--------------|--------------|
| 1  | {topic} | {resolved/open/dropped} | {evidence} | {evidence} |

## 合意点

両者が合意に達した点:

1. {合意点1}
2. {合意点2}

## 対立点

解消されなかった対立:

1. **{対立点1}**
   - Role A ({name}): {stance}
   - Role B ({name}): {stance}
   - **トレードオフ**: {trade-off の分析}

## トレードオフ分析

| 観点 | Role A 側 | Role B 側 |
|------|----------|----------|
| {aspect1} | {pro/stance} | {pro/stance} |
| {aspect2} | {pro/stance} | {pro/stance} |

## 推奨アクション

Judge としての中立的な推奨:

1. **最優先**: {最も重要なアクション}
2. **次点**: {代替案または補完的なアクション}
3. **追加調査**: {判断に追加情報が必要な点}

## 全ラウンド記録

<details>
<summary>Round 1</summary>

**Role A ({name})**:
{full_text}

**Role B ({name})**:
{full_text}

</details>

<details>
<summary>Round 2</summary>
...
</details>
```

---

## Judge へのプロンプト指示

Judge は以下の原則に従ってサマリーを生成すること:

1. **中立性**: どちらの立場にも偏らず、両方の論点を公平に扱う
2. **構造化**: 上記テンプレートに沿って出力する
3. **具体性**: 抽象的な表現を避け、議論中に出た具体的な根拠を引用する
4. **実用性**: 推奨アクションは実行可能なレベルで記述する
5. **対立の保存**: 合意に至らなかった点は無理に結論を出さず、対立として明示する
