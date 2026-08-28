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
    public enum ArithmeticOperator: Codable, Sendable {
        case add, subtract, multiply
    }
    
    public struct Arithmetic<
        LHS : FilterExpression,
        RHS : FilterExpression
    > : FilterExpression
    where
        LHS.Output == RHS.Output,
        LHS.Output : Numeric
    {
        public typealias Output = LHS.Output
        
        public let op: ArithmeticOperator
        
        public let lhs: LHS
        public let rhs: RHS
        
        public init(lhs: LHS, rhs: RHS, op: ArithmeticOperator) {
            self.lhs = lhs
            self.rhs = rhs
            self.op = op
        }
        
        public func evaluate(_ bindings: FilterBindings) throws -> Output {
            let a = try lhs.evaluate(bindings)
            let b = try rhs.evaluate(bindings)
            switch op {
            case .add:      return a + b
            case .subtract: return a - b
            case .multiply: return a * b
            }
        }
    }
    
    public static func build_Arithmetic<LHS, RHS>(lhs: LHS, rhs: RHS, op: ArithmeticOperator) -> Arithmetic<LHS, RHS> {
        Arithmetic(lhs: lhs, rhs: rhs, op: op)
    }
}

extension FilterExpressions.Arithmetic : StandardFilterExpression where LHS : StandardFilterExpression, RHS : StandardFilterExpression {}

extension FilterExpressions.Arithmetic : CustomStringConvertible {
    public var description: String {
        "Arithmetic(lhs: \(lhs), operator: \(op), rhs: \(rhs))"
    }
}

extension FilterExpressions.Arithmetic : Codable where LHS : Codable, RHS : Codable {
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
        op = try container.decode(FilterExpressions.ArithmeticOperator.self)
    }
}

extension FilterExpressions.Arithmetic : Sendable where LHS : Sendable, RHS : Sendable {}
