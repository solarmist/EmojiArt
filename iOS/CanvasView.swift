//
//  CanvasView.swift
//  EmojiArt (iOS)
//
//  Created by Joshua Olson on 11/23/20.
//

import SwiftUI
import PencilKit

struct CanvasView: View {
    @Binding var canvasView: PKCanvasView

    @Binding var zoomScale: CGFloat
    @Binding var contentOffset: CGPoint

    @State var toolPicker = PKToolPicker()

    let onSaved: (PKDrawing) -> Void
}

// Delegate Extension
extension CanvasView: UIViewRepresentable {
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.tool = PKInkingTool(.pen, color: .gray, width: 10)
        canvasView.delegate = context.coordinator
        canvasView.maximumZoomScale = 20
        canvasView.minimumZoomScale = 1/20

        #if targetEnvironment(simulator)
        canvasView.drawingPolicy = .anyInput
        #endif
        showToolPicker()
        return canvasView
    }

    func showToolPicker() {
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(canvasView: $canvasView,
                    onSaved: onSaved)
    }

    // TODO: This needs to keep it's zoom and offset in sync with the document
    // probably using UIScrollViewDelegate
    class Coordinator: NSObject, PKCanvasViewDelegate {
        @Binding var canvasView: PKCanvasView

        let onSaved: (PKDrawing) -> Void

        init (canvasView: Binding<PKCanvasView>,
              onSaved: @escaping (PKDrawing) -> Void) {
            _canvasView = canvasView
            self.onSaved = onSaved
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            guard !canvasView.drawing.bounds.isEmpty else {
                return
            }
            onSaved(canvasView.drawing)
        }
    }
}
//
//struct CanvasView_Previews: PreviewProvider {
//    static var previews: some View {
//        CanvasView(
//            canvasView: .constant(PKCanvasView()),
//            zoomSize: .constant(CGFloat(100)),
//            contentOffset: .constant(CGPoint.zero),
//            onSaved: { _ in })
//    }
//}
