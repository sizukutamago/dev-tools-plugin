#!/usr/bin/env python3
"""
extract_transcript.py - JSONLトランスクリプトからフィードバック情報を抽出

使用方法:
    python3 extract_transcript.py <transcript.jsonl>

出力: YAML形式の extracted セクション（標準出力）
依存: Python 3.x 標準ライブラリのみ（json, re, sys）
"""

import json
import re
import sys
import os
from collections import defaultdict
from typing import Optional

# セクションキーワードマッピングファイルのパス
KEYWORDS_FILE = os.path.join(os.path.dirname(__file__), "section_keywords.json")

# デフォルトのキーワードマッピング（外部ファイルがない場合のフォールバック）
DEFAULT_KEYWORDS = {
    "claude_md": {
        "RULES.md": {
            "## Git Workflow": ["git", "commit", "push", "branch", "PR", "rebase", "checkout", "merge"],
            "## Implementation Completeness": ["TODO", "実装", "完成", "未完了", "stub", "incomplete"],
            "## Scope Discipline": ["スコープ", "MVP", "機能追加", "YAGNI", "scope"],
            "## Failure Investigation": ["エラー", "デバッグ", "失敗", "調査", "debug", "error"],
            "## Professional Honesty": ["マーケティング", "誇張", "正直", "professional"],
            "## Workspace Hygiene": ["クリーンアップ", "一時ファイル", "cleanup", "temp"],
            "## Tool Optimization": ["ツール", "並列", "parallel", "効率"],
            "## File Organization": ["ファイル構成", "ディレクトリ", "directory", "organization"]
        },
        "PRINCIPLES.md": {
            "## Engineering Mindset": ["SOLID", "DRY", "KISS", "設計", "design"],
            "## Decision Framework": ["決定", "トレードオフ", "trade-off", "decision"],
            "## Quality Philosophy": ["品質", "quality", "テスト", "test"]
        },
        "FLAGS.md": {
            "## Mode Activation Flags": ["brainstorm", "introspect", "orchestrate", "flag"],
            "## MCP Server Flags": ["context7", "sequential", "playwright", "MCP"]
        }
    },
    "skills": {
        "architecture": {
            "## セキュリティパターン": ["JWT", "認証", "OAuth", "セキュリティ", "暗号化", "auth", "security"],
            "## アーキテクチャ決定": ["ADR", "設計", "構造", "レイヤー", "architecture"]
        },
        "api": {
            "## エンドポイント設計": ["REST", "API", "エンドポイント", "HTTP", "endpoint"]
        },
        "database": {
            "## データモデル": ["スキーマ", "エンティティ", "schema", "entity", "table", "index"]
        },
        "implementation": {
            "## コーディング規約": ["コーディング", "規約", "coding", "standard", "convention"]
        }
    }
}

# ユーザー修正検出パターン
CORRECTION_PATTERNS = {
    # 既存パターン
    "negation_start": re.compile(r"^(いや|違う|違います|そうじゃない|それじゃない|間違|訂正|no[,.]|not |that's not|you misunderstood)", re.IGNORECASE),
    "contrast": re.compile(r"(ではなく|じゃなくて|ではなくて|instead|rather than)", re.IGNORECASE),
    "correction_request": re.compile(r"(直して|修正して|やり直して|〜にして|してください|please fix|please change|redo)", re.IGNORECASE),

    # 新規: ユーザー指摘パターン
    "instruction_reminder": re.compile(
        r"(って言った|と言った|って指示した|って頼んだ|told you|said to|asked you|I said)",
        re.IGNORECASE
    ),
    "why_doing": re.compile(
        r"(なんで|なぜ|どうして|why).{0,20}(してる|やってる|している|するの|させてる|させて|doing|did you)",
        re.IGNORECASE
    ),
    "comprehension_check": re.compile(
        r"(聞いてた|聞いてる|わかってる|理解してる|読んだ(?:\?|？)|見た(?:\?|？)|are you listening|did you understand|did you read)",
        re.IGNORECASE
    ),

    # 繰り返し不満
    "repetition_frustration": re.compile(
        r"(もう一回|何度も|さっきも)(言|説明)",
        re.IGNORECASE
    ),

    # 不足指摘（質問形式・確認形式を除外）
    "missing_element": re.compile(
        r"(がない|が足りない|が抜けてる|を忘れてる)(?!か|ことを|ように|ようです|かも)",
        re.IGNORECASE
    ),

    # 確認期待
    "expectation_check": re.compile(
        r"(じゃないの|でしょ|だよね)(?:\?|？)",
        re.IGNORECASE
    ),
}


