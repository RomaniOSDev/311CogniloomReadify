import UIKit
import AudioToolbox

enum HapticService {
    private static let soundKey = "cr_sound_enabled"
    private static let hapticsKey = "cr_haptics_enabled"

    private static let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private static let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private static let notificationGenerator = UINotificationFeedbackGenerator()

    static var soundEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: soundKey) == nil { return true }
            return UserDefaults.standard.bool(forKey: soundKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: soundKey) }
    }

    static var hapticsEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: hapticsKey) == nil { return true }
            return UserDefaults.standard.bool(forKey: hapticsKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: hapticsKey) }
    }

    /// Call once at launch so the first feedback / keyboard interaction is not cold.
    static func prepare() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        notificationGenerator.prepare()
    }

    static func light() {
        guard hapticsEnabled else { return }
        lightGenerator.impactOccurred()
        lightGenerator.prepare()
    }

    static func medium() {
        guard hapticsEnabled else { return }
        mediumGenerator.impactOccurred()
        mediumGenerator.prepare()
    }

    static func success() {
        if hapticsEnabled {
            notificationGenerator.notificationOccurred(.success)
            notificationGenerator.prepare()
        }
        play(1057)
    }

    static func warning() {
        guard hapticsEnabled else { return }
        notificationGenerator.notificationOccurred(.warning)
        notificationGenerator.prepare()
    }

    static func play(_ id: SystemSoundID) {
        guard soundEnabled else { return }
        AudioServicesPlaySystemSound(id)
    }
}
