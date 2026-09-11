import AppKit
import CopyCoveCore
import Foundation
import ServiceManagement

let args = Set(CommandLine.arguments)

// 登录项自检（自动化验证用）：注册/注销后直接退出，不进入 App 主循环
if args.contains("--register-login-item") || args.contains("--unregister-login-item") {
    let register = args.contains("--register-login-item")
    print("SELFTEST: 开始\(register ? "注册" : "注销")登录项…")
    do {
        if register {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
        print("SELFTEST: OK 登录项\(register ? "注册" : "注销")成功")
        exit(0)
    } catch {
        print("SELFTEST: FAIL \(error.localizedDescription)")
        exit(1)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
