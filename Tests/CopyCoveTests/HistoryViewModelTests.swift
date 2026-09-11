import Combine
import CopyCoveCore
import Foundation

func historyViewModelTests() {
    func makeItem(_ i: Int) -> ClipItem {
        ClipItem(id: UUID(), kind: .text, createdAt: Date(), fingerprint: "f\(i)",
                 text: "t\(i)", imageFileName: nil)
    }
    func makeStore(count: Int) -> HistoryStore {
        let storage = InMemoryStore()
        let items = (0..<count).map(makeItem)
        storage.saveItems(items.reversed()) // 最新在前
        return HistoryStore(storage: storage)
    }

    runTest("初始选中第一条") {
        try expectEqual(HistoryViewModel(store: makeStore(count: 3)).selectedIndex, 0)
    }
    runTest("向下移动") {
        let vm = HistoryViewModel(store: makeStore(count: 3))
        vm.moveSelection(1)
        try expectEqual(vm.selectedIndex, 1)
    }
    runTest("到底后循环回第一条") {
        let vm = HistoryViewModel(store: makeStore(count: 3))
        vm.moveSelection(1); vm.moveSelection(1); vm.moveSelection(1)
        try expectEqual(vm.selectedIndex, 0)
    }
    runTest("在第一条向上移动循环到最后一条") {
        let vm = HistoryViewModel(store: makeStore(count: 3))
        vm.moveSelection(-1)
        try expectEqual(vm.selectedIndex, 2)
    }
    runTest("列表清空后选中复位") {
        let storage = InMemoryStore()
        let store = HistoryStore(storage: storage)
        let vm = HistoryViewModel(store: store)
        store.add(makeItem(1))
        store.add(makeItem(2))
        vm.moveSelection(1)
        try expectEqual(vm.selectedIndex, 1)
        store.removeAll() // 触发 items 更新
        try expectEqual(vm.selectedIndex, 0)
    }
}