def load_section_keywords() -> dict:
    """セクションキーワードをファイルまたはデフォルトから読み込み"""
    if os.path.exists(KEYWORDS_FILE):
        try:
            with open(KEYWORDS_FILE, "r", encoding="utf-8") as f:
                return json.load(f)
        except (json.JSONDecodeError, IOError):
            pass
    return DEFAULT_KEYWORDS


def extract_text_from_content(content) -> str:
    """メッセージコンテンツからテキストを抽出"""
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        texts = []
        for item in content:
            if isinstance(item, dict):
                if item.get("type") == "text":
                    texts.append(item.get("text", ""))
                elif item.get("type") == "tool_result":
                    result_content = item.get("content", "")
                    if isinstance(result_content, str):
                        texts.append(result_content)
        return " ".join(texts)
    return ""


# 弱キーワード（汎用的すぎるため、単独ではマッチしない）
WEAK_KEYWORDS = {"error", "debug", "test", "file", "code", "data", "config", "エラー", "テスト", "ファイル"}


def extract_keywords_from_text(text: str) -> set:
    """テキストからキーワードを抽出（小文字化して単語分割）"""
    # 日本語と英語の両方に対応
    words = set(re.findall(r"[a-zA-Z]+|[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FFF]+", text.lower()))
    return words


def keyword_matches_in_text(context_text: str, keyword: str) -> bool:
    """キーワードがコンテキストに部分一致するか（大文字小文字無視）"""
    # 部分一致で検索（日本語・英語両対応）
    return keyword.lower() in context_text.lower()


def find_linked_target(context_text: str, active_skill: Optional[str], section_keywords: dict) -> Optional[dict]:
    """コンテキストテキストからリンク先セクションを特定（部分一致方式）"""
    if not context_text.strip():
        return None

    best_match = None
    best_score = 0.0
    best_strong_count = 0  # 強キーワードの数

    # claude_md セクションをチェック
    for file_name, sections in section_keywords.get("claude_md", {}).items():
        for section, section_kws in sections.items():
            score = 0.0
            strong_count = 0
            matched_kws = []
            for kw in section_kws:
                if keyword_matches_in_text(context_text, kw):
                    matched_kws.append(kw)
                    if kw.lower() in WEAK_KEYWORDS:
                        score += 0.5  # 弱キーワードは半分のスコア
                    else:
                        score += 1.0
                        strong_count += 1

            # 強キーワードが1つ以上必要（弱キーワードだけではマッチしない）
            if strong_count > 0 and (score > best_score or (score == best_score and strong_count > best_strong_count)):
                best_score = score
                best_strong_count = strong_count
                best_match = {
                    "type": "claude_md",
                    "file": file_name,
                    "section": section,
                    "confidence": round(min(score / 3.0, 1.0), 2),  # 3ポイントで100%
                    "matched_keywords": sorted(matched_kws)  # 根拠キーワード
                }

    # skills セクションをチェック（active_skillがあれば優先）
    for skill_name, sections in section_keywords.get("skills", {}).items():
        for section, section_kws in sections.items():
            score = 0.0
            strong_count = 0
            matched_kws = []
            for kw in section_kws:
                if keyword_matches_in_text(context_text, kw):
                    matched_kws.append(kw)
                    if kw.lower() in WEAK_KEYWORDS:
                        score += 0.5
                    else:
                        score += 1.0
                        strong_count += 1

            # active_skill と一致する場合はボーナス
            active_bonus = 0.0
            if active_skill and skill_name == active_skill:
                active_bonus = 0.5
                score += active_bonus

            if strong_count > 0 and (score > best_score or (score == best_score and strong_count > best_strong_count)):
                best_score = score
                best_strong_count = strong_count
                evidence_score = max(score - active_bonus, 0.0)
                best_match = {
                    "type": "skill",
                    "file": f"skills/{skill_name}/SKILL.md",
                    "section": section,
                    # confidence はキーワード根拠のみ（active_bonusは含めない）
                    "confidence": round(min(evidence_score / 3.0, 1.0), 2),
                    "matched_keywords": sorted(matched_kws)
                }

    return best_match if best_score > 0 else None


