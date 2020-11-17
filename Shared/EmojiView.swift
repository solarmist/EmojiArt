//
//  EmojiView.swift
//  EmojiArt
//
//  Created by Joshua Olson on 11/17/20.
//

import SwiftUI

struct EmojiView: View {
    @EnvironmentObject var document: EmojiArtDocument
    var emoji: EmojiArt.Emoji

    var zoomScale: CGFloat

    @GestureState var gestureEmojiPanOffset = CGSize.zero

    var body: some View {

        Text(emoji.text)
            .font(animatableWithSize: emoji.fontSize * zoomScale)
            // Highlight selected emoji
            .overlay(document.selectedEmoji.contains(emoji)
                ? RoundedRectangle(cornerRadius: 10).stroke(Color.blue, lineWidth: 3)
                : nil)

    //                        .rotationEffect(emoji.angle + (document.selectedEmoji.contains(emoji)
    //                                                        ? rotationAngle
    //                                                        : Angle.degrees(0)))
    //                        .gesture(rotationGesture)
//        .position(position(for: emoji, in: geometry.size))
//        .gesture(emojiPanGesture)
    }

}

struct EmojiView_Previews: PreviewProvider {
    static var emoji: EmojiArt.Emoji {
        let document = EmojiArtDocument()
        document.addEmoji("👯‍♀️",
                          at: CGPoint(x: 0, y: 0),
                          size: 1)
        return document.emojis[0]
    }

    static var previews: some View {
        EmojiView(emoji: emoji, zoomScale: 1)
    }
}
