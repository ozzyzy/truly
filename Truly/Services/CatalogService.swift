import Foundation

final class CatalogService {
    func loadActions() -> [ActionItem] {
        guard let url = Bundle.main.url(forResource: "actions", withExtension: "json"),
              let data = try? Data(contentsOf: url) else { return [] }
        return (try? JSONDecoder().decode([ActionItem].self, from: data)) ?? []
    }
}
