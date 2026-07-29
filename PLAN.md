# 記帳 iOS App — 前置作業與開發規劃

## Context

使用者是第一次寫 iOS app，想做一個記帳軟體，分成「日常記帳」與「旅遊分帳」兩大模組。目前 `/Users/jean/CodePractice/DualTally` 是空目錄，尚未建立任何專案。使用者的目標是：
1. 了解需要哪些前置作業（環境、帳號、外部服務）
2. 釐清需求規格中模糊的地方
3. 得到一個可執行的開發規劃
4. 不打算上架 App Store，但會推上 GitHub，需要一個 repo 名稱

本文件是給第一次寫 iOS app 的人看的完整前置準備 + 規格釐清 + 開發路線圖。透過與使用者確認，以下規格已定案：

- **日常記帳**：單一幣別（不用跨幣別加總）；可用餘額 = 預算 − 全部支出（含未付款；**已歸還的墊付除外**）；「當月」依使用者自訂的「**每月起算日**」界定（不一定是 1 號）；支出可標記「**墊付**」並於墊付管理畫面勾選歸還；列表另提供「**日曆瀏覽模式**」點日期看當日明細/帶入日期新增；**不記錄通用收入**（充當預算＝調預算、墊付還款＝勾歸還，皆已涵蓋）；另外需要一個 **鎖定畫面小工具**，只顯示日常記帳當月剩餘可用餘額的數字（旅遊記帳不需要小工具）
- **旅遊記帳**：帳本設定**預設幣別**，每筆支出**可逐筆各自選幣別**；結算時每筆用「該筆支出當天」的匯率從各自幣別換成結算幣別；匯率有網路時自動抓取並快取在手機內，抓取失敗則手動輸入；成員可標記「**已付清**」（當場結清者不納入轉帳建議）；帳本詳情可**點 Day N 看當日全員支出**；結算用「債務簡化演算法」呈現最少轉帳次數

---

## 一、前置作業（開始寫 code 之前要準備的東西）

### 1. 硬體 / 系統需求
- 需要一台 **Mac**（iOS 開發只能在 Mac 上進行，無法在 Windows/Linux 上用 Xcode）
- macOS 版本需能安裝最新版 **Xcode**（App Store 免費下載）；建議先到 App Store 更新 Xcode 到最新穩定版
- 若要在實機（自己的 iPhone）上測試，需要一條傳輸線或同網段的無線偵錯，以及在 iPhone 上開啟「開發者模式」。**這個選項預設是隱藏的、要先跟 Xcode 連過一次才會出現**，正確順序是：
  1. 用傳輸線把 iPhone 接上 Mac，手機上會跳出「信任這台電腦」，選信任
  2. 打開 Xcode 專案，在上方裝置選單選到你的 iPhone 當作執行目標
  3. 按下 Run（⌘R）讓 Xcode 嘗試安裝到手機上，這時 Xcode 通常會跳出訊息說手機需要開啟開發者模式
  4. 這時候再去 iPhone 的「設定 > 隱私權與安全性」，最下面才會出現「開發者模式」這個選項，把它打開，手機會要求重新開機
  5. 重開機後手機會再跳一次確認視窗，按「開啟」，然後回 Xcode 再按一次 Run 就可以了
  - 如果第 2、3 步之前完全沒連過 Xcode，「開發者模式」選項就是找不到的，這是正常現象，不是設定錯誤

### 2. 帳號準備
- **Apple ID（免費）**：登入 Xcode（Xcode > Settings > Accounts）即可用「Personal Team」簽署 App，足夠在自己的實機上安裝測試
- **付費的 Apple Developer Program（US$99/年）目前不申請**。付費加入跟「要不要上架 App Store」是兩件獨立的事 —— 它本質上是簽署與 capability 的會員資格，繳了費也可以完全不送審、純粹自己用。純粹自己開發 + 推 GitHub + 實機測試，免費 Apple ID 即可
  - 但要注意：免費簽署的 App 在裝置上每 **7 天**就會過期，需要重新用 Xcode 安裝一次（正常開發階段不影響，只是長期擺著不管的話要記得重裝）
  - ⚠️ 免費簽署會擋掉部分 capability（推播、iCloud、Sign in with Apple 等），**其中 App Groups 很可能無法使用**，這會直接影響鎖定畫面小工具。詳見「八、已知風險與待驗證事項」
- **開發者模式一旦開啟就是永久設定**：拔掉傳輸線、重新開機都不會關閉，只有手動去「設定 > 隱私權與安全性 > 開發者模式」關掉才會關。開發期間讓它一直開著即可，不用每次重設
- **GitHub 帳號**：用來建立 repo、推送程式碼

### 3. 需要事先研究/申請的外部服務
- **匯率 API（旅遊記帳結算功能需要）**：這是唯一需要額外申請的外部服務。因為使用者要的是「每筆支出當天的歷史匯率」且要支援 TWD，這裡有幾個候選，需要使用者在動工前挑一個並註冊：
  1. **台灣銀行 / 中央銀行公開資料**（data.gov.tw 上有「台灣銀行牌告匯率」歷史資料集）— 免費、官方、對 TWD 支援最好，缺點是資料格式較陽春、可能沒有你需要的所有外幣對外幣直接匯率（多半是「該幣別 vs TWD」）
  2. **exchangerate-api.com** — 有免費方案，需註冊拿 API key，需自行確認免費方案是否含「歷史日期查詢」與是否支援 TWD
  3. **currencyapi.com** — 類似，免費方案需註冊，需確認歷史查詢額度
  - 建議：因為使用者主要換算對象大概率是 TWD，先去試「台灣銀行/央行開放資料」，若涵蓋的幣別不夠再補一個國際 API 當備援。這件事我無法幫你在網路上確認最新的免費額度與條款，需要你自己申請帳號後回來一起確認 API 回傳格式，我再幫你寫串接程式碼。

