//
//  EmojiArtExtensions.swift
//  EmojiArt
//
//  Created by CS193p Instructor on 4/27/20.
//  Copyright © 2020 Stanford University. All rights reserved.
//

import SwiftUI

extension Collection where Element: Identifiable {
    func firstIndex(matching element: Element) -> Self.Index? {
        firstIndex(where: { $0.id == element.id })
    }
    // note that contains(matching:) is different than contains()
    // this version uses the Identifiable-ness of its elements
    // to see whether a member of the Collection has the same identity
    func contains(matching element: Element) -> Bool {
        self.contains(where: { $0.id == element.id })
    }
}

extension Data {
    // just a simple converter from a Data to a String
    var utf8: String? { String(data: self, encoding: .utf8 ) }
}

extension URL {
    var imageURL: URL {
        // check to see if there is an embedded imgurl reference
        for query in query?.components(separatedBy: "&") ?? [] {
            let queryComponents = query.components(separatedBy: "=")
            if queryComponents.count == 2 {
                if queryComponents[0] == "imgurl", let url = URL(
                    string: queryComponents[1].removingPercentEncoding ?? "") {
                    return url
                }
            }
        }
        // this snippet supports the demo in Lecture 14
        // see storeInFilesystem below
        if isFileURL {
            var url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            url = url?.appendingPathComponent(self.lastPathComponent)
            if url != nil {
                return url!
            }
        }
        return self.baseURL ?? self
    }
}

extension GeometryProxy {
    // converts from some other coordinate space to the proxy's own
    func convert(_ point: CGPoint, from coordinateSpace: CoordinateSpace) -> CGPoint {
        let frame = self.frame(in: coordinateSpace)
        return CGPoint(x: point.x - frame.origin.x,
                       y: point.y - frame.origin.y)
    }
}

// simplifies the drag/drop portion of the demo
// you might be able to grok this
// but it does use a generic function
// and also is doing multithreaded stuff here
// and also is bridging to Objective-C-based API
// so kind of too much to talk about during lecture at this point in the game!

extension Array where Element == NSItemProvider {
    func loadObjects<T>(
        ofType theType: T.Type,
        firstOnly: Bool = false,
        using load: @escaping (T) -> Void
    ) -> Bool where T: NSItemProviderReading {
        if let provider = self.first(where: { $0.canLoadObject(ofClass: theType) }) {
            provider.loadObject(ofClass: theType) { object, _ in
                if let value = object as? T {
                    DispatchQueue.main.async {
                        load(value)
                    }
                }
            }
            return true
        }
        return false
    }
    func loadObjects<T>(
        ofType theType: T.Type,
        firstOnly: Bool = false,
        using load: @escaping (T) -> Void
    ) -> Bool where T: _ObjectiveCBridgeable, T._ObjectiveCType: NSItemProviderReading {
        if let provider = self.first(where: { $0.canLoadObject(ofClass: theType) }) {
            _ = provider.loadObject(ofClass: theType) { object, _ in
                if let value = object {
                    DispatchQueue.main.async {
                        load(value)
                    }
                }
            }
            return true
        }
        return false
    }
    func loadFirstObject<T>(
        ofType theType: T.Type,
        using load: @escaping (T) -> Void
    ) -> Bool where T: NSItemProviderReading {
        self.loadObjects(ofType: theType, firstOnly: true, using: load)
    }
    func loadFirstObject<T>(
        ofType theType: T.Type,
        using load: @escaping (T) -> Void
    ) -> Bool where T: _ObjectiveCBridgeable, T._ObjectiveCType: NSItemProviderReading {
        self.loadObjects(ofType: theType, firstOnly: true, using: load)
    }
}

extension String {
    // returns ourself without any duplicate Characters
    // not very efficient, so only for use on small-ish Strings
    func uniqued() -> String {
        var uniqued = ""
        for cha in self {
            if !uniqued.contains(cha) {
                uniqued.append(cha)
            }
        }
        return uniqued
    }
}

// it cleans up our code to be able to do more "math" on points and sizes

extension CGPoint {
    static func - (lhs: Self, rhs: Self) -> CGSize {
        CGSize(width: lhs.x - rhs.x, height: lhs.y - rhs.y)
    }
    static func + (lhs: Self, rhs: CGSize) -> CGPoint {
        CGPoint(x: lhs.x + rhs.width, y: lhs.y + rhs.height)
    }
    static func - (lhs: Self, rhs: CGSize) -> CGPoint {
        CGPoint(x: lhs.x - rhs.width, y: lhs.y - rhs.height)
    }
    static func * (lhs: Self, rhs: CGFloat) -> CGPoint {
        CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
    }
    static func / (lhs: Self, rhs: CGFloat) -> CGPoint {
        CGPoint(x: lhs.x / rhs, y: lhs.y / rhs)
    }
}

extension CGSize {
    static func + (lhs: Self, rhs: Self) -> CGSize {
        CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }
    static func - (lhs: Self, rhs: Self) -> CGSize {
        CGSize(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
    }
    static func * (lhs: Self, rhs: CGFloat) -> CGSize {
        CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
    }
    static func / (lhs: Self, rhs: CGFloat) -> CGSize {
        CGSize(width: lhs.width/rhs, height: lhs.height/rhs)
    }
}

extension String {
    // returns ourself but with numbers appended to the end
    // if necessary to make ourself unique with respect to those other Strings
    func uniqued<StringCollection>(withRespectTo otherStrings: StringCollection) -> String
        where StringCollection: Collection, StringCollection.Element == String {
        var unique = self
        while otherStrings.contains(unique) {
            unique = unique.incremented
        }
        return unique
    }

    // if a number is at the end of this String
    // this increments that number
    // otherwise, it appends the number 1
    var incremented: String {
        let prefix = String(self.reversed().drop(while: { $0.isNumber }).reversed())
        if let number = Int(self.dropFirst(prefix.count)) {
            return "\(prefix)\(number+1)"
        } else {
            return "\(self) 1"
        }
    }
}

// new
// CGSize and CGFloat are made to be RawRepresentable
// so that they can be used with @SceneStorage

extension CGSize: RawRepresentable {
    // want to use NSCoder.cgSize, but evidently not available on Mac?
    // so we use our own format for representing a CGSize as a String
    public var rawValue: String {
        "\(width),\(height)"
    }
    public init?(rawValue: String) {
        let values = rawValue.components(separatedBy: ",")
        if values.count == 2, let width = Double(values[0]), let height = Double(values[1]) {
            self.init(width: width, height: height)
        } else {
            return nil
        }
    }
}

extension CGFloat: RawRepresentable {
    public var rawValue: String {
        description
    }
    public init?(rawValue: String) {
        if let doubleValue = Double(rawValue) {
            self.init(doubleValue)
        } else {
            return nil
        }
    }
}
