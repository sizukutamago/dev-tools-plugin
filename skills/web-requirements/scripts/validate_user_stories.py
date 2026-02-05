#!/usr/bin/env python3
"""
User Stories Validator

ユーザーストーリーの Markdown ファイルをパースし、品質チェックを行う。
"""

import re
import sys
import json
import argparse
from pathlib import Path
from typing import NamedTuple
from dataclasses import dataclass, field


# 曖昧語リスト
AMBIGUOUS_WORDS_JA = [
    "適切に", "適宜", "十分に", "妥当な", "合理的に",
    "定期的に", "必要に応じて", "随時", "時々",
    "など", "等", "その他", "各種", "いくつかの",
    "多い", "少ない", "大量の", "少量の",
    "速やかに", "すぐに", "早く", "遅く",
    "高品質", "使いやすい", "見やすい", "シンプルな"
]

AMBIGUOUS_WORDS_EN = [
    "appropriate", "adequate", "proper",
    "periodically", "as needed", "regularly",
    "etc", "and so on", "various", "some",
    "many", "few", "lots of",
    "quickly", "soon", "fast",
    "high-quality", "user-friendly", "intuitive"
]


@dataclass
class Issue:
    """検出された問題"""
    severity: str  # P0, P1, P2
    category: str
    description: str
    location: str
    fix: str = ""


@dataclass
class ValidationResult:
    """バリデーション結果"""
    passed: bool
    issues: list = field(default_factory=list)
    summary: dict = field(default_factory=dict)


