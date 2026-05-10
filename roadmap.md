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

- [ ] 單元測試:`OrderRepository` 與 ViewModel 已注入式設計可 mock,但 0 個 test
- [ ] Crashlytics / Analytics
- [ ] CI/CD(GitHub Actions / Xcode Cloud)
- [ ] Dark Mode 全頁驗證
- [ ] `.gitignore`(目前沒設,`xcuserdata` 等容易被誤 track)
- [ ] 把 hardcoded 的中文文案集中到 `Localizable.strings`

## Maybe(構想)

- [ ] 把 storyboard 完全拿掉,全程式碼 / 改 SwiftUI
- [ ] 店家後台(Firestore + 不同 collection 給管理者)
- [ ] 訂單分享連結(Universal Link)
