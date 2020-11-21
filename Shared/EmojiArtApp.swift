//
//  EmojiArtApp.swift
//  Shared
//
//  Created by Joshua Olson on 11/14/20.
//

import SwiftUI

@main
struct EmojiArtApp: App {

    var body: some Scene {
        DocumentGroup(newDocument: EmojiArtDocument.init) { config in
            EmojiArtDocumentView(document: config.document)
        }
    }
}
