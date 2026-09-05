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
    public struct Negation<Wrapped: FilterExpression> : FilterExpression where Wrapped.Output == Bool {
        public typealias Output = Bool
        
        public let wrapped: Wrapped
        
        public init(_ wrapped: Wrapped) {
            self.wrapped = wrapped
        }
        
        public func evaluate(_ bindings: FilterBindings) throws -> Bool {
            try !wrapped.evaluate(bindings)
        }
    }
    
    public static func build_Negation<T>(_ wrapped: T) -> Negation<T> {
        Negation(wrapped)
    }
}

extension FilterExpressions.Negation : CustomStringConvertible {
    public var description: String {
        "Negation(wrapped: \(wrapped))"
    }
}

extension FilterExpressions.Negation : StandardFilterExpression where Wrapped : StandardFilterExpression {}

extension FilterExpressions.Negation : Codable where Wrapped : Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrapped)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        wrapped = try container.decode(Wrapped.self)
    }
}

extension FilterExpressions.Negation : Sendable where Wrapped : Sendable {}
