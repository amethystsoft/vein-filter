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
    public struct Equal<
        LHS : FilterExpression,
        RHS : FilterExpression
    > : FilterExpression
    where
        LHS.Output == RHS.Output,
        LHS.Output : Equatable
    {
        public typealias Output = Bool
        
        public let lhs: LHS
        public let rhs: RHS
        
        public init(lhs: LHS, rhs: RHS) {
            self.lhs = lhs
            self.rhs = rhs
        }
        
        public func evaluate(_ bindings: FilterBindings) throws -> Bool {
            try lhs.evaluate(bindings) == rhs.evaluate(bindings)
        }
    }
    
    public static func build_Equal<LHS, RHS>(lhs: LHS, rhs: RHS) -> Equal<LHS, RHS> {
        Equal(lhs: lhs, rhs: rhs)
    }
}

extension FilterExpressions.Equal : CustomStringConvertible {
    public var description: String {
        "Equal(lhs: \(lhs), rhs: \(rhs))"
    }
}

extension FilterExpressions.Equal : StandardFilterExpression where LHS : StandardFilterExpression, RHS : StandardFilterExpression {}

extension FilterExpressions.Equal : Codable where LHS : Codable, RHS : Codable {
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

extension FilterExpressions.Equal : Sendable where LHS : Sendable, RHS : Sendable {}
