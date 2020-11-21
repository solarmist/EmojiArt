//
//  EmojiArtApp.swift
//  Shared
//
//  Created by Joshua Olson on 11/14/20.
//

// TODO: drag without select not working
// TODO: Figure out how to make a delete button out of an Emoji with an overlay or the like

import SwiftUI

@main
struct EmojiArtApp: App {

    var body: some Scene {
        DocumentGroup(newDocument: EmojiArtDocument.init) { config in
            EmojiArtDocumentView(document: config.document)
        }
    }
}