### 4. GitHub Project 名稱
已選定 **`DualTally`** 作為 GitHub repo 名稱（呼應「日常記帳 + 旅遊分帳」雙模組的概念）。

---

## 二、技術選型建議

- **UI 框架：SwiftUI**（宣告式 UI，對新手比較好上手，官方主推方向）
- **本地資料庫：SwiftData**（Apple 在 iOS 17 推出的現代化本地持久化框架，取代 CoreData，寫法更簡單，完全離線可用，剛好符合旅遊記帳「無網路也要能用」的核心需求）
- **最低支援版本：iOS 17+**（SwiftData 的最低需求；因為不上架 App Store、只給自己/朋友用，不需要顧慮支援舊機型）
- **不需要後端伺服器**：所有資料存在裝置本機，符合離線需求；唯一的網路呼叫是旅遊記帳結算時抓取歷史匯率
- **雙語支援（中文／英文）**：App 介面文字需同時支援繁體中文與英文，依系統語言自動切換。以 SwiftUI 的 String Catalog（`Localizable.xcstrings`）做在地化，所有使用者可見字串走 `LocalizedStringKey`／`String(localized:)`，不寫死單一語言。金額、日期沿用 `Locale.current` 格式化。預設分類名稱與圖示為資料而非介面文字，seed 時以當下語言帶入
- **鎖定畫面小工具：WidgetKit**（iOS 16+ 支援的 Lock Screen Widget，依線框稿定案採用 `.accessoryCircular` 純數字呈現）。小工具跟主 App 是不同的 Extension Target，各自有獨立沙盒容器，要共用資料就必須設定 **App Group**（Signing & Capabilities > App Groups），並把 SwiftData 的資料庫檔案放在 App Group 的共用容器路徑下，小工具才讀得到主 App 記錄的最新可用餘額
  - 釐清：**「把小工具放上鎖定畫面」本身不需要 App Groups**，需要 App Groups 的是「小工具要顯示主 App 的資料」。純靜態或自己算得出來的小工具（例如倒數計時）不需要。本專案的小工具要顯示 SwiftData 裡的可用餘額，所以需要
  - App Groups 是 Xcode 專案設定、不需申請外部帳號，但**可能需要付費的 Apple Developer Program 才能啟用**，詳見「八、已知風險與待驗證事項」

---

## 三、需求規格細節（已與使用者確認）

### 日常記帳
- **月預算**：每個月手動設定一個總預算金額（不分類別），預設不自動從上月延續（每月獨立輸入）
- **每月起算日（預算週期）**：使用者可設定「一個月」的起算日，不一定是每月 1 號（例如設 5 號 → 當月週期為 7/05–8/04，適合對齊薪水日等情境）。起算日限 **1–28**（避開月底日數不足的邊界），為全 App 共用的單一設定。「當月」的支出範圍、可用餘額、已花費、月度復盤、報表的「月」粒度都以此週期界定，而非日曆月。此設定需存放在 **App Group 共用容器**（UserDefaults 或 SwiftData 設定物件），小工具才能用相同週期計算可用餘額
- **支出紀錄欄位**：金額、幣別（固定為帳本設定的單一幣別，記錄時不用再選）、用途類型（分類）、日期、是否已付款（true/false）、**是否為墊付（true/false）**、**幫誰墊付（純文字姓名，僅在「墊付」開啟時填寫）**、備註（選填）。**新增/編輯支出的畫面不需要「是否為衝動購物」欄位**，記帳當下不用去判斷這個
- **墊付（幫別人代墊）**：每筆支出可標記為「墊付」並填寫幫誰墊付。定案採「**整筆墊付**」語意——這筆記帳整筆都是幫對方代墊，非部分金額。墊付的錢視為已付款（你已把錢墊出去）
  - **計入規則**：一筆支出「計入我的花費」，除非它是墊付且對方已歸還（`isAdvancePayment && isRepaid`）。也就是**未歸還的墊付照算入我的支出**（含可用餘額、已花費、報表、衝動購物統計），**一旦歸還就從上述所有統計排除**（錢已收回，不算我的消費）——與可用餘額口徑一致
  - **墊付管理畫面（`AdvancePaymentView`）**：從列表右上角「墊付」進入，列出所有墊付紀錄（幫誰墊付、用途、日期、金額、是否已歸還），頂部顯示「尚未收回」總額。點選某筆標記為「已歸還」→ 寫回該筆 `Expense.isRepaid = true`、`repaidDate`、關閉墊付 → 該筆不再計入我的花費 → 可用餘額回升 → 呼叫 `WidgetCenter.shared.reloadTimeline` 刷新小工具
  - **資料欄位**：在 `Expense` 加 `isAdvancePayment: Bool`、`advancePaidForName: String?`、`isRepaid: Bool`、`repaidDate: Date?`（不另開 `@Model`，因為墊付本質是「某一筆支出」的屬性）
