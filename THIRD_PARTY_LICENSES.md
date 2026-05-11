# Third-Party Licenses

NewOrderOoO 透過 Swift Package Manager 引入 Firebase iOS SDK,以下是直接相依套件與主要 transitive 相依套件的授權資訊。

完整、與當前 lockfile (`Package.resolved`) 完全對應的授權文件可於 Xcode `Project Settings → Package Dependencies` 中,點各套件查看 LICENSE。

---

## Direct dependency

### Firebase iOS SDK

- 來源:https://github.com/firebase/firebase-ios-sdk
- 授權:Apache License 2.0
- 版本:11.x (詳細版本以 `Package.resolved` 為準)
- 本專案使用的子 module:
  - `FirebaseAuth` (Anonymous sign-in)
  - `FirebaseFirestore`
  - `FirebaseStorage` (linked but currently unused)

完整授權:https://github.com/firebase/firebase-ios-sdk/blob/main/LICENSE

---

## Transitive dependencies

下列套件由 Firebase iOS SDK 透過 SPM 自動引入。版本由 Firebase iOS SDK 的相依範圍決定。

| Package | License | Repo |
| --- | --- | --- |
| abseil-cpp-binary | Apache License 2.0 | https://github.com/google/abseil-cpp-binary |
| grpc-binary | Apache License 2.0 | https://github.com/google/grpc-binary |
| leveldb | BSD-3-Clause | https://github.com/google/leveldb |
| nanopb | zlib License | https://github.com/nanopb/nanopb |
| GoogleUtilities | Apache License 2.0 | https://github.com/google/GoogleUtilities |
| GoogleDataTransport | Apache License 2.0 | https://github.com/google/GoogleDataTransport |
| GoogleAppMeasurement | Google APIs Terms of Service | https://github.com/google/GoogleAppMeasurement |
| GTMSessionFetcher | Apache License 2.0 | https://github.com/google/gtm-session-fetcher |
| Promises | Apache License 2.0 | https://github.com/google/promises |
| SwiftProtobuf | Apache License 2.0 | https://github.com/apple/swift-protobuf |
| InteropForGoogle | Apache License 2.0 | https://github.com/google/interop-ios-for-google-sdks |
| AppCheck | Apache License 2.0 | https://github.com/google/app-check |

> 此列表為主要 transitive 相依套件,實際解出的全部套件以 `Package.resolved` 為準。

---

## Apple Platform Frameworks

下列由 Apple 提供的 framework 不在此第三方授權列表中,使用條款依據 Apple Developer Program License Agreement 及各 framework 的標頭授權:

- UIKit
- Foundation
- XCTest
- ImageIO (用於 GIF 動畫)
- UserNotifications (尚未實作,roadmap 項目)

---

## 文字 / 字型

App 內所有顯示文字目前以 hardcoded 繁體中文出現於 source code,使用系統內建字型 (`UIFont.systemFont`,`SF Pro` family on iOS),未隨 app 打包任何第三方字型檔案。
