//
//  EmojiArtDocumentView.swift
//  Shared
//
//  Created by Joshua Olson on 11/14/20.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument

    var body: some View {
        VStack {
            PaletteChooser(document: document).environmentObject(document)

            documentBody.zIndex(-1)
            HStack {
                Spacer()
                Button(
                    action: {
                        print("Delete selected items")
                        document.deleteSelectedEmoji()
                    },
                    label: {
                        // Try to make a minus badge on the emoji
                        Text("😀")
                        Image(systemName: "minus.circle")
                            .alignmentGuide(.top) { $0.height / 2}
                            .alignmentGuide(.trailing) { $0.width / 2}
//                                .offset(x: geometry.size.width/2,
//                                        y: geometry.size.height/2)
                                .foregroundColor(.red)
                    }
                )
                    .disabled(document.selectedEmoji.count == 0)
                    .keyboardShortcut(.delete)
            }
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
                                  // We can scale the emoji size independently of the whole document
                                  fontScale: fontScale,
                                  zoomScale: zoomScale,
                                  rotationAngle: rotationAngle
                        )
                        .environmentObject(document)
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
//            .gesture(zoomGesture.simultaneously(with: RotationGesture().onChanged {
//                value in
//            }))
            // For background and new emoji
            .onDrop(of: [.image, .text], isTargeted: nil) { providers, location in
                let frameCoordinates = geometry.convert(location, from: .global)
                let centerOffset = geometry.size / 2
                // todo: - The grab location is ignored for the drop location
                // The emoji is dropped with its center at the pointer tip
                var location = CGPoint(x: frameCoordinates.x - centerOffset.width,
                                       y: frameCoordinates.y - centerOffset.height)
                // Move origin from top left to view center
                location = CGPoint(x: location.x - panOffset.width, y: location.y - panOffset.height)

                // Now scale adjust the distances to the current scale
                return self.drop(providers: providers, at: location / zoomScale)
            }

            .navigationBarItems(
                trailing: Button(
                    action: {
                        guard let url = UIPasteboard.general.url,
                              url == document.backgroundURL else {
                            explainBackgroundPaste = true
                            return
                        }

                        document.backgroundURL = url
                    },
                    label: { pasteBackgroundImage }
                )
            )
        }.alert(isPresented: $confirmBackgroundPaste) { confirmBackgroundPasteAlert() }

    }
    @State var explainBackgroundPaste = false
    @State var confirmBackgroundPaste = false
    @Environment(\.undoManager) var undoManager

    // This should probably go in iOS specific code
    private var pasteBackgroundImage: some View {
        Button(action: {
            if let url = UIPasteboard.general.url, url != document.backgroundURL {
                confirmBackgroundPaste = true
            } else if UIPasteboard.general.image != nil {
                confirmBackgroundPaste = true
            } else {
                explainBackgroundPaste = true
            }
        }, label: {
            Image(systemName: "doc.on.clipboard").imageScale(.large)
                .alert(isPresented: $explainBackgroundPaste) {
                    Alert(
                        title: Text("Paste Background"),
                        message: Text("Copy an image to the clip board and touch " +
                                      "this button to make it the background of your document."),
                        dismissButton: .default(Text("OK"))
                    )
                }
        })
    }

    private func confirmBackgroundPasteAlert() -> Alert {
        let url = UIPasteboard.general.url
        let pastedThing = url == nil ? "pasted image" : url!.absoluteString
        return Alert(
            title: Text("Paste Background"),
            message: Text("Replace your background with \(pastedThing)?."),
            primaryButton: .default(Text("OK")) {
                document.backgroundURL = UIPasteboard.general.url
//                if url != nil {
//                    document.setBackgroundURL(url, undoManager: undoManager)
//                } else if let imageData = UIPasteboard.general.image?.jpegData(compressionQuality: 1.0) {
//                    document.setBackgroundImageData(imageData, undoManager: undoManager)
//                }
            },
            secondaryButton: .cancel()
        )
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let emojiArtDoc = EmojiArtDocument()
        EmojiArtDocumentView(document: emojiArtDoc)
    }
}
