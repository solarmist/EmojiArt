//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by Joshua Olson on 11/14/20.
//

import SwiftUI
import Combine

class EmojiArtDocument: ObservableObject, Hashable, Identifiable {
    static func == (lhs: EmojiArtDocument, rhs: EmojiArtDocument) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    var name: String = "Untitled"
    // swiftlint:disable:next identifier_name
    var id: UUID

    var backgroundURL: URL? {
        get { emojiArt.backgroundURL }
        set {
            emojiArt.backgroundURL = newValue?.imageURL
            fetchBackgroundImageData()
        }
    }

    private var fetchBackgroundCancellable: AnyCancellable?

    @Published private var emojiArt: EmojiArt = EmojiArt()
    @Published private(set) var backgroundImage: UIImage?

    private var autosaveCancellable: AnyCancellable?

    // swiftlint:disable:next identifier_name
    init(id: UUID? = nil) {
        self.id = id ?? UUID()
        let defaultsKey = "\(type(of: self)).\(self.id.uuidString)"
        let data = UserDefaults.standard.data(forKey: defaultsKey)
        autosaveCancellable = $emojiArt.sink { emojiArt in
//            print("\(emojiArt.json?.utf8 ?? "nil")")
            UserDefaults.standard.set(emojiArt.json, forKey: defaultsKey)
        }
        emojiArt = EmojiArt(json: data) ?? EmojiArt()
        fetchBackgroundImageData()
    }

    private func fetchBackgroundImageData() {
        backgroundImage = nil
        guard let url = emojiArt.backgroundURL else {
            return
        }
        fetchBackgroundCancellable?.cancel()  // Cancel any existing queries

        fetchBackgroundCancellable = URLSession.shared.dataTaskPublisher(for: url)
            .map {data, _ in UIImage(data: data) }
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .assign(to: \.backgroundImage, on: self)
    }
    var emojis: [EmojiArt.Emoji] { emojiArt.emojis }
    @Published private(set) var selectedEmoji: Set<EmojiArt.Emoji> = []

    // MARK: - Intent(s)

    func clearSelectedEmoji() {
        selectedEmoji = []
    }

    func selectAllEmoji() {
        selectedEmoji = Set(emojis)
    }

    // (De)select an emoji
    func toggleEmojiSelection(_ emoji: EmojiArt.Emoji) {
        if selectedEmoji.contains(emoji) {
            selectedEmoji.remove(emoji)
        } else {
            selectedEmoji.insert(emoji)
        }
    }

    func addEmoji(_ emoji: String, at location: CGPoint, size: CGFloat) {
        emojiArt.addEmoji(text: emoji, location: location, size: Double(size))
    }

    func deleteSelectedEmoji() {
        for emoji in selectedEmoji {
            guard let index = emojiArt.emojis.firstIndex(matching: emoji) else {
                return
            }
            print("Deleting: \(emoji.text)")

            emojiArt.remove(at: index)
        }
    }

    func moveSelectedEmoji(by offset: CGSize) {
        for emoji in selectedEmoji {
            moveEmoji(emoji, by: offset)
        }
    }

    func moveEmoji(_ emoji: EmojiArt.Emoji, by offset: CGSize) {
        guard let index = emojiArt.emojis.firstIndex(matching: emoji) else {
            return
        }
        emojiArt.emojis[index].x += offset.width
        emojiArt.emojis[index].y += offset.height
        print("Moved emoji \(emoji.text) to: \(emojiArt.emojis[index].x), \(emojiArt.emojis[index].y)")

    }

    func scaleSelectedEmoji(by scale: CGFloat) {
        for emoji in selectedEmoji {
            scaleEmoji(emoji, by: scale)
        }
    }

    func scaleEmoji(_ emoji: EmojiArt.Emoji, by scale: CGFloat) {
        guard let index = emojiArt.emojis.firstIndex(matching: emoji) else {
            return
        }
        emojiArt.emojis[index].size = Double((CGFloat(emojiArt.emojis[index].size) * scale))
    }

    func rotateSelectedEmoji(by angle: Angle) {
        for emoji in selectedEmoji {

            guard let index = emojiArt.emojis.firstIndex(matching: emoji) else {
                return
            }
            emojiArt.emojis[index].rotation += angle.radians
        }
    }

    func rotateEmoji(_ emoji: EmojiArt.Emoji, by angle: Angle) {
        guard let index = emojiArt.emojis.firstIndex(matching: emoji) else {
            return
        }
        emojiArt.emojis[index].rotation += angle.radians
    }
}

extension EmojiArt.Emoji {
    var fontSize: CGFloat { CGFloat(self.size) }
    var location: CGPoint { CGPoint(x: CGFloat(x), y: CGFloat(y)) }
}