def detect_user_correction(text: str) -> Optional[dict]:
    """ユーザーの修正指示を検出"""
    score = 0
    patterns_matched = []

    # 高スコアパターン（単独で検出されるべき明示的な指摘）
    # expectation_check は曖昧なため除外（他パターンとの組み合わせで検出）
    high_score_patterns = {
        "instruction_reminder", "why_doing", "comprehension_check",
        "repetition_frustration", "missing_element"
    }

    for pattern_name, pattern in CORRECTION_PATTERNS.items():
        if pattern.search(text):
            # 明示的な指摘パターンは高スコア（単独で閾値を超える）
            if pattern_name in high_score_patterns:
                score += 3
            else:
                score += 2
            patterns_matched.append(pattern_name)

    # ファイル名や具体名詞があればボーナス
    if re.search(r"\.\w{2,4}\b", text):  # ファイル拡張子
        score += 1
    if re.search(r"[A-Z][a-z]+[A-Z]", text):  # CamelCase
        score += 1

    if score >= 3:
        return {
            "score": score,
            "patterns": patterns_matched,
            "excerpt": text[:120]
        }
    return None


def process_transcript(jsonl_path: str) -> dict:
    """JSONLトランスクリプトを1パスで処理"""
    section_keywords = load_section_keywords()

    # 状態管理
    active_skill = None
    line_number = 0

    # 結果格納
    skills_used = defaultdict(lambda: {"count": 0, "first_line": None, "last_line": None})
    changed_files = []
    errors = []
    user_corrections = []
    context_buffer = []  # 直近のコンテキスト（前後10行分）

    # improvement_targets 集計用（タプルキーで安全に）
    target_issues = defaultdict(lambda: {
        "errors": 0,
        "corrections": 0,
        "matched_keywords": set(),  # 根拠キーワード（精度優先）
        "total_confidence": 0.0,  # confidenceの合計（重み付け用）
        "link_count": 0  # リンク回数
    })

    with open(jsonl_path, "r", encoding="utf-8") as f:
        for line in f:
            line_number += 1
            try:
                entry = json.loads(line.strip())
            except json.JSONDecodeError:
                continue

            entry_type = entry.get("type")
            message = entry.get("message", {})
            content = message.get("content", [])

            # コンテキストバッファを更新（最大20行保持）
            text_content = extract_text_from_content(content)
            context_buffer.append(text_content)
            if len(context_buffer) > 20:
                context_buffer.pop(0)

            # スキル使用の検出（<command-name>/skill</command-name>）
            if isinstance(content, str):
                skill_match = re.search(r"<command-name>/([^<]+)</command-name>", content)
                if skill_match:
                    skill_name = skill_match.group(1)
                    active_skill = skill_name
                    if skills_used[skill_name]["first_line"] is None:
                        skills_used[skill_name]["first_line"] = line_number
                    skills_used[skill_name]["last_line"] = line_number
                    skills_used[skill_name]["count"] += 1

            # ツール使用の検出（assistant メッセージ内）
            if entry_type == "assistant" and isinstance(content, list):
                for item in content:
                    if isinstance(item, dict) and item.get("type") == "tool_use":
                        tool_name = item.get("name", "")
                        tool_input = item.get("input", {})

                        # ファイル変更の検出
                        if tool_name in ("Write", "Edit"):
                            file_path = tool_input.get("file_path", "")
                            if file_path:
                                changed_files.append({
                                    "path": file_path,
                                    "op": "write" if tool_name == "Write" else "edit",
                                    "via": tool_name,
                                    "line": line_number
                                })

                        # Skill ツール使用
                        if tool_name == "Skill":
                            skill_name = tool_input.get("skill", "")
                            if skill_name:
                                active_skill = skill_name
                                if skills_used[skill_name]["first_line"] is None:
                                    skills_used[skill_name]["first_line"] = line_number
                                skills_used[skill_name]["last_line"] = line_number
                                skills_used[skill_name]["count"] += 1

            # エラーの検出（tool_result with is_error）
            if entry_type == "user" and isinstance(content, list):
                for item in content:
                    if isinstance(item, dict) and item.get("type") == "tool_result":
                        if item.get("is_error"):
                            error_content = item.get("content", "")
                            if isinstance(error_content, str):
                                context_text = " ".join(context_buffer[-10:])
                                linked = find_linked_target(context_text, active_skill, section_keywords)

                                error_entry = {
                                    "kind": "tool_error",
                                    "tool": "unknown",  # tool_use_id から逆引きが必要だが簡略化
                                    "message": error_content[:200],
                                    "line": line_number,
                                }
                                if linked:
                                    error_entry["linked_target"] = linked
                                    # タプルキーで安全に（パスに:が含まれる環境対応）
                                    target_key = (linked['type'], linked['file'], linked['section'])
                                    confidence = linked.get('confidence', 0.5)
                                    matched_kws = linked.get('matched_keywords', [])
                                    target_issues[target_key]["errors"] += 1
                                    target_issues[target_key]["total_confidence"] += confidence
                                    target_issues[target_key]["link_count"] += 1
                                    # 根拠キーワードを優先して保存
                                    target_issues[target_key]["matched_keywords"].update(matched_kws)

                                # context_keywords を YAML 出力用に保存（recommend_structure.py で使用）
                                error_entry["context_keywords"] = sorted(
                                    list(extract_keywords_from_text(context_text))
                                )[:15]
                                errors.append(error_entry)

            # ユーザー修正の検出
            if entry_type == "user":
                user_text = extract_text_from_content(content)
                correction = detect_user_correction(user_text)
                if correction:
                    context_text = " ".join(context_buffer[-10:])
                    linked = find_linked_target(context_text, active_skill, section_keywords)

                    correction_entry = {
                        "line": line_number,
                        "excerpt": correction["excerpt"],
                        "patterns": correction["patterns"],
                        "score": correction["score"],
                        "linked_skill": active_skill,
                        "context_keywords": sorted(list(
                            extract_keywords_from_text(context_text)
                        ))[:10]
                    }
                    if linked:
                        correction_entry["linked_target"] = linked
                        # タプルキーで安全に
                        target_key = (linked['type'], linked['file'], linked['section'])
                        confidence = linked.get('confidence', 0.5)
                        matched_kws = linked.get('matched_keywords', [])
                        target_issues[target_key]["corrections"] += 1
                        target_issues[target_key]["total_confidence"] += confidence
                        target_issues[target_key]["link_count"] += 1
                        # 根拠キーワードを優先して保存
                        target_issues[target_key]["matched_keywords"].update(matched_kws)

                    user_corrections.append(correction_entry)

    # improvement_targets の生成（weighted_blame_score でソート）
    improvement_targets = []
    for target_key, issues in target_issues.items():
        target_type, file_path, section = target_key

        # 平均confidence（リンクの信頼度）
        avg_confidence = (
            issues["total_confidence"] / issues["link_count"]
            if issues["link_count"] > 0 else 0.5
        )

        # 重み付きblame_score（confidence考慮）
        raw_blame_score = 3 * issues["errors"] + 2 * issues["corrections"]
        blame_score = round(raw_blame_score * avg_confidence, 1)

        improvement_targets.append({
            "target": {
                "type": target_type,
                "file": file_path,
                "section": section
            },
            "errors": issues["errors"],
            "corrections": issues["corrections"],
            "raw_blame_score": raw_blame_score,  # 元式: 3*errors + 2*corrections
            "blame_score": blame_score,  # 重み付き（ソートに使用）
            "avg_confidence": round(avg_confidence, 2),
            "keywords": sorted(list(issues["matched_keywords"]))[:10]  # 根拠キーワード優先
        })

    # blame_score（重み付き）で降順ソート
    improvement_targets.sort(key=lambda x: (x["blame_score"], x["raw_blame_score"]), reverse=True)

    return {
        "skills_used": [
            {"name": name, **data}
            for name, data in skills_used.items()
        ],
        "changed_files": changed_files[:50],  # 最大50件
        "errors": errors[:20],  # 最大20件
        "user_corrections": {
            "count": len(user_corrections),
            "items": user_corrections[:10]  # 最大10件
        },
        "improvement_targets": improvement_targets[:10]  # 最大10件
    }


