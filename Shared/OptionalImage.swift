//
//  OptionalImage.swift
//  EmojiArt
//
//  Created by Joshua Olson on 11/15/20.
//

import SwiftUI

struct OptionalImage: View {
    var uiImage: UIImage?

    @ViewBuilder
    var body: some View {
        Group {
            if uiImage != nil {
                Image(uiImage: uiImage!)
            }
        }
    }
}

struct OptionalImage_Previews: PreviewProvider {
    static var previews: some View {
        OptionalImage()
    }
}
