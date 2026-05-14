# Privacy / 隱私說明

NewOrderOoO 是一個個人作品集展示用的 iOS 飲料訂購 demo app。本文件說明:

1. 本 repository 本身的內容
2. App 在實際被執行 (使用者自行 clone、自行建立 Firebase project 並 build) 時,會處理哪些資料

---

## 1. 本 repository 不包含個資

公開 repo 中**不包含**任何使用者個人資料、訂單紀錄、Firebase 設定檔、或可識別第三方的內容。

`GoogleService-Info.plist` (Firebase 本機設定) 已列入 `.gitignore`,只追蹤範本 `GoogleService-Info.example.plist`。

---

## 2. App 執行時會處理的資料

當你 clone 此 repo、建立自己的 Firebase project 並執行 app 時,以下資料會被處理。**所有資料只存於你自己的 Firebase project,不會回傳給本 repo 作者。**

| 資料 | 來源 | 用途 | 儲存位置 |
| --- | --- | --- | --- |
| Firebase Auth 匿名 UID | Firebase Authentication 自動產生 | 區分不同裝置 / 不同使用者的訂單 | Firebase Authentication |
| 訂購人姓名 | 使用者於 app 內輸入 | 顯示於訂單 | Cloud Firestore (`orderList`) |
| 飲料品項與規格 (大小 / 糖 / 冰 / 加料 / 數量) | 使用者於 app 內選擇 | 訂單內容 | Cloud Firestore (`orderList`) |
| 訂單建立時間 | App 自動 (server timestamp) | 訂單排序 | Cloud Firestore (`orderList`) |

### 不會收集的資料

- ❌ Email / 電話 / 真實姓名 (除非使用者自願在「訂購人姓名」欄輸入)
- ❌ 位置 / GPS
- ❌ 裝置識別碼 (IDFA / IDFV)
- ❌ 聯絡人 / 行事曆 / 相機 / 麥克風 / 相簿
- ❌ 健康 / 動作資料
- ❌ 任何分析 / 廣告 / 追蹤 SDK 資料

App 在 `Info.plist` 中也未宣告任何隱私權限 (NSCameraUsageDescription 等),因為這些權限完全沒被使用。

### 通知 (Local notifications)

App 啟動時會請求 **通知授權** (`UNUserNotificationCenter.requestAuthorization`),用途是在下單成功 3 秒後顯示一則本地通知 (「訂購成功」)。

- 這是 **本地** 通知,完全在裝置端排程,不經過任何 server 或第三方 push service
- 通知內容僅為固定字串,**不包含**訂單內容、姓名、價格等個資
- 拒絕授權不影響下單功能,只是不會看到通知
- 隨時可在 iOS **設定 > 通知 > 沏光 (NewOrderOoO)** 關閉

---

## 3. 第三方服務

App 透過 Firebase iOS SDK 與下列 Google 服務互動:

- **Firebase Authentication** (Anonymous sign-in)
- **Cloud Firestore** (訂單儲存)

這些服務由 Google 經營,使用條款與隱私政策見:

- https://firebase.google.com/support/privacy
- https://policies.google.com/privacy

實際資料的擁有者 (Data Controller) 是「執行 app 並建立 Firebase project 的人」,而不是本 repo 的作者。

App 內 **未**整合 Crashlytics、Analytics、Performance Monitoring、Remote Config、Ads 等其他 Firebase 模組。

---

## 4. 資料保留與刪除

- App 內支援左滑刪除個別訂單 (Firestore 文件會被立刻刪除)
- 完整清空可直接在 Firebase Console > Firestore Database 刪除 `orderList` collection
- 移除整個 Firebase project 即可清除所有 Auth 紀錄與資料

---

## 5. 適用範圍

本說明僅描述 NewOrderOoO 原始碼在 Firebase Anonymous Auth + Firestore 行為下的資料流。

若你 fork 本專案並:

- 加入其他第三方 SDK (Crashlytics、Analytics、廣告、推播等)
- 改接其他後端 / 加入登入機制
- 增加新欄位或新 collection

請自行更新隱私說明並遵守當地法規 (例如 GDPR、CCPA、台灣個資法)。

---

## 6. 聯絡方式

任何隱私相關問題請透過此 GitHub repository 的 issues 反映。
