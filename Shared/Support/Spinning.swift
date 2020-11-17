//
//  Spinning.swift
//  EmojiArt (iOS)
//
//  Created by Joshua Olson on 11/16/20.
//

import SwiftUI

struct Spinning: ViewModifier {
    @State var isVisible = false

    func body(content: Content) -> some View {
        content
            .rotationEffect(Angle.degrees(isVisible ? 360 : 0))
            .animation(Animation.linear(duration: 1)
                        .repeatForever(autoreverses: false))
            .onAppear { isVisible = true }
    }
}

extension View {
    func spinning() -> some View {
        modifier(Spinning())
    }
}

struct Spinning_Previews: PreviewProvider {
    static var previews: some View {
        Text("Hugs are neat.").spinning()
    }
}
