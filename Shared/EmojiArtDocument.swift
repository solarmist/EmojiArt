//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by Joshua Olson on 11/14/20.
//

import SwiftUI
import Combine
import UniformTypeIdentifiers

extension UTType {
    static var emojiart = UTType(exportedAs: "solarmist.emojiart")
}

class EmojiArtDocument: ReferenceFileDocument {

    // MARK: - Document Handling

    static var readableContentTypes: [UTType] { [.emojiart ] }
    static var writeableContentTypes: [UTType] { [.emojiart ] }

    func snapshot(contentType: UTType) throws -> Data {
        emojiArt.json!
    }

    func fileWrapper(
        snapshot: Data,
        configuration: WriteConfiguration
    ) throws -> FileWrapper {
        let data = (try? self.snapshot(contentType: .emojiart)) ?? Data()
        print("Saving: \(data)")
        return FileWrapper(regularFileWithContents: data)
    }

    required init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let newEmojiArt = EmojiArtModel(json: data) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        emojiArt = newEmojiArt
        fetchBackgroundImageData()
    }

    init () {
        emojiArt = EmojiArtModel()
    }

    // MARK: - Model

    @Published private var emojiArt: EmojiArtModel = EmojiArtModel()
    @Published private(set) var backgroundImage: UIImage?
    @Published private(set) var selectedEmoji: Set<EmojiArtModel.Emoji> = []

    var emojis: [EmojiArtModel.Emoji] { emojiArt.emojis }
    var backgroundURL: URL? { emojiArt.backgroundURL }

    // MARK: - FetchBackground Image
    private var fetchBackgroundCancellable: AnyCancellable?
    @Published private(set) var isFetchingBackground = false

    private func fetchBackgroundImageData() {
        backgroundImage = nil
        guard let url = emojiArt.backgroundURL?.imageURL else {
            return
        }
        fetchBackgroundCancellable?.cancel()  // Cancel any existing queries

        fetchBackgroundCancellable = URLSession.shared.dataTaskPublisher(for: url)
            .map {data, _ in UIImage(data: data) }
            .replaceError(with: nil)
            .receive(on: DispatchQueue.main)
            .assign(to: \.backgroundImage, on: self)
    }

    // MARK: - Undo
    var undoManager: UndoManager?  // The undoManager for the view that owns this document
    var inUndoGroup: Bool = false

    // All changes to the Model should (must) be undoable
    // not just because we want a good UI (with Undo and Redo) for our users
    // but because a ReferenceFileDocument only knows to save itself when an undo is registered
    // thus any changes made to the Model without registering an undo are at risk of being lost
    // currently, only our Intent functions can change our Model
    // so the API for those Intent functions now ask for the UndoManager from the View
    // on iOS, there's no "Save" menu item, so documents are "autosaved"
    // (this happens on certain events like switching to another app)

    func undoablyPerform(
        operation: String,
        startGroupIfNotInGroup: Bool = false,
        endGroupIfInGroup: Bool = false,
        doit: () -> Void
    ) {
        let oldEmojiArt = emojiArt
        doit()

        if startGroupIfNotInGroup && !inUndoGroup {
            inUndoGroup = true
            undoManager?.beginUndoGrouping()
        }
        undoManager?.setActionName(operation)
        undoManager?.registerUndo(withTarget: self) { [weak self] document in
            // perform the undo undoably (i.e. allow redo)
            self?.undoablyPerform(operation: operation) {
                let needBackgroundFetch = document.emojiArt.backgroundIsDifferentThan(oldEmojiArt)
                document.emojiArt = oldEmojiArt
                if needBackgroundFetch {
                    self?.fetchBackgroundImageData()
                }
            }
        }
        if endGroupIfInGroup && inUndoGroup {
            inUndoGroup = false
            undoManager?.endUndoGrouping()
        }
    }

    // MARK: - Intent(s)

    // Selection should begin/end an UndoGroup

    // Ideally I'd like to be able to decorate the function like this to add Undo.
    // @Undoable("Clear Selected Emoji")
    func clearSelectedEmoji() {
        undoablyPerform(operation: "Clear Selected Emoji", endGroupIfInGroup: true) {
            selectedEmoji = []
        }
    }

    func selectAllEmoji() {
        undoablyPerform(operation: "Select All Emoji", startGroupIfNotInGroup: true) {
            selectedEmoji = Set(emojis)
        }
    }

    // (De)select an emoji
    func toggleEmojiSelection(_ emoji: EmojiArtModel.Emoji) {
        let action = selectedEmoji.contains(emoji) ? "Unselect" : "Select"
        let removeLast = selectedEmoji.count == 1 && selectedEmoji.contains(emoji)
        undoablyPerform(operation: "\(action) Emoji \(emoji)",
                        startGroupIfNotInGroup: selectedEmoji.count == 0,
                        endGroupIfInGroup: removeLast ) {
            if selectedEmoji.contains(emoji) {
                selectedEmoji.remove(emoji)
            } else {
                selectedEmoji.insert(emoji)
            }
        }
    }

    func setBackgroundURL(_ url: URL?) {
        undoablyPerform(operation: "Set Background URL") {
            emojiArt.backgroundImageData = nil
            emojiArt.backgroundURL = url?.imageURL
            fetchBackgroundImageData()
        }
    }

    func setBackgroundImageData(_ data: Data) {
        undoablyPerform(operation: "Set Background Image") {
            emojiArt.backgroundImageData = data
            emojiArt.backgroundURL = nil
            backgroundImage = UIImage(data: data)
        }
    }

    func addEmoji(_ emoji: String, at location: CGPoint, size: CGFloat) {
        undoablyPerform(operation: "Add Emoji \(emoji)") {
            emojiArt.addEmoji(text: emoji, location: location, size: Double(size))
        }
    }

    func deleteSelectedEmoji() {
        undoablyPerform(operation: "Delete Emoji") {
            for emoji in selectedEmoji {
                guard let index = emojiArt.emojis.firstIndex(matching: emoji) else {
                    return
                }
                emojiArt.remove(at: index)
            }
        }
    }

    func moveSelectedEmoji(by offset: CGSize) {
        undoablyPerform(operation: "Move Selected Emoji") {
            for emoji in selectedEmoji {
                moveEmoji(emoji, by: offset)
            }
        }
    }

    func moveEmoji(_ emoji: EmojiArtModel.Emoji, by offset: CGSize) {
        undoablyPerform(operation: "Move Emoji \(emoji)") {
            guard let index = emojiArt.emojis.firstIndex(matching: emoji) else {
                return
            }
            emojiArt.emojis[index].x += offset.width
            emojiArt.emojis[index].y += offset.height
        }
    }

    func scaleSelectedEmoji(by scale: CGFloat) {
        undoablyPerform(operation: "Scale Selected Emoji") {
            for emoji in selectedEmoji {
                scaleEmoji(emoji, by: scale)
            }
        }
    }

    func scaleEmoji(_ emoji: EmojiArtModel.Emoji, by scale: CGFloat) {
        undoablyPerform(operation: "Scale Emoji \(emoji)") {
            guard let index = emojiArt.emojis.firstIndex(matching: emoji) else {
                return
            }
            emojiArt.emojis[index].size = Double((CGFloat(emojiArt.emojis[index].size) * scale))
        }
    }

    func rotateSelectedEmoji(by angle: Angle) {
        undoablyPerform(operation: "Rotate Selected Emoji") {
            for emoji in selectedEmoji {
                guard let index = emojiArt.emojis.firstIndex(matching: emoji) else {
                    return
                }
                emojiArt.emojis[index].rotation += angle.radians
            }
        }
    }

    func rotateEmoji(_ emoji: EmojiArtModel.Emoji, by angle: Angle) {
        undoablyPerform(operation: "Move Emoji \(emoji)") {
            guard let index = emojiArt.emojis.firstIndex(matching: emoji) else {
                return
            }
            emojiArt.emojis[index].rotation += angle.radians
        }
    }
}

extension EmojiArtModel.Emoji {
    var fontSize: CGFloat { CGFloat(self.size) }
    var location: CGPoint { CGPoint(x: CGFloat(x), y: CGFloat(y)) }
}

extension EmojiArtModel {
    func backgroundIsDifferentThan(_ otherEmojiArt: EmojiArtModel) -> Bool {
        (backgroundURL != otherEmojiArt.backgroundURL) ||
        (backgroundImageData != otherEmojiArt.backgroundImageData)
    }
}
