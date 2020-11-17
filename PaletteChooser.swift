//
//  PaletteChooser.swift
//  EmojiArt (iOS)
//
//  Created by Joshua Olson on 11/15/20.
//

import SwiftUI

struct PaletteChooser: View {
    @State private var chosenPalette = ""
    @EnvironmentObject var document: EmojiArtDocument

    var body: some View {
        HStack {
            HStack {
                Stepper(
                    onIncrement: {
                        chosenPalette = document.palette(after: chosenPalette)
                    },
                    onDecrement: {
                        chosenPalette = document.palette(before: chosenPalette)
                    },
                    label: { EmptyView() })
                Text(document.paletteNames[chosenPalette] ?? "Missing palette")
            }.fixedSize(horizontal: true, vertical: false)
            .onAppear { chosenPalette = document.defaultPalette}
            ScrollView(.horizontal) {
                HStack {
                    // Key-Path syntax \.self
                    ForEach(chosenPalette.map {text in String(text) }, id: \.self) { emoji in
                        Text(emoji)
                            .background(Color.clear)
                            .padding(.bottom)
                            .font(Font.system(size: defaultEmojiSize))

                            .onDrag { NSItemProvider(object: emoji as NSString) }
//                            .gesture(DragGesture().onChanged { _ in NSItemProvider(object: emoji as NSString) } )
                    }
                }
            }
        }
        .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.blue, lineWidth: 3))
    }

    // MARK: - Constants

    private let defaultEmojiSize: CGFloat = 40

}

struct PalletView_Previews: PreviewProvider {
    static var previews: some View {
        PaletteChooser()
    }
}
