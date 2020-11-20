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
    }
}
