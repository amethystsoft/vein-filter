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
    public enum ComparisonOperator: Codable, Sendable {
        case lessThan, lessThanOrEqual, greaterThan, greaterThanOrEqual
    }

    public struct Comparison<
        LHS : FilterExpression,
        RHS : FilterExpression
    > : FilterExpression
    where
        LHS.Output == RHS.Output,
        LHS.Output : Comparable
    {
        public typealias Output = Bool
        
        public let op: ComparisonOperator

        public let lhs: LHS
        public let rhs: RHS
        
        public init(lhs: LHS, rhs: RHS, op: ComparisonOperator) {
            self.lhs = lhs
            self.rhs = rhs
            self.op = op
        }
        
        public func evaluate(_ bindings: FilterBindings) throws -> Bool {
            let a = try lhs.evaluate(bindings)
            let b = try rhs.evaluate(bindings)
            switch op {
            case .lessThan:           return a < b
            case .lessThanOrEqual:    return a <= b
            case .greaterThan:        return a > b
            case .greaterThanOrEqual: return a >= b
            }
        }
    }
    
    public static func build_Comparison<LHS, RHS>(lhs: LHS, rhs: RHS, op: ComparisonOperator) -> Comparison<LHS, RHS> {
        Comparison(lhs: lhs, rhs: rhs, op: op)
    }
}

extension FilterExpressions.Comparison : CustomStringConvertible {
    public var description: String {
        "Comparison(lhs: \(lhs), operator: \(op), rhs: \(rhs))"
    }
}

extension FilterExpressions.Comparison : StandardFilterExpression where LHS : StandardFilterExpression, RHS : StandardFilterExpression {}

extension FilterExpressions.Comparison : Codable where LHS : Codable, RHS : Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(lhs)
        try container.encode(rhs)
        try container.encode(op)
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        lhs = try container.decode(LHS.self)
        rhs = try container.decode(RHS.self)
        op = try container.decode(FilterExpressions.ComparisonOperator.self)
    }
}

extension FilterExpressions.Comparison : Sendable where LHS : Sendable, RHS : Sendable {}
