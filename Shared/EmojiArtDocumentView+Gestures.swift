//
//  EmojiArtDocumentView+Gestures.swift
//  EmojiArt (iOS)
//
//  Created by Joshua Olson on 11/15/20.
//

import SwiftUI

extension EmojiView {
    var emojiOffset: CGSize {
        (steadyStateEmojiPanOffset + gestureEmojiPanOffset) * zoomScale
    }

    var emojiDragGesture: some Gesture {
        DragGesture()
            // swiftlint:disable:next unused_closure_parameter
            .updating($gestureEmojiPanOffset) { latestDragValue, gestureEmojiPanOffset, transition in
                gestureEmojiPanOffset = latestDragValue.translation / zoomScale
            }
            .onEnded { finalDragValue in
                for emoji in selectedEmoji {
                    document.moveSelectedEmoji(by: finalDragValue.translation / zoomScale)
                }
                if !selectedEmoji.contains(self.emoji) {
                    // swiftlint:disable:next shorthand_operator
                    steadyStateEmojiPanOffset = steadyStateEmojiPanOffset + (finalDragValue.translation / zoomScale)
                }
            }
    }
}

extension EmojiArtDocumentView {

    // Give priority to multiple taps
    func emojiTaps(on emoji: EmojiArt.Emoji) -> some Gesture {
        ExclusiveGesture(
            TapGesture(count: 2)
                .onEnded {
                    document.selectAllEmoji()
                },
            TapGesture(count: 1)
                .onEnded {
                    document.toggleEmojiSelection(emoji)
                }
        )
    }

    var panOffset: CGSize {
        (steadyStatePanOffset + gesturePanOffset) * zoomScale
    }

    var panGesture: some Gesture {
        DragGesture()
            // swiftlint:disable:next unused_closure_parameter
            .updating($gesturePanOffset) { latestDragValue, gesturePanOffset, transition in
                gesturePanOffset = latestDragValue.translation / zoomScale
            }
            .onEnded { finalDragValue in
                // swiftlint:disable:next shorthand_operator
                steadyStatePanOffset = steadyStatePanOffset + (finalDragValue.translation / zoomScale)
            }
    }

    var rotationGesture: some Gesture {
        RotationGesture()
            .onChanged { angle in
                rotationAngle = angle
            }
            .onEnded { finalAngle in
                document.rotateSelectedEmoji(by: finalAngle)
            }
    }

    var zoomScale: CGFloat {
        steadyStateZoomScale * gestureZoomScale
    }

    var zoomGesture: some Gesture {
        MagnificationGesture()
            .updating($gestureZoomScale) { latestGestureScale, gestureZoomScale, _ in
                gestureZoomScale = latestGestureScale
            }
            .onEnded { finalGestureScale in
                steadyStateZoomScale *= finalGestureScale
            }
    }

    func doubleTapToZoom(in size: CGSize) -> some Gesture {
        TapGesture(count: 2)
            .onEnded {
                withAnimation {
                    zoomToFit(document.backgroundImage, in: size)
                }
            }
    }

    func zoomToFit(_ image: UIImage?, in size: CGSize) {
        guard let image = image, image.size.width > 0, image.size.height > 0 else {
            return
        }
        let hZoom = size.width / image.size.width
        let vZoom = size.height / image.size.height
        steadyStatePanOffset = .zero
        steadyStateZoomScale = min(vZoom, hZoom)
    }

}
