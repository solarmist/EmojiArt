//
//  EmojiArtDocumentView.swift
//  Shared
//
//  Created by Joshua Olson on 11/14/20.
//

import SwiftUI

struct EmojiView: View {
    var emoji: EmojiArt.Emoji

    @EnvironmentObject var document: EmojiArtDocument

    @Binding var selectedEmoji: Set<EmojiArt.Emoji>
    @Binding var zoomScale: CGFloat
    @Binding var panOffset: CGSize

    @State var steadyStateEmojiPanOffset = CGSize.zero
    @GestureState var gestureEmojiPanOffset = CGSize.zero

    var body: some View {
        GeometryReader { geometry in

            Text(emoji.text)
                .overlay(
                    selectedEmoji.contains(emoji)
                        ? RoundedRectangle(cornerRadius: 10)

                            .stroke(Color.blue, lineWidth: 3)
                        : nil)
                .font(animatableWithSize: emoji.fontSize * zoomScale)
    //                        .rotationEffect(emoji.angle + (document.selectedEmoji.contains(emoji)
    //                                                        ? rotationAngle
    //                                                        : Angle.degrees(0)))
    //                        .gesture(rotationGesture)
                .position(position(for: emoji, in: geometry.size))
                .gesture(emojiDragGesture)
        }
    }

    private func position(for emoji: EmojiArt.Emoji, in size: CGSize) -> CGPoint {
        var location = emoji.location
        location = CGPoint(x: location.x * zoomScale, y: location.y * zoomScale)
        location = CGPoint(x: location.x + emojiOffset.width, y: location.y + emojiOffset.height)
        location = CGPoint(x: location.x + panOffset.width, y: location.y + panOffset.height)
        location = CGPoint(x: location.x + size.width / 2, y: location.y + size.height / 2)

        return location
    }

}

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument

    var body: some View {
        VStack {
            PalletView()

            documentBody
            Button("Delete Emoji") {
                // TODO: - Doesn't work when there the emoji hasn't sync'ed to the UserDefaults store
                print("Delete stuff")
                document.deleteSelectedEmoji()
            }
//            .hidden()  // Hide if there's a keyboard?
            .keyboardShortcut(.delete)
        }

    }
    private var documentBody: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white.overlay(
                    OptionalImage(uiImage: document.backgroundImage)
                        .scaleEffect(zoomScale)
                )
                    .offset(panOffset)
                    .gesture(doubleTapToZoom(in: geometry.size))
                    .gesture(panGesture)

                ForEach(document.emojis) { emoji in
                    EmojiView(emoji: emoji,
                              selectedEmoji: .constant(document.selectedEmoji),
                              zoomScale: .constant(zoomScale),
                              panOffset: .constant(panOffset)
                    )
                    .environmentObject(document)
                        .onDrag { NSItemProvider(object: emoji.text as NSString) }
//                        .gesture(emojiDragGesture(with: emoji))
                        .gesture(emojiTaps(on: emoji))
                }
            }
            .clipped()
            .edgesIgnoringSafeArea([.horizontal, .bottom])
            .onTapGesture(count: 1) { document.clearSelectedEmoji() }
            // If zoom is before pan then the panGesture doesn't update properly
            .gesture(zoomGesture)
//            .gesture(zoomGesture.simultaneously(with: RotationGesture().onChanged {
//                value in
//            }))
            .onDrop(of: [.image, .text], isTargeted: nil) { providers, location in
                var location = geometry.convert(location, from: .global)
                // TODO: - The grab location is ignored for the drop location
                // The emoji is dropped with its center at the pointer tip
                location = CGPoint(x: location.x - geometry.size.width / 2,
                                   y: location.y - geometry.size.height / 2)
                location = CGPoint(x: location.x - panOffset.width, y: location.y - panOffset.height)
                location = CGPoint(x: location.x / zoomScale, y: location.y / zoomScale)
                return self.drop(providers: providers, at: location)
            }
        }
    }

//    private func position(for emoji: EmojiArt.Emoji, in size: CGSize) -> CGPoint {
//        var location = emoji.location
//        location = CGPoint(x: location.x * zoomScale, y: location.y * zoomScale)
//        if document.selectedEmoji.contains(emoji) {
//            location = CGPoint(x: location.x + emojiOffset.width, y: location.y + emojiOffset.height)
//        }
//        location = CGPoint(x: location.x + panOffset.width, y: location.y + panOffset.height)
//        location = CGPoint(x: location.x + size.width / 2, y: location.y + size.height / 2)
//
//        return location
//    }

    private func drop(providers: [NSItemProvider], at location: CGPoint) -> Bool {
        var found = providers.loadFirstObject(ofType: URL.self) { url in
            print("Dropped image \(url)")
            self.document.setBackgroundURL(url)

        }
        if !found {
            found = providers.loadObjects(ofType: String.self) { string in
                self.document.addEmoji(string, at: location, size: self.defaultEmojiSize)
            }
        }
        return found
    }

    // MARK: - Constants
    // new: added @ScaledMetric this this line of code
    // so our default emoji size now scales with the user's font size preference
    @ScaledMetric var defaultEmojiSize: CGFloat = 40

    // MARK: - State and GestureState

    @State var rotationAngle = Angle(degrees: 0)
    @State var steadyStatePanOffset = CGSize.zero
    @State var steadyStateZoomScale: CGFloat = 1.0

    @GestureState var gesturePanOffset = CGSize.zero
    @GestureState var gestureZoomScale: CGFloat = 1.0

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let emojiArtDoc = EmojiArtDocument()
        EmojiArtDocumentView(document: emojiArtDoc)
    }
}
