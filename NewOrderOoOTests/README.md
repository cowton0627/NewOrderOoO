# NewOrderOoOTests

單元測試。Mock + tests 已經寫好,但**還需要在 Xcode 加 unit test target** 才能跑。
程式碼用 `@testable import NewOrderOoO`,所以只能跟 Xcode test target 配,不能單獨 build。

## 加 test target 步驟(Xcode UI 操作,~30 秒)

1. 開 Xcode → 左側選最上層 **NewOrderOoO** project(藍色那個)
2. 中間 **TARGETS** 區下方 **+** 按鈕 → 跳出視窗 → 上方分頁選 **Test** → 點 **Unit Testing Bundle** → Next
3. 設定:
   - Product Name: `NewOrderOoOTests`
   - Target to be Tested: `NewOrderOoO`
   - Language: Swift
   - 其他預設 → Finish
4. Xcode 會自動建一個 `NewOrderOoOTests/` 資料夾(跟這個資料夾路徑可能不同)跟一個範例 `NewOrderOoOTestsTests.swift`
5. 把那個範例檔**刪掉**(右鍵 → Delete → Move to Trash)
6. 把 **這個資料夾內** 的這四個 `.swift` 檔拖到 Project navigator 的 NewOrderOoOTests group 內
   - 拖入時跳出視窗:**勾選** Add to targets: `NewOrderOoOTests`,**取消勾選** `NewOrderOoO`(這些只屬於 test target)
   - 不要勾「Copy items if needed」(已在對的位置了)
7. 把 `README.md` 也加進去(optional,加進去 group 但不要勾任何 target)

## 跑測試

⌘+U 或 **Product → Test**。底部 navigator 切到 ◇ Test navigator 看結果。

## 已涵蓋的測試

- **MoneyTests** — Decimal 精度、parse 各種格式、`*` 運算、ISO / storage 字串
- **MenuDetailViewModelTests** — 價格計算、`OrderError.missingName / .invalidPrice`、空白姓名 trimming、repository 錯誤傳遞
- **OrderListViewModelTests** — load(空 / 多筆 / error)、delete optimistic + 失敗時不 rollback、無 id 訂單早 return 不打 repo、avatar 穩定性
- **EditOrderViewModelTests** — 空白姓名 throw、白空格 trim、所有參數正確傳給 repo、repo 錯誤傳遞、initialOrder 暴露給 VC prefill

## 未涵蓋(可後續補)

- `FirestoreOrderRepository` 的 integration test(需要 Firebase emulator)
- UI test(`XCUITest` 需要另外加 UI test target)
- `MenuListViewModel`(目前邏輯太薄,沒什麼可測)