def format_yaml_output(extracted: dict) -> str:
    """手動でYAML形式に変換（PyYAML依存なし）"""
    lines = ["extracted:"]

    # skills_used
    skills_used = extracted.get("skills_used", [])
    if skills_used:
        lines.append("  skills_used:")
        for skill in skills_used:
            lines.append(f"    - name: \"{skill['name']}\"")
            lines.append(f"      count: {skill['count']}")
            lines.append(f"      first_line: {skill['first_line']}")
            lines.append(f"      last_line: {skill['last_line']}")
    else:
        lines.append("  skills_used: []")

    # changed_files
    changed_files = extracted.get("changed_files", [])
    if changed_files:
        lines.append("  changed_files:")
        for f in changed_files:
            lines.append(f"    - path: \"{f['path']}\"")
            lines.append(f"      op: \"{f['op']}\"")
            lines.append(f"      via: \"{f['via']}\"")
    else:
        lines.append("  changed_files: []")

    # errors
    errors = extracted.get("errors", [])
    if errors:
        lines.append("  errors:")
        for err in errors:
            lines.append(f"    - kind: \"{err['kind']}\"")
            lines.append(f"      tool: \"{err['tool']}\"")
            # メッセージは改行やクォートをエスケープ
            msg = err['message'].replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n')
            lines.append(f"      message: \"{msg[:100]}\"")
            lines.append(f"      line: {err['line']}")
            if "linked_target" in err:
                lt = err["linked_target"]
                lines.append("      linked_target:")
                lines.append(f"        type: \"{lt['type']}\"")
                lines.append(f"        file: \"{lt['file']}\"")
                lines.append(f"        section: \"{lt['section']}\"")
                lines.append(f"        confidence: {lt.get('confidence', 0.5)}")
                if lt.get('matched_keywords'):
                    lines.append(
                        f"        matched_keywords: {json.dumps(lt['matched_keywords'][:5], ensure_ascii=False)}"
                    )
            # context_keywords を出力（recommend_structure.py で使用）
            if err.get("context_keywords"):
                lines.append(
                    f"      context_keywords: {json.dumps(err['context_keywords'][:10], ensure_ascii=False)}"
                )
    else:
        lines.append("  errors: []")

    # user_corrections
    uc = extracted.get("user_corrections", {})
    lines.append("  user_corrections:")
    lines.append(f"    count: {uc.get('count', 0)}")
    correction_items = uc.get("items", [])
    if correction_items:
        lines.append("    items:")
        for item in correction_items:
            lines.append(f"      - line: {item['line']}")
            excerpt = item['excerpt'].replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n')
            lines.append(f"        excerpt: \"{excerpt}\"")
            lines.append(f"        patterns: {json.dumps(item['patterns'], ensure_ascii=False)}")
            lines.append(f"        score: {item['score']}")
            if item.get("linked_skill"):
                lines.append(f"        linked_skill: \"{item['linked_skill']}\"")
            if "linked_target" in item:
                lt = item["linked_target"]
                lines.append("        linked_target:")
                lines.append(f"          type: \"{lt['type']}\"")
                lines.append(f"          file: \"{lt['file']}\"")
                lines.append(f"          section: \"{lt['section']}\"")
                lines.append(f"          confidence: {lt.get('confidence', 0.5)}")
                if lt.get('matched_keywords'):
                    lines.append(
                        f"          matched_keywords: {json.dumps(lt['matched_keywords'][:5], ensure_ascii=False)}"
                    )
    else:
        lines.append("    items: []")

    # improvement_targets
    improvement_targets = extracted.get("improvement_targets", [])
    if improvement_targets:
        lines.append("  improvement_targets:")
        for target in improvement_targets:
            t = target["target"]
            lines.append("    - target:")
            lines.append(f"        type: \"{t['type']}\"")
            lines.append(f"        file: \"{t['file']}\"")
            lines.append(f"        section: \"{t['section']}\"")
            lines.append(f"      errors: {target['errors']}")
            lines.append(f"      corrections: {target['corrections']}")
            lines.append(f"      raw_blame_score: {target['raw_blame_score']}")
            lines.append(f"      blame_score: {target['blame_score']}")
            lines.append(f"      avg_confidence: {target['avg_confidence']}")
            lines.append(f"      keywords: {json.dumps(target['keywords'][:5], ensure_ascii=False)}")
    else:
        lines.append("  improvement_targets: []")

    return "\n".join(lines)


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 extract_transcript.py <transcript.jsonl>", file=sys.stderr)
        sys.exit(1)

    jsonl_path = sys.argv[1]
    if not os.path.exists(jsonl_path):
        print(f"Error: File not found: {jsonl_path}", file=sys.stderr)
        sys.exit(1)

    extracted = process_transcript(jsonl_path)
    print(format_yaml_output(extracted))


if __name__ == "__main__":
    main()
