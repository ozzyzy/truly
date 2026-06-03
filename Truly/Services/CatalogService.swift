import Foundation

final class CatalogService {

    static let shared = CatalogService()

    /// Loaded once from disk on first access, then cached for the app's lifetime.
    lazy var actions: [ActionItem] = {
        guard let url = Bundle.main.url(forResource: "actions", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([ActionItem].self, from: data)) ?? []
    }()
}
