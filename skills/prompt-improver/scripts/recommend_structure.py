#!/usr/bin/env python3
"""
構造改善レポート生成スクリプト

フィードバック YAML を分析して、新スキル作成・スキル分割の推奨を生成する。
PyYAML なしで動作する限定パーサを使用。

Usage:
    python3 recommend_structure.py [--feedback-dir DIR] [--status STATUS]
"""

import argparse
import os
import re
import unicodedata
from collections import defaultdict
from pathlib import Path
from typing import Dict, List, Set, Tuple, Optional


# ===============================
# 設定
# ===============================

# 新スキル候補の閾値
MIN_DOC_FREQUENCY = 3  # 同系統キーワードが出現する最小 fb 数
LOW_CONFIDENCE_THRESHOLD = 0.5  # 低信頼度の閾値

# 分割候補の閾値
MIN_CLUSTER_SIZE = 3  # クラスターに必要な最小 fb 数
MAX_JACCARD_SIMILARITY = 0.3  # クラスター間の最大類似度（これ以下で分割推奨）

# 無視するキーワード（汎用すぎるもの）
STOP_WORDS = {
    "the", "a", "an", "is", "are", "was", "were", "be", "been",
    "have", "has", "had", "do", "does", "did", "will", "would",
    "could", "should", "may", "might", "must", "shall",
    "this", "that", "these", "those", "it", "its",
    "and", "or", "but", "if", "then", "else",
    "for", "to", "from", "with", "by", "at", "in", "on", "of",
    "file", "files", "code", "error", "errors", "test", "tests",
}


# ===============================
# YAML 限定パーサ
# ===============================

def parse_feedback_yaml(filepath: str) -> Optional[Dict]:
    """
    フィードバック YAML から必要なフィールドだけを抽出する限定パーサ。
    PyYAML なしで動作。
    """
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception:
        return None

    result = {
        'id': None,
        'triage_status': None,
        'improvement_targets': [],
        'errors': [],
        'user_corrections': [],
    }

    # ID
    match = re.search(r'^id:\s*(\S+)', content, re.MULTILINE)
    if match:
        result['id'] = match.group(1)

    # triage.status
    match = re.search(r'triage:\s*\n\s+status:\s*(\S+)', content)
    if match:
        result['triage_status'] = match.group(1)

    # improvement_targets セクションを抽出（ネスト構造を含む全行をキャプチャ）
    targets_match = re.search(
        r'improvement_targets:\s*\n((?:\s{4,}.*\n?)+?)(?=\n\s{2}\w+:|\Z)',
        content
    )
    if targets_match:
        targets_section = targets_match.group(1)
        result['improvement_targets'] = parse_improvement_targets(targets_section)

    # errors セクションからキーワードを抽出（ネスト構造を含む）
    errors_match = re.search(
        r'^\s+errors:\s*\n((?:\s{6,}.*\n?)+?)(?=\n\s{2,4}\w+:|\Z)',
        content,
        re.MULTILINE
    )
    if errors_match:
        errors_section = errors_match.group(1)
        result['errors'] = extract_error_keywords(errors_section)

    # user_corrections セクションからキーワードと詳細を抽出
    # items: セクションを探す（ネスト構造を含む全行をキャプチャ）
    items_match = re.search(
        r'user_corrections:\s*\n\s+count:\s*\d+\s*\n\s+items:\s*\n((?:\s{6,}.*\n?)+)',
        content
    )
    if items_match:
        items_section = items_match.group(1)
        result['user_corrections'] = extract_correction_keywords(items_section)
        result['user_correction_items'] = extract_correction_items(items_section)
    else:
        result['user_correction_items'] = []

    return result


