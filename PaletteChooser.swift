//
//  PaletteChooser.swift
//  EmojiArt (iOS)
//
//  Created by Joshua Olson on 11/15/20.
//

import SwiftUI

struct PaletteChooser: View {
    @State private var chosenPalette: String
    @State private var showPaletteEditor = false
    @ObservedObject var document: EmojiArtDocument

    init(document: EmojiArtDocument) {
        self.document = document
        _chosenPalette = State(wrappedValue: document.defaultPalette)
    }

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
                Image(systemName: "keyboard").imageScale(.large).onTapGesture {
                    showPaletteEditor = true
                }
//                    .sheet(isPresented: $showPaletteEditor) {
                    .popover(isPresented: $showPaletteEditor) {
                        PaletteEditor(chosenPalette: $chosenPalette, isShowing: $showPaletteEditor)
                            .frame(minWidth: 300, minHeight: 500)
                    }
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

struct PaletteEditor: View {
    @Binding var chosenPalette: String
    @Binding var isShowing: Bool
    @EnvironmentObject var document: EmojiArtDocument
    @State private var paletteName: String = ""
    @State private var emojisToAdd: String = ""

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Text("Palette Editor").font(.headline).padding()
                HStack {
                    Spacer()
                    Button(action: {
                        isShowing = false
                    },
                    label: { Text("Done") }).padding()
                }
            }
            Divider()
            Form {
                Section {
                    TextField("Palette Name", text: $paletteName, onEditingChanged: { began in
                        if !began {
                            document.renamePalette(chosenPalette, to: paletteName)
                        }
                    })
                    TextField("Add Emoji", text: $emojisToAdd, onEditingChanged: { began in
                        if !began {
                            chosenPalette = document.addEmoji(emojisToAdd, toPalette: chosenPalette)
                            emojisToAdd = ""
                        }
                    })
                }
                Section(header: Text("Remove Emoji")) {
                    Grid(chosenPalette.map { String($0) }, id: \.self) { emoji in
                        VStack {
                            Text(emoji).font(Font.system(size: fontSize))
                                .onTapGesture {
                                    chosenPalette = document.removeEmoji(emoji, fromPalette: chosenPalette)
                                }
                        }
                    }
                    .frame(height: height)
                }
            }
        }.onAppear {
            paletteName = document.paletteNames[chosenPalette] ?? ""
        }
    }

    // MARK: - Drawing constants
    var height: CGFloat {
        CGFloat((chosenPalette.count - 1) / 6 * 70 + 70)
    }
    // new: added @ScaledMetric this this line of code
    // so our default emoji size now scales with the user's font size preference
    @ScaledMetric var fontSize: CGFloat = 40

}

struct PalletView_Previews: PreviewProvider {
    static var previews: some View {
        PaletteChooser(document: EmojiArtDocument())
    }
}
