import TVServices

/// Fills the Top Shelf (shown when Clock Face is in the Home Screen's top row) with
/// upcoming reminders, or the next race. The app writes the entries and their card
/// images into the shared App Group container; this just reads them.
final class ContentProvider: TVTopShelfContentProvider {
    override func loadTopShelfContent() async -> (any TVTopShelfContent)? {
        guard let directory = TopShelfEntry.directory,
              let data = try? Data(contentsOf: directory.appending(path: TopShelfEntry.indexFileName)),
              let entries = try? JSONDecoder().decode([TopShelfEntry].self, from: data),
              !entries.isEmpty else { return nil }

        let items = entries.map { entry -> TVTopShelfSectionedItem in
            let item = TVTopShelfSectionedItem(identifier: entry.id)
            item.title = entry.title
            item.imageShape = .hdtv
            item.setImageURL(directory.appending(path: entry.imageFileName), for: [.screenScale1x, .screenScale2x])
            if let url = URL(string: entry.url) {
                item.displayAction = TVTopShelfAction(url: url)
                item.playAction = TVTopShelfAction(url: url)
            }
            return item
        }

        let section = TVTopShelfItemCollection(items: items)
        section.title = entries.first?.sectionTitle ?? "Upcoming"
        return TVTopShelfSectionedContent(sections: [section])
    }
}

/// Mirrors `TopShelfEntry` in the app (Services/TopShelfPublisher.swift).
struct TopShelfEntry: Decodable {
    static let appGroupID = "group.gowtham.Clock-Face"
    static let indexFileName = "entries.json"

    let id: String
    let title: String
    let sectionTitle: String
    let imageFileName: String
    let url: String

    static var directory: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appending(path: "TopShelf", directoryHint: .isDirectory)
    }
}
