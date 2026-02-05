# Interview Questions Template

AskUserQuestion 用の質問テンプレート集。Double Diamond パターンに沿った質問設計。

## Double Diamond パターン

```
Phase 1: Discover（発散）  →  Phase 2: Define（収束）
         自由回答で                選択肢で
         全体像を把握              優先度を確定

Phase 3: Develop（発散）  →  Phase 4: Deliver（収束）
         提案を提示して            最終確認
         フィードバック            要約→承認
```

## 質問テンプレート

### Phase 1: Discover（発散）- 全体像の把握

#### 目的・背景

```yaml
question: "この機能で解決したい最大の課題は何ですか？"
header: "Pain point"
options:
  - label: "業務効率化"
    description: "手作業を減らし、時間を節約したい"
  - label: "ユーザー体験改善"
    description: "使いにくい部分を改善したい"
  - label: "売上向上"
    description: "コンバージョン率を上げたい"
  - label: "コスト削減"
    description: "運用コストを下げたい"
multiSelect: false
```

```yaml
question: "この機能が必要になった背景を教えてください（自由記述）"
header: "背景"
options:
  - label: "顧客からの要望"
    description: "具体的な要望があれば後述"
  - label: "競合対策"
    description: "競合が先行している"
  - label: "社内の課題"
    description: "業務上の問題が発生"
  - label: "その他"
    description: "自由記述で詳細を"
multiSelect: false
```

#### ペルソナ特定

```yaml
question: "この機能を主に使うユーザーは誰ですか？"
header: "Primary User"
options:
  - label: "一般ユーザー（会員）"
    description: "サービスに登録済みの顧客"
  - label: "管理者"
    description: "社内のスタッフ、運用担当者"
  - label: "ゲスト（未登録）"
    description: "まだ会員登録していない訪問者"
  - label: "外部パートナー"
    description: "API 連携する外部システム/企業"
multiSelect: true
```

```yaml
question: "ユーザーの技術レベルはどの程度を想定しますか？"
header: "Tech Level"
options:
  - label: "初心者"
    description: "IT に詳しくない一般消費者"
  - label: "一般的"
    description: "PC/スマホの基本操作はできる"
  - label: "上級者"
    description: "技術的な知識がある"
  - label: "開発者"
    description: "API/コマンドラインも使える"
multiSelect: false
```

### Phase 2: Define（収束）- 優先度と制約の確定

#### スコープ確認

```yaml
question: "MVP（最小限の製品）に含めるべき機能はどれですか？"
header: "MVP Scope"
options:
  - label: "基本機能のみ"
    description: "コア機能だけを最初にリリース"
  - label: "基本＋主要な拡張"
    description: "よく使われる機能も含める"
  - label: "フル機能"
    description: "全ての機能を一度にリリース"
  - label: "要相談"
    description: "具体的な機能リストを確認したい"
multiSelect: false
```

```yaml
question: "以下のうち、今回のスコープ外とするものはどれですか？"
header: "Non-goals"
options:
  - label: "モバイルアプリ対応"
    description: "Web のみで開始"
  - label: "多言語対応"
    description: "日本語のみで開始"
  - label: "高度な分析機能"
    description: "基本的なレポートのみ"
  - label: "API 公開"
    description: "内部利用のみ"
multiSelect: true
```

#### 優先度確認

```yaml
question: "以下の品質特性で最も重視するのはどれですか？"
header: "Priority"
options:
  - label: "使いやすさ（UX）"
    description: "直感的で迷わない操作"
  - label: "パフォーマンス"
    description: "高速なレスポンス"
  - label: "セキュリティ"
    description: "堅牢な保護"
  - label: "拡張性"
    description: "将来の機能追加のしやすさ"
multiSelect: false
```

#### 制約確認

```yaml
question: "技術的な制約はありますか？"
header: "Constraints"
options:
  - label: "既存システムとの連携必須"
    description: "レガシーシステムとの互換性が必要"
  - label: "特定のクラウド環境"
    description: "AWS/GCP/Azure など指定あり"
  - label: "特定のフレームワーク"
    description: "React/Vue など指定あり"
  - label: "特になし"
    description: "技術選定は自由"
multiSelect: true
```

### Phase 3: Develop（発散）- 提案とフィードバック

#### 実装アプローチ

```yaml
question: "認証方式はどちらが適切ですか？"
header: "Auth Method"
options:
  - label: "JWT（トークンベース）(推奨)"
    description: "ステートレス、マイクロサービス向き、拡張性高い"
  - label: "セッション（サーバーサイド）"
    description: "シンプル、セキュリティ管理しやすい"
  - label: "OAuth/ソーシャルログイン"
    description: "Google/GitHub などでログイン"
  - label: "要検討"
    description: "詳細を確認してから決定"
multiSelect: false
```

