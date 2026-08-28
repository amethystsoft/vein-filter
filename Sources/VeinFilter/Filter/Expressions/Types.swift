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
    public struct ConditionalCast<
        Input : FilterExpression,
        Desired
    > : FilterExpression
    {
        public typealias Output = Optional<Desired>
        public let input: Input
        
        public init(_ input: Input) {
            self.input = input
        }
        
        public func evaluate(_ bindings: FilterBindings) throws -> Output {
            return try input.evaluate(bindings) as? Desired
        }
    }
    
    public struct ForceCast<
        Input : FilterExpression,
        Desired
    > : FilterExpression
    {
        public typealias Output = Desired
        public let input: Input
        
        public init(_ input: Input) {
            self.input = input
        }
        
        public func evaluate(_ bindings: FilterBindings) throws -> Output {
            let input = try input.evaluate(bindings)
            guard let output = input as? Desired else {
                throw FilterError(.forceCastFailure("Failed to cast value of type '\(type(of: input))' to '\(Desired.self)'"))
            }
            return output
        }
    }
    
    public struct TypeCheck<
        Input : FilterExpression,
        Desired
    > : FilterExpression
    {
        public typealias Output = Bool
        public let input: Input
        
        public init(_ input: Input) {
            self.input = input
        }
        
        public func evaluate(_ bindings: FilterBindings) throws -> Output {
            return try input.evaluate(bindings) is Desired
        }
    }
}

extension FilterExpressions.ConditionalCast : CustomStringConvertible {
    public var description: String {
        "ConditionalCast(input: \(input), desiredType: \(_typeName(Desired.self)))"
    }
}

extension FilterExpressions.ForceCast : CustomStringConvertible {
    public var description: String {
        "ForceCast(input: \(input), desiredType: \(_typeName(Desired.self)))"
    }
}

extension FilterExpressions.TypeCheck : CustomStringConvertible {
    public var description: String {
        "TypeCheck(input: \(input), desiredType: \(_typeName(Desired.self)))"
    }
}

extension FilterExpressions.ConditionalCast : StandardFilterExpression where Input : StandardFilterExpression {}

extension FilterExpressions.ForceCast : StandardFilterExpression where Input : StandardFilterExpression {}

extension FilterExpressions.TypeCheck : StandardFilterExpression where Input : StandardFilterExpression {}

extension FilterExpressions.ConditionalCast : Codable where Input : Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(input)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        input = try container.decode(Input.self)
    }
}

extension FilterExpressions.ForceCast : Codable where Input : Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(input)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        input = try container.decode(Input.self)
    }
}

extension FilterExpressions.TypeCheck : Codable where Input : Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(input)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        input = try container.decode(Input.self)
    }
}

extension FilterExpressions.ConditionalCast : Sendable where Input : Sendable {}

extension FilterExpressions.ForceCast : Sendable where Input : Sendable {}

extension FilterExpressions.TypeCheck : Sendable where Input : Sendable {}
