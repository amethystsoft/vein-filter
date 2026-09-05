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

// Modified by Mia Koring as amethystsoft in 2026 for vein-filter:
// Adjusted to work with older Apple OS versions.

extension FilterExpressions {
    public struct SequenceMaximum<
        Elements : FilterExpression
    > : FilterExpression where
        Elements.Output : Sequence,
        Elements.Output.Element : Comparable
    {
        public typealias Output = Optional<Elements.Output.Element>
        
        public let elements: Elements
        
        public init(elements: Elements) {
            self.elements = elements
        }
        
        public func evaluate(_ bindings: FilterBindings) throws -> Output {
            try elements.evaluate(bindings).max()
        }
    }
    
    public static func build_max<Elements>(_ elements: Elements) -> SequenceMaximum<Elements> {
        SequenceMaximum(elements: elements)
    }
}

extension FilterExpressions.SequenceMaximum : StandardFilterExpression where Elements : StandardFilterExpression {}

extension FilterExpressions.SequenceMaximum : CustomStringConvertible {
    public var description: String {
        "SequenceMaximum(elements: \(elements))"
    }
}

extension FilterExpressions.SequenceMaximum : Codable where Elements : Codable {}

extension FilterExpressions.SequenceMaximum : Sendable where Elements : Sendable {}

extension FilterExpressions {
    public struct SequenceMinimum<
        Elements : FilterExpression
    > : FilterExpression where
        Elements.Output : Sequence,
        Elements.Output.Element : Comparable
    {
        public typealias Output = Optional<Elements.Output.Element>
        
        public let elements: Elements
        
        public init(elements: Elements) {
            self.elements = elements
        }
        
        public func evaluate(_ bindings: FilterBindings) throws -> Output {
            try elements.evaluate(bindings).min()
        }
    }
    
    public static func build_min<Elements>(_ elements: Elements) -> SequenceMinimum<Elements> {
        SequenceMinimum(elements: elements)
    }
}

extension FilterExpressions.SequenceMinimum : StandardFilterExpression where Elements : StandardFilterExpression {}

extension FilterExpressions.SequenceMinimum : CustomStringConvertible {
    public var description: String {
        "SequenceMinimum(elements: \(elements))"
    }
}

extension FilterExpressions.SequenceMinimum : Codable where Elements : Codable {}

extension FilterExpressions.SequenceMinimum : Sendable where Elements : Sendable {}
