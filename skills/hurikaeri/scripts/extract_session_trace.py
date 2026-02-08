#!/usr/bin/env python3
"""
extract_session_trace.py - セッショントレース抽出（hurikaeri 用）

使用方法:
    python3 extract_session_trace.py <transcript.jsonl>

出力: YAML 形式のセッショントレース（標準出力）
依存: Python 3.x 標準ライブラリのみ（json, re, sys, os, collections）

prompt-improver の extract_transcript.py をベースに、
AI の行動分析に特化した抽出ロジックを追加。
"""

import json
import re
import sys
import os
from collections import defaultdict
from typing import Optional


# ユーザー修正検出パターン（extract_transcript.py と共通）
CORRECTION_PATTERNS = {
    "negation_start": re.compile(
        r"^(いや|違う|違います|そうじゃない|それじゃない|間違|訂正|no[,.]|not |that's not|you misunderstood)",
        re.IGNORECASE,
    ),
    "contrast": re.compile(
        r"(ではなく|じゃなくて|ではなくて|instead|rather than)", re.IGNORECASE
    ),
    "correction_request": re.compile(
        r"(直して|修正して|やり直して|〜にして|してください|please fix|please change|redo)",
        re.IGNORECASE,
    ),
    "instruction_reminder": re.compile(
        r"(って言った|と言った|って指示した|って頼んだ|told you|said to|asked you|I said)",
        re.IGNORECASE,
    ),
    "why_doing": re.compile(
        r"(なんで|なぜ|どうして|why).{0,20}(してる|やってる|している|するの|doing|did you)",
        re.IGNORECASE,
    ),
    "comprehension_check": re.compile(
        r"(聞いてた|聞いてる|わかってる|理解してる|読んだ(?:\?|？)|見た(?:\?|？)|are you listening|did you understand)",
        re.IGNORECASE,
    ),
    "repetition_frustration": re.compile(
        r"(もう一回|何度も|さっきも)(言|説明)", re.IGNORECASE
    ),
    "missing_element": re.compile(
        r"(がない|が足りない|が抜けてる|を忘れてる)(?!か|ことを|ように|ようです|かも)",
        re.IGNORECASE,
    ),
}

# 高スコアパターン（単独で閾値を超える明示的な指摘）
HIGH_SCORE_PATTERNS = {
    "correction_request",
    "instruction_reminder",
    "why_doing",
    "comprehension_check",
    "repetition_frustration",
    "missing_element",
}


def extract_text_from_content(content, include_tool_results: bool = True) -> str:
    """メッセージコンテンツからテキストを抽出

    Args:
        content: メッセージの content フィールド
        include_tool_results: tool_result のテキストも含めるか（修正検出では False 推奨）
    """
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        texts = []
        for item in content:
            if isinstance(item, dict):
                if item.get("type") == "text":
                    texts.append(item.get("text", ""))
                elif item.get("type") == "tool_result" and include_tool_results:
                    result_content = item.get("content", "")
                    if isinstance(result_content, str):
                        texts.append(result_content)
                    elif isinstance(result_content, list):
                        for block in result_content:
                            if isinstance(block, dict) and block.get("type") == "text":
                                texts.append(block.get("text", ""))
        return " ".join(texts)
    return ""


def detect_user_correction(text: str) -> Optional[dict]:
    """ユーザーの修正指示を検出"""
    score = 0
    patterns_matched = []

    for pattern_name, pattern in CORRECTION_PATTERNS.items():
        if pattern.search(text):
            if pattern_name in HIGH_SCORE_PATTERNS:
                score += 3
            else:
                score += 2
            patterns_matched.append(pattern_name)

    if re.search(r"\.\w{2,4}\b", text):
        score += 1
    if re.search(r"[A-Z][a-z]+[A-Z]", text):
        score += 1

    if score >= 3:
        return {
            "score": score,
            "patterns": patterns_matched,
            "excerpt": text[:120],
        }
    return None


