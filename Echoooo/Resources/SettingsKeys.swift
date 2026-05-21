import Foundation

enum SettingsKey {
    static let consentPrompt = "settings.consentPrompt"
    static let keepAudio = "settings.keepAudio"
    static let autoTranscribe = "settings.autoTranscribe"
    static let hapticOnStop = "settings.hapticOnStop"
}

enum SettingsDefault {
    static let consentPrompt = true
    static let keepAudio = false
    static let autoTranscribe = true
    static let hapticOnStop = true
}