class UserStoriesValidator:
    """ユーザーストーリーのバリデーター"""

    def __init__(self, content: str, strict: bool = False):
        self.content = content
        self.strict = strict
        self.issues: list[Issue] = []
        self.lines = content.split('\n')

    def validate(self) -> ValidationResult:
        """全てのバリデーションを実行"""
        self._check_required_sections()
        self._check_personas()
        self._check_stories()
        self._check_ac_format()
        self._check_ambiguous_words()
        self._check_id_format()

        # 結果の集計
        p0_count = len([i for i in self.issues if i.severity == "P0"])
        p1_count = len([i for i in self.issues if i.severity == "P1"])
        p2_count = len([i for i in self.issues if i.severity == "P2"])

        # 判定
        if p0_count > 0:
            passed = False
        elif p1_count >= 2:
            passed = False
        elif self.strict and (p1_count > 0 or p2_count > 0):
            # strict モードでは P1/P2 が 1 件でも不合格
            passed = False
        else:
            passed = True

        return ValidationResult(
            passed=passed,
            issues=self.issues,
            summary={
                "p0_count": p0_count,
                "p1_count": p1_count,
                "p2_count": p2_count,
                "total_issues": len(self.issues),
                "passed": passed
            }
        )

    def _check_required_sections(self):
        """必須セクションの存在チェック"""
        required = [
            ("## 概要", "overview"),
            ("## ペルソナ", "persona"),
            ("## 非ゴール", "non_goals"),
            ("## 成功指標", "success_metrics"),
        ]

        for section, name in required:
            if section not in self.content:
                self.issues.append(Issue(
                    severity="P0" if name == "persona" else "P1",
                    category="missing_section",
                    description=f"必須セクション「{section}」が存在しない",
                    location="user-stories.md",
                    fix=f"{section} セクションを追加"
                ))

    def _check_personas(self):
        """ペルソナ定義のチェック"""
        # ペルソナテーブルの検出
        persona_pattern = r'\|\s*P-\d{3}\s*\|'
        personas = re.findall(r'P-(\d{3})', self.content)

        if not personas:
            self.issues.append(Issue(
                severity="P0",
                category="missing_persona",
                description="ペルソナが1件も定義されていない",
                location="user-stories.md",
                fix="ペルソナテーブルを追加（P-001 形式）"
            ))
            return

        # ペルソナ参照のチェック
        defined_personas = set(personas)
        used_pattern = r'As a\*?\*?\s+P-(\d{3})'
        used_personas = set(re.findall(used_pattern, self.content))

        undefined = used_personas - defined_personas
        for p in undefined:
            self.issues.append(Issue(
                severity="P0",
                category="undefined_persona",
                description=f"未定義のペルソナ P-{p} が参照されている",
                location="user-stories.md",
                fix=f"P-{p} をペルソナテーブルに追加するか、参照を修正"
            ))

    def _check_stories(self):
        """ストーリー構造のチェック"""
        # US-XXX パターンの検出
        story_pattern = r'####\s+US-(\d{3}):\s*(.+)'
        stories = re.findall(story_pattern, self.content)

        if not stories:
            self.issues.append(Issue(
                severity="P1",
                category="no_stories",
                description="ユーザーストーリーが1件も存在しない",
                location="user-stories.md",
                fix="User Stories セクションにストーリーを追加"
            ))
            return

        for us_id, title in stories:
            story_section = self._get_story_section(us_id)
            if story_section:
                self._check_story_structure(us_id, story_section)

    def _get_story_section(self, us_id: str) -> str:
        """特定のストーリーのセクションを取得"""
        pattern = rf'####\s+US-{us_id}:.*?(?=####\s+US-|\Z)'
        match = re.search(pattern, self.content, re.DOTALL)
        return match.group(0) if match else ""

    def _check_story_structure(self, us_id: str, section: str):
        """ストーリーの構造チェック"""
        # As a / I want / So that のチェック
        if "As a" not in section and "**As a**" not in section:
            self.issues.append(Issue(
                severity="P0",
                category="missing_as_a",
                description=f"US-{us_id}: 'As a' が欠落",
                location=f"user-stories.md:US-{us_id}",
                fix="'As a [ペルソナ]' を追加"
            ))

        if "I want to" not in section and "**I want to**" not in section:
            self.issues.append(Issue(
                severity="P0",
                category="missing_i_want",
                description=f"US-{us_id}: 'I want to' が欠落",
                location=f"user-stories.md:US-{us_id}",
                fix="'I want to [アクション]' を追加"
            ))

        if "So that" not in section and "**So that**" not in section:
            self.issues.append(Issue(
                severity="P0",
                category="missing_so_that",
                description=f"US-{us_id}: 'So that' が欠落",
                location=f"user-stories.md:US-{us_id}",
                fix="'So that [価値]' を追加"
            ))

        # AC の存在チェック
        ac_pattern = rf'AC-{us_id}-\d+'
        acs = re.findall(ac_pattern, section)

        if not acs:
            self.issues.append(Issue(
                severity="P0",
                category="missing_ac",
                description=f"US-{us_id}: Acceptance Criteria が存在しない",
                location=f"user-stories.md:US-{us_id}",
                fix="AC-{us_id}-1 以降の形式で AC を追加"
            ))

        # 異常系 AC のチェック
        failure_keywords = ["異常系", "エラー", "失敗", "error", "failure", "invalid"]
        has_failure_ac = any(kw in section.lower() for kw in failure_keywords)

        if not has_failure_ac and acs:
            self.issues.append(Issue(
                severity="P1",
                category="missing_failure_ac",
                description=f"US-{us_id}: 異常系の AC がない",
                location=f"user-stories.md:US-{us_id}",
                fix="エラーケース/失敗ケースの AC を追加"
            ))

    def _check_ac_format(self):
        """AC の Gherkin 形式チェック"""
        # コードブロック内の Given/When/Then を検出
        gherkin_blocks = re.findall(r'```gherkin\n(.*?)```', self.content, re.DOTALL)

        for i, block in enumerate(gherkin_blocks):
            if "Given" not in block:
                self.issues.append(Issue(
                    severity="P1",
                    category="missing_given",
                    description=f"Gherkin ブロック {i+1}: 'Given' が欠落",
                    location="user-stories.md",
                    fix="'Given [前提条件]' を追加"
                ))

            if "When" not in block:
                self.issues.append(Issue(
                    severity="P1",
                    category="missing_when",
                    description=f"Gherkin ブロック {i+1}: 'When' が欠落",
                    location="user-stories.md",
                    fix="'When [操作]' を追加"
                ))

            if "Then" not in block:
                self.issues.append(Issue(
                    severity="P1",
                    category="missing_then",
                    description=f"Gherkin ブロック {i+1}: 'Then' が欠落",
                    location="user-stories.md",
                    fix="'Then [期待結果]' を追加"
                ))

    def _check_ambiguous_words(self):
        """曖昧語のチェック（ストーリー単位で判定）"""
        all_ambiguous = AMBIGUOUS_WORDS_JA + AMBIGUOUS_WORDS_EN

        # ストーリーごとに曖昧語をカウント
        story_pattern = r'####\s+US-(\d{3}):'
        stories = re.split(story_pattern, self.content)

        total_found = []
        stories_with_excessive = []

        # stories[0] はヘッダー部分、stories[1::2] が US-ID、stories[2::2] が本文
        for i in range(1, len(stories), 2):
            us_id = stories[i]
            if i + 1 < len(stories):
                story_content = stories[i + 1]
                story_found = []

                for word in all_ambiguous:
                    if word in story_content:
                        story_found.append(word)
                        total_found.append((word, us_id))

                # 同一ストーリー内で 3 件以上は P0
                if len(story_found) >= 3:
                    stories_with_excessive.append((us_id, story_found))

        # ストーリー単位で 3 件以上あれば P0
        if stories_with_excessive:
            for us_id, words in stories_with_excessive:
                self.issues.append(Issue(
                    severity="P0",
                    category="excessive_ambiguity",
                    description=f"US-{us_id} に曖昧語が {len(words)} 件（3件以上でP0）: {', '.join(words[:5])}",
                    location=f"user-stories.md:US-{us_id}",
                    fix="具体的な条件・数値に置き換え"
                ))
        elif len(total_found) > 0:
            self.issues.append(Issue(
                severity="P2",
                category="ambiguous_words",
                description=f"曖昧語が全体で {len(total_found)} 件検出: {', '.join(set([f[0] for f in total_found[:5]]))}",
                location="user-stories.md",
                fix="具体的な条件・数値に置き換えを検討"
            ))

    def _check_id_format(self):
        """ID フォーマットと連番チェック"""
        # US-ID の連番チェック
        us_ids = [int(m) for m in re.findall(r'US-(\d{3})', self.content)]
        if us_ids:
            us_ids_sorted = sorted(set(us_ids))
            expected = list(range(1, max(us_ids_sorted) + 1))
            missing = set(expected) - set(us_ids_sorted)

            if missing:
                self.issues.append(Issue(
                    severity="P1",
                    category="missing_us_id",
                    description=f"US-ID に欠番: {', '.join([f'US-{m:03d}' for m in sorted(missing)])}",
                    location="user-stories.md",
                    fix="ID を再採番するか、欠番を埋める"
                ))

        # AC-ID の重複チェック
        ac_ids = re.findall(r'AC-(\d{3}-\d+)', self.content)
        duplicates = [ac for ac in ac_ids if ac_ids.count(ac) > 1]

        if duplicates:
            self.issues.append(Issue(
                severity="P0",
                category="duplicate_ac_id",
                description=f"AC-ID に重複: {', '.join(set(duplicates))}",
                location="user-stories.md",
                fix="重複する AC-ID を修正"
            ))


