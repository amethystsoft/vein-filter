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

extension FilterExpressions {
    public struct DictionaryKeySubscript<
        Wrapped : FilterExpression,
        Key : FilterExpression,
        Value
    > : FilterExpression
    where
        Wrapped.Output == Dictionary<Key.Output, Value>
    {
        public typealias Output = Optional<Value>
        
        public let wrapped: Wrapped
        public let key: Key
        
        public init(wrapped: Wrapped, key: Key) {
            self.wrapped = wrapped
            self.key = key
        }
        
        public func evaluate(_ bindings: FilterBindings) throws -> Output {
            try wrapped.evaluate(bindings)[try key.evaluate(bindings)]
        }
    }
    
    public static func build_subscript<Wrapped, Key, Value>(_ wrapped: Wrapped, _ key: Key) -> DictionaryKeySubscript<Wrapped, Key, Value> {
        DictionaryKeySubscript(wrapped: wrapped, key: key)
    }
}

extension FilterExpressions.DictionaryKeySubscript : CustomStringConvertible {
    public var description: String {
        "DictionaryKeySubscript(wrapped: \(wrapped), key: \(key))"
    }
}

extension FilterExpressions.DictionaryKeySubscript : Sendable where Wrapped : Sendable, Key : Sendable {}

extension FilterExpressions.DictionaryKeySubscript : Codable where Wrapped : Codable, Key : Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(wrapped)
        try container.encode(key)
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.wrapped = try container.decode(Wrapped.self)
        self.key = try container.decode(Key.self)
    }
}

extension FilterExpressions.DictionaryKeySubscript : StandardFilterExpression where Wrapped : StandardFilterExpression, Key : StandardFilterExpression {}

extension FilterExpressions {
    public struct DictionaryKeyDefaultValueSubscript<
        Wrapped : FilterExpression,
        Key : FilterExpression,
        Default : FilterExpression
    > : FilterExpression
    where
        Wrapped.Output == Dictionary<Key.Output, Default.Output>
    {
        public typealias Output = Default.Output
        
        public let wrapped: Wrapped
        public let key: Key
        public let `default`: Default
        
        public init(wrapped: Wrapped, key: Key, `default`: Default) {
            self.wrapped = wrapped
            self.key = key
            self.`default` = `default`
        }
        
        public func evaluate(_ bindings: FilterBindings) throws -> Output {
            guard let value =  try wrapped.evaluate(bindings)[try key.evaluate(bindings)] else {
                return try `default`.evaluate(bindings)
            }
            return value
        }
    }
    
    public static func build_subscript<Wrapped, Key, Default>(_ wrapped: Wrapped, _ key: Key, default: Default) -> DictionaryKeyDefaultValueSubscript<Wrapped, Key, Default> {
        DictionaryKeyDefaultValueSubscript(wrapped: wrapped, key: key, default: `default`)
    }
}

extension FilterExpressions.DictionaryKeyDefaultValueSubscript : CustomStringConvertible {
    public var description: String {
        "DictionaryKeyDefaultValueSubscript(wrapped: \(wrapped), key: \(key), defaultValue: \(`default`))"
    }
}

extension FilterExpressions.DictionaryKeyDefaultValueSubscript : Sendable where Wrapped : Sendable, Key : Sendable, Default : Sendable {}

extension FilterExpressions.DictionaryKeyDefaultValueSubscript : Codable where Wrapped : Codable, Key : Codable, Default : Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(wrapped)
        try container.encode(key)
        try container.encode(`default`)
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.wrapped = try container.decode(Wrapped.self)
        self.key = try container.decode(Key.self)
        self.`default` = try container.decode(Default.self)
    }
}

extension FilterExpressions.DictionaryKeyDefaultValueSubscript : StandardFilterExpression where Wrapped : StandardFilterExpression, Key : StandardFilterExpression, Default : StandardFilterExpression {}
