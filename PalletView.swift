//
//  PalletView.swift
//  EmojiArt (iOS)
//
//  Created by Joshua Olson on 11/15/20.
//

import SwiftUI

struct PalletView: View {
    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                // Key-Path syntax \.self
                ForEach(EmojiArtDocument.palette.map { String($0) }, id: \.self) { emoji in
                    Text(emoji)
                        .background(Color.clear)
                        .padding(.bottom)
                        .font(Font.system(size: defaultEmojiSize))

                        .onDrag { NSItemProvider(object: emoji as NSString) }
//                            .gesture(DragGesture().onChanged { _ in NSItemProvider(object: emoji as NSString) } )
                }
            }
        }
        .padding(.horizontal)
        .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.blue, lineWidth: 3))
    }

    // MARK: - Constants

    private let defaultEmojiSize: CGFloat = 40

}

struct PalletView_Previews: PreviewProvider {
    static var previews: some View {
        PalletView()
    }
}