- **分類（用途類型）**：首次啟動 seed 一組預設清單（飲食、交通、娛樂、醫療、購物、居住、學習、其他），使用者可**自行增減**——透過預算設定頁進入 `CategoryManagementView` 新增自訂分類（名稱＋從精選 SF Symbol 挑一個圖示）或刪除任一分類（含預設）。刪除分類採 `.nullify`，既有支出不會被刪、只會變成未分類。以 App Group `UserDefaults` 的「已 seed」旗標避免使用者刪光預設後下次啟動又被塞回
- **支付方式（現金／信用卡…）**：與「用途分類」**互相獨立的第二個分類軸**，記錄每筆支出是怎麼付的。首次啟動 seed 預設「現金、信用卡」，使用者可**自行增減**——透過預算設定頁進入 `PaymentMethodManagementView` 新增（名稱＋SF Symbol）或刪除任一項（含預設）。資料上為 `Expense.paymentMethod`（`@Model PaymentMethod`，與 `ExpenseCategory` 結構平行），刪除同樣採 `.nullify`、既有支出只會變成未指定，並以獨立的「已 seed」旗標守護。與「已付款（`isPaid`）」是不同概念：`isPaid` 是錢是否已離開帳戶、`paymentMethod` 是用哪種方式付
- **當月報表**：
  - 當月預算（使用者設定值）
  - 可用餘額 = 預算 − 全部支出（含未付款，因為未付款視為已預定要花的錢；但**已歸還的墊付不計入**）
  - 已花費支出 = 只加總「已付款」的支出（同樣**排除已歸還的墊付**）
  - 「當月」的範圍以「每月起算日」界定的週期為準，而非日曆月
- **月度復盤**：「是否為衝動購物」這個標記**只在月底復盤畫面才會出現**，不會出現在平常新增/編輯支出的表單裡（記帳當下通常也不會覺得自己是衝動購物）。流程是：使用者進入復盤畫面 → 看到當月支出清單（每列格式為 `[核取框][日期] 用途 金額`）→ 逐筆勾選事後回顧覺得是衝動購物的項目 → App 存回該筆 `Expense` 的 `isImpulse` 欄位 → 統計「衝動購物金額 ÷ 當月全部支出金額」的佔比（採用全部支出而非只算已付款，因為復盤討論的是消費決策而非金流，之後可依實際使用感受調整）
- **報表（週/月/年）**：獨立的 `ReportView`，從列表畫面右上角「報表」進入，柱狀圖呈現，兩層切換都在同一畫面內完成，不另外開新畫面：
  1. **時間粒度**：週 / 月 / 年
  2. **檢視模式**：
     - 總支出：該時間粒度下每期的支出加總（例如選「月」時，看一個月內每週的總支出柱狀圖）
     - 分類佔比：柱狀圖依分類堆疊呈現，一眼看出每期哪個分類花最多
     - 依分類：先選一個分類（chips 單選），只看該分類在各期的金額變化趨勢
  - 用 **Swift Charts** 的 `BarMark` 實作（iOS 16+ 內建框架，不需額外套件），資料來源是 `Expense`，依 `date` 分組加總（週/月/年、總支出），以及依 `ExpenseCategory` 分組（分類佔比、依分類）
- **鎖定畫面小工具**：只給日常記帳用，顯示當月「可用餘額」這一個數字（跟報表用同一個計算公式：預算 − 全部支出），純數字呈現、不用互動；每次新增/編輯/刪除支出或修改當月預算後，主 App 要呼叫 `WidgetCenter.shared.reloadTimeline` 讓小工具即時更新
- **支出列表依日期分段**：列表模式的支出**以「日」為單位分段**（`List` 的 `Section`），每段段標為醒目的「日期（含星期）＋當日小計」，同一天的支出集中在同一段、日期不再只放在每列右側的小字。段依日期由新到舊排列，段內維持原有的時間順序。當日小計沿用 `DailyExpenseCalculator.countedTotal`（已歸還墊付不計），與 stat-card、日曆口徑一致。`ExpenseRow` 因此移除每列右側的日期（日期資訊已由段標／日曆選中日提供）
- **日曆瀏覽模式**：`DailyExpenseListView` 提供「列表 / 日曆」兩種瀏覽模式，右上角一顆工具列鈕來回雙向切換（列表模式顯示 `calendar` icon、日曆模式顯示 `list.bullet` icon，icon 永遠代表要切過去的那一邊）。頂部 stat-card 在兩種模式都固定在上方，只切換下半部。日曆為 `LazyVGrid` 月曆格：**有記帳的日子以小圓點標示**（僅標示有無，不在格內放金額），點選某天 → 下方顯示「當日小計 + 該日支出明細」，右上角「＋」開新增表單、**日期預先帶入該天**（＋放在當日小計列、與可點擊的支出列分開以免誤觸）。**切換月份可用左右滑動或上方箭頭鈕**（箭頭鈕給足夠的點擊範圍並與上方 stat-card 保持距離，避免誤觸到預算卡）。一致性註記：日曆用**日曆月**翻頁，與 stat-card 依「每月起算日」界定的週期無關——它是瀏覽輔助，不是餘額檢視
- **不記錄收入（設計決策）**：本 App **不提供通用收入記帳**。使用者實務上唯二會想記「進帳」的情境都已被現有機制涵蓋——（1）**充當預算**：直接設定/調整當月 `MonthlyBudget` 即可，收入等同預算；（2）**墊付還款**：在墊付管理畫面勾選「已歸還」，該筆即從所有統計排除、可用餘額自動回升，效果等同一筆進帳且更貼合語意。因此維持不變式 `可用餘額 = 預算 − 全部支出（已歸還墊付除外）`，不引入平行的收入概念以免整個口徑（報表、小工具）複雜化；偶發額外進帳的建議做法是「調高當月預算」

