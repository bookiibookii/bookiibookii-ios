import Foundation

final class SearchHistoryManager {
    private let key = "group_search_history"
    private let maxCount = 10
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    func load() -> [String] { defaults.stringArray(forKey: key) ?? [] }

    func add(_ keyword: String) {
        let trimmed = keyword.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        var list = load()
        list.removeAll { $0 == trimmed }
        list.insert(trimmed, at: 0)
        defaults.set(Array(list.prefix(maxCount)), forKey: key)
    }

    func remove(_ keyword: String) {
        var list = load()
        list.removeAll { $0 == keyword }
        defaults.set(list, forKey: key)
    }
}
