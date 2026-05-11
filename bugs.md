# Bugs / 踩坑紀錄

按發生時間排序,記錄症狀 + 根因 + 解法,避免下次再撞。

## Firebase 10.29 + Xcode 26 編譯失敗:`ABSL_CONST_INIT`

- **症狀**:升級 macOS / Xcode 後,build 跳 `ABSL_CONST_INIT` macro 編譯錯誤(`error: 'attribute(const_init)' attribute may not be used on global variables`)
- **根因**:Firebase 10.x 的 abseil-cpp 跟新 Clang 不相容
- **解**:升級 Firebase iOS SDK 到 11.x;pbxproj `minimumVersion = 11.0.0`
- **連帶**:Firebase 11 移除了 `FirebaseFirestoreSwift` / `FirebaseStorageSwift`,Swift API 已併入主 module。要 `import FirebaseFirestore` 而非 `FirebaseFirestoreSwift`

## Xcode UI 還顯示舊 SPM 殭屍錯誤

- **症狀**:升級 Firebase 後 issue navigator 還掛 `Missing package product 'FirebaseFirestoreSwift-Beta'`
- **根因**:Xcode UI 跟 SPM 解析狀態不同步,DerivedData / xcuserdata 殘留
- **解**:關 Xcode → 刪 `~/Library/Developer/Xcode/DerivedData/<proj>-*` + `xcuserdata` + `Package.resolved` → 重開

## GIF 動畫只跑第一幀就停了

- **症狀**:訂單頁 banner GIF 第一次顯示後就靜止
- **根因**:`CGAnimateImageDataWithBlock` callback 內用 `self.animeImgView`(weak outlet IUO)
  - 第一幀觸發時 outlet 暫時 nil(因為我搬動 imageView 到新 container 的瞬間)
  - 我的 crash fix 設 `stop.pointee = true`,把整個動畫關了
- **解**:不靠 weak outlet,controller 自己持有 `bannerImageView` strong property,callback 寫到它

## App crash:line 144 nil unwrap

- **症狀**:進訂單頁 crash,`Fatal error: Unexpectedly found nil while implicitly unwrapping an Optional value` 在 `self.animeImgView.image = ...`
- **根因**:同上(weak outlet 在 view 移動時 nil),IUO `!` force unwrap 直接 crash
- **解**:`[weak self]` + `guard let imgView = self?.animeImgView else { stop.pointee = true; return }`

## tableHeaderView 高度算錯,內容被擠扁

- **症狀**:Hero card 在 viewDidLoad 算 fitted size 後設 `tableView.tableHeaderView = container`,但畫面上文字區大幅縮水
- **根因**:viewDidLoad 時 `view.bounds.width` 不準(view 還沒 layout)
- **解**:把 `systemLayoutSizeFitting` 計算搬到 `viewDidLayoutSubviews`,並加 height diff 防無限循環:
  ```swift
  if abs(header.frame.height - fitted.height) > 0.5 {
      header.frame = CGRect(...)
      tableView.tableHeaderView = header
  }
  ```

## Storyboard 元件貼齊 card 邊緣

- **症狀**:詳細頁姓名 / 大小 / 糖量等元件貼在白色 card 左邊
- **根因**:Card view 縮 16pt(`leadingAnchor + 16`),但 storyboard 元件相對 contentView leading 也是 16pt → 元件落在 card 邊緣 0pt
- **解**:`willDisplay` 內把 storyboard 元件的 leading constant 16 → 32、trailingMargin 8 → 16

## storyboard 留下空白 cell

- **症狀**:詳細頁底下有一格空 cell
- **根因**:Storyboard 第 7 個 cell 是 44pt 預留空白(原作者習慣)
- **解**:`staticHeights[6] = 0` 隱藏

## 截圖時剛好截到啟動白屏

- **症狀**:`xcrun simctl launch` 後立刻 screenshot,只截到狀態列 + 全白
- **根因**:Launch screen 還沒過去,view 還沒 ready
- **解**:`sleep 3` 以上(冷啟比想像久)

## scaleAspectFill 把產品圖中段切掉

- **症狀**:商品詳細 hero 用 `.scaleAspectFill` 後,直立 / 帶設計字樣的圖被裁掉一塊
- **根因**:Fill 為填滿固定高度,不在乎內容構圖
- **解**:詳細頁改 `.scaleAspectFit` + 加大 height(從 180 → 300)讓圖夠大但不裁;留白用 `tertiarySystemFill` 背景襯不顯髒

## Firestore 文件少一個 uid 欄位,加 Auth 後拿不到舊單

- **症狀**:加 Anonymous Auth + per-user query 後,舊測試訂單看不到
- **根因**:舊 Firestore 文件沒 `uid` 欄位(後來才加的),`whereField("uid", isEqualTo: uid)` 自然查不到
- **解**:加 `migrateLegacyOrdersIfNeeded()`,進訂單頁時(VM.load 開頭)全 fetch 後對沒 uid 的文件 `updateData(["uid": currentUid])`,並用 UserDefaults flag 確保只跑一次
- **連帶**:如果已 deploy security rules 把寫入限 owner-only,migration 會被擋。要先暫時放寬 rules 或在 console 手動補欄位
- **後續(公開 portfolio 版)**:為避免公開 demo 把陌生 uid 的舊資料拉進自己帳號,`migrateLegacyOrdersIfNeeded` 已從 `VM.load` 移除,`FirestoreOrderRepository` 改空 no-op;Mock 與 protocol 留著只為了測試相容,`OrderListViewModelTests` 反過來驗它不被呼叫

## 「載入失敗:尚未登入,請稍後再試」

- **症狀**:剛 launch 進訂單頁立刻跳這訊息,但不是每次都中
- **根因**:`AppDelegate.signInAnonymously` 是 async callback,如果 user 太快進訂單頁,`Auth.auth().currentUser?.uid` 還是 nil,Repository `currentUid()` throw `notAuthenticated`
- **解**:`currentUid()` 改 async,沒登入時自己 `await Auth.auth().signInAnonymously()` 主動觸發,等完成才回 uid
- **連帶**:如果 Firebase Console 沒啟用 **Authentication > Sign-in method > Anonymous**,sign-in 會失敗 → 統一 throw `RepositoryError.signInFailed` 帶 user 友善的提示訊息

## SourceKit 一直跳「No such module 'UIKit'」

- **症狀**:diagnostics 區一直紅字 `No such module 'UIKit'` / `No such module 'FirebaseAuth'`,但 `xcodebuild` 跑得過
- **根因**:SourceKit / IDE index 跟 SPM 解析有時間差,`/tmp/NewOrderOoO-build` 跟 Xcode 預設 DerivedData 路徑不同也會誤導
- **解**:忽略,只看 `xcodebuild` 的 `** BUILD SUCCEEDED **`;Xcode 重啟一次 index 會 catch up
