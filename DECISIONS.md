# Decisions

記錄關鍵架構選擇與背後理由(避免之後忘了為什麼這樣寫)。

## MVVM,不用 VIPER / Coordinator

- 專案 1100 行,3 個 view controller。VIPER / Clean Architecture 切五層對這個規模是負擔
- MVVM 把業務邏輯從 VC 抽出已經夠用,測試也方便(VM 都接 protocol)
- 將來若擴張到多人合作或頁面數變多,可以再把 navigation 拆到 Coordinator

## Repository protocol + Firestore impl

- VC / VM 不直接碰 `Firestore.firestore()`,改注入 `OrderRepository` protocol
- 好處:swap 成 mock 做單元測試;將來換 backend(REST、其他 BaaS)只動 impl
- 用 async/await 而非 Combine — 看起來更線性,Swift 5.5+ 就有,不依賴 Combine

## Money 用 Decimal,不用 Double

- 金額計算如果用 Double 會有浮點誤差(例如 `45.0 * 3 = 134.99999...`)
- `Decimal` 是 Swift 內建精確型別
- 字串 → Money 的 parse 跟回寫 Firestore 用的 `formatted/storageString` 都收斂在 `Money` 內,呼叫端不重複處理

## Firestore 資料仍存字串,不存數字 / enum raw type

- 跟既有資料相容(舊文件 price 是 "$45.00")
- 強型別在 Swift layer 解釋 — 規格 enum 用 `rawValue == "正常糖"` 等中文字串對應 Firestore 既有欄位
- 缺點:Firestore 那端做數字統計要 parse;但目前不需要

## 規格用 enum,不用字串

- 規格(Tall / 半糖 / 少冰...)從 `UISegmentedControl.titleForSegment` 拿字串很容易因 storyboard 改字串而跟 server 對不上
- enum + `allCases` 自動跟 segmented control 順序對應,順序 / 拼字錯誤 compile-time 抓

## Anonymous Auth(MVP),不一開始上 Apple / Google Sign-In

- 把 Firestore Security Rules 設成 per-user(`uid == request.auth.uid`)就需要 auth
- Anonymous 對 user 零 friction,uid 是真的(每台裝置不同)
- 缺點:重灌 app 拿不回舊訂單。要解這個就要實名登入 + 把 anon uid link 過去(Roadmap 上)

## 保留 Storyboard,但 cell 與細節 VC 用程式碼覆寫

- 動 storyboard XML 風險高(merge conflict、靜態檢查弱)
- 但既有 segue / static cells / outlets 整個拔掉成本太大
- 折衷:storyboard 留著,cell 用 `awakeFromNib` 把 subviews 清空後重畫,outlet 變成 dummy
- Programmatic 新增的頁(Receipt / EditOrder)直接純程式碼,不進 storyboard

## Hero card 用 tableHeaderView,不用第 1 個 static cell

- MenuDetailVC 的 storyboard 第 1 個 cell 是「圖+資訊」,但 static cell 改 layout 很卡(constraint 動不掉)
- 把第 1 cell 高度設 0 隱藏,新建 `heroCard` 設 `tableView.tableHeaderView = container`
- 高度在 `viewDidLayoutSubviews` 用 `systemLayoutSizeFitting` 計算,viewDidLoad 算的話 view.bounds.width 還沒準

## 表單 cell 元件用 `willDisplay` 動態調 constraint constant,不重畫

- MenuDetailVC 的姓名 / 大小 / 糖 / 冰 / 加料 是 storyboard 5 個 static cell
- 加 card view 後元件相對 contentView 16pt margin = card 邊緣 0pt → 貼邊
- 重畫 5 個 cell 工作量大;改 storyboard XML 風險高
- 解:`willDisplay` 內遍歷 `cell.contentView.constraints`,把 leading 16 → 32、trailingMargin 8 → 16,讓元件相對 card 內縮 16pt

## AppTheme 集中色彩 / 字型 / 圓角 / 陰影

- `colorLiteral` 散落不同 VC 維護地獄
- `AppTheme` 用 `enum` namespace,所有 VC 與新元件統一引用
- 配色改一次全 app 同步;將來上 dark mode 也只動這一個檔

## PaddedLabel 子類,不用 UIView 包 UILabel

- 價格膠囊需要文字 + 內邊距 + 圓角
- UIView 包 UILabel 要兩層約束,不必要
- UILabel 子類覆寫 `intrinsicContentSize` / `drawText(in:)` / `layoutSubviews` 算 capsule 圓角,單一元件

## 編輯訂單支援改杯數 → Firestore schema 加 `quantity` + `unitPrice`

- 早期 schema 只存 `price` 字串(`"TWD 90"`),沒留 quantity / unit price → 編輯時無法重算 total,所以 EditOrderVC 刻意省略數量欄位
- 修法選項:
  - **A**:擴充 schema,加 `quantity: Int?` + `unitPrice: String?` 兩個 optional 欄;`placeOrder` 寫入,`updateOrder` 重算 total
  - **B**:不動 schema,編輯時從 `ProductCatalog` 反查 unit price(用 `drinkName` 當 key)
- 選 A,理由:結構乾淨、編輯時不依賴靜態 catalog、未來 catalog 漲價也不會回頭算錯歷史單
- 兩欄設成 `optional` 而非 required,讓舊文件(沒這兩欄)還能正常解出 `OrderData`;EditVM 內 fallback 三段:document `unitPrice` → catalog 反查 → 整單 `price`(假設 quantity=1)
- `quantity` 用 number 存(不像其他欄位都字串):跟「Firestore 資料仍存字串」那條的取捨不同 — quantity 是純計數,沒有單位或顯示格式議題,直接存 Int 更省心,parse 也少一層

## `OrderListViewModel` 拆 sync `removeLocally` + async `deleteRemote`

- VM 對外有三個 method:`delete(at:) async throws`(原 API,給單元測試)、`removeLocally(at:) -> String?`(sync)、`deleteRemote(id:) async throws`(async)
- 動機:UITableView 的 batch update(`deleteRows` / `insertRows` / `reloadRows`)是 sync — 一呼叫 UIKit 同 turn 內就驗證 `numberOfRowsInSection` 是否跟動畫一致;若 data source 改動包在 `Task { await ... }` 裡,就算 await 的第一行是 sync,也要跨 run loop tick 才執行 → 驗證當下資料源還是舊長度 → crash
- 拆 sync / async 是設計選擇而不只 bug 修法:
  - **sync API 處理 UI invariant**:呼叫端要在同一 run loop 內把資料源跟 UI 同步,沒得 await
  - **async API 處理 I/O**:網路慢、可能失敗,跟 UI 解耦
- `delete(at:)` 保留兩段組合的便利版,讓不需要立即 UI 更新的呼叫端(測試、後續批次刪除)可以一行寫完
- 反例:很多 sample code 把 sync data 改動跟 async network 都包在同一 async func,VC 直接 `Task { await vm.delete(...); tableView.deleteRows(...) }` — 看起來乾淨,但同樣有 race;或更糟,先 `deleteRows` 再 `await` 出 inconsistency crash。詳 `bugs.md`「左滑刪除訂單 crash」

## 圖片用 `.scaleAspectFit` 不用 `.scaleAspectFill`

- 商品列表用 fill(統一視覺,可接受裁切)
- 商品詳細 hero 用 fit(產品圖看完整不裁,代價是兩側留白)
- 訂單頁 banner GIF 用 fill(裝飾性,裁切無妨)
- 視 context 取捨,不一律
