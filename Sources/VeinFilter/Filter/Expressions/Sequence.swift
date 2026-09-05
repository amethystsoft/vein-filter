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
    public struct SequenceContains<
        LHS : FilterExpression,
        RHS : FilterExpression
    > : FilterExpression
    where
        LHS.Output : Sequence,
        LHS.Output.Element : Equatable,
        RHS.Output == LHS.Output.Element
    {
        public typealias Output = Bool
        
        public let sequence: LHS
        public let element: RHS
        
        public init(sequence: LHS, element: RHS) {
            self.sequence = sequence
            self.element = element
        }
        
        public func evaluate(_ bindings: FilterBindings) throws -> Bool {
            let a = try sequence.evaluate(bindings)
            let b = try element.evaluate(bindings)
            return a.contains(b)
        }
    }
    
    public struct SequenceContainsWhere<
        LHS : FilterExpression,
        RHS : FilterExpression
    > : FilterExpression
    where
        LHS.Output : Sequence,
        RHS.Output == Bool
    {
        public typealias Element = LHS.Output.Element
        public typealias Output = Bool

        public let sequence: LHS
        public let test: RHS
        public let variable: Variable<Element>
        
        public init(_ sequence: LHS, builder: (Variable<Element>) -> RHS) {
            self.variable = Variable()
            self.sequence = sequence
            self.test = builder(variable)
        }
        
        public func evaluate(_ bindings: FilterBindings) throws -> Output {
            var mutableBindings = bindings
            return try sequence.evaluate(bindings).contains {
                mutableBindings[variable] = $0
                return try test.evaluate(mutableBindings)
            }
        }
    }
    
    public struct SequenceAllSatisfy<
        LHS : FilterExpression,
        RHS : FilterExpression
    > : FilterExpression
    where
        LHS.Output : Sequence,
        RHS.Output == Bool
    {
        public typealias Element = LHS.Output.Element
        public typealias Output = Bool

        public let sequence: LHS
        public let test: RHS
        public let variable: Variable<Element>
        
        public init(_ sequence: LHS, builder: (Variable<Element>) -> RHS) {
            self.variable = Variable()
            self.sequence = sequence
            self.test = builder(variable)
        }
        
        public func evaluate(_ bindings: FilterBindings) throws -> Output {
            var mutableBindings = bindings
            return try sequence.evaluate(bindings).allSatisfy {
                mutableBindings[variable] = $0
                return try test.evaluate(mutableBindings)
            }
        }
    }
    
    public struct SequenceStartsWith<
        Base : FilterExpression,
        Prefix : FilterExpression
    > : FilterExpression
    where
        Base.Output : Sequence,
        Prefix.Output : Sequence,
        Base.Output.Element == Prefix.Output.Element,
        Base.Output.Element : Equatable
    {
        public typealias Output = Bool
        
        public let base: Base
        public let prefix: Prefix
        
        public init(base: Base, prefix: Prefix) {
            self.base = base
            self.prefix = prefix
        }
        
        public func evaluate(_ bindings: FilterBindings) throws -> Bool {
            try base.evaluate(bindings).starts(with: try prefix.evaluate(bindings))
        }
    }
    
    @_disfavoredOverload
    public static func build_contains<LHS, RHS>(_ lhs: LHS, _ rhs: RHS) -> SequenceContains<LHS, RHS> {
        SequenceContains(sequence: lhs, element: rhs)
    }
    
    public static func build_contains<LHS, RHS>(_ lhs: LHS, where builder: (Variable<LHS.Output.Element>) -> RHS) -> SequenceContainsWhere<LHS, RHS> {
        SequenceContainsWhere(lhs, builder: builder)
    }
    
    public static func build_allSatisfy<LHS, RHS>(_ lhs: LHS, _ builder: (Variable<LHS.Output.Element>) -> RHS) -> SequenceAllSatisfy<LHS, RHS> {
        SequenceAllSatisfy(lhs, builder: builder)
    }
    
    public static func build_starts<Base, Prefix>(_ base: Base, with prefix: Prefix) -> SequenceStartsWith<Base, Prefix> {
        SequenceStartsWith(base: base, prefix: prefix)
    }
}

extension FilterExpressions.SequenceContains : CustomStringConvertible {
    public var description: String {
        "SequenceContains(sequence: \(sequence), element: \(element))"
    }
}

extension FilterExpressions.SequenceContainsWhere : CustomStringConvertible {
    public var description: String {
        "SequenceContainsWhere(sequence: \(sequence), variable: \(variable), test: \(test))"
    }
}

extension FilterExpressions.SequenceAllSatisfy : CustomStringConvertible {
    public var description: String {
        "SequenceAllSatisfy(sequence: \(sequence), variable: \(variable), test: \(test))"
    }
}

extension FilterExpressions.SequenceContains : StandardFilterExpression where LHS : StandardFilterExpression, RHS : StandardFilterExpression {}

extension FilterExpressions.SequenceContainsWhere : StandardFilterExpression where LHS : StandardFilterExpression, RHS : StandardFilterExpression {}

extension FilterExpressions.SequenceAllSatisfy : StandardFilterExpression where LHS : StandardFilterExpression, RHS : StandardFilterExpression {}

extension FilterExpressions.SequenceStartsWith : StandardFilterExpression where Base : StandardFilterExpression, Prefix : StandardFilterExpression {}

extension FilterExpressions.SequenceContains : Codable where LHS : Codable, RHS : Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(sequence)
        try container.encode(element)
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        sequence = try container.decode(LHS.self)
        element = try container.decode(RHS.self)
    }
}

extension FilterExpressions.SequenceContainsWhere : Codable where LHS : Codable, RHS : Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(sequence)
        try container.encode(test)
        try container.encode(variable)
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        sequence = try container.decode(LHS.self)
        test = try container.decode(RHS.self)
        variable = try container.decode(FilterExpressions.Variable<Element>.self)
    }
}

extension FilterExpressions.SequenceAllSatisfy : Codable where LHS : Codable, RHS : Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(sequence)
        try container.encode(test)
        try container.encode(variable)
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        sequence = try container.decode(LHS.self)
        test = try container.decode(RHS.self)
        variable = try container.decode(FilterExpressions.Variable<Element>.self)
    }
}

extension FilterExpressions.SequenceStartsWith : Codable where Base : Codable, Prefix : Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(base)
        try container.encode(prefix)
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.base = try container.decode(Base.self)
        self.prefix = try container.decode(Prefix.self)
    }
}

extension FilterExpressions.SequenceContains : Sendable where LHS : Sendable, RHS : Sendable {}

extension FilterExpressions.SequenceContainsWhere : Sendable where LHS : Sendable, RHS : Sendable {}

extension FilterExpressions.SequenceAllSatisfy : Sendable where LHS : Sendable, RHS : Sendable {}

extension FilterExpressions.SequenceStartsWith : Sendable where Base : Sendable, Prefix : Sendable {}
