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

```bash
# 關 Xcode 後再跑
rm -rf ~/Library/Developer/Xcode/DerivedData/NewOrderOoO-*
rm -rf NewOrderOoO.xcodeproj/xcuserdata
rm -f NewOrderOoO.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved

open NewOrderOoO.xcodeproj
# 等左上角 SPM 解析完,⌘+Shift+K Clean,⌘+R 重跑
```

如果 Firebase SDK 也要清:`File → Packages → Reset Package Caches`(在 Xcode UI)。

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

不在 runbook 範圍(目前還是 dev demo)。要簽證書 + provisioning profile,用 Xcode 自動 signing 即可。

## 常用 git 動作

- 看哪些 commits 還沒 push:`git log origin/main..HEAD --oneline`
- push:`git push`(目前沒設遠端就先 `git remote add origin <url>`)