def parse_improvement_targets(section: str) -> List[Dict]:
    """improvement_targets セクションをパース"""
    targets = []
    current_target = {}

    for line in section.split('\n'):
        if re.match(r'\s+-\s+target:', line):
            if current_target:
                targets.append(current_target)
            current_target = {'keywords': [], 'avg_confidence': 1.0, 'file': None, 'section': None, 'type': None}
        elif 'type:' in line and current_target:
            match = re.search(r'type:\s*["\']?(\S+?)["\']?$', line)
            if match:
                current_target['type'] = match.group(1).strip('"\'')
        elif 'file:' in line and current_target:
            match = re.search(r'file:\s*["\']?(.+?)["\']?\s*$', line)
            if match:
                current_target['file'] = match.group(1).strip('"\'')
        elif 'section:' in line and current_target:
            match = re.search(r'section:\s*["\']?(.+?)["\']?\s*$', line)
            if match:
                current_target['section'] = match.group(1).strip('"\'')
        elif 'avg_confidence:' in line and current_target:
            match = re.search(r'avg_confidence:\s*([\d.]+)', line)
            if match:
                current_target['avg_confidence'] = float(match.group(1))
        elif 'keywords:' in line and current_target:
            # keywords リストを抽出
            match = re.search(r'keywords:\s*\[(.+?)\]', line)
            if match:
                keywords_str = match.group(1)
                current_target['keywords'] = [
                    k.strip().strip('"\'')
                    for k in keywords_str.split(',')
                ]

    if current_target:
        targets.append(current_target)

    return targets


def extract_error_keywords(section: str) -> List[str]:
    """errors セクションからキーワードを抽出"""
    keywords = []
    matches = re.findall(r'matched_keywords:\s*\[(.+?)\]', section)
    for match in matches:
        for kw in match.split(','):
            kw = kw.strip().strip('"\'')
            if kw:
                keywords.append(kw)
    return keywords


def extract_correction_keywords(section: str) -> List[str]:
    """user_corrections セクションからキーワードを抽出"""
    keywords = []
    # patterns から抽出
    matches = re.findall(r'patterns:\s*\[(.+?)\]', section)
    for match in matches:
        for kw in match.split(','):
            kw = kw.strip().strip('"\'')
            if kw:
                keywords.append(kw)
    return keywords


def extract_correction_items(section: str) -> List[Dict]:
    """user_corrections セクションから詳細情報を抽出"""
    items = []
    current_item = {}

    for line in section.split('\n'):
        if re.match(r'\s+-\s+line:', line):
            if current_item:
                items.append(current_item)
            current_item = {'excerpt': '', 'patterns': [], 'linked_target': None}
        elif 'excerpt:' in line and current_item is not None:
            match = re.search(r'excerpt:\s*["\']?(.+?)["\']?\s*$', line)
            if match:
                current_item['excerpt'] = match.group(1)[:100]
        elif 'patterns:' in line and current_item is not None:
            match = re.search(r'patterns:\s*\[(.+?)\]', line)
            if match:
                current_item['patterns'] = [
                    p.strip().strip('"\'') for p in match.group(1).split(',')
                ]
        elif 'linked_target:' in line and current_item is not None:
            current_item['linked_target'] = True

    if current_item:
        items.append(current_item)

    return items


# ===============================
# キーワード正規化
# ===============================

def normalize_keyword(keyword: str) -> str:
    """キーワードを正規化（大小文字、Unicode正規化）"""
    # Unicode正規化（NFKC）
    normalized = unicodedata.normalize('NFKC', keyword)
    # 小文字化
    normalized = normalized.lower()
    # 記号除去（アンダースコア、ハイフンは残す）
    normalized = re.sub(r'[^\w\s-]', '', normalized)
    return normalized.strip()


def is_valid_keyword(keyword: str) -> bool:
    """有効なキーワードかどうか"""
    normalized = normalize_keyword(keyword)
    if len(normalized) < 2:
        return False
    if normalized in STOP_WORDS:
        return False
    return True


# ===============================
# 新スキル候補検出
# ===============================

