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
        // For ReferenceFileDocument
        DocumentGroup(newDocument: EmojiArtDocument.init) { file in
            EmojiArtDocumentViewShared(document: file.document)
        }
    }
}
