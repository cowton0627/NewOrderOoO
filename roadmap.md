# Roadmap

長期規劃與未做事項。已完成的功能放在 README,只在這裡留一份 Done 簡表給未來讀者看脈絡。

## Done

- [x] Firebase iOS SDK 升級 10.29 → 11.x(配合 Xcode 26 / 新 Clang 的 ABSL_CONST_INIT 問題)
- [x] 卡片化 UI:商品列表、商品詳細 hero card、訂單清單卡片
- [x] 抽 `AppTheme`(色彩 / 字型 / 圓角 / 陰影集中)
- [x] Domain Models:`Money`(Decimal)、規格 enum、`OrderInput`、`ProductCatalog`
- [x] Repository pattern(`OrderRepository` protocol + Firestore impl,async/await)
- [x] MVVM(三個 ViewModel)
- [x] Firebase Anonymous Auth + Firestore Security Rules(per-user scoped)
- [x] 載入 / 空 / 錯誤狀態 UI(`StatusOverlayView`)
- [x] 下單後 Receipt 確認頁
- [x] 編輯訂單(規格 + 訂購人)
- [x] App Icon (Three Pearls — 三顆 boba pearls 配蜂蜜金漸層)
- [x] `.gitignore` (Xcode / Swift / SPM 標準)
- [x] 單元測試:Mock + Money / 兩個 VM tests (Xcode test target 需手動加,詳 `NewOrderOoOTests/README.md`)

### 公開前處理(portfolio release prep)

- [x] `LICENSE` (MIT for code, assets 保留所有權利)、`PRIVACY.md`、`THIRD_PARTY_LICENSES.md`
- [x] 移除 `DEVELOPMENT_TEAM`,`CODE_SIGN_STYLE` 改 `Manual`,避免 Xcode 重新 inject 個人 Apple Team ID
- [x] Git history rewrite:統一 author 為 `cowton0627 <83654992+cowton0627@users.noreply.github.com>`,工作信箱不留歷史
- [x] 清掉同名專案的舊副本(Downloads ZIP / iCloud),避免 Xcode 開錯版本
- [x] `migrateLegacyOrdersIfNeeded` 從預設流程移除(改 no-op + 測試反向驗證),避免公開 demo 接管別人 uid 的舊資料
- [x] 移除 unused `FirebaseStorage` SPM 依賴

## Next(體驗)

- [ ] 購物車(一次下多杯不同規格)
- [ ] 訂單狀態 lifecycle(待製作 / 製作中 / 完成 / 取消)
- [ ] Skeleton loading(目前 spinner 是 placeholder)
- [ ] 自訂備註欄(像「少糖去冰再加椰果」)

## Later(功能)

- [ ] 推播:訂單完成可取餐
- [ ] Apple Pay
- [ ] 產品搜尋 / 分類
- [ ] 產品資料動態化(從 Firestore `products` collection 拿,目前寫死在 `ProductCatalog`)
- [ ] 多語系(i18n / l10n)
- [ ] 帶身分的登入(Apple / Google),目前是 anonymous;需要保留資料移轉機制讓 anon → 實名

## 工程 / 體質

- [ ] Crashlytics / Analytics
- [ ] CI/CD(GitHub Actions / Xcode Cloud)
- [ ] Dark Mode 全頁驗證
- [ ] 把 hardcoded 的中文文案集中到 `Localizable.strings`
- [ ] 補充更多測試:`FirestoreOrderRepository` 整合測試(用 Firebase Emulator)、UI test

## Maybe(構想)

- [ ] 把 storyboard 完全拿掉,全程式碼 / 改 SwiftUI
- [ ] 店家後台(Firestore + 不同 collection 給管理者)
- [ ] 訂單分享連結(Universal Link)