def detect_new_skill_candidates(feedbacks: List[Dict]) -> List[Dict]:
    """
    新スキル作成候補を検出。

    条件:
    - improvement_targets の avg_confidence が低い
    - または linked_target がない（errors/corrections に未リンクが多い）
    - 同系統キーワードが複数 fb で出現
    """
    # キーワード → 出現 fb_id のマッピング
    keyword_to_fb_ids: Dict[str, Set[str]] = defaultdict(set)
    # キーワード → 低信頼度フラグ
    keyword_low_confidence: Dict[str, int] = defaultdict(int)

    for fb in feedbacks:
        fb_id = fb.get('id')
        if not fb_id:
            continue

        # improvement_targets から低信頼度のキーワードを収集
        for target in fb.get('improvement_targets', []):
            confidence = target.get('avg_confidence', 1.0)
            for kw in target.get('keywords', []):
                if not is_valid_keyword(kw):
                    continue
                normalized = normalize_keyword(kw)
                keyword_to_fb_ids[normalized].add(fb_id)
                if confidence < LOW_CONFIDENCE_THRESHOLD:
                    keyword_low_confidence[normalized] += 1

        # errors のキーワードも収集
        for kw in fb.get('errors', []):
            if not is_valid_keyword(kw):
                continue
            normalized = normalize_keyword(kw)
            keyword_to_fb_ids[normalized].add(fb_id)

        # user_corrections のキーワードも収集
        for kw in fb.get('user_corrections', []):
            if not is_valid_keyword(kw):
                continue
            normalized = normalize_keyword(kw)
            keyword_to_fb_ids[normalized].add(fb_id)

    # 候補を検出
    candidates = []

    # doc frequency が閾値以上のキーワードをグループ化
    high_freq_keywords = {
        kw: fb_ids
        for kw, fb_ids in keyword_to_fb_ids.items()
        if len(fb_ids) >= MIN_DOC_FREQUENCY
    }

    # キーワードをクラスタリング（共起ベース）
    clusters = cluster_keywords_by_cooccurrence(high_freq_keywords)

    for cluster_keywords, fb_ids in clusters:
        if len(fb_ids) < MIN_DOC_FREQUENCY:
            continue

        # 低信頼度の割合を計算
        low_conf_count = sum(keyword_low_confidence.get(kw, 0) for kw in cluster_keywords)

        candidate = {
            'proposed_name': suggest_skill_name(cluster_keywords),
            'keywords': list(cluster_keywords)[:5],
            'fb_count': len(fb_ids),
            'fb_ids': sorted(list(fb_ids))[:5],
            'low_confidence_count': low_conf_count,
            'rationale': '既存ターゲットに結び付かない指摘が反復',
        }
        candidates.append(candidate)

    # fb_count で降順ソート
    candidates.sort(key=lambda x: x['fb_count'], reverse=True)

    return candidates[:5]  # 上位5件まで


def cluster_keywords_by_cooccurrence(keyword_fb_map: Dict[str, Set[str]]) -> List[Tuple[Set[str], Set[str]]]:
    """共起ベースでキーワードをクラスタリング"""
    if not keyword_fb_map:
        return []

    # 簡易クラスタリング: fb_id の重なりが大きいキーワードをまとめる
    keywords = list(keyword_fb_map.keys())
    clusters = []
    used = set()

    for kw in keywords:
        if kw in used:
            continue

        cluster = {kw}
        fb_ids = set(keyword_fb_map[kw])

        for other_kw in keywords:
            if other_kw in used or other_kw == kw:
                continue

            other_fb_ids = keyword_fb_map[other_kw]
            # Jaccard 類似度
            intersection = len(fb_ids & other_fb_ids)
            union = len(fb_ids | other_fb_ids)

            if union > 0 and intersection / union > 0.5:
                cluster.add(other_kw)
                fb_ids |= other_fb_ids

        for c in cluster:
            used.add(c)

        clusters.append((cluster, fb_ids))

    return clusters


