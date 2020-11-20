//
//  EmojiArtDocumentViewShared+Drop.swift
//  EmojiArt
//
//  Created by Joshua Olson on 11/20/20.
//

import SwiftUI

extension EmojiArtDocumentViewShared {
    func drop(providers: [NSItemProvider], at viewLocation: CGPoint, in geometry: GeometryProxy) -> Bool {
        let frameCoordinates = geometry.convert(viewLocation, from: .global)
        let centerOffset = geometry.size / 2
        // todo: - The grab location is ignored for the drop location
        // The emoji is dropped with its center at the pointer tip
        var location = CGPoint(x: frameCoordinates.x - centerOffset.width,
                               y: frameCoordinates.y - centerOffset.height)
        // Move origin from top left to view center
        location = CGPoint(x: location.x - panOffset.width, y: location.y - panOffset.height)

        // Now scale adjust the distances to the current scale
        return drop(providers: providers, at: location / zoomScale)
    }

    private func drop(providers: [NSItemProvider], at location: CGPoint) -> Bool {
        var found = providers.loadFirstObject(ofType: URL.self) { url in
            document.setBackgroundURL(url)
        }

        if !found {
            found = providers.loadObjects(ofType: String.self) { string in
                document.addEmoji(string, at: location, size: defaultEmojiSize)
            }
        }
        return found
    }
}
