import SwiftUI

enum Theme {
    static let paper = Color("Paper")
    static let ink = Color("Ink")
    static let inkMuted = Color("InkMuted")
    static let inkFaint = Color("InkFaint")
    static let surface2 = Color("Surface2")
    static let hairline = Color("Hairline")
    static let accent = Color("Accent")
}

extension Font {
    static func body300(_ size: CGFloat) -> Font {
        .system(size: size, weight: .light, design: .default)
    }

    static func display400(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }

    static func mono400(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .monospaced)
    }
}
