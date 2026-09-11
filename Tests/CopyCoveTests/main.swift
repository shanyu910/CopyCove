import CopyCoveCore
import Foundation

// 汇总运行所有测试；新增测试文件后在此登记
print("Running CopyCoveTests...")

relativeTimeTests()
clipItemBuilderTests()

print("\n\(MiniTest.passed) passed, \(MiniTest.failed) failed")
if MiniTest.failed > 0 { exit(1) }
