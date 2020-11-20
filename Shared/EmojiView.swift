//
//  EmojiView.swift
//  EmojiArt
//
//  Created by Joshua Olson on 11/17/20.
//

import SwiftUI

struct EmojiView: View {
    @ObservedObject var document: EmojiArtDocument
    var emoji: EmojiArtModel.Emoji

    var fontScale: CGFloat
    var zoomScale: CGFloat
    var rotationAngle = Angle(degrees: 0)

    var fontSize: CGFloat {
        emoji.fontSize * (document.selectedEmoji.contains(emoji) ? fontScale : 1)
    }

    var additionalRotation: Angle {
        document.selectedEmoji.contains(emoji) ? rotationAngle : Angle.degrees(0)
    }

    @GestureState var gestureEmojiPanOffset = CGSize.zero

    var body: some View {

        Text(emoji.text)
            .font(animatableWithSize: fontSize * zoomScale)
            // Highlight selected emoji
            .overlay(document.selectedEmoji.contains(emoji)
                ? RoundedRectangle(cornerRadius: 10).stroke(Color.blue, lineWidth: 3)
                : nil)
            .rotationEffect(emoji.angle + additionalRotation)
//        .gesture(emojiPanGesture)
    }

}
//
//struct EmojiView_Previews: PreviewProvider {
//    static var emoji: EmojiArtModel.Emoji {
//        let document = EmojiArtDocument()
//        document.addEmoji("👯‍♀️",
//                          at: CGPoint(x: 0, y: 0),
//                          size: 1)
//        return document.emojis[0]
//    }
//
//    static var previews: some View {
//        EmojiView(emoji: emoji, fontScale: 1, zoomScale: 1)
//    }
//}
