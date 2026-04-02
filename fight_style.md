1. 有陣容狀態：【系統已就緒】(System Ready)
視覺情境： 深黑背景下，卡片邊緣被一圈電漿綠 (Plasma Green) 的流光環繞，像是數據正在高速傳輸。

頂部標籤 (Status)： * 文案： RUNNING // 陣容載入中

位置： 卡片左上角，搭配一個微小的閃爍綠點。

核心數據 (Power)： * 文案： 戰力值：[ 479 ]

字體： 採用 Digital Clock (電子管/時鐘風格)，數字間有微弱的網格線感。

位置： 卡片正中央上方。

次要資訊 (Matchmaking)： * 文案： 目標匹配：戰力 460+ 的對手

位置： 數據下方，字體縮小，帶有掃描線特效。

操作按鈕 (Action Button)： * 文案： ENGAGE / 開始對戰

設計： 半透明玻璃質感，底部透出微弱綠光。

交互細節： 點擊瞬間，按鈕向後方噴射出「光粒粒子 (Particles)」，模擬噴射引擎啟動感。

2. 無陣容狀態：【異常警示】(System Warning)
視覺情境： 卡片整體籠罩在淡淡的熔岩紅 (Lava Red) 霧氣中，背景佈滿了傾斜 45 度的 CRITICAL 或 EMPTY 浮水印，營造迫切感。

頂部標籤 (Status)： * 文案： ALERT // 檢測到陣容空缺

位置： 卡片左上角，搭配紅色警示方塊。

視覺中心 (Warning Icon)： * 設計： 一個精細的三角形幾何警告標誌，緩緩繞著 Y 軸旋轉。

位置： 卡片中央，取代戰力數字。

提示文案 (Instruction)： * 文案： ERROR: 尚未配置球員，請先前往陣容設定

位置： 警告標誌下方，採用打字機效果 (Typewriter effect) 循環顯示。

操作按鈕 (Action Button)： * 文案： DEPLOY / 前往設定

設計： 帶有紅色「呼吸燈」光暈，忽明忽暗（頻率 1.5s）。

交互細節： 點擊時，整個卡片會產生微弱的震動感 (Haptic feedback)，強調修正錯誤的必要性。

＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝＝
為了達到這種「科技感」，在 Flutter 開發時你可以這樣組合：
元件名稱		推薦套件 / 屬性									視覺目的
流光邊框		CustomPainter + SweepGradient					實現邊緣緩緩流動的螢光綠光流。
毛玻璃底色	BackdropFilter(filter: ImageFilter.blur)		營造高級的半透明玻璃擬態感。
數字時鐘		Google Fonts: Orbitron 或 Share Tech Mono		建立極客科技風的字體視覺。
噴射特效		Confetti 或 Lottie								點擊按鈕時噴射粒子的動畫回饋。
背景浮水印	Transform.rotate + Opacity						建立「警告」字樣傾斜排列的底紋。