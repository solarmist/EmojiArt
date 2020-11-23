//
//  EmojiArtDocumentViewShared.swift
//  Shared
//
//  Created by Joshua Olson on 11/14/20.
//

import SwiftUI
#if os(iOS)
import PencilKit
#endif

struct EmojiArtDocumentViewShared: View {
    @ObservedObject var document: EmojiArtDocument
    @State private var chosenPalette: String = ""
    @Environment(\.undoManager) var undoManager

    #if os(iOS)
    @State var pkCanvasView = PKCanvasView()
    #endif

    var body: some View {
        if document.undoManager == nil && undoManager != nil {
            document.undoManager = undoManager
        }

        return VStack {
            documentBody
                .zIndex(-1)
                .frame(minWidth: 350, minHeight: 350)
            HStack {
                Spacer()
                Button(
                    action: {
                        print("Delete selected items")
                        document.deleteSelectedEmoji()
                    },
                    label: {
                        ZStack(alignment: .topTrailing) {
                            Text("😀").imageScale(.large)
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                                .font(.headline).imageScale(.small)
                                .opacity(true ? 1 : 0)
                        }
                    }
                )
                    .disabled(document.selectedEmoji.count == 0)
                    .keyboardShortcut(.delete)
            }
            PaletteChooser(document: document, chosenPalette: $chosenPalette)
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
                // TODO: - Get Background Image to show up again
                canvasView
                    // Don't scale the canvas. Scale the drawing on the canvas
                    .gesture(doubleTapToZoom(in: geometry.size))
                    .gesture(panGesture)

                // Emojis
                if document.isFetchingBackground {
                    ProgressView().progressViewStyle(CircularProgressViewStyle()).imageScale(.large)
                } else {
                    ForEach(document.emojis) { emoji in
                        EmojiView(document: document,
                                  emoji: emoji,
                                  // We can scale the emoji size independently of the whole document
                                  fontScale: fontScale,
                                  zoomScale: zoomScale,
                                  rotationAngle: rotationAngle
                        )
                        .offset(panOffset)
                        .position(groupPosition(for: emoji, in: geometry.size))
                        .gesture(emojiTaps(on: emoji))
                        .gesture(selectedEmojiPanGesture)
                    }
                }
            }
            .clipped()
            .edgesIgnoringSafeArea([.horizontal, .bottom])
            .onTapGesture(count: 1) { document.clearSelectedEmoji() }
            // If zoom is before pan then the panGesture doesn't update properly
            .gesture(zoomAndRotationGesture)
            .onReceive(document.$backgroundImage) { image in
                if steadyStateZoomScale == 1 {
                    zoomToFit(image, in: geometry.size)
                }
            }
            // For background and new emoji
            .onDrop(of: [.image, .utf8PlainText, .url], isTargeted: nil) { providers, location in
                drop(providers: providers, at: location, in: geometry)
            }
        }
    }

    // MARK: - Constants
    @ScaledMetric var defaultEmojiSize: CGFloat = 40

    // MARK: - State and GestureState

    @State var rotationAngle = Angle(degrees: 0)

    // zoom and panOffset have moved back here from EmojiArtDocument
    // note that in order to store CGSize or CGFloat in a @SceneStorage
    // we have to make CGSize and CGFloat RawRepresentable
    // (see EmojiArtExtensions.swift for that)
    @SceneStorage("EmojiArtDocumentView.panOffset") var steadyStatePanOffset = CGSize.zero
    @SceneStorage("EmojiArtDocumentView.zoom") var steadyStateZoomScale: CGFloat = 1 {
        didSet { print("zoom factor: \(oldValue) -> \(steadyStateZoomScale)") }
    }

    @GestureState var gestureEmojiPanOffset = CGSize.zero
    @GestureState var gesturePanOffset = CGSize.zero
    @GestureState var gestureZoomScale: CGFloat = 1.0
    @GestureState var fontScale: CGFloat = 1.0

}

//
//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        EmojiArtDocumentViewShared(document: EmojiArtDocument())
//    }
//}
