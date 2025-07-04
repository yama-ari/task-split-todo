# タスク分割支援型ToDoアプリ（仮）

## ■ サービス概要

行動に移せない目標や理想を、実行可能なタスクに分けて管理できるToDoアプリです。  
「できなかった理由」を「分割不足だった」と捉え直すことで、前向きに行動を続けられるようにします。  
小さな達成を積み重ねて、自己効力感と行動の習慣化をサポートします。

---

## ■ このサービスを作ろうと思った理由

私は現在、エンジニア転職という目標に向けて学習を進めていますが、やるべきことが多すぎて、何から手をつければいいのか分からなくなることがよくあります。  
特に、学習カリキュラムを終えて自由に動けるようになったとたんに、迷子のような感覚に陥りました。

振り返ってみると、カリキュラム中も「やったほうがいいこと」は頭では分かっていても、それを具体的な行動に落とし込めず、時間をうまく使えなかったことが悔しく感じています。

「もう少し小さな単位に分けていれば動けたかも」と思い、このアプリを作ることにしました。

---

## ■ 想定するユーザー層

- 目標はあるけれど、なかなか行動に移せない人  
- ToDoリストを作ろうとしても、作成途中で手が止まってしまう人  
- タスクをこなせなかったとき、原因の振り返りが苦手な人  
- やる気はあるけど、何から手をつけるべきか分からない人

---

## ■ サービスの利用イメージ

このアプリでは、「わける → えらぶ → ふりかえる」のサイクルを回すことで、日々のタスクを実行に移しやすくします。

1. タスクを登録する  
2. 必要に応じてタスクを分割する（3つ程度の入力欄が出現）  
3. 実行したタスクには完了チェック。スキップしたタスクはあとで分割を提案  
4. 朝・夜のタイミングで、できたこと・できなかったことを簡単に振り返る  
5. 表示されるタスクの数は上限を決めておき、然に「今やること」へ集中できるようにする

失敗を「根性が足りない」と責めるのではなく、「タスクの分け方が足りなかった」と考え直せるようにしたいです。

---

## ■ ユーザーへの届け方

日常的に使いやすくしたいので、スマートフォンでも使いやすいUIを目指したいです。  
完成したらSNSなどで紹介したいと思っています。

---

## ■ 差別化ポイント・推しポイント

一般的なToDoアプリと違って、「タスクを分割すること」に注目している点が特徴です。  
また、できなかった理由を分析して、再チャレンジにつなげる考え方もこのアプリの強みだと思います。
- 期限やジャンルなどの分類や入力項目をあえて設定せず、ユーザーの認知負荷を下げて「今できること」に集中しやすくしている  
- タスクを決められないときはAIが分割・所要時間・ゴールイメージを提示し、考えることに疲れたユーザーの助けになる

---

## ■ 実装したい機能（アイデア段階含む）

### ▼ MVP

- ユーザー登録・ログイン機能（Deviseなどを使う予定）  
- タスクの登録・表示・編集・削除  
- タスクを分割して登録できる機能
- タスクを決められないときAIに提案してもらう機能
- 表示されるタスク数に上限を設けて、今やることに集中しやすくする仕組み
- タスクの完了チェックと、振り返り用メモの記録  
- タスク一覧での簡単な検索（Hotwireを使う予定）
- 朝・夜の振り返りログインを記録して、習慣化をサポートする機能（カレンダーに印が付く程度）
- ログイン数に応じてトークン使用可能ポイントが付く機能
- 未実施・スキップしたタスクに対してタスク分割を提案する機能
- タスクの実行状況と振り返りメモを元にAIから週次アドバイスを貰える機能

### ▼ 本リリースで実現できたらうれしい機能

- 完了したタスクをスキルツリーのように表示する機能（構想中）  
- 自分の成長をSNSなどでシェアできる機能
- 未ログインをLINEで通知する機能

---

## ■ 技術的な実装について（現時点で考えていること）

- フロント:Hotwire（Turbo / Stimulus）
- サーバサイド:Ruby on Rails
- API:openaiapi
- スマホ対応はレスポンシブデザインで対応する方向で考えています  
- CSSフレームワーク:Tailwind
