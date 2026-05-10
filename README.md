# NewOrderOoO

iOS 飲料訂購 demo app — Swift / UIKit + Firebase Firestore,MVVM + Repository 架構,卡片化 UI。

## Features

### 商品列表
- 12 杯飲料卡片化 cell:圖、品名、副標、描述、金色價格膠囊
- 按下有縮放回饋、下拉重整、大標題 navigation

### 商品詳細(下單)
- Hero card 大圖 + 品名 + 金色價格膠囊
- 規格選擇:大小 / 糖量 / 冰塊 / 加料(用 enum 驅動 segmented control)
- 數量 stepper,即時換算總額
- 浮動「送出訂單」按鈕,圓角 + 陰影
- 送出後排程本地通知

### 訂單確認(Receipt)
- 下單成功後跳到摘要頁:大綠勾勾、訂購人、飲料、規格、數量、總額
- 「查看所有訂單」走 navigation stack 重設;「再點一杯」popToRoot

### 訂單清單
- Firebase Firestore 同步,**只顯示當前使用者的訂單**(per-user scoped)
- 每筆顯示:頭像、訂購人、飲料名、規格 chip(`Tall · 半糖 · 少冰 · 珍珠`)、價格膠囊
- 左滑「刪除 / 考慮」action
- 點 cell 進入「編輯訂單」可改規格與訂購人
- 頂部 GIF banner 動畫
- 空 / 載入 / 錯誤狀態(可重試)

### 設計系統 / Auth
- `AppTheme` 集中色彩、字型、圓角、陰影
- Firebase Anonymous Auth 自動登入,搭配 Firestore Security Rules per-user 隔離

## Tech stack

- Swift 5.9 / UIKit
- Storyboard + 程式碼混合 layout(cell 與細節 VC 用程式碼覆寫)
- async/await + Task
- Firebase iOS SDK 11.x:Firestore / Auth / Storage
- Swift Package Manager
- iOS deployment target 14.5+
- Xcode 26+

## 架構

```
ViewController       <-- 純 UI 渲染、把 UIControl 值翻成 enum
      │
      ▼
ViewModel            <-- 業務邏輯、價格計算、validation
      │
      ▼
Repository (protocol) <-- 可 mock 用於測試
      │
      ▼
FirestoreOrderRepository (impl)
```

| 層 | 檔案 | 職責 |
|----|------|------|
| Domain | `DomainModels.swift` | `Money`(Decimal)、`DrinkSize` / `SugarLevel` / `IceLevel` / `AddOn` enum、`OrderInput`、`ProductCatalog` |
| Repository | `OrderRepository.swift` | `placeOrder` / `fetchOrders` / `deleteOrder` / `updateOrder`,async/await,自動注入 uid |
| ViewModel | `ViewModels.swift` | `MenuListViewModel` / `MenuDetailViewModel` / `OrderListViewModel` |
| Theme | `AppTheme.swift` | 設計系統(色彩、字型、圓角、陰影、`PaddedLabel` 膠囊) |
| Reusable views | `StatusOverlayView.swift` | 載入 / 空 / 錯誤狀態的全頁覆蓋 |
| Views (Storyboard) | `Menu*VC.swift` / `OrderDetailVC.swift` | 商品列表、商品詳細、訂單清單 |
| Views (Programmatic) | `ReceiptViewController.swift` / `EditOrderViewController.swift` | 訂單確認頁、編輯訂單頁 |

## 開發

### 需要

- Xcode 26+
- macOS 26+
- Firebase 專案,自備 `GoogleService-Info.plist` 放在 `NewOrderOoO/` 底下
- Firebase Console 啟用 **Authentication > Sign-in method > Anonymous**(否則 sign-in 會失敗,所有 Firestore 操作會 throw `notAuthenticated`)
- 部署 Security Rules:
  ```bash
  firebase deploy --only firestore:rules
  ```
  (要先 `firebase init firestore` 把專案綁好)

### 跑起來

```bash
git clone <repo>
open NewOrderOoO.xcodeproj
```

第一次開啟 Xcode 會自動透過 SPM 解析 Firebase 等套件。選個 iPhone 模擬器後 ⌘+R。

### Firestore schema

Collection: `orderList`

| 欄位 | 型別 | 說明 |
|------|------|------|
| `uid` | string | 文件擁有者(Anonymous Auth uid),Security Rules 過濾用 |
| `orderName` | string | 訂購人姓名 |
| `drinkName` | string | 飲料名稱 |
| `drinkSize` | string | `Tall` / `Grande` / `Venti` |
| `sugar` | string | `正常糖` / `半糖` / `無糖` |
| `cold` | string | `正常冰` / `少冰` / `去冰` |
| `add` | string | `珍珠` / `愛玉` / `仙草` |
| `price` | string | 總額(formatted ISO,如 `TWD 90`) |

### Security Rules 摘要(`firestore.rules`)

- `read` / `update` / `delete`:必須登入且 `resource.data.uid == request.auth.uid`
- `create`:必須登入、`request.resource.data.uid == request.auth.uid`、且必填欄位齊全

## 專案結構

```
NewOrderOoO/
├── AppDelegate.swift / SceneDelegate.swift
├── Base.lproj/Main.storyboard
├── MenuTableViewController.swift       # 商品列表
├── MenuDetailTableViewController.swift # 商品詳細(下單)
├── OrderDetailTableViewController.swift# 訂單清單
├── ReceiptViewController.swift         # 下單成功確認頁(programmatic)
├── EditOrderViewController.swift       # 編輯訂單(programmatic)
├── DomainModels.swift                   # Money、規格 enum、OrderInput、ProductCatalog
├── OrderRepository.swift                # Firestore CRUD + uid 注入
├── ViewModels.swift                     # MVVM 三層
├── AppTheme.swift                       # 設計系統
├── StatusOverlayView.swift              # 載入 / 空 / 錯誤狀態 view
├── ProductData.swift / OrderData.swift  # 資料 struct
└── Assets.xcassets/
firestore.rules                          # Firestore Security Rules
```

## Roadmap

### 體驗
- [ ] 購物車(一次下多杯不同規格)
- [ ] 訂單狀態 lifecycle(待製作 / 製作中 / 完成)
- [ ] Skeleton loading(目前是 spinner)
- [ ] 自訂備註欄(去冰再加椰果...)

### 功能
- [ ] 推播:訂單完成可取餐
- [ ] Apple Pay
- [ ] 產品搜尋 / 分類
- [ ] 產品資料動態化(從 Firestore 拿,目前寫死在 `ProductCatalog`)
- [ ] 多語系
- [ ] 帶身分的登入(Apple / Google),目前是 anonymous

### 工程
- [ ] 單元測試(`OrderRepository` 與 ViewModel 都已可測)
- [ ] Crashlytics / Analytics
- [ ] CI/CD
- [ ] Dark Mode 全頁驗證
- [ ] 加 `.gitignore`(目前沒設,`xcuserdata` 等容易被誤 track)

## License

MIT
