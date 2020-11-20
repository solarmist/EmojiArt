//
//  EmojiArtDocumentView.swift
//  EmojiArt
//
//  Created by Joshua Olson on 11/20/20.
//

import SwiftUI

struct EmojiArtDocumentView: View {
    @Environment(\.undoManager) var undoManager
    @ObservedObject var document: EmojiArtDocument

    var body: some View {
        EmojiArtDocumentViewShared(document: document)
            .navigationBarItems(trailing: iOSOnlyToolbarItems)
            .alert(isPresented: $confirmBackgroundPaste, content: confirmBackgroundPasteAlert)
    }

    @State var explainBackgroundPaste = false
    @State var confirmBackgroundPaste = false

    private var iOSOnlyToolbarItems: some View {
        HStack(spacing: 20) {
            pasteBackgroundImage
        }
    }

    private var pasteBackgroundImage: some View {
        Button(action: {
            if let url = UIPasteboard.general.url, url != document.backgroundURL {
                confirmBackgroundPaste = true
            } else if UIPasteboard.general.image != nil {
                confirmBackgroundPaste = true
            } else {
                explainBackgroundPaste = true
            }
        }, label: {
            Image(systemName: "doc.on.clipboard").imageScale(.large)
                .alert(isPresented: $explainBackgroundPaste) {
                    Alert(
                        title: Text("Paste Background"),
                        message: Text("Copy an image to the clip board and touch " +
                                      "this button to make it the background of your document."),
                        dismissButton: .default(Text("OK"))
                    )
                }
        })
    }

    private func confirmBackgroundPasteAlert() -> Alert {
        let url = UIPasteboard.general.url
        let pastedThing = url == nil ? "pasted image" : url!.absoluteString
        return Alert(
            title: Text("Paste Background"),
            message: Text("Replace your background with \(pastedThing)?."),
            primaryButton: .default(Text("OK")) {
                document.setBackgroundURL(UIPasteboard.general.url)
                if url != nil {
                    document.setBackgroundURL(url)
                } else if let imageData = UIPasteboard.general.image?.jpegData(compressionQuality: 1.0) {
                    document.setBackgroundImageData(imageData)
                }
            },
            secondaryButton: .cancel()
        )
    }
}
//
//struct EmojiArtDocumentView_Previews: PreviewProvider {
//    static var previews: some View {
//        EmojiArtDocumentView()
//    }
//}
