//
//  EmojiArt.swift
//  EmojiArt
//
//  Created by Joshua Olson on 11/14/20.
//

import SwiftUI

struct EmojiArt: Codable {
    var backgroundURL: URL?
    var emojis = [Emoji]()

    struct Emoji: Identifiable, Codable, Hashable {
        let text: String
        // swiftlint:disable:next identifier_name
        var x: CGFloat  // offset from center
        // swiftlint:disable:next identifier_name
        var y: CGFloat
        var size: Double
        var rotation: Double  // In radians
        // swiftlint:disable:next identifier_name
        let id: UUID

        var angle: Angle { Angle.radians(rotation) }

        fileprivate init(text: String, location: CGPoint, size: Double, rotation: Angle = Angle.degrees(0)) {
            self.id = UUID()
            self.text = text
            self.x = location.x
            self.y = location.y
            self.size = size
            self.rotation = rotation.radians
        }
    }
    var json: Data? {
        return try? JSONEncoder().encode(self)
    }

    init() { }

    init?(json: Data?) {
        if json != nil, let newEmojiArt = try? JSONDecoder().decode(EmojiArt.self, from: json!) {
            self = newEmojiArt
        } else {
            // Only return nil if it fails to load
            return nil
        }
    }

    mutating func remove(at index: Int) {
        emojis.remove(at: index)
    }

    mutating func addEmoji(text: String, location: CGPoint, size: Double) {
        emojis.append(Emoji(text: text, location: location, size: size))
    }
}
