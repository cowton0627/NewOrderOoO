# Runbook

部署、debug、維運常用流程。新人 onboarding 也看這個。

## 第一次設定 Firebase 專案

1. 到 [Firebase Console](https://console.firebase.google.com) 建專案
2. 加 iOS app(Bundle ID 必須跟 Xcode 一致:`ClcStudio.NewOrderOoO`)
3. 下載 `GoogleService-Info.plist`,放到 `NewOrderOoO/` 底下(同 `AppDelegate.swift` 那層)。這是本機 Firebase 設定檔,不要 commit 到 repo。build phase 會自動複製到 app bundle
4. 在 console 啟用:
   - **Authentication > Sign-in method > Anonymous** (打開 Enable)
   - **Firestore Database > Create database**(選 production mode)
5. 部署 security rules(下面)

> ⚠️ 沒啟用 Anonymous Auth 的話,app 一啟動就會 sign-in 失敗,所有 Firestore 操作會 throw `RepositoryError.notAuthenticated`

## 部署 Firestore Security Rules

需要 `firebase` CLI(`npm install -g firebase-tools`):

```bash
# 第一次:綁專案
firebase login
firebase init firestore   # 選現有 project,rules 檔指到 firestore.rules

# 之後每次 rules 改完
firebase deploy --only firestore:rules
```

## Build / Run

```bash
open NewOrderOoO.xcodeproj
# 選個 iPhone 模擬器 → ⌘+R
```

第一次開 Xcode 會自動 SPM resolve(可能要等 1-2 分鐘下 Firebase),完成後再執行。

## 命令列 build(CI 或不開 Xcode 用)

```bash
xcodebuild \
  -project NewOrderOoO.xcodeproj \
  -scheme NewOrderOoO \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.4.1' \
  -configuration Debug \
  -derivedDataPath /tmp/NewOrderOoO-build \
  build
```

列出可用模擬器:`xcrun simctl list devices available`

## 安裝 + 跑模擬器

```bash
DEVICE_ID="<UUID from simctl list>"
APP="/tmp/NewOrderOoO-build/Build/Products/Debug-iphonesimulator/NewOrderOoO.app"
BUNDLE_ID="ClcStudio.NewOrderOoO"

xcrun simctl boot "$DEVICE_ID"
open -a Simulator
xcrun simctl install "$DEVICE_ID" "$APP"
xcrun simctl launch "$DEVICE_ID" "$BUNDLE_ID"
xcrun simctl io "$DEVICE_ID" screenshot /tmp/sim.png
```

## 看 app log

```bash
xcrun simctl spawn "$DEVICE_ID" log show \
  --predicate 'processImagePath CONTAINS "NewOrderOoO"' --last 2m
```

過濾 crash:加 `| grep -iE "fatal|crash|exception"`。

## Crash log 詳細

```bash
ls -t ~/Library/Logs/DiagnosticReports/NewOrderOoO-*.ips | head -1 | xargs cat
```

stack trace 在 `threads[].frames[]` 裡,看 `sourceFile` 跟 `symbol`。

## 出怪事(build 過但 UI / SPM 行為怪)時的清快取流程

由溫和到激進,逐步試,不一定要每條都跑:

```bash
# 關 Xcode 後再跑
rm -rf ~/Library/Developer/Xcode/DerivedData/NewOrderOoO-*
rm -rf NewOrderOoO.xcodeproj/xcuserdata

# ⚠️ 下面這條會讓 git working tree 變 dirty,因為 Package.resolved 是 tracked。
# 只有 DerivedData / xcuserdata 都清完還是不對才動它;清完 Xcode 會重新解出新版本,
# 內容通常一樣只是時戳變,確認沒問題後可以 `git checkout -- ...Package.resolved` 還原。
rm -f NewOrderOoO.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved

open NewOrderOoO.xcodeproj
# 等左上角 SPM 解析完,⌘+Shift+K Clean,⌘+R 重跑
```

更深層的快取(`~/Library/Caches/com.apple.dt.Xcode/Cache.db*`、`~/Library/Caches/org.swift.swiftpm/repositories`、`~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex`)只有在前面都試過還不對才清;會 force re-download 所有 SPM 套件,慢。

如果 Firebase SDK 也要清:`File → Packages → Reset Package Caches`(在 Xcode UI)。

> 注意:如果錯誤是 `Missing package product 'FirebaseFirestoreSwift-Beta'` 之類已過期的 product,**先檢查 Xcode 開的是不是這份專案**,不是清快取問題。詳 `bugs.md`「Build 一直跳 Missing package product 清快取也沒用」。

## 驗證本地推播

下單成功會 3 秒後跳本地通知 banner。

- 第一次跑會跳系統授權對話框,要點「允許」才會收到
- 如果不小心拒絕、或要重測授權流程:
  ```bash
  # 完整 reset app 狀態(包含通知授權)
  xcrun simctl uninstall "$DEVICE_ID" "$BUNDLE_ID"
  # 重裝 + 重跑,授權對話框會重新出現
  ```
- 前景時 banner 會直接顯示在 app 上方(靠 `AppDelegate` 的 `UNUserNotificationCenterDelegate.willPresent` 回 `[.banner, .sound]`)
- 背景 / 鎖屏會走系統通知中心
- 觸發點:`MenuDetailTableViewController.scheduleSuccessNotification`(送單成功時呼叫)

> 通知授權 API 不需要在 `Info.plist` 加 key — `UNUserNotificationCenter.requestAuthorization` 是系統 API,只有 alert / sound / badge 三個 option,跟 Camera / Mic 等 capability 不同。

## Firestore 看資料

- Firebase Console > Firestore Database > Data tab
- Collection `orderList`,看每個文件的 `uid` 欄位
- 想用某個 uid 模擬查詢,用 console 的 query builder 加 `Where uid == <uid>`

## 在模擬器拿目前 anonymous uid

執行中的 app 沒有 UI 顯示 uid。要拿:
- 在 Xcode debugger 暫停 → console 打 `po Auth.auth().currentUser?.uid`
- 或加暫時 print 到 `AppDelegate.signInAnonymously` callback

## 加新檔到 Xcode project(命令列)

不開 Xcode 加新 Swift 檔需要動 `project.pbxproj` 4 處。流程:

1. 寫好新檔 `Foo.swift` 放對位置
2. 在 pbxproj 對應 4 處加 entry:
   - `PBXBuildFile` section
   - `PBXFileReference` section
   - 對應 `PBXGroup` 的 `children`
   - `PBXSourcesBuildPhase` 的 `files`
3. ID 用 `2938xxxx26CBxxxx0010E2A5` 格式生成兩個 unique 24-char hex

或最穩:直接在 Xcode UI 拖檔進去,自動處理。

## 部署到實機

不在 runbook 主要範圍(目前還是 dev demo)。signing 預設是 `Manual`,Simulator build 不需要 Team。

要 build 到實機時臨時切換:

1. Xcode → Target → **Signing & Capabilities** → 把 **Automatically manage signing** 打勾(等同 `CODE_SIGN_STYLE = Automatic`)
2. 選自己的 **Team**(Xcode 會把 `DEVELOPMENT_TEAM` 寫進 pbxproj)
3. ⌘+R build 到實機
4. **build 完務必把 signing 改回 Manual**(取消 Automatically manage signing 的勾)
5. **`git diff` 檢查 pbxproj 沒有殘留 `DEVELOPMENT_TEAM = ...;` 才能 commit**;Team ID 是個人 Apple Developer 識別碼,不該進公開 portfolio repo

詳 `bugs.md`「Xcode 自動把 DEVELOPMENT_TEAM 加回 pbxproj」。

## CI(GitHub Actions)操作

Workflow:`.github/workflows/ios.yml`(macos-15 runner / Xcode 16.x)。push / PR 到 `main` 自動跑 `xcodebuild test`,也可手動 `workflow_dispatch`。

```bash
# 看最近 runs
gh run list --workflow=ios.yml --limit 5

# 看單一 run 摘要
gh run view <run-id>

# 紅了只看失敗 step log(最常用)
gh run view <run-id> --log-failed

# 手動觸發一次(不用真 push)
gh workflow run ios.yml

# 等某 run 跑完(blocking)
gh run watch <run-id> --exit-status
```

或網頁:https://github.com/cowton0627/NewOrderOoO/actions

### CI 失敗時的常見原因

- **iOS deployment target 失配**:test target / 主 target 的 `IPHONEOS_DEPLOYMENT_TARGET` 比 runner 預裝的最新 iOS sim 高。詳 `bugs.md`「CI 紅:test target 的 iOS deployment target 比 runner sim 高」
- **runner image 無 destination 指定的 sim**:`xcrun simctl list devices available` 在 runner 跑出來才知道實際有什麼;workflow 用 `OS=latest` 不綁特定版本

### 下載 .xcresult 看細節

CI 上傳 test 結果為 artifact:

```bash
gh run download <run-id> -n test-results -D /tmp/ci-result
open /tmp/ci-result/TestResults.xcresult   # 用 Xcode 開
```

裡面有完整 build settings + test stack trace,比只看 log 直觀。

## 常用 git 動作

- 看哪些 commits 還沒 push:`git log origin/main..HEAD --oneline`
- push:`git push`(目前沒設遠端就先 `git remote add origin <url>`)