#### ユースケース深掘り

```yaml
question: "エラーが発生した場合、ユーザーにどう伝えますか？"
header: "Error UX"
options:
  - label: "インライン表示"
    description: "入力フィールドの下にエラーメッセージ"
  - label: "トースト通知"
    description: "画面上部/下部にポップアップ"
  - label: "モーダルダイアログ"
    description: "重要なエラーはモーダルで確認"
  - label: "全て併用"
    description: "エラーの重大度で使い分け"
multiSelect: false
```

### Phase 4: Deliver（収束）- 最終確認

#### 要約と承認

```yaml
question: "以下の理解で正しいですか？

【目的】認証機能の実装
【ペルソナ】一般ユーザー、管理者
【MVP】ログイン、ログアウト、パスワードリセット
【スコープ外】ソーシャルログイン、2FA
【優先事項】セキュリティ > UX"
header: "Confirm"
options:
  - label: "はい、この内容で進めてください"
    description: "要件が確定しました"
  - label: "一部修正が必要"
    description: "追加のヒアリングを行います"
  - label: "大幅な修正が必要"
    description: "もう一度整理し直します"
multiSelect: false
```

## 追加の確認項目（要件以外）

### 影響範囲

```yaml
question: "この機能追加で影響を受ける既存機能はありますか？"
header: "Impact"
options:
  - label: "ユーザー管理"
    description: "ユーザー関連の機能に影響"
  - label: "決済機能"
    description: "支払い関連に影響"
  - label: "通知機能"
    description: "メール/プッシュ通知に影響"
  - label: "影響なし/不明"
    description: "独立した新機能として追加"
multiSelect: true
```

### 削除・廃止

```yaml
question: "この機能に伴い、削除や廃止する既存機能はありますか？"
header: "Deprecation"
options:
  - label: "旧バージョンの機能を廃止"
    description: "新機能で置き換え"
  - label: "一部の設定項目を削除"
    description: "不要になる設定がある"
  - label: "API エンドポイントの廃止"
    description: "旧 API を削除"
  - label: "なし"
    description: "削除するものはない"
multiSelect: true
```

### 間接的影響

```yaml
question: "直接は関係しないが、影響があるかもしれない機能や懸念はありますか？"
header: "Indirect"
options:
  - label: "パフォーマンスへの影響"
    description: "負荷が増える可能性"
  - label: "他チームの作業との競合"
    description: "同じ領域を触る可能性"
  - label: "運用手順の変更"
    description: "サポート対応が変わる"
  - label: "特になし"
    description: "影響は限定的"
multiSelect: true
```

### リファクタリング

```yaml
question: "この機能追加に伴い、リファクタリングが必要な箇所はありますか？"
header: "Refactor"
options:
  - label: "認証ロジックの整理"
    description: "既存の認証コードを改善"
  - label: "データベーススキーマ変更"
    description: "テーブル構造の見直し"
  - label: "API 設計の統一"
    description: "一貫性のある API に"
  - label: "不要/未把握"
    description: "リファクタなしで追加可能"
multiSelect: true
```

### 依存関係

```yaml
question: "この機能は他のチームや外部サービスに依存しますか？"
header: "Dependencies"
options:
  - label: "他チームの API が必要"
    description: "社内の別チームとの調整が必要"
  - label: "外部サービスの契約が必要"
    description: "Stripe、SendGrid 等の契約"
  - label: "法務/コンプライアンス確認"
    description: "規約変更や法的確認が必要"
  - label: "依存なし"
    description: "自チームで完結"
multiSelect: true
```

## 質問のベストプラクティス

### Do（推奨）

- 選択肢に必ず「その他」「未定」を用意（誘導を避ける）
- 1 回あたり 2〜4 問に抑える
- 各サイクル末尾で要約（Paraphrasing）→ 確認
- 情報利得ベース: 不確実性/リスクが高い点から優先

### Don't（避ける）

- 誘導的な質問（「〜すべきですよね？」）
- Yes/No だけの質問（深掘りできない）
- 一度に 5 問以上（認知負荷が高い）
- 技術用語の羅列（ペルソナに合わせる）

### 停止条件

以下の場合はヒアリングを終了:

1. 意思決定に足る粒度が揃った
2. ユーザーが疲労サインを出した（回答が雑になる、「もういいです」等）
3. 情報利得が低下した（同じ回答の繰り返し）

### 認知負荷への配慮

```yaml
# 高負荷になりそうな場合
question: "ここまでの内容で一度整理しますか？それとも追加で深掘りして良いですか？"
header: "Continue?"
options:
  - label: "ここで一旦整理"
    description: "現状の情報でストーリーを作成"
  - label: "もう少し深掘り"
    description: "追加の質問に答える"
multiSelect: false
```