def suggest_skill_name(keywords: Set[str]) -> str:
    """キーワードからスキル名を提案"""
    # 上位2つのキーワードをハイフンで結合
    sorted_keywords = sorted(keywords, key=len, reverse=True)[:2]
    return '-'.join(sorted_keywords) if sorted_keywords else 'unknown-skill'


# ===============================
# スキル分割候補検出
# ===============================

def detect_split_candidates(feedbacks: List[Dict]) -> List[Dict]:
    """
    スキル分割候補を検出。

    条件:
    - 同一 skill ファイルに対する指摘が複数セクションに分散
    - セクション間のキーワード重なりが薄い（Jaccard 類似度が低い）
    """
    # skill ファイル → セクション → キーワード集合
    skill_sections: Dict[str, Dict[str, Set[str]]] = defaultdict(lambda: defaultdict(set))
    # skill ファイル → セクション → fb_id 集合
    skill_section_fb_ids: Dict[str, Dict[str, Set[str]]] = defaultdict(lambda: defaultdict(set))

    for fb in feedbacks:
        fb_id = fb.get('id')
        if not fb_id:
            continue

        for target in fb.get('improvement_targets', []):
            if target.get('type') != 'skill':
                continue

            file_path = target.get('file')
            section = target.get('section')
            if not file_path or not section:
                continue

            for kw in target.get('keywords', []):
                if is_valid_keyword(kw):
                    normalized = normalize_keyword(kw)
                    skill_sections[file_path][section].add(normalized)
                    skill_section_fb_ids[file_path][section].add(fb_id)

    # 分割候補を検出
    candidates = []

    for skill_file, sections in skill_sections.items():
        if len(sections) < 2:
            continue

        # セクション間の Jaccard 類似度を計算
        section_names = list(sections.keys())
        clusters = []

        for i, sec1 in enumerate(section_names):
            kw1 = sections[sec1]
            fb1 = skill_section_fb_ids[skill_file][sec1]

            # 十分な fb がなければスキップ
            if len(fb1) < MIN_CLUSTER_SIZE:
                continue

            is_distinct = True
            for j, sec2 in enumerate(section_names):
                if i >= j:
                    continue

                kw2 = sections[sec2]
                fb2 = skill_section_fb_ids[skill_file][sec2]

                if len(fb2) < MIN_CLUSTER_SIZE:
                    continue

                # Jaccard 類似度
                intersection = len(kw1 & kw2)
                union = len(kw1 | kw2)
                similarity = intersection / union if union > 0 else 0

                if similarity <= MAX_JACCARD_SIMILARITY:
                    # 類似度が低い = 分割推奨
                    clusters.append({
                        'section': sec1,
                        'keywords': list(kw1)[:5],
                        'fb_count': len(fb1),
                    })
                    clusters.append({
                        'section': sec2,
                        'keywords': list(kw2)[:5],
                        'fb_count': len(fb2),
                    })

        # 重複を除去してクラスターをまとめる
        unique_clusters = {}
        for c in clusters:
            key = c['section']
            if key not in unique_clusters:
                unique_clusters[key] = c

        if len(unique_clusters) >= 2:
            candidates.append({
                'skill_path': skill_file,
                'clusters': list(unique_clusters.values()),
                'total_fb_count': sum(c['fb_count'] for c in unique_clusters.values()),
                'proposed_splits': [
                    f"{skill_file.replace('.md', '')}-{normalize_keyword(c['section'].replace('##', '').strip())}"
                    for c in list(unique_clusters.values())[:2]
                ],
            })

    # total_fb_count で降順ソート
    candidates.sort(key=lambda x: x['total_fb_count'], reverse=True)

    return candidates[:3]  # 上位3件まで


# ===============================
# prompt-improver 自己改善検出
# ===============================