### 旅遊記帳
- **開帳本**：設定帳本名稱、**預設幣別**（例如 JPY——僅作為新增消費時的預設值，可逐筆更改，不再是整本固定單一幣別）、手動新增分攤人員清單（純文字姓名即可）
- **每筆消費紀錄**：項目名稱（例如「晚餐」「飯店」「交通票券」）、金額、**幣別（逐筆可各自選擇，預設帶入帳本預設幣別）**、日期、付款人（哪位成員先墊的）、分攤方式：
  - 均分：金額 ÷ 人數
  - 自訂：針對每個人輸入各自要分攤的金額（總和需等於該筆總金額，以「該筆消費的幣別」為單位）。輸入過程中即時顯示「合計 / 與總額的落差」，未對齊總額前「儲存」按鈕維持停用狀態，避免存入分攤總和對不上的紀錄
  - **改為逐筆各自幣別後**，同一本帳可混用多種幣別（例如日本行程中一筆記日幣現金、一筆刷卡記台幣），最後結算時再統一換算
- **逐日支出檢視**：`LedgerDetailView` 的消費列表以相對天數（Day 1、Day 2…）分段，**點選某個 Day 標頭 → 進入 `DayExpenseDetailView`，列出該日「所有成員」的支出明細與當日總額**（不限特定付款人，純粹回答「這天總共花多少、花在哪」）。混幣別的當日總額以帳本預設幣別換算（沿用與成員支出總覽/結算相同的「當天歷史匯率＋本機快取」機制；換算不到時退為各幣別分項小計）。此為與日常記帳「日曆日鑽取」對稱的瀏覽功能
- **成員支出總覽**：帳本詳情頁「成員支出總覽」入口，進入 `MemberSummaryView`，依 `ExpenseSplit` 加總「每個成員在這趟旅程的分攤總金額」（注意是依**分攤人**加總，不是依付款人）。因各筆可為不同幣別，總覽金額**以帳本預設幣別為顯示幣別**，用「每筆消費當天」的歷史匯率換算後加總（沿用與結算相同的換算機制與本機快取；換算不到時同樣可手動輸入匯率）
  - **成員「已付清」旗標（`Member.isSettled`）**：記帳當下常有人立刻把自己該分攤的金額還清（尤其別人先墊付時），因此成員支出總覽在每位成員旁提供一個「已付清」旗標，可勾選。標記後代表該成員在本趟的所有分攤都已當場結清；此狀態會帶入結算（見下）
  - 點進某個成員後進入 `MemberExpenseDetailView`，列出構成該總額的每一筆消費項目（項目名稱、日期、幣別、該筆中他的分攤金額），若該筆消費是他自己墊付的會額外標註「墊付」
- **結算流程**：
  1. 使用者選擇「結算幣別」（例如結算成 TWD 分給大家）
  2. **每一筆支出用「該筆支出自己的幣別 ＋ 發生當天的歷史匯率」換算成結算幣別**（每筆各自幣別，不再假設整本同一幣別；用當天匯率而非結算當天匯率統一換算）
  3. 換算後計算每個人的淨損益（付了多少 − 應分攤多少）
  4. **已付清（`isSettled`）的成員**：視為其所有分攤已於當場歸還給各筆的付款人——計算時將這些成員的分攤自淨損益中扣除、並同額回沖給對應付款人（等同該成員已把自己那份還給墊款人），使其淨額歸零。此類成員**仍會出現在結算清單**，標註「已付清（免再轉帳）」，但不納入債務簡化的轉帳建議
  5. 對其餘未結清成員，用「債務簡化演算法」（貪婪配對法：把最大債權人跟最大債務人互相沖銷，重複直到全部結清）算出最少轉帳次數的建議清單
- **匯率取得與快取**：
  - 有網路時，記帳當下或結算/總覽換算時自動呼叫匯率 API 抓取「特定日期、特定幣別對」的匯率並存在本機（SwiftData）快取，同一天同一貨幣對只抓一次
  - 抓取失敗（離線/API 掛掉）時，跳出手動輸入畫面讓使用者輸入當天匯率，一樣存入本機快取供之後使用

---

## 四、建議開發路線圖（循序漸進，先求可用再求完整）

1. **環境建置**：安裝/更新 Xcode、註冊 Apple ID 到 Xcode、建立空的 SwiftUI + SwiftData 專案、推第一版到 GitHub（含 `.gitignore`，用 GitHub 官方 Swift/Xcode 範本）
   - ✅ **已完成**：專案已建立（bundle id `com.yichenli.DualTally`、deployment target iOS 17.0、SwiftData 範本），App Groups 驗證通過（見第八節風險 1）
