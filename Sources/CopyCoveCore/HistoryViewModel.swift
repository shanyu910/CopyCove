import Combine
import Foundation

public final class HistoryViewModel: ObservableObject {
    @Published public private(set) var items: [ClipItem]
    @Published public var selectedIndex: Int = 0

    private var cancellable: AnyCancellable?

    public init(store: HistoryStore) {
        items = store.items
        cancellable = store.$items
            .sink { [weak self] newItems in
                guard let self else { return }
                self.items = newItems
                if self.selectedIndex >= newItems.count {
                    self.selectedIndex = 0
                }
            }
    }

    /// 上/下移动选择，列表两端循环
    public func moveSelection(_ delta: Int) {
        guard !items.isEmpty else { return }
        selectedIndex = (selectedIndex + delta + items.count) % items.count
    }
}