def detect_self_improvement_candidates(feedbacks: List[Dict]) -> Dict:
    """
    フィードバックから prompt-improver 自体への改善提案を生成。

    1. パターン提案: ユーザー修正があるが patterns_matched が空 → 新パターン候補
    2. キーワード提案: linked_target が null または confidence < 0.3 → 新キーワード候補
    """
    pattern_proposals = []
    keyword_proposals = []

    # パターン提案: 検出されなかったユーザー指摘を収集
    undetected_excerpts = []
    for fb in feedbacks:
        fb_id = fb.get('id')
        for item in fb.get('user_correction_items', []):
            # patterns が空 = 検出パターンに引っかからなかった
            if not item.get('patterns'):
                excerpt = item.get('excerpt', '')
                if excerpt and len(excerpt) > 5:
                    undetected_excerpts.append({
                        'fb_id': fb_id,
                        'excerpt': excerpt,
                    })

    # 類似 excerpt をグループ化して提案
    if undetected_excerpts:
        # 簡易的にキーワード抽出してグループ化
        excerpt_keywords = defaultdict(list)
        for item in undetected_excerpts:
            # excerpt から特徴的なフレーズを抽出
            excerpt = item['excerpt']
            # 日本語の指摘パターンを抽出
            phrases = re.findall(r'(なんで|なぜ|どうして|って言った|聞いてた|わかってる|させて|してる|やってる)', excerpt)
            for phrase in phrases:
                excerpt_keywords[phrase].append(item)

        for phrase, items in excerpt_keywords.items():
            if len(items) >= 2:  # 2件以上で提案
                pattern_proposals.append({
                    'reason': f'"{phrase}" が {len(items)} 件検出されていない',
                    'example': items[0]['excerpt'][:50],
                    'proposed_pattern': phrase,
                    'source_fb_ids': [i['fb_id'] for i in items[:3]],
                })

    # キーワード提案: リンクされなかった improvement_targets を収集
    unlinked_keywords = defaultdict(lambda: {'fb_ids': set(), 'keywords': set()})
    for fb in feedbacks:
        fb_id = fb.get('id')
        for target in fb.get('improvement_targets', []):
            confidence = target.get('avg_confidence', 1.0)
            target_file = target.get('file')

            # 低信頼度またはファイルがない = リンク不十分
            if confidence < 0.3 or not target_file:
                for kw in target.get('keywords', []):
                    if is_valid_keyword(kw):
                        normalized = normalize_keyword(kw)
                        unlinked_keywords[normalized]['fb_ids'].add(fb_id)
                        unlinked_keywords[normalized]['keywords'].add(kw)

    # 3件以上で提案
    for kw, data in unlinked_keywords.items():
        if len(data['fb_ids']) >= 3:
            keyword_proposals.append({
                'reason': f'"{kw}" が {len(data["fb_ids"])} 件リンク先なし',
                'keywords': list(data['keywords'])[:3],
                'proposed_section': 'skills/??? または CLAUDE.md',
                'source_fb_ids': sorted(list(data['fb_ids']))[:3],
            })

    return {
        'pattern_proposals': pattern_proposals[:5],
        'keyword_proposals': keyword_proposals[:5],
    }


# ===============================
# レポート生成
# ===============================

