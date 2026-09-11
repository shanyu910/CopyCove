import Foundation

// CLT 环境没有 XCTest / swift-testing，这里是保持 TDD 循环的极简 harness。
// 安装 Xcode 后可平移回 XCTest（断言函数签名与 XCTAssertEqual 等对应）。

struct TestFailure: Error, CustomStringConvertible {
    let message: String
    var description: String { message }
}

enum MiniTest {
    static var passed = 0
    static var failed = 0
}

func runTest(_ name: String, _ body: () throws -> Void) {
    do {
        try body()
        MiniTest.passed += 1
        print("  ✅ \(name)")
    } catch {
        MiniTest.failed += 1
        print("  ❌ \(name)\n     \(error)")
    }
}

func expectEqual<T: Equatable>(_ actual: T, _ expected: T,
                               file: StaticString = #fileID, line: UInt = #line) throws {
    guard actual == expected else {
        throw TestFailure(message: "\(file):\(line) 期望 \(expected)，实际 \(actual)")
    }
}

func expectTrue(_ condition: Bool, _ message: String = "",
                file: StaticString = #fileID, line: UInt = #line) throws {
    guard condition else {
        throw TestFailure(message: "\(file):\(line) \(message)")
    }
}

func expectNil<T>(_ value: T?, file: StaticString = #fileID, line: UInt = #line) throws {
    guard value == nil else {
        throw TestFailure(message: "\(file):\(line) 期望 nil，实际 \(String(describing: value!))")
    }
}

func expectNotNil<T>(_ value: T?, file: StaticString = #fileID, line: UInt = #line) throws {
    guard value != nil else {
        throw TestFailure(message: "\(file):\(line) 期望非 nil")
    }
}