def main():
    parser = argparse.ArgumentParser(description="Validate user stories markdown")
    parser.add_argument("file", nargs="?", default="docs/requirements/user-stories.md",
                        help="Path to user-stories.md")
    parser.add_argument("--strict", action="store_true",
                        help="Strict mode (fail on any issue)")
    parser.add_argument("--json", action="store_true",
                        help="Output as JSON")

    args = parser.parse_args()

    file_path = Path(args.file)
    if not file_path.exists():
        print(f"Error: File not found: {file_path}", file=sys.stderr)
        sys.exit(1)

    content = file_path.read_text(encoding="utf-8")
    validator = UserStoriesValidator(content, strict=args.strict)
    result = validator.validate()

    if args.json:
        output = {
            "passed": result.passed,
            "summary": result.summary,
            "issues": [
                {
                    "severity": i.severity,
                    "category": i.category,
                    "description": i.description,
                    "location": i.location,
                    "fix": i.fix
                }
                for i in result.issues
            ]
        }
        print(json.dumps(output, indent=2, ensure_ascii=False))
    else:
        # Human-readable output
        print(f"Validation {'PASSED' if result.passed else 'FAILED'}")
        print(f"P0: {result.summary['p0_count']}, P1: {result.summary['p1_count']}, P2: {result.summary['p2_count']}")
        print()

        if result.issues:
            print("Issues:")
            for issue in result.issues:
                print(f"  [{issue.severity}] {issue.category}: {issue.description}")
                print(f"       Location: {issue.location}")
                if issue.fix:
                    print(f"       Fix: {issue.fix}")
                print()

    sys.exit(0 if result.passed else 1)


if __name__ == "__main__":
    main()