def summarize_tool_input(tool_name: str, tool_input: dict) -> str:
    """ツール入力を簡潔にサマリーする"""
    if tool_name in ("Read", "Grep", "Glob"):
        path = tool_input.get("file_path", tool_input.get("path", ""))
        pattern = tool_input.get("pattern", "")
        if path and pattern:
            return f"{pattern} in {path}"
        return path or pattern or ""

    if tool_name in ("Write", "Edit"):
        path = tool_input.get("file_path", "")
        return path

    if tool_name == "Bash":
        cmd = tool_input.get("command", "")
        # 主要コマンドを抽出（パイプチェーンの先頭コマンド）
        first_cmd = cmd.split("|")[0].split("&&")[0].strip()
        return first_cmd[:80]

    if tool_name == "Skill":
        return tool_input.get("skill", "")

    if tool_name == "Task":
        desc = tool_input.get("description", "")
        return desc[:60]

    if tool_name == "AskUserQuestion":
        questions = tool_input.get("questions", [])
        if questions and isinstance(questions, list):
            return questions[0].get("question", "")[:60]
        return ""

    return str(tool_input)[:60]


def process_session_trace(jsonl_path: str) -> dict:
    """JSONL トランスクリプトからセッショントレースを抽出"""

    line_number = 0
    turn_number = 0
    last_entry_type = None

    # 結果格納
    tool_timeline = []
    search_paths = []
    changed_files = []
    file_edit_counts = defaultdict(int)  # backtrack 検出用
    file_edit_turns = defaultdict(list)
    errors = []
    user_corrections = []
    skills_used = defaultdict(int)
    tool_use_id_map = {}  # tool_use_id → timeline_entry（エラー紐付け用）

    # メトリクス
    user_turns = 0
    assistant_turns = 0
    tool_use_count = 0
    unique_tools = set()

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

            # ターンカウント
            if entry_type != last_entry_type:
                if entry_type in ("user", "human"):
                    user_turns += 1
                    turn_number += 1
                elif entry_type == "assistant":
                    assistant_turns += 1
            last_entry_type = entry_type

            # スキル使用検出（Skill ツール呼び出しで統一、<command-name> は二重カウント防止のため除外）

            # ツール使用の検出・タイムライン記録
            if entry_type == "assistant" and isinstance(content, list):
                for item in content:
                    if isinstance(item, dict) and item.get("type") == "tool_use":
                        tool_name = item.get("name", "")
                        tool_input = item.get("input", {})
                        tool_use_count += 1
                        unique_tools.add(tool_name)

                        input_summary = summarize_tool_input(tool_name, tool_input)

                        tool_use_id = item.get("id", "")
                        timeline_entry = {
                            "turn": turn_number,
                            "line": line_number,
                            "tool": tool_name,
                            "input_summary": input_summary[:100],
                            "success": True,  # デフォルト、後でエラーで上書き
                        }
                        tool_timeline.append(timeline_entry)
                        # tool_use_id → timeline_entry のマッピング（エラー紐付け用）
                        if tool_use_id:
                            tool_use_id_map[tool_use_id] = timeline_entry

                        # 検索パスの記録
                        if tool_name in ("Grep", "Glob", "Read"):
                            path = tool_input.get(
                                "file_path", tool_input.get("path", "")
                            )
                            pattern = tool_input.get("pattern", "")
                            search_paths.append(
                                {
                                    "turn": turn_number,
                                    "tool": tool_name,
                                    "path": path,
                                    "pattern": pattern,
                                }
                            )

                        # ファイル変更の記録
                        if tool_name in ("Write", "Edit"):
                            file_path = tool_input.get("file_path", "")
                            if file_path:
                                changed_files.append(
                                    {
                                        "path": file_path,
                                        "op": (
                                            "write"
                                            if tool_name == "Write"
                                            else "edit"
                                        ),
                                        "turn": turn_number,
                                    }
                                )
                                file_edit_counts[file_path] += 1
                                file_edit_turns[file_path].append(turn_number)

                        # Skill ツール使用
                        if tool_name == "Skill":
                            skill_name = tool_input.get("skill", "")
                            if skill_name:
                                skills_used[skill_name] += 1

            # エラーの検出
            if entry_type in ("user", "human") and isinstance(content, list):
                for item in content:
                    if isinstance(item, dict) and item.get("type") == "tool_result":
                        if item.get("is_error"):
                            error_content = item.get("content", "")
                            if isinstance(error_content, str):
                                errors.append(
                                    {
                                        "line": line_number,
                                        "turn": turn_number,
                                        "message": error_content[:200],
                                    }
                                )
                                # tool_use_id で正確にツール使用を紐付け
                                result_tool_use_id = item.get("tool_use_id", "")
                                if result_tool_use_id and result_tool_use_id in tool_use_id_map:
                                    tool_use_id_map[result_tool_use_id]["success"] = False
                                elif tool_timeline:
                                    # フォールバック: tool_use_id がない場合は直前に紐付け
                                    tool_timeline[-1]["success"] = False

            # ユーザー修正の検出
            if entry_type in ("user", "human"):
                # tool_result を除外してユーザーのテキストのみ抽出（誤検出防止）
                user_text = extract_text_from_content(content, include_tool_results=False)
                # system-reminder を除外
                if user_text.startswith("<system-reminder>"):
                    continue
                correction = detect_user_correction(user_text)
                if correction:
                    user_corrections.append(
                        {
                            "turn": turn_number,
                            "line": line_number,
                            "excerpt": correction["excerpt"],
                            "patterns": correction["patterns"],
                            "score": correction["score"],
                        }
                    )

    # backtrack イベントの検出（同一ファイルの複数回編集）
    backtrack_events = []
    for file_path, count in file_edit_counts.items():
        if count >= 2:
            backtrack_events.append(
                {
                    "file": file_path,
                    "edit_count": count,
                    "turns": file_edit_turns[file_path],
                }
            )
    backtrack_events.sort(key=lambda x: x["edit_count"], reverse=True)

    # 変更ファイルのユニーク化（表示用）
    unique_changed = []
    seen_files = set()
    for cf in changed_files:
        if cf["path"] not in seen_files:
            seen_files.add(cf["path"])
            unique_changed.append(cf)

    return {
        "metrics": {
            "total_lines": line_number,
            "user_turns": user_turns,
            "assistant_turns": assistant_turns,
            "tool_use_count": tool_use_count,
            "unique_tools": sorted(unique_tools),
            "code_changes_count": len(unique_changed),  # ユニークファイル数
            "error_count": len(errors),
            "correction_count": len(user_corrections),
            "backtrack_count": len(backtrack_events),
            "skills_used": dict(skills_used),
        },
        "tool_timeline": tool_timeline[:100],  # 最大100件
        "search_paths": search_paths[:50],  # 最大50件
        "changed_files": unique_changed[:30],  # ユニーク最大30件
        "backtrack_events": backtrack_events[:10],  # 最大10件
        "errors": errors[:20],  # 最大20件
        "user_corrections": user_corrections[:10],  # 最大10件
    }


