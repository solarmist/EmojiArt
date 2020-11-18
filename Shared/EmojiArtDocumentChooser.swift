//
//  EmojiArtDocumentChooser.swift
//  EmojiArt
//
//  Created by Joshua Olson on 11/17/20.
//

import SwiftUI

struct EmojiArtDocumentChooser: View {
    @EnvironmentObject var store: EmojiArtDocumentStore

    @State private var editMode: EditMode = .inactive

    var body: some View {
        NavigationView {
            List {
                ForEach(store.documents) { document in
                    NavigationLink(destination: EmojiArtDocumentView(document: document)
                        .navigationBarTitle(store.name(for: document))
                    ) {
                        EditableText(store.name(for: document), isEditing: editMode.isEditing) { newValue in
                            store.setName(newValue, for: document)
                        }
                    }
                }
                .onDelete { indexSet in
                    indexSet.map { store.documents[$0] }.forEach { document in
                        print("Delete \(store.name(for: document))")
                        store.removeDocument(document)
                    }
                }
            }
            .navigationBarTitle(store.name)
            .navigationBarItems(
                leading: Button(action: { store.addDocument() },
                                label: { Image(systemName: "plus").imageScale(.large) }
                ),
                trailing: EditButton()
            )
            // This needs to be on the List not the NavigationView
            .environment(\.editMode, $editMode)
        }
    }
}

struct EmojiArtDocumentChooser_Previews: PreviewProvider {
    static var store: EmojiArtDocumentStore {
        let store = EmojiArtDocumentStore()
        store.addDocument()
        store.addDocument(named: "Some Document")
        return store
    }
    static var previews: some View {
        EmojiArtDocumentChooser().environmentObject(store)
    }
}
