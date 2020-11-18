//
//  EmojiArtApp.swift
//  Shared
//
//  Created by Joshua Olson on 11/14/20.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    var store: EmojiArtDocumentStore {
        let store = EmojiArtDocumentStore(named: "Emoji Art")
        return store
    }

    var body: some Scene {
        WindowGroup {
            EmojiArtDocumentChooser().environmentObject(store)
        }
    }
}
