//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2022-2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

// Modified by Mia Koring as amethystsoft in 2026 for vein-filter:
// Adjusted to work with older Apple OS versions.

extension FilterExpressions {
    public struct Range<
        LHS : FilterExpression,
        RHS : FilterExpression
    > : FilterExpression
    where
        LHS.Output == RHS.Output,
        LHS.Output: Comparable
    {
        public typealias Output = Swift.Range<LHS.Output>
        
        public let lower: LHS
        public let upper: RHS
        
        public init(lower: LHS, upper: RHS) {
            self.lower = lower
            self.upper = upper
        }
        
        public func evaluate(_ bindings: FilterBindings) throws -> Swift.Range<LHS.Output> {
            let low = try lower.evaluate(bindings)
            let high = try upper.evaluate(bindings)
            guard low <= high else {
                throw FilterError(.invalidInput("Range requires that lowerBound (\(low)) <= upperBound (\(high))"))
            }
            return low ..< high
        }
    }
    
    public static func build_Range<LHS, RHS>(lower: LHS, upper: RHS) -> Range<LHS, RHS> {
        Range(lower: lower, upper: upper)
    }
}

extension FilterExpressions.Range : CustomStringConvertible {
    public var description: String {
        "Range(lower: \(lower), upper: \(upper))"
    }
}

extension FilterExpressions.Range : StandardFilterExpression where LHS : StandardFilterExpression, RHS : StandardFilterExpression {}

extension FilterExpressions.Range : Codable where LHS : Codable, RHS : Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(lower)
        try container.encode(upper)
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        lower = try container.decode(LHS.self)
        upper = try container.decode(RHS.self)
    }
}

extension FilterExpressions.Range : Sendable where LHS : Sendable, RHS : Sendable {}

extension FilterExpressions {
    public struct ClosedRange<
        LHS : FilterExpression,
        RHS : FilterExpression
    > : FilterExpression
    where
        LHS.Output == RHS.Output,
        LHS.Output: Comparable
    {
        public typealias Output = Swift.ClosedRange<LHS.Output>
        
        public let lower: LHS
        public let upper: RHS
        
        public init(lower: LHS, upper: RHS) {
            self.lower = lower
            self.upper = upper
        }
        
        public func evaluate(_ bindings: FilterBindings) throws -> Swift.ClosedRange<LHS.Output> {
            let low = try lower.evaluate(bindings)
            let high = try upper.evaluate(bindings)
            return low...high
        }
    }
    
    public static func build_ClosedRange<LHS, RHS>(lower: LHS, upper: RHS) -> ClosedRange<LHS, RHS> {
        ClosedRange(lower: lower, upper: upper)
    }
}

extension FilterExpressions.ClosedRange : CustomStringConvertible {
    public var description: String {
        "ClosedRange(lower: \(lower), upper: \(upper))"
    }
}

extension FilterExpressions.ClosedRange : StandardFilterExpression where LHS : StandardFilterExpression, RHS : StandardFilterExpression {}

extension FilterExpressions.ClosedRange : Codable where LHS : Codable, RHS : Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(lower)
        try container.encode(upper)
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        lower = try container.decode(LHS.self)
        upper = try container.decode(RHS.self)
    }
}

extension FilterExpressions.ClosedRange : Sendable where LHS : Sendable, RHS : Sendable {}

extension FilterExpressions {
    public struct RangeExpressionContains<
        RangeExpression : FilterExpression,
        Element : FilterExpression
    > : FilterExpression where
        RangeExpression.Output : Swift.RangeExpression,
        Element.Output == RangeExpression.Output.Bound
    {
        public typealias Output = Bool
        
        public let range: RangeExpression
        public let element: Element
        
        public init(range: RangeExpression, element: Element) {
            self.range = range
            self.element = element
        }
        
        public func evaluate(_ bindings: FilterBindings) throws -> Output {
            try range.evaluate(bindings).contains(try element.evaluate(bindings))
        }
    }
    
    public static func build_contains<RangeExpression, Element>(_ range: RangeExpression, _ element: Element) -> RangeExpressionContains<RangeExpression, Element> {
        RangeExpressionContains(range: range, element: element)
    }
}

extension FilterExpressions.RangeExpressionContains : CustomStringConvertible {
    public var description: String {
        "RangeExpressionContains(range: \(range), element: \(element))"
    }
}

extension FilterExpressions.RangeExpressionContains : StandardFilterExpression where RangeExpression : StandardFilterExpression, Element : StandardFilterExpression {}

extension FilterExpressions.RangeExpressionContains : Codable where RangeExpression : Codable, Element : Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(range)
        try container.encode(element)
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        range = try container.decode(RangeExpression.self)
        element = try container.decode(Element.self)
    }
}

extension FilterExpressions.RangeExpressionContains : Sendable where RangeExpression : Sendable, Element : Sendable {}
