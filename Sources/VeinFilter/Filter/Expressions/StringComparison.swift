//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation

extension FilterExpressions {
    public struct StringCaseInsensitiveCompare<
        Root : FilterExpression,
        Other : FilterExpression
    > : FilterExpression where
        Root.Output : StringProtocol,
        Other.Output : StringProtocol
    {
        
        public typealias Output = ComparisonResult
        
        public let root: Root
        public let other: Other
        
        public init(root: Root, other: Other) {
            self.root = root
            self.other = other
        }
        
        public func evaluate(_ bindings: FilterBindings) throws -> Output {
            try root.evaluate(bindings).caseInsensitiveCompare(try other.evaluate(bindings))
        }
    }
    
    public static func build_caseInsensitiveCompare<Root, Other>(_ root: Root, _ other: Other) -> StringCaseInsensitiveCompare<Root, Other> {
        StringCaseInsensitiveCompare(root: root, other: other)
    }
}

extension FilterExpressions.StringCaseInsensitiveCompare : CustomStringConvertible {
    public var description: String {
        "StringCaseInsensitiveCompare(root: \(root), other: \(other))"
    }
}

extension FilterExpressions.StringCaseInsensitiveCompare : StandardFilterExpression where Root : StandardFilterExpression, Other : StandardFilterExpression {}

extension FilterExpressions.StringCaseInsensitiveCompare : Codable where Root : Codable, Other : Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(root)
        try container.encode(other)
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        root = try container.decode(Root.self)
        other = try container.decode(Other.self)
    }
}

extension FilterExpressions.StringCaseInsensitiveCompare : Sendable where Root : Sendable, Other : Sendable {}