2. **App 骨架**：TabView 兩個分頁（日常記帳 / 旅遊記帳），兩分頁狀態互相獨立、可隨時切換
3. **日常記帳 — 資料模型**：`MonthlyBudget`、`ExpenseCategory`、`PaymentMethod`、`Expense`（SwiftData `@Model`，含 `category`／`paymentMethod` 關聯與墊付欄位 `isAdvancePayment`／`advancePaidForName`／`isRepaid`／`repaidDate`），以及「每月起算日」設定（存 App Group 共用容器，供小工具讀取同一週期）
4. **日常記帳 — UI**：設定當月預算與「每月起算日」、新增/編輯支出（含「墊付」開關＋幫誰墊付欄位）、列表頂部 stat-card（預算/可用餘額/已花費，依起算日週期計算）、墊付列標記、**列表/日曆兩種瀏覽模式切換**（日曆格圓點標示有記帳的日子，點某天看當日明細並可帶入日期新增）
5. **日常記帳 — 墊付管理**：`AdvancePaymentView`，列出未歸還/已歸還墊付與「尚未收回」總額，勾選歸還 → 關閉墊付、回補可用餘額、`WidgetCenter.shared.reloadTimeline` 刷新小工具
6. **日常記帳 — 復盤功能**：支出清單逐列（日期＋用途＋金額）勾選衝動購物、復盤統計畫面（當月範圍依「每月起算日」界定）
7. **日常記帳 — 報表畫面**：`ReportView`，週/月/年 × 總支出/分類佔比/依分類三種檢視，Swift Charts `BarMark` 實作（「月」粒度依起算日週期；已歸還墊付不計入）
8. **日常記帳 — 鎖定畫面小工具**：新增 Widget Extension Target、設定 App Group 共用 SwiftData 容器、實作 Timeline Provider 顯示可用餘額數字（依起算日週期計算）、確認主 App 資料變動後小工具會刷新（App Groups 已驗證可用，見第八節）
9. **旅遊記帳 — 資料模型**：`TravelLedger`（含預設幣別）、`Member`（含 `isSettled` 已付清旗標）、`TravelExpense`（含逐筆 `currency`）、`ExpenseSplit`、`ExchangeRateCache`
10. **旅遊記帳 — UI**：建立帳本、帳本詳情、新增分帳紀錄（逐筆選幣別＋均分/自訂切換＋自訂分攤加總即時驗證）
11. **旅遊記帳 — 成員支出總覽**：`MemberSummaryView`（依成員加總分攤金額，混幣別以帳本預設幣別換算顯示，每位成員含「已付清」旗標）與 `MemberExpenseDetailView`（單一成員的明細項目）
12. **旅遊記帳 — 結算**：串接匯率 API + 本機快取 + 手動輸入備援、逐筆各自幣別 × 當天匯率換算、已付清成員回沖、債務簡化演算法、結算結果畫面
13. **收尾**：中／英雙語在地化（`Localizable.xcstrings` String Catalog，補齊所有介面文字兩種語言）、README、基本單元測試（至少涵蓋可用餘額計算〔含墊付計入/排除、起算日週期〕、已付清回沖、債務簡化演算法等純邏輯部分）、資料匯出功能（CSV／JSON，見第八節風險 2）、確認 `.gitignore` 沒有把使用者本機資料庫檔案或 API key 推上去
    - 進度：日常記帳計算層的單元測試已於步驟 3–7 期間提前建立並通過（見第七節）；此步驟剩雙語在地化、旅遊側純邏輯測試、資料匯出與收尾檢查。
   - 註：介面字串從實作各畫面時就一律走 `LocalizedStringKey`／`String(localized:)`，收尾階段只是集中補齊 String Catalog 的兩語翻譯，避免最後回頭改寫大量硬編字串

---

## 五、專案目錄架構

