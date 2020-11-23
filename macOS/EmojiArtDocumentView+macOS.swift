//
//  EmojiArtDocumentView+macOS.swift
//  EmojiArt (macOS)
//
//  Created by Joshua Olson on 11/20/20.
//

import SwiftUI

typealias UIImage = NSImage

struct EmojiArtDocumentView: View {
    @ObservedObject var document: EmojiArtDocument

    var body: some View {
        EmojiArtDocumentViewShared(document: document)
            .navigationBarItems(
                leading: HStack {
                    Button(action: {document.undo()},
                           label: { Image(systemName: "arrow.uturn.backward") })
                        .disabled(!(document.undoManager?.canUndo ?? false))
                    Button(action: {document.redo()},
                           label: { Image(systemName: "arrow.uturn.forward") })
                        .disabled(!(document.undoManager?.canRedo ?? false))
                })
    }
}

extension EmojiArtDocumentViewShared {
    var canvasView: some View {
        Color.white
        )
    }
}
