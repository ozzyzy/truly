import Foundation
import Combine

final class PreferenceStore: ObservableObject {

    @Published private(set) var likedActionIds:  Set<String> = []
    @Published private(set) var hiddenActionIds: Set<String> = []

    @Published var hasSeenSwipeHint: Bool {
        didSet { UserDefaults.standard.set(hasSeenSwipeHint, forKey: swipeHintKey) }
    }

    private let likedKey     = "truly.liked.v1"
    private let hiddenKey    = "truly.hidden.v1"
    private let swipeHintKey = "truly.swipeHintShown"

    init() {
        hasSeenSwipeHint = UserDefaults.standard.bool(forKey: swipeHintKey)
        load()
    }

    func isLiked(_ id: String)  -> Bool { likedActionIds.contains(id) }
    func isHidden(_ id: String) -> Bool { hiddenActionIds.contains(id) }

    func toggleLike(_ id: String) {
        if likedActionIds.contains(id) { likedActionIds.remove(id) }
        else { likedActionIds.insert(id) }
        save()
    }

    func hide(_ id: String) {
        hiddenActionIds.insert(id)
        likedActionIds.remove(id)
        save()
    }

    func unhide(_ id: String) {
        hiddenActionIds.remove(id)
        save()
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: likedKey),
           let arr  = try? JSONDecoder().decode([String].self, from: data) {
            likedActionIds = Set(arr)
        }
        if let data = UserDefaults.standard.data(forKey: hiddenKey),
           let arr  = try? JSONDecoder().decode([String].self, from: data) {
            hiddenActionIds = Set(arr)
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(Array(likedActionIds)) {
            UserDefaults.standard.set(data, forKey: likedKey)
        }
        if let data = try? JSONEncoder().encode(Array(hiddenActionIds)) {
            UserDefaults.standard.set(data, forKey: hiddenKey)
        }
    }
}