def generate_markdown_report(
    new_skill_candidates: List[Dict],
    split_candidates: List[Dict],
    self_improvement: Dict,
    total_scanned: int,
) -> str:
    """Markdown レポートを生成"""
    lines = [
        "==========================================",
        "構造改善レポート",
        "==========================================",
        f"",
        f"分析対象: {total_scanned} 件のフィードバック（status: open）",
        "",
    ]

    # prompt-improver 自己改善
    pattern_proposals = self_improvement.get('pattern_proposals', [])
    keyword_proposals = self_improvement.get('keyword_proposals', [])

    if pattern_proposals or keyword_proposals:
        lines.append("【prompt-improver 自己改善】")

        if pattern_proposals:
            lines.append("新パターン候補:")
            for i, proposal in enumerate(pattern_proposals, 1):
                lines.append(f"  {i}) \"{proposal['proposed_pattern']}\"")
                lines.append(f"     - 理由: {proposal['reason']}")
                lines.append(f"     - 例: \"{proposal['example']}...\"")
                lines.append(f"     - 提案: CORRECTION_PATTERNS に追加")
            lines.append("")

        if keyword_proposals:
            lines.append("新キーワード候補:")
            for i, proposal in enumerate(keyword_proposals, 1):
                lines.append(f"  {i}) {proposal['keywords']}")
                lines.append(f"     - 理由: {proposal['reason']}")
                lines.append(f"     - 提案: {proposal['proposed_section']} に追加")
            lines.append("")

        lines.append("")

    # 新スキル候補
    lines.append("【新スキル候補】")
    if new_skill_candidates:
        for i, candidate in enumerate(new_skill_candidates, 1):
            lines.append(f"{i}) {candidate['proposed_name']}（{candidate['fb_count']}件）")
            lines.append(f"   - 根拠: {candidate['rationale']}")
            lines.append(f"   - 代表キーワード: {', '.join(candidate['keywords'])}")
            lines.append(f"   - 代表フィードバック: {', '.join(candidate['fb_ids'][:3])}")
            lines.append(f"   - 推奨アクション:")
            lines.append(f"     - skills/{candidate['proposed_name']}/SKILL.md を新規作成")
            lines.append(f"     - 最低3つの実例を追加")
            lines.append(f"     - トリガー文言を定義")
            lines.append("")
    else:
        lines.append("該当なし")
        lines.append("")

    # 分割候補
    lines.append("【スキル分割候補】")
    if split_candidates:
        for i, candidate in enumerate(split_candidates, 1):
            lines.append(f"{i}) {candidate['skill_path']}（{candidate['total_fb_count']}件）")
            for j, cluster in enumerate(candidate['clusters'], ord('A')):
                lines.append(f"   - クラスター{chr(j)}: {cluster['section']}（{cluster['fb_count']}件）")
                lines.append(f"     キーワード: {', '.join(cluster['keywords'][:3])}")
            if candidate.get('proposed_splits'):
                lines.append(f"   - 推奨: {' + '.join(candidate['proposed_splits'][:2])} に分割")
            lines.append("")
    else:
        lines.append("該当なし")
        lines.append("")

    lines.append("==========================================")

    return "\n".join(lines)


# ===============================
# メイン処理
# ===============================

def main():
    parser = argparse.ArgumentParser(description='構造改善レポート生成')
    parser.add_argument(
        '--feedback-dir',
        default=os.path.expanduser('~/.claude/feedback'),
        help='フィードバックディレクトリ'
    )
    parser.add_argument(
        '--status',
        default='open',
        help='対象とするトリアージステータス'
    )
    args = parser.parse_args()

    feedback_dir = Path(args.feedback_dir)
    if not feedback_dir.exists():
        print(f"Error: フィードバックディレクトリが存在しません: {feedback_dir}")
        return 1

    # フィードバックファイルを読み込み
    feedbacks = []
    for yaml_file in sorted(feedback_dir.glob('fb-*.yaml')):
        fb = parse_feedback_yaml(str(yaml_file))
        if fb is None:
            continue

        # ステータスフィルタ
        status = fb.get('triage_status')
        if args.status == 'open':
            # open または triage がない場合は対象
            if status and status != 'open':
                continue
        elif status != args.status:
            continue

        feedbacks.append(fb)

    if not feedbacks:
        print("対象となるフィードバックがありません。")
        return 0

    # 検出
    new_skill_candidates = detect_new_skill_candidates(feedbacks)
    split_candidates = detect_split_candidates(feedbacks)
    self_improvement = detect_self_improvement_candidates(feedbacks)

    # レポート生成
    report = generate_markdown_report(
        new_skill_candidates,
        split_candidates,
        self_improvement,
        len(feedbacks),
    )

    print(report)
    return 0


if __name__ == '__main__':
    exit(main())