```
DualTally/
├── DualTally.xcodeproj
├── DualTally/                          # 主 App Target
│   ├── DualTallyApp.swift              # @main App 進入點，設定 SwiftData ModelContainer（App Group 共用容器）
│   ├── Models/                         # SwiftData @Model
│   │   ├── MonthlyBudget.swift
│   │   ├── ExpenseCategory.swift
│   │   ├── PaymentMethod.swift         # 支付方式（現金/信用卡…），結構平行 ExpenseCategory
│   │   ├── Expense.swift               # 日常記帳：含 category/paymentMethod、isImpulse 與墊付欄位（isAdvancePayment/advancePaidForName/isRepaid/repaidDate）
│   │   ├── TravelLedger.swift          # 含預設幣別（僅為新增消費的預設值）
│   │   ├── Member.swift                # 含 isSettled 已付清旗標
│   │   ├── TravelExpense.swift         # 含逐筆 currency 欄位
│   │   ├── ExpenseSplit.swift
│   │   └── ExchangeRateCache.swift
│   ├── DailyExpense/                   # 日常記帳模組
│   │   ├── Views/
│   │   │   ├── DailyExpenseListView.swift  # 根畫面，含頂部 stat-card、報表/復盤/墊付入口、列表/日曆切換
│   │   │   ├── ExpenseCalendarView.swift    # 日曆瀏覽模式：月曆格圓點＋選中日明細＋帶入日期新增
│   │   │   ├── CategoryManagementView.swift # 分類管理：列出、新增（名稱＋SF Symbol）、刪除分類
│   │   │   ├── PaymentMethodManagementView.swift # 支付方式管理：列出、新增、刪除（結構平行分類管理）
│   │   │   ├── DailyExpenseSettingsView.swift # 預算/每月起算日設定，含分類管理入口
│   │   │   ├── AddEditExpenseView.swift
│   │   │   ├── MonthlyReviewView.swift     # 月度復盤（逐列日期＋用途＋金額，勾選衝動購物；依起算日界定當月）
│   │   │   ├── AdvancePaymentView.swift    # 墊付管理（列出墊付、勾選歸還 → 回補餘額並刷新小工具）
│   │   │   └── ReportView.swift            # 週/月/年 × 總支出/分類佔比/依分類，Swift Charts BarMark
│   │   └── ViewModels/
│   │       └── DailyExpenseViewModel.swift
│   ├── TravelSplit/                    # 旅遊分帳模組
│   │   ├── Views/
│   │   │   ├── LedgerListView.swift
│   │   │   ├── AddLedgerView.swift
│   │   │   ├── LedgerDetailView.swift      # 帳本內消費列表（Day N 分段可點選），成員支出總覽/＋新增/結算入口
│   │   │   ├── DayExpenseDetailView.swift   # 某一天全員支出明細＋當日總額（混幣別以帳本預設幣別換算）
│   │   │   ├── AddTravelExpenseView.swift  # 含自訂分攤逐人輸入 + 加總即時驗證
│   │   │   ├── MemberSummaryView.swift     # 依成員加總這趟旅程的分攤總金額
│   │   │   ├── MemberExpenseDetailView.swift # 單一成員的分攤明細，標註本人墊付項目
│   │   │   └── SettlementView.swift        # 結算結果（債務簡化演算法輸出）
│   │   └── ViewModels/
│   │       └── TravelLedgerViewModel.swift
│   ├── Services/
│   │   ├── ExchangeRateService.swift   # 匯率 API 串接 + 快取讀寫
│   │   └── DebtSimplifier.swift        # 債務簡化演算法（純邏輯，方便單元測試）
│   ├── Shared/
│   │   └── AppGroupConstants.swift     # App Group identifier、共用容器路徑、「每月起算日」共用設定的存取
│   ├── Localizable.xcstrings           # 中／英雙語 String Catalog（介面文字在地化）
│   └── Assets.xcassets
├── DualTallyWidget/                    # 鎖定畫面小工具 Extension Target
│   ├── DualTallyWidget.swift           # WidgetBundle / Widget 定義
│   ├── DailyBalanceProvider.swift      # TimelineProvider，讀 App Group 共用的 SwiftData
│   └── DailyBalanceWidgetView.swift    # .accessoryInline / .accessoryCircular 畫面
├── DualTallyTests/                     # 單元測試（已含 BudgetCycle/DailyExpense/Report 計算層；DebtSimplifier 待補）
│   ├── DebtSimplifierTests.swift
│   └── BalanceCalculationTests.swift
├── .gitignore                          # GitHub 官方 Swift/Xcode 範本
├── README.md
└── PLAN.md
```

- `Models/` 放所有 SwiftData `@Model`，主 App 與 Widget Extension 都會 import，資料庫檔案實體位置在 App Group 共用容器內
- `Services/DebtSimplifier.swift` 與 `Services/ExchangeRateService.swift` 的核心邏輯與 UI 分離，方便寫純邏輯單元測試
- `DualTallyWidget/` 是獨立的 Widget Extension Target，需在 Xcode 用 File > New > Target > Widget Extension 建立，並在 Signing & Capabilities 為主 App 與 Widget 都加上同一個 App Group

---

## 六、畫面清單與導覽流程

App 根畫面是 `TabView`，「日常記帳」與「旅遊記帳」兩個分頁各自維護獨立狀態、可隨時切換，兩邊本來就會同時被使用（例如同時在追蹤本月預算，也同時在記一趟進行中的旅程），不需要額外設計切換機制。

低保真線框稿（僅供確認佈局與跳轉關係，非最終視覺）：https://claude.ai/code/artifact/febc6fcc-8687-4828-9d02-5383f09246a1

線框稿定案的 UI 慣例（實作時依此為準）：

- **視覺樣式**：直接採用 SwiftUI 系統元件預設外觀（`List`、`Form`、系統色彩），已符合 Apple HIG，不另外設計視覺。報表的分類配色僅為示意，正式配色留待實作階段再定
- **轉場**：膠囊標籤的「Sheet」對應 `.sheet()`，「Push」對應 `NavigationStack` 推頁
- **日常記帳列表**：**只有「未付款」的列**在左側顯示一個空心圓點標記，已付款（多數情況）不顯示任何標記以減少視覺雜訊；未付款的支出仍看得出來
- **報表畫面**：兩排 segmented control 上下疊放，上排「週/月/年」、下排「總支出/分類佔比/依分類」；「總支出」模式底部顯示當期總額與較上期增減百分比（例如 `19,760 ▼8% 較上月`），「依分類」模式底部顯示該分類的期間均值（例如 `1,850 / 週`）
- **帳本詳情**：「成員支出總覽」是列表的第一列（非工具列按鈕）；底部兩顆按鈕並排 —— `＋新增`（外框樣式）／`結算`（實心樣式）；消費列左側顯示**付款人**頭像縮寫，日期以相對天數呈現（`Day 1`、`Day 2`）
- **成員支出總覽／成員明細**：頂部各有一個總計框（`本趟總支出 ¥52,000`／`總計 ¥24,600`）
- **自訂分攤驗證**：未對齊總額時底部驗證框整個標紅並顯示差額（例如 `合計 ¥50,000 · 尚差 ¥2,000`），同時停用「儲存」
- **結算畫面**：標題列右側顯示結算幣別（`→ TWD`）；每人淨損益以綠色（+）／紅色（−）區分

