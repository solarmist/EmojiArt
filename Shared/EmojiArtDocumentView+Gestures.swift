//
//  EmojiArtDocumentView+Gestures.swift
//  EmojiArt (iOS)
//
//  Created by Joshua Olson on 11/15/20.
//

import SwiftUI

// Extension for Dragging groups of emoji around
extension EmojiArtDocumentView {
    var emojiOffset: CGSize {
        gestureEmojiPanOffset * zoomScale
    }

    var selectedEmojiPanGesture: some Gesture {
        DragGesture()
            // swiftlint:disable:next unused_closure_parameter
            .updating($gestureEmojiPanOffset) { latestDragValue, gestureEmojiPanOffset, transition in
                gestureEmojiPanOffset = latestDragValue.translation / zoomScale
            }
            .onEnded { finalDragValue in
                print("Selected Move")
                document.moveSelectedEmoji(by: finalDragValue.translation / zoomScale)
                document.clearSelectedEmoji()
            }
    }

    // Panning works correctly, but zooming moves the coordinates
    func groupPosition(for emoji: EmojiArt.Emoji, in size: CGSize) -> CGPoint {
        var location = emoji.location * zoomScale

        if document.selectedEmoji.contains(emoji) {
            location = CGPoint(x: location.x + emojiOffset.width,
                               y: location.y + emojiOffset.height)
        }
//        location = CGPoint(x: location.x + panOffset.width,
//                           y: location.y + panOffset.height)
        // Return frame coords
        return CGPoint(x: location.x + size.width / 2, y: location.y + size.height / 2)
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
}

extension EmojiArtDocumentView {
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
}

extension EmojiView {
}

// Add a zoom gesture
extension EmojiArtDocumentView {
    var zoomScale: CGFloat {
        steadyStateZoomScale * gestureZoomScale
    }

    var zoomAndRotationGesture: some Gesture {
        SimultaneousGesture(
            RotationGesture()
                .onChanged { angle in
                    rotationAngle = angle
                }
                .onEnded { finalAngle in
                    document.rotateSelectedEmoji(by: finalAngle)
                    rotationAngle = Angle.degrees(0)
                },
            MagnificationGesture()
                .updating(document.selectedEmoji.count > 0
                            ? $fontScale
                            : $gestureZoomScale
                ) { latestGestureScale, scaleFactor, _ in
                    scaleFactor = latestGestureScale
                }
                .onEnded { finalGestureScale in
                    if document.selectedEmoji.count > 0 {
                        document.scaleSelectedEmoji(by: finalGestureScale)
                    } else {
                        steadyStateZoomScale *= finalGestureScale
                    }
                })
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
