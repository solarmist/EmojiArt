//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by Joshua Olson on 11/14/20.
//

import SwiftUI
import Combine

class EmojiArtDocument: ObservableObject {
    static let palette: String = "🦇😱🙀😈🎃👻🍭🍬💀👺👽🕸🤖🧛🏻👾💩👅🧜🏼‍♀️💁🏼‍♀️👯‍♀️🧣🐝"

    var documentName: String = "Untitled"
    var documentKey: String { "\(type(of: self)).\(documentName)" }

    @Published private var emojiArt: EmojiArt = EmojiArt() {
        didSet {
            UserDefaults.standard.set(emojiArt.json, forKey: documentKey)
        }
    }

    @Published private(set) var backgroundImage: UIImage?

    init() {
        let data = UserDefaults.standard.data(forKey: documentKey)
        emojiArt = EmojiArt(json: data) ?? EmojiArt()
        fetchBackgroundImageData()
    }

    // For a progress indicator
    @Published private(set) var isLoading = false

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

    func moveSelectedEmoji(by offset: CGSize) {
        for emoji in selectedEmoji {
            guard let index = emojiArt.emojis.firstIndex(matching: emoji) else {
                return
            }
            emojiArt.emojis[index].x += offset.width
            emojiArt.emojis[index].y += offset.height
            print("Moved emoji \(emoji.text) to: \(emojiArt.emojis[index].x), \(emojiArt.emojis[index].y)")
        }
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

    func setBackgroundURL(_ url: URL?) {
        emojiArt.backgroundURL = url?.imageURL
        fetchBackgroundImageData()
    }

    private var cancellable: AnyCancellable?

    private func fetchBackgroundImageData() {
        backgroundImage = nil
        isLoading = true

        cancel()  // Cancel any existing queries
        if let url = self.emojiArt.backgroundURL {
            cancellable = URLSession.shared.dataTaskPublisher(for: url)
                        .map { UIImage(data: $0.data) }
                        .replaceError(with: nil)
                        .receive(on: DispatchQueue.main)
                        .sink { [weak self] in self?.backgroundImage = $0 }
            // Explicit version
//            DispatchQueue.global(qos: .userInitiated).async {
//                if let imageData = try? Data(contentsOf: url) {
//                    DispatchQueue.main.async {
//                        if url == self.emojiArt.backgroundURL {
//                            self.backgroundImage = UIImage(data: imageData)
//                            self.isLoading = false
//                        }
//                    }
//                }
//            }
        }
    }

    func cancel() {
        cancellable?.cancel()
    }

}

extension EmojiArt.Emoji {
    var fontSize: CGFloat { CGFloat(self.size) }
    var location: CGPoint { CGPoint(x: CGFloat(x), y: CGFloat(y)) }
}