所有以 Push 進入的畫面，標題列左上角都有「‹ 上一頁名稱」返回按鈕，對應 SwiftUI `NavigationStack` 的預設行為。

### 日常記帳（Tab 1）

| 畫面 | 進入方式 | 說明 |
|---|---|---|
| `DailyExpenseListView` | 根畫面 | 無大標題（Tab 已標示）+ 頂部精簡 stat-card（預算/可用餘額/已花費，依起算日週期），下方支出列表**依日期分段**（段標＝日期＋當日小計，墊付列標「墊 ○○」），右上角「列表/日曆切換」＋「報表」「復盤」「墊付」入口，右下角＋新增 |
| `ExpenseCalendarView` | 列表右上角〈切換鈕〉 | 月曆格瀏覽模式，有記帳的日子標圓點，點某天顯示當日小計＋明細，＋在小計列帶入該日新增；**月份可左右滑動或箭頭鈕切換**；與列表雙向切換，stat-card 共用固定於上方 |
| `AddEditExpenseView` | Sheet ← 列表〈＋〉/ 日曆〈＋〉/ 點列表項目 | 金額、分類、**支付方式**、日期（日曆進入時帶入該天）、已付款、墊付（開啟才顯示「幫誰墊付」）、備註 |
| `DailyExpenseSettingsView` | Sheet ← 點 stat-card | 設定本週期預算、每月起算日，並提供「分類管理」「支付方式」入口 |
| `CategoryManagementView` | Push ← 預算設定〈分類管理〉 | 列出分類，右上角＋新增（名稱＋SF Symbol），滑動刪除；刪除採 nullify，既有支出變未分類 |
| `PaymentMethodManagementView` | Push ← 預算設定〈支付方式〉 | 列出支付方式，右上角＋新增（名稱＋SF Symbol），滑動刪除；刪除採 nullify，既有支出變未指定 |
| `ReportView` | Push ← 列表〈報表〉 | 週/月/年 × 總支出/分類佔比/依分類，三層切換都在同一畫面內完成（已歸還墊付不計） |
| `MonthlyReviewView` | Push ← 列表〈復盤〉 | 每列 `[核取框][日期] 用途 金額`，勾選寫回 `isImpulse`，底部統計佔比（當月依起算日界定） |
| `AdvancePaymentView` | Push ← 列表〈墊付〉 | 頂部「尚未收回」總額，每列 `[核取框][日期] 用途·幫誰墊付 金額`，勾選＝已歸還 → 關閉墊付、回補可用餘額、刷新小工具 |
| 鎖定畫面小工具 | 獨立 Widget Extension | 只顯示可用餘額數字 |

### 旅遊記帳（Tab 2）

| 畫面 | 進入方式 | 說明 |
|---|---|---|
| `LedgerListView` | 根畫面 | 帳本卡片列表（名稱/幣別/成員數），右下角＋新增帳本 |
| `AddLedgerView` | Sheet ← 列表〈＋〉 | 帳本名稱、預設幣別（新增消費時的預設值）、成員清單 |
| `LedgerDetailView` | Push ← 列表〈點選帳本〉 | 消費紀錄列表（以 Day N 分段，標頭可點選），頂部「成員支出總覽」入口，底部＋新增消費／結算 |
| `DayExpenseDetailView` | Push ← 帳本詳情〈點選 Day N 標頭〉 | 該日全員支出明細（項目/付款人/金額幣別）與當日總額（混幣別以帳本預設幣別換算，換算不到退為各幣別分項小計） |
| `AddTravelExpenseView` | Sheet ← 帳本詳情〈＋〉 | 項目名稱、金額、幣別（預設帶帳本預設幣別，可逐筆改）、日期、付款人、分攤方式（均分/自訂）；選「自訂」展開逐人金額輸入，即時顯示合計與總額落差，未對齊前「儲存」停用 |
| `MemberSummaryView` | Push ← 帳本詳情〈成員支出總覽〉 | 依 `ExpenseSplit` 加總每個成員的分攤總金額（依分攤人，非付款人；混幣別以帳本預設幣別換算顯示），每位成員旁「已付清」旗標可勾選 |
| `MemberExpenseDetailView` | Push ← 成員支出總覽〈點選成員〉 | 列出構成該成員總額的每一筆消費（含幣別），標註本人墊付的項目 |
| `SettlementView` | Push ← 帳本詳情〈結算〉 | 結算幣別選擇、每人淨損益（逐筆各自幣別×當天匯率換算）、已付清成員標註「已付清（免再轉帳）」、債務簡化演算法建議轉帳清單 |

---

## 七、驗證方式

- 每個階段完成後在 Xcode Simulator 跑起來手動測試對應功能
- 債務簡化演算法、可用餘額計算、報表分組加總（週/月/年、依分類）、成員分攤總金額計算等純邏輯建議寫 Swift Testing / XCTest 單元測試，用具體數字案例驗證（例如三人均分、多人不均分、含負數/四捨五入邊界）
  - **已提前落地（日常記帳計算層）**：`DualTallyTests` target 已建立（hosted unit-test、Swift Testing），涵蓋 `BudgetCycleCalculator`（起算日邊界／含括語意／clamp）、`DailyExpenseCalculator`（可用餘額 vs 已花費、墊付計入/排除、依人分組、衝動佔比、逐日）、`ReportCalculator`（視窗邊界、各範圍分桶、三種模式、已歸還墊付排除），共 27 個案例全數通過。旅遊側 `DebtSimplifier`／成員分攤與匯率邏輯仍留待步驟 13 補齊。
  - 執行：`xcodebuild test -scheme DualTally -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5'`
