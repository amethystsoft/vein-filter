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

extension FilterExpressions {
    public struct IntDivision<
        LHS : FilterExpression,
        RHS : FilterExpression
    > : FilterExpression
    where
        LHS.Output == RHS.Output,
        LHS.Output : BinaryInteger
    {
        public typealias Output = LHS.Output
        
        public let lhs: LHS
        public let rhs: RHS
        
        public init(lhs: LHS, rhs: RHS) {
            self.lhs = lhs
            self.rhs = rhs
        }
        
        public func evaluate(_ bindings: FilterBindings) throws -> Output {
            let a = try lhs.evaluate(bindings)
            let b = try rhs.evaluate(bindings)
            return a / b
        }
    }

    public struct IntRemainder<
        LHS : FilterExpression,
        RHS : FilterExpression
    > : FilterExpression
    where
        LHS.Output == RHS.Output,
        LHS.Output : BinaryInteger
    {
        public typealias Output = LHS.Output
        
        public let lhs: LHS
        public let rhs: RHS
        
        public init(lhs: LHS, rhs: RHS) {
            self.lhs = lhs
            self.rhs = rhs
        }
        
        public func evaluate(_ bindings: FilterBindings) throws -> Output {
            let a = try lhs.evaluate(bindings)
            let b = try rhs.evaluate(bindings)
            return a % b
        }
    }

    public struct FloatDivision<
        LHS : FilterExpression,
        RHS : FilterExpression
    > : FilterExpression
    where
        LHS.Output == RHS.Output,
        LHS.Output : FloatingPoint
    {
        public typealias Output = LHS.Output
        
        public let lhs: LHS
        public let rhs: RHS
        
        public init(lhs: LHS, rhs: RHS) {
            self.lhs = lhs
            self.rhs = rhs
        }
        
        public func evaluate(_ bindings: FilterBindings) throws -> Output {
            let a = try lhs.evaluate(bindings)
            let b = try rhs.evaluate(bindings)
            return a / b
        }
    }
    
    public static func build_Division<LHS, RHS>(lhs: LHS, rhs: RHS) -> IntDivision<LHS, RHS> {
        IntDivision(lhs: lhs, rhs: rhs)
    }
    
    public static func build_Division<LHS, RHS>(lhs: LHS, rhs: RHS) -> FloatDivision<LHS, RHS> {
        FloatDivision(lhs: lhs, rhs: rhs)
    }
    
    public static func build_Remainder<LHS, RHS>(lhs: LHS, rhs: RHS) -> IntRemainder<LHS, RHS> {
        IntRemainder(lhs: lhs, rhs: rhs)
    }
}

extension FilterExpressions.FloatDivision : CustomStringConvertible {
    public var description: String {
        "FloatDivision(lhs: \(lhs), rhs: \(rhs))"
    }
}

extension FilterExpressions.IntDivision : CustomStringConvertible {
    public var description: String {
        "IntDivision(lhs: \(lhs), rhs: \(rhs))"
    }
}

extension FilterExpressions.IntRemainder : CustomStringConvertible {
    public var description: String {
        "IntRemainder(lhs: \(lhs), rhs: \(rhs))"
    }
}

extension FilterExpressions.FloatDivision : StandardFilterExpression where LHS : StandardFilterExpression, RHS : StandardFilterExpression {}

extension FilterExpressions.IntRemainder : StandardFilterExpression where LHS : StandardFilterExpression, RHS : StandardFilterExpression {}

extension FilterExpressions.IntDivision : StandardFilterExpression where LHS : StandardFilterExpression, RHS : StandardFilterExpression {}

extension FilterExpressions.FloatDivision : Codable where LHS : Codable, RHS : Codable {
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

extension FilterExpressions.IntRemainder : Codable where LHS : Codable, RHS : Codable {
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

extension FilterExpressions.IntDivision : Codable where LHS : Codable, RHS : Codable {
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

extension FilterExpressions.FloatDivision : Sendable where LHS : Sendable, RHS : Sendable {}

extension FilterExpressions.IntRemainder : Sendable where LHS : Sendable, RHS : Sendable {}

extension FilterExpressions.IntDivision : Sendable where LHS : Sendable, RHS : Sendable {}
