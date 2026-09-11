// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "CopyCove",
    platforms: [.macOS("26.0")],
    targets: [
        // 核心逻辑库（监听/存储/粘贴等，全部纯系统框架）
        .target(name: "CopyCoveCore", path: "Sources/CopyCoveCore"),
        // App 入口
        .executableTarget(name: "CopyCove", dependencies: ["CopyCoveCore"], path: "Sources/CopyCove"),
        // 轻量测试运行器（CLT 无 XCTest/Testing，自研极简 harness）
        .executableTarget(name: "CopyCoveTests", dependencies: ["CopyCoveCore"], path: "Tests/CopyCoveTests"),
    ]
)
