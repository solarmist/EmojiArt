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
        if document.undoManager == nil && undoManager != nil {
            document.undoManager = undoManager
        }
        return EmojiArtDocumentViewShared(document: document)
            .navigationBarItems(
                leading: HStack {
                    Button(action: {document.undo()},
                           label: { Image(systemName: "arrow.uturn.backward") })
                        .disabled(!(document.undoManager?.canUndo ?? false))
                    Button(action: {document.redo()},
                           label: { Image(systemName: "arrow.uturn.forward") })
                        .disabled(!(document.undoManager?.canRedo ?? false))
                },
                trailing: iOSOnlyToolbarItems)
            .alert(isPresented: $confirmBackgroundPaste,
                   content: confirmBackgroundPasteAlert)
    }

    @State var showImagePicker = false
    @State var imagePickerSourceType = UIImagePickerController.SourceType.photoLibrary

    private var iOSOnlyToolbarItems: some View {
        HStack(spacing: 20) {
            photoLibraryImagePicker
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                cameraImagePicker
            }
            pasteBackgroundImage
        }
        .sheet(isPresented: $showImagePicker) {
            imagePicker
        }
    }

    private var photoLibraryImagePicker: some View {
        Image(systemName: "photo")
            .imageScale(.large)
            .foregroundColor(.accentColor)
            .onTapGesture {
                imagePickerSourceType = .photoLibrary
                showImagePicker = true
            }

    }

    private var cameraImagePicker: some View {
        Image(systemName: "camera")
            .imageScale(.large)
            .foregroundColor(.accentColor)
            .onTapGesture {
                imagePickerSourceType = .camera
                showImagePicker = true
            }
    }

    private var imagePicker: some View {
        ImagePicker(sourceType: imagePickerSourceType) { image in
            guard image != nil else { return }
            // Throw it on the main queue for after the UI finishes handling
            // showing the image picker stuff and putting it away
            // To avoid something like: "Not allowed to modify view while constructing body", etc.
            DispatchQueue.main.async {
                guard let imageData = image?.jpegData(compressionQuality: 1.0) else { return }
                print("Setting background image")
                document.setBackgroundImageData(imageData)
            }
            showImagePicker = false
        }
    }

    @State var explainBackgroundPaste = false
    @State var confirmBackgroundPaste = false

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

// Extend the document view with PencilKit
extension EmojiArtDocumentViewShared {
    var canvasView: some View {
        if pkCanvasView.drawing != document.drawing {
            pkCanvasView.drawing = document.drawing
        }
        pkCanvasView.backgroundColor = .clear
        pkCanvasView.isOpaque = false
        let view = CanvasView(
            canvasView: $pkCanvasView,
            zoomScale: .constant(zoomScale),
            contentOffset: .constant(CGPoint.zero + panOffset),
            onSaved: document.drawingChanged)
        return view
    }
}

//
//struct EmojiArtDocumentView_Previews: PreviewProvider {
//    static var previews: some View {
//        EmojiArtDocumentView()
//    }
//}