- 旅遊記帳的匯率快取與離線手動輸入，建議在 Simulator 上關閉網路（或用 Xcode 的 Network Link Conditioner）實際測試離線流程是否真的能繼續記帳與結算
- 鎖定畫面小工具：實機加入鎖定畫面測試（Simulator 對 Lock Screen Widget 的預覽有限，建議用實機鎖屏長按加入小工具確認），並實際新增一筆支出後回鎖定畫面確認數字有即時更新

---

## 八、已知風險與待驗證事項

### ✅ 風險 1（已解除）：App Groups 在免費 Personal Team 下可用

- **原本的疑慮**：免費 Apple ID 的「Personal Team」簽署會擋掉一批 capability（推播通知、iCloud、Sign in with Apple 等），擔心 App Groups 也在其中。主 App 與 Widget Extension 各自有獨立沙盒容器，沒有 App Group 就無法共用 SwiftData 資料庫，小工具會讀不到可用餘額，且此限制沒有繞道方案
- **注意範圍**：需要 App Groups 的是「小工具要顯示主 App 的資料」，不是「把小工具放上鎖定畫面」這個行為本身。純靜態或自行計算的小工具不受影響
- **驗證結果（2026-07-21，已完成）**：疑慮不成立。免費 Personal Team **可以**正常使用 App Groups
  - 在 Xcode 加入 App Groups capability 並填入 `group.com.yichenli.DualTally`，沒有出現任何錯誤
  - 跑 `xcodebuild -destination 'generic/platform=iOS' -allowProvisioningUpdates build` 實際做裝置簽署，`BUILD SUCCEEDED`，profile 正常產生
  - 用 `codesign -d --entitlements` 檢查簽署後的 binary，確認 `com.apple.security.application-groups` 有實際帶入。這是最終證據 —— entitlements 檔案存在只代表設定寫入，binary 帶得到才代表簽署真的通過
- **結論**：小工具**不需要**付費 Apple Developer Program，維持在路線圖「日常記帳 — 鎖定畫面小工具」該步（現為第 8 步）

### 風險 2：免費簽署每 7 天過期（影響長期日常使用）

- 免費簽署的 App 安裝到裝置後 **7 天**就會過期，過期後點開會閃退或跳出無法驗證的提示，需重新用 Xcode 連線按一次 Run 重裝
- **資料不會因為過期而遺失**：過期的是簽署憑證，不是 App 本身。App 的資料容器仍留在裝置上，用 Xcode 重裝（相同 bundle identifier）屬於覆蓋安裝，SwiftData 資料庫會保留
- **但以下情況資料會遺失**：手動從裝置刪除 App、變更 bundle identifier、或 Xcode 因簽署身分變動而要求先刪除再安裝
- **建議緩解措施**：因為這是要長期累積資料的記帳 App，建議在路線圖第 13 步「收尾」時補做一個**資料匯出功能**（匯出 CSV／JSON 到「檔案」App 或分享表單），確保任何情況下資料都能自行備份還原

### 待實作：回看過往週期（目前只顯示當前週期）

- **現況**：`DailyExpenseListView` 的 stat-card、列表模式都固定用 `BudgetCycleCalculator.currentCycle()`，只呈現「當前週期」的可用餘額／已花費與支出流水
- **落差**：支出以「該筆日期」歸屬週期，所以在新週期補記一筆屬於上一週期的支出（例如起算日 5 號，8/5 當天補記一筆日期 7/28 的支出 → 該筆歸入 7/5–8/4 週期）時，它雖然正確計入上一週期的統計，但**不會**出現在當前（8 月）週期的 stat-card 與列表中，使用者當下看不到自己剛補記的那筆
- **可見的地方**：日曆瀏覽模式按「日曆月」翻頁、顯示所有支出（不受週期限制），翻到 7 月即可看到該筆的圓點與明細——可作為暫時的查看途徑
- **待實作方向**：在 stat-card 或列表加上「上一／下一週期」切換（例如 stat-card 兩側 `‹ ›`），讓可用餘額、已花費、支出流水都能切到任一過往週期檢視；月度復盤與報表本身已含週期／時間粒度選擇，切換週期的入口可與其一致。歸屬邏輯（`BudgetCycleCalculator.cycle(containing:startDay:)`）不需改動，只需讓 UI 能選定要顯示的週期
- **歸類**：日常記帳 UI 增補，優先度中；不影響現有計算正確性，僅是可見性/瀏覽便利

### 待確認事項：匯率 API 尚未選定

- 第一節列出的三個候選（台銀／央行開放資料、exchangerate-api.com、currencyapi.com）都還沒註冊與確認免費方案條款
- 需確認：是否支援**歷史日期查詢**、是否涵蓋所需幣別（特別是 TWD）、免費額度上限
- **影響範圍**：只卡路線圖第 12 步（旅遊記帳結算）與成員支出總覽的混幣別換算（第 11 步可先做加總、換算後補），第 1～10 步都可以照常進行