def format_yaml_output(trace: dict) -> str:
    """手動で YAML 形式に変換（PyYAML 依存なし）"""
    lines = [
        "# turn = ユーザーターン番号（ユーザー発言ごとにインクリメント）",
        "session_trace:",
    ]

    # metrics
    m = trace["metrics"]
    lines.append("  metrics:")
    lines.append(f"    total_lines: {m['total_lines']}")
    lines.append(f"    user_turns: {m['user_turns']}")
    lines.append(f"    assistant_turns: {m['assistant_turns']}")
    lines.append(f"    tool_use_count: {m['tool_use_count']}")
    lines.append(
        f"    unique_tools: {json.dumps(m['unique_tools'], ensure_ascii=False)}"
    )
    lines.append(f"    code_changes_count: {m['code_changes_count']}")
    lines.append(f"    error_count: {m['error_count']}")
    lines.append(f"    correction_count: {m['correction_count']}")
    lines.append(f"    backtrack_count: {m['backtrack_count']}")
    if m["skills_used"]:
        lines.append("    skills_used:")
        for name, count in m["skills_used"].items():
            lines.append(f"      {name}: {count}")
    else:
        lines.append("    skills_used: {}")

    # tool_timeline（最大20件表示）
    timeline = trace["tool_timeline"][:20]
    if timeline:
        lines.append("  tool_timeline:")
        for t in timeline:
            lines.append(f"    - turn: {t['turn']}")
            lines.append(f"      tool: \"{t['tool']}\"")
            summary = t["input_summary"].replace('"', '\\"').replace("\n", "\\n")
            lines.append(f"      input_summary: \"{summary}\"")
            lines.append(f"      success: {str(t['success']).lower()}")
    else:
        lines.append("  tool_timeline: []")

    # search_paths（最大15件表示）
    searches = trace["search_paths"][:15]
    if searches:
        lines.append("  search_paths:")
        for s in searches:
            lines.append(f"    - turn: {s['turn']}")
            lines.append(f"      tool: \"{s['tool']}\"")
            path = s["path"].replace('"', '\\"') if s["path"] else ""
            lines.append(f"      path: \"{path}\"")
            pattern = s["pattern"].replace('"', '\\"') if s["pattern"] else ""
            lines.append(f"      pattern: \"{pattern}\"")
    else:
        lines.append("  search_paths: []")

    # changed_files
    changed = trace["changed_files"]
    if changed:
        lines.append("  changed_files:")
        for cf in changed:
            path = cf["path"].replace('"', '\\"')
            lines.append(f"    - path: \"{path}\"")
            lines.append(f"      op: \"{cf['op']}\"")
            lines.append(f"      turn: {cf['turn']}")
    else:
        lines.append("  changed_files: []")

    # backtrack_events
    backtracks = trace["backtrack_events"]
    if backtracks:
        lines.append("  backtrack_events:")
        for bt in backtracks:
            path = bt["file"].replace('"', '\\"')
            lines.append(f"    - file: \"{path}\"")
            lines.append(f"      edit_count: {bt['edit_count']}")
            lines.append(f"      turns: {json.dumps(bt['turns'])}")
    else:
        lines.append("  backtrack_events: []")

    # errors
    errs = trace["errors"]
    if errs:
        lines.append("  errors:")
        for err in errs:
            lines.append(f"    - turn: {err['turn']}")
            lines.append(f"      line: {err['line']}")
            msg = err["message"].replace('"', '\\"').replace("\n", "\\n")
            lines.append(f"      message: \"{msg[:100]}\"")
    else:
        lines.append("  errors: []")

    # user_corrections
    corrections = trace["user_corrections"]
    if corrections:
        lines.append("  user_corrections:")
        for uc in corrections:
            lines.append(f"    - turn: {uc['turn']}")
            excerpt = uc["excerpt"].replace('"', '\\"').replace("\n", "\\n")
            lines.append(f"      excerpt: \"{excerpt}\"")
            lines.append(
                f"      patterns: {json.dumps(uc['patterns'], ensure_ascii=False)}"
            )
            lines.append(f"      score: {uc['score']}")
    else:
        lines.append("  user_corrections: []")

    return "\n".join(lines)


def main():
    if len(sys.argv) < 2:
        print(
            "Usage: python3 extract_session_trace.py <transcript.jsonl>",
            file=sys.stderr,
        )
        sys.exit(1)

    jsonl_path = sys.argv[1]
    if not os.path.exists(jsonl_path):
        print(f"Error: File not found: {jsonl_path}", file=sys.stderr)
        sys.exit(1)

    trace = process_session_trace(jsonl_path)
    print(format_yaml_output(trace))


if __name__ == "__main__":
    main()
