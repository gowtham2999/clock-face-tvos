import Foundation
import Observation

@Observable
final class AppSettings {
    private enum Keys {
        static let faceType = "faceType"
        static let theme = "theme"
        static let uses24HourTime = "uses24HourTime"
        static let accentColor = "accentColor"
        static let chimeSource = "chimeSource"
        static let volume = "volume"
    }

    var faceType: WatchFaceType {
        didSet { UserDefaults.standard.set(faceType.rawValue, forKey: Keys.faceType) }
    }

    var theme: AppTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: Keys.theme) }
    }

    var uses24HourTime: Bool {
        didSet { UserDefaults.standard.set(uses24HourTime, forKey: Keys.uses24HourTime) }
    }

    var accentColor: AccentColorOption {
        didSet { UserDefaults.standard.set(accentColor.rawValue, forKey: Keys.accentColor) }
    }

    var chimeSource: ChimeSource {
        didSet { UserDefaults.standard.set(chimeSource.rawValue, forKey: Keys.chimeSource) }
    }

    var volume: Double {
        didSet { UserDefaults.standard.set(volume, forKey: Keys.volume) }
    }

    init() {
        let defaults = UserDefaults.standard

        faceType = defaults.string(forKey: Keys.faceType).flatMap(WatchFaceType.init(rawValue:)) ?? .analogClassic
        theme = defaults.string(forKey: Keys.theme).flatMap(AppTheme.init(rawValue:)) ?? .dark
        uses24HourTime = defaults.bool(forKey: Keys.uses24HourTime)
        accentColor = defaults.string(forKey: Keys.accentColor).flatMap(AccentColorOption.init(rawValue:)) ?? .yellow
        chimeSource = defaults.string(forKey: Keys.chimeSource).flatMap(ChimeSource.init(rawValue:)) ?? .watch

        if defaults.object(forKey: Keys.volume) != nil {
            volume = defaults.double(forKey: Keys.volume)
        } else {
            volume = 1.0
        }
    }
}
