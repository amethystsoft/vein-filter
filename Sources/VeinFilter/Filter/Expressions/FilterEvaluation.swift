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
/*
extension FilterExpressions {
        public struct FilterEvaluate<
        Condition : FilterExpression,
        each Input : FilterExpression
    > : FilterExpression
    where
        Condition.Output == Filter<repeat (each Input).Output>
    {
        
        public typealias Output = Bool
        
        public let Filter: Condition
        public let input: (repeat each Input)
        
        public init(Filter: Condition, input: repeat each Input) {
            self.Filter = Filter
            self.input = (repeat each input)
        }
        
        public func evaluate(_ bindings: FilterBindings) throws -> Output {
            try Filter.evaluate(bindings).evaluate(repeat try (each input).evaluate(bindings))
        }
    }
    
        public static func build_evaluate<Condition, each Input>(_ Filter: Condition, _ input: repeat each Input) -> FilterEvaluate<Condition, repeat each Input> {
        FilterEvaluate<Condition, repeat each Input>(Filter: Filter, input: repeat each input)
    }
}

extension FilterExpressions.FilterEvaluate : CustomStringConvertible {
    public var description: String {
        "FilterEvaluate(Filter: \(Filter), input: \(input))"
    }
}

extension FilterExpressions.FilterEvaluate : StandardFilterExpression where Condition : StandardFilterExpression, repeat each Input : StandardFilterExpression {}

extension FilterExpressions.FilterEvaluate : Codable where Condition : Codable, repeat each Input : Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(Filter)
        repeat try container.encode(each input)
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.Filter = try container.decode(Condition.self)
        self.input = (repeat try container.decode((each Input).self))
    }
}

extension FilterExpressions.FilterEvaluate : Sendable where Condition : Sendable, repeat each Input : Sendable {}
*/
