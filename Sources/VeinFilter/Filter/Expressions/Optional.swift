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
    public struct OptionalFlatMap<
        LHS : FilterExpression,
        Wrapped,
        RHS : FilterExpression,
        Result
    > : FilterExpression
    where
    LHS.Output == Optional<Wrapped>
    {
        public typealias Output = Optional<Result>

        public let wrapped: LHS
        public let transform: RHS
        public let variable: Variable<Wrapped>

        public init(_ wrapped: LHS, _ builder: (Variable<Wrapped>) -> RHS) where RHS.Output == Result {
            self.wrapped = wrapped
            self.variable = Variable()
            self.transform = builder(variable)
        }
        
        public init(_ wrapped: LHS, _ builder: (Variable<Wrapped>) -> RHS) where RHS.Output == Optional<Result> {
            self.wrapped = wrapped
            self.variable = Variable()
            self.transform = builder(variable)
        }
        
        public func evaluate(_ bindings: FilterBindings) throws -> Output {
            var mutableBindings = bindings
            return try wrapped.evaluate(bindings).flatMap { inner in
                mutableBindings[variable] = inner
                return try transform.evaluate(mutableBindings) as! Result?
            }
        }
    }

    public static func build_flatMap<LHS, RHS, Wrapped, Result>(_ wrapped: LHS, _ builder: (Variable<Wrapped>) -> RHS) -> OptionalFlatMap<LHS, Wrapped, RHS, Result> where RHS.Output == Result {
        OptionalFlatMap(wrapped, builder)
    }

    public static func build_flatMap<LHS, RHS, Wrapped, Result>(_ wrapped: LHS, _ builder: (Variable<Wrapped>) -> RHS) -> OptionalFlatMap<LHS, Wrapped, RHS, Result> where RHS.Output == Optional<Result> {
        OptionalFlatMap(wrapped, builder)
    }
    
    public struct NilCoalesce<
        LHS : FilterExpression,
        RHS : FilterExpression
    > : FilterExpression
    where
    LHS.Output == Optional<RHS.Output>
    {
        public typealias Output = RHS.Output
        
        public let lhs: LHS
        public let rhs: RHS
        
        public init(lhs: LHS, rhs: RHS) {
            self.lhs = lhs
            self.rhs = rhs
        }
        
        public func evaluate(_ bindings: FilterBindings) throws -> Output {
            try lhs.evaluate(bindings) ?? rhs.evaluate(bindings)
        }
    }
    
    public static func build_NilCoalesce<LHS, RHS>(lhs: LHS, rhs: RHS) -> NilCoalesce<LHS, RHS> {
        NilCoalesce(lhs: lhs, rhs: rhs)
    }
    
    public struct ForcedUnwrap<
        Inner : FilterExpression,
        Wrapped
    > : FilterExpression
    where
        Inner.Output == Optional<Wrapped>
    {
        public typealias Output = Wrapped
        
        public let inner: Inner
        
        public init(_ inner: Inner) {
            self.inner = inner
        }
        
        public func evaluate(_ bindings: FilterBindings) throws -> Wrapped {
            let input = try inner.evaluate(bindings)
            if let result = input {
                return result
            }
            throw FilterError(.forceUnwrapFailure("Found nil when unwrapping value of type '\(type(of: input))'"))
        }
    }
    
    public static func build_ForcedUnwrap<Inner, Wrapped>(_ inner: Inner) -> ForcedUnwrap<Inner, Wrapped> where Inner.Output == Optional<Wrapped> {
        ForcedUnwrap(inner)
    }
}

extension FilterExpressions.OptionalFlatMap : CustomStringConvertible {
    public var description: String {
        "OptionalFlatMap(wrapped: \(wrapped), variable: \(variable), transform: \(transform))"
    }
}

extension FilterExpressions.NilCoalesce : CustomStringConvertible {
    public var description: String {
        "NilCoalesce(lhs: \(lhs), rhs: \(rhs))"
    }
}

extension FilterExpressions.ForcedUnwrap : CustomStringConvertible {
    public var description: String {
        "ForcedUnwrap(inner: \(inner))"
    }
}

extension FilterExpressions.OptionalFlatMap : StandardFilterExpression where LHS : StandardFilterExpression, RHS : StandardFilterExpression {}

extension FilterExpressions.NilCoalesce : StandardFilterExpression where LHS : StandardFilterExpression, RHS : StandardFilterExpression {}

extension FilterExpressions.ForcedUnwrap : StandardFilterExpression where Inner : StandardFilterExpression {}

extension FilterExpressions.OptionalFlatMap : Codable where LHS : Codable, RHS : Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(wrapped)
        try container.encode(transform)
        try container.encode(variable)
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        wrapped = try container.decode(LHS.self)
        transform = try container.decode(RHS.self)
        variable = try container.decode(FilterExpressions.Variable<Wrapped>.self)
    }
}

extension FilterExpressions.NilCoalesce : Codable where LHS : Codable, RHS : Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(lhs)
        try container.encode(rhs)
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        lhs = try container.decode(LHS.self)
        rhs = try container.decode(RHS.self)
    }
}

extension FilterExpressions.ForcedUnwrap : Codable where Inner : Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(inner)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        inner = try container.decode(Inner.self)
    }
}

extension FilterExpressions.OptionalFlatMap : Sendable where LHS : Sendable, RHS : Sendable {}

extension FilterExpressions.NilCoalesce : Sendable where LHS : Sendable, RHS : Sendable {}

extension FilterExpressions.ForcedUnwrap : Sendable where Inner : Sendable {}

extension FilterExpressions {
    public struct NilLiteral<Wrapped> : StandardFilterExpression, Codable, Sendable {
        public typealias Output = Optional<Wrapped>
        
        public init() {}
        
        public func evaluate(_ bindings: FilterBindings) throws -> Output {
            nil
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encodeNil()
        }
        
        public init(from decoder: Decoder) throws {}
    }
    
    public static func build_NilLiteral<Wrapped>() -> NilLiteral<Wrapped> {
        NilLiteral()
    }
}
