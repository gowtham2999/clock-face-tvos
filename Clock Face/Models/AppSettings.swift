import Foundation
import Observation

@Observable
final class AppSettings {
    private enum Keys {
        static let faceType = "faceType"
        static let myFaces = "myFaces"
        static let faceColors = "faceColors"
        static let theme = "theme"
        static let uses24HourTime = "uses24HourTime"
        static let chimeSource = "chimeSource"
        static let volume = "volume"
        static let pixelShiftEnabled = "pixelShiftEnabled"
        static let worldCities = "worldCities"
    }

    @ObservationIgnored private let defaults: UserDefaults

    /// The face currently shown on the Clock tab.
    var faceType: WatchFaceType {
        didSet { defaults.set(faceType.rawValue, forKey: Keys.faceType) }
    }

    /// The faces the user cycles through on the Clock tab, in order.
    private(set) var myFaces: [WatchFaceType] {
        didSet { defaults.set(myFaces.map(\.rawValue), forKey: Keys.myFaces) }
    }

    /// Chosen palette colour per face, keyed by face raw value.
    private var faceColorIDs: [String: String] {
        didSet { defaults.set(faceColorIDs, forKey: Keys.faceColors) }
    }

    var theme: AppTheme {
        didSet { defaults.set(theme.rawValue, forKey: Keys.theme) }
    }

    var uses24HourTime: Bool {
        didSet { defaults.set(uses24HourTime, forKey: Keys.uses24HourTime) }
    }

    var chimeSource: ChimeSource {
        didSet { defaults.set(chimeSource.rawValue, forKey: Keys.chimeSource) }
    }

    var volume: Double {
        didSet { defaults.set(volume, forKey: Keys.volume) }
    }

    /// Burn-in protection: nudges the face a few points every minute.
    var pixelShiftEnabled: Bool {
        didSet { defaults.set(pixelShiftEnabled, forKey: Keys.pixelShiftEnabled) }
    }

    /// Time zone IDs shown on the World tab, at most `WorldCity.maximumSelection`.
    private(set) var worldCityIDs: [String] {
        didSet { defaults.set(worldCityIDs, forKey: Keys.worldCities) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        faceType = defaults.string(forKey: Keys.faceType).flatMap(WatchFaceType.init(rawValue:)) ?? .analogClassic
        let storedFaces = (defaults.stringArray(forKey: Keys.myFaces) ?? []).compactMap(WatchFaceType.init(rawValue:))
        myFaces = storedFaces.isEmpty ? [.analogClassic, .sky, .essential, .tint, .flip] : storedFaces
        faceColorIDs = defaults.dictionary(forKey: Keys.faceColors) as? [String: String] ?? [:]
        theme = defaults.string(forKey: Keys.theme).flatMap(AppTheme.init(rawValue:)) ?? .dark
        uses24HourTime = defaults.bool(forKey: Keys.uses24HourTime)
        chimeSource = defaults.string(forKey: Keys.chimeSource).flatMap(ChimeSource.init(rawValue:)) ?? .watch
        volume = defaults.object(forKey: Keys.volume) != nil ? defaults.double(forKey: Keys.volume) : 1.0
        pixelShiftEnabled = defaults.object(forKey: Keys.pixelShiftEnabled) != nil
            ? defaults.bool(forKey: Keys.pixelShiftEnabled) : true
        let storedCities = (defaults.stringArray(forKey: Keys.worldCities) ?? []).filter { WorldCity.city(withID: $0) != nil }
        worldCityIDs = storedCities.isEmpty ? WorldCity.defaultSelection : storedCities

        if !myFaces.contains(faceType) {
            myFaces.insert(faceType, at: 0)
        }
    }

    // MARK: - Faces

    func color(for face: WatchFaceType) -> FaceColor? {
        let palette = face.palette
        let chosenID = faceColorIDs[face.rawValue]
        return palette.first { $0.id == chosenID } ?? palette.first
    }

    func setColor(_ color: FaceColor, for face: WatchFaceType) {
        faceColorIDs[face.rawValue] = color.id
    }

    func isInMyFaces(_ face: WatchFaceType) -> Bool {
        myFaces.contains(face)
    }

    func addToMyFaces(_ face: WatchFaceType) {
        guard !myFaces.contains(face) else { return }
        myFaces.append(face)
    }

    /// Removes a face from My Faces. The last remaining face can't be removed.
    func removeFromMyFaces(_ face: WatchFaceType) {
        guard myFaces.count > 1, let index = myFaces.firstIndex(of: face) else { return }
        myFaces.remove(at: index)
        if faceType == face {
            faceType = myFaces[min(index, myFaces.count - 1)]
        }
    }

    /// The face `offset` steps away from the current one in My Faces, wrapping around.
    func face(offsetBy offset: Int) -> WatchFaceType {
        guard let index = myFaces.firstIndex(of: faceType) else { return myFaces.first ?? faceType }
        let count = myFaces.count
        return myFaces[((index + offset) % count + count) % count]
    }

    // MARK: - World clock

    var worldCities: [WorldCity] {
        worldCityIDs.compactMap(WorldCity.city(withID:))
    }

    func isWorldCitySelected(_ city: WorldCity) -> Bool {
        worldCityIDs.contains(city.id)
    }

    var canAddWorldCity: Bool {
        worldCityIDs.count < WorldCity.maximumSelection
    }

    func toggleWorldCity(_ city: WorldCity) {
        if let index = worldCityIDs.firstIndex(of: city.id) {
            worldCityIDs.remove(at: index)
        } else if canAddWorldCity {
            worldCityIDs.append(city.id)
        }
    }
}
