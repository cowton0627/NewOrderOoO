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
- **後續(公開 portfolio 版)**:為避免公開 demo 把陌生 uid 的舊資料拉進自己帳號,`migrateLegacyOrdersIfNeeded` 已**從 protocol 完全移除**(`VM.load` 不呼叫、`FirestoreOrderRepository` / Mock 都不再有此方法、相關 `migrateCalled` 測試 flag 一併刪掉)

## 「載入失敗:尚未登入,請稍後再試」

- **症狀**:剛 launch 進訂單頁立刻跳這訊息,但不是每次都中
- **根因**:`AppDelegate.signInAnonymously` 是 async callback,如果 user 太快進訂單頁,`Auth.auth().currentUser?.uid` 還是 nil,Repository `currentUid()` throw `notAuthenticated`
- **解**:`currentUid()` 改 async,沒登入時自己 `await Auth.auth().signInAnonymously()` 主動觸發,等完成才回 uid
- **連帶**:如果 Firebase Console 沒啟用 **Authentication > Sign-in method > Anonymous**,sign-in 會失敗 → 統一 throw `RepositoryError.signInFailed` 帶 user 友善的提示訊息

## SourceKit 一直跳「No such module 'UIKit'」

- **症狀**:diagnostics 區一直紅字 `No such module 'UIKit'` / `No such module 'FirebaseAuth'`,但 `xcodebuild` 跑得過
- **根因**:SourceKit / IDE index 跟 SPM 解析有時間差,`/tmp/NewOrderOoO-build` 跟 Xcode 預設 DerivedData 路徑不同也會誤導
- **解**:忽略,只看 `xcodebuild` 的 `** BUILD SUCCEEDED **`;Xcode 重啟一次 index 會 catch up

## Build 一直跳「Missing package product 'FirebaseFirestoreSwift-Beta'」清快取也沒用

- **症狀**:Xcode 跳 `Missing package product 'FirebaseFirestoreSwift-Beta'` / `'FirebaseStorageSwift-Beta'`。清 DerivedData、Xcode `Cache.db`、SPM `repositories` cache、`ModuleCache.noindex` 通通試過,重開 Xcode 還是錯;但命令列 `xcodebuild` 卻能 build 過
- **根因**:系統上有多份同名專案(`~/Desktop/NewOrderOoO`、`~/Downloads/NewOrderOoO-main`、`~/Library/Mobile Documents/.../NewOrderOoO`),Xcode UI 從 recent 或雙擊開到的是某份 Firebase 10 時代的舊 pbxproj(真的還有 `Swift-Beta` 引用),不是我們在維護的 Desktop 那份。命令列 `xcodebuild -project NewOrderOoO.xcodeproj` 在 Desktop dir 跑,讀的才是對的那份,所以過
- **線索**:DerivedData 資料夾名稱裡的 hash 是用「專案絕對路徑」算出來的。看到兩個 `<Project>-<hash>` 但 hash 不同 → 就是兩條路徑各自被 Xcode 開過。每個 DerivedData 的 `info.plist` 有 `WorkspacePath` 欄位,直接看就知道對應哪份專案:
  ```bash
  for dd in ~/Library/Developer/Xcode/DerivedData/<Project>-*; do
    plutil -extract WorkspacePath raw "$dd/info.plist"
  done
  ```
- **解**:在 Xcode 內 `File → Close Project` 關錯的那份,從 Finder 雙擊正確路徑的 `.xcodeproj`(或 `xed <絕對路徑>`)。確認 Xcode 標題列的路徑指到對的位置
- **預防**:同名專案的舊副本(GitHub 下載 ZIP、雲端備份)用完就刪,不要留在 `~/Downloads` 等容易被 macOS Spotlight / Xcode recent 索引到的地方

## Xcode 自動把 `DEVELOPMENT_TEAM` 加回 pbxproj

- **症狀**:已經把 `DEVELOPMENT_TEAM = <team_id>;` 從 pbxproj 拿掉、push 上 GitHub 之後,本機開 Xcode 一次,`git diff` 又看到 Team ID 跑回來。同時 `objectVersion` 可能也被升(如 52 → 54)
- **根因**:Code Signing Style 是 `Automatic`,Xcode 一打開專案就根據本機登入的 Apple ID 自動補 Team ID 進 target build settings(讓 signing 確保有 team 可用)
- **解**:target build settings 把 `CODE_SIGN_STYLE` 改成 `Manual`。Simulator build 不需要 Team(走 "Sign to Run Locally"),Manual 完全 OK;只有 build 到實機才需要,屆時臨時切回 Automatic + 選自己 team,build 完改回 Manual,別把 Team ID commit 進 git
- **連帶**:Xcode UI 的 Signing & Capabilities 分頁可能顯示 "Signing for "NewOrderOoO" requires a development team" 警告;Simulator build 可以忽略

## Manual signing 設一半 → 「requires a provisioning profile」

- **症狀**:Xcode 跳 `"NewOrderOoO" requires a provisioning profile. Select a provisioning profile in the Signing & Capabilities editor.`,連 Simulator build 都跑不起來
- **根因**:pbxproj 在「半邊改、半邊沒改」的狀態 — `CODE_SIGN_STYLE = Automatic` 但 `CODE_SIGN_IDENTITY = "Apple Development"` 且 `PROVISIONING_PROFILE_SPECIFIER = ""`(空字串)。Xcode 試圖 auto-resolve profile 但 specifier 是空的,UI 嚴格驗證直接報錯
- **解**:鎖死成 Simulator 友善設定:`CODE_SIGN_STYLE = Manual` + `CODE_SIGN_IDENTITY = "-"`(代表 "Sign to Run Locally",不需 team、不需 profile)。Debug 跟 Release 都要設
- **連帶**:實機 build 不會過(沒 profile)。要 build 到實機臨時切回 Automatic + 選 team,build 完務必改回 Manual + `"-"` 並 `git diff` 確認 Team ID 沒留下
