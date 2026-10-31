// swift-tools-version: 5.9
// Chumbaq iOS SDK — Swift Package Manager manifest.
//
// Four products mirror the four Android SDK modules:
//
//   ChumbaqCore     — identity, events, deep links, offline queue, sessions.
//                     The minimal module: `.package(url: ...)` + `.product(name: "ChumbaqCore")`.
//   ChumbaqPush     — APNs push token registration. Depends on ChumbaqCore.
//   ChumbaqBanners  — native `BannerCarouselView` (UICollectionView). Depends on ChumbaqCore.
//   ChumbaqMessages — in-app message overlay. Depends on ChumbaqCore.
//
// Apps pick only the products they need; ChumbaqCore is the only mandatory one.
//
// Min iOS 14 — required for async/await, NWPathMonitor, modern UICollectionView.

import PackageDescription

let package = Package(
    name: "Chumbaq",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v14),
    ],
    products: [
        .library(name: "ChumbaqCore", targets: ["ChumbaqCore"]),
        .library(name: "ChumbaqPush", targets: ["ChumbaqPush"]),
        .library(name: "ChumbaqBanners", targets: ["ChumbaqBanners"]),
        .library(name: "ChumbaqMessages", targets: ["ChumbaqMessages"]),
    ],
    dependencies: [
        // No external dependencies — URLSession + Foundation only.
    ],
    targets: [
        // ── Core ───────────────────────────────────────────────────────
        .target(
            name: "ChumbaqCore",
            path: "Sources/ChumbaqCore"
        ),
        .testTarget(
            name: "ChumbaqCoreTests",
            dependencies: ["ChumbaqCore"],
            path: "Tests/ChumbaqCoreTests"
        ),

        // ── Push ───────────────────────────────────────────────────────
        .target(
            name: "ChumbaqPush",
            dependencies: ["ChumbaqCore"],
            path: "Sources/ChumbaqPush"
        ),
        .testTarget(
            name: "ChumbaqPushTests",
            dependencies: ["ChumbaqPush", "ChumbaqCore"],
            path: "Tests/ChumbaqPushTests"
        ),

        // ── Banners ────────────────────────────────────────────────────
        .target(
            name: "ChumbaqBanners",
            dependencies: ["ChumbaqCore"],
            path: "Sources/ChumbaqBanners"
        ),
        .testTarget(
            name: "ChumbaqBannersTests",
            dependencies: ["ChumbaqBanners", "ChumbaqCore"],
            path: "Tests/ChumbaqBannersTests"
        ),

        // ── Messages ───────────────────────────────────────────────────
        .target(
            name: "ChumbaqMessages",
            dependencies: ["ChumbaqCore"],
            path: "Sources/ChumbaqMessages"
        ),
        .testTarget(
            name: "ChumbaqMessagesTests",
            dependencies: ["ChumbaqMessages", "ChumbaqCore"],
            path: "Tests/ChumbaqMessagesTests"
        ),
    ]
)
