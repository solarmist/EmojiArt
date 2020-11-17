//
//  EmojiArtDocumentView.swift
//  Shared
//
//  Created by Joshua Olson on 11/14/20.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @EnvironmentObject var document: EmojiArtDocument

    var body: some View {
        VStack {
            PaletteChooser()

            documentBody
            Button("Delete selected items") {
                print("Delete selected items")
                document.deleteSelectedEmoji()
            }
//            .hidden()  // Hide if there's a keyboard?
            .keyboardShortcut(.delete)
        }
    }

    private var documentBody: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.white.overlay(
                    OptionalImage(uiImage: document.backgroundImage)
                        .scaleEffect(zoomScale)
                )
                    .offset(panOffset)
                    .gesture(doubleTapToZoom(in: geometry.size))
                    .gesture(panGesture)

                // Emojis
                if isLoading {
                    ProgressView().progressViewStyle(CircularProgressViewStyle()).imageScale(.large)
                } else {
                    ForEach(document.emojis) { emoji in
                        EmojiView(emoji: emoji,
                                  zoomScale: zoomScale
                        )
                        .offset(panOffset)
                        .position(groupPosition(for: emoji, in: geometry.size))
                        .gesture(emojiTaps(on: emoji))
                        .gesture(selectedEmojiPanGesture)
                        // TODO: - Still need to scale and rotate emoji
                    }
                }
            }
            .clipped()
            .edgesIgnoringSafeArea([.horizontal, .bottom])
            .onTapGesture(count: 1) { document.clearSelectedEmoji() }
            // If zoom is before pan then the panGesture doesn't update properly
            .gesture(zoomGesture)
            .onReceive(document.$backgroundImage) { image in
                zoomToFit(image, in: geometry.size)
            }
//            .gesture(zoomGesture.simultaneously(with: RotationGesture().onChanged {
//                value in
//            }))
            // For background and new emoji
            .onDrop(of: [.image, .text], isTargeted: nil) { providers, location in
                let frameCoordinates = geometry.convert(location, from: .global)
                let centerOffset = geometry.size / 2
                // TODO: - The grab location is ignored for the drop location
                // The emoji is dropped with its center at the pointer tip
                var location = CGPoint(x: frameCoordinates.x - centerOffset.width,
                                       y: frameCoordinates.y - centerOffset.height)
                // Move origin from top left to view center
                location = CGPoint(x: location.x - panOffset.width, y: location.y - panOffset.height)

                // Now scale adjust the distances to the current scale
                return self.drop(providers: providers, at: location / zoomScale)
            }
        }
    }

    var isLoading: Bool {
        document.backgroundURL != nil && document.backgroundImage == nil
    }

    private func drop(providers: [NSItemProvider], at location: CGPoint) -> Bool {
        var found = providers.loadFirstObject(ofType: URL.self) { url in
            print("Dropped image \(url)")
            self.document.backgroundURL = url
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

    @GestureState var gestureEmojiPanOffset = CGSize.zero
    @GestureState var gesturePanOffset = CGSize.zero
    @GestureState var gestureZoomScale: CGFloat = 1.0

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let emojiArtDoc = EmojiArtDocument()
        EmojiArtDocumentView().environmentObject(emojiArtDoc)
    }
}
