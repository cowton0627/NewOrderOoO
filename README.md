# NewOrderOoO

iOS 飲料訂購 demo app — Swift / UIKit + Firebase Firestore,MVVM + Repository 架構,卡片化 UI。

## Features

- **商品列表**:12 杯飲料卡片化 cell,圖、品名、副標、描述、金色價格膠囊;按下有縮放回饋,下拉可重整,大標題 navigation
- **商品詳細**:hero card 大圖 + 品名 + 價格膠囊 + 規格(大小 / 糖量 / 冰塊 / 加料) + 數量 stepper;送出後浮動按鈕送單到 Firestore 並排程通知
- **訂單清單**:Firestore 同步;每筆顯示頭像 + 訂購人 + 飲料名 + 規格(`Tall · 半糖 · 少冰 · 珍珠`)+ 價格膠囊;左滑刪除 / 考慮;頂部 GIF banner
- **AppTheme**:色彩 / 字型 / 圓角 / 陰影集中,單一改動全 app 跟著變

## Tech stack

- Swift 5.9 / UIKit
- Storyboard + 程式碼混合 layout(cell 用程式碼覆寫)
- Firebase iOS SDK 11.x(Firestore / Auth / Storage),Swift Package Manager
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
| Domain | `DomainModels.swift` | `Money` (Decimal)、`DrinkSize` / `SugarLevel` / `IceLevel` / `AddOn` enum、`OrderInput`、`ProductCatalog` |
| Repository | `OrderRepository.swift` | protocol + Firestore 實作,async/await |
| ViewModel | `ViewModels.swift` | `MenuListViewModel` / `MenuDetailViewModel` / `OrderListViewModel` |
| Theme | `AppTheme.swift` | 設計系統(色彩、字型、圓角、陰影、`PaddedLabel` 膠囊) |
| Views | `Menu*VC` / `OrderDetail*VC` | UIKit thin shell |

## 開發

需要:

- Xcode 26+
- Firebase 專案,自備 `GoogleService-Info.plist` 放在 `NewOrderOoO/` 底下
- macOS 26+(Xcode 26 要求)

```bash
git clone <repo>
open NewOrderOoO.xcodeproj
```

第一次開啟 Xcode 會自動透過 SPM 解析 Firebase 等套件。選個 iPhone 模擬器後 ⌘+R。

### Firestore collections

- `orderList` — 訂單資料(每筆含 orderName / drinkName / drinkSize / sugar / cold / add / price)

## 專案結構

```
NewOrderOoO/
├── AppDelegate.swift / SceneDelegate.swift
├── Base.lproj/Main.storyboard
├── MenuTableViewController.swift       # 商品列表
├── MenuDetailTableViewController.swift # 商品詳細(下單)
├── OrderDetailTableViewController.swift# 訂單清單
├── DomainModels.swift                   # Money、規格 enum、OrderInput、ProductCatalog
├── OrderRepository.swift                # Firestore CRUD
├── ViewModels.swift                     # MVVM 三層
├── AppTheme.swift                       # 設計系統
├── ProductData.swift / OrderData.swift  # 資料 struct
└── Assets.xcassets/
```

## Roadmap

### 安全 / 必要
- [ ] 使用者登入(Firebase Auth)
- [ ] Firestore Security Rules — 目前 collection 任何人可讀寫
- [ ] 下單後 receipt / 確認頁
- [ ] 編輯訂單(目前只能刪)

### 體驗
- [ ] 購物車(一次下多杯不同規格)
- [ ] 訂單狀態 lifecycle(待製作 / 製作中 / 完成)
- [ ] 空狀態 / 錯誤狀態 UI
- [ ] Skeleton loading
- [ ] 自訂備註欄(去冰再加椰果...)

### 功能
- [ ] 推播:訂單完成可取餐
- [ ] Apple Pay
- [ ] 產品搜尋 / 分類
- [ ] 產品資料動態化(從 Firestore 拿,目前寫死在 `ProductCatalog`)
- [ ] 多語系

### 工程
- [ ] 單元測試(`OrderRepository` 與 ViewModel 都已可測)
- [ ] Crashlytics / Analytics
- [ ] CI/CD
- [ ] Dark Mode 全頁驗證

## License

MIT
