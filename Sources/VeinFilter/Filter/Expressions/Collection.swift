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
    public struct CollectionIndexSubscript<
        Wrapped : FilterExpression,
        Index : FilterExpression
    > : FilterExpression
    where
        Wrapped.Output : Collection,
        Index.Output == Wrapped.Output.Index
    {
        public typealias Output = Wrapped.Output.Element
        
        public let wrapped: Wrapped
        public let index: Index
        
        public init(wrapped: Wrapped, index: Index) {
            self.wrapped = wrapped
            self.index = index
        }
        
        public func evaluate(_ bindings: FilterBindings) throws -> Output {
            let collection = try wrapped.evaluate(bindings)
            let indexValue = try index.evaluate(bindings)
            guard indexValue >= collection.startIndex && indexValue < collection.endIndex else {
                throw FilterError(.invalidInput("Index \(indexValue) was not within the valid bounds of the collection (\(collection.startIndex) ..< \(collection.endIndex))"))
            }
            return collection[indexValue]
        }
    }
    
    public static func build_subscript<Wrapped, Index>(_ wrapped: Wrapped, _ index: Index) -> CollectionIndexSubscript<Wrapped, Index> {
        CollectionIndexSubscript(wrapped: wrapped, index: index)
    }
}

extension FilterExpressions.CollectionIndexSubscript : Sendable where Wrapped : Sendable, Index : Sendable {}

extension FilterExpressions.CollectionIndexSubscript : CustomStringConvertible {
    public var description: String {
        "CollectionIndexSubscript(wrapped: \(wrapped), index: \(index))"
    }
}

extension FilterExpressions.CollectionIndexSubscript : Codable where Wrapped : Codable, Index : Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(wrapped)
        try container.encode(index)
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.wrapped = try container.decode(Wrapped.self)
        self.index = try container.decode(Index.self)
    }
}

extension FilterExpressions.CollectionIndexSubscript : StandardFilterExpression where Wrapped : StandardFilterExpression, Index : StandardFilterExpression {}

extension FilterExpressions {
    public struct CollectionRangeSubscript<
        Wrapped : FilterExpression,
        Range : FilterExpression
    > : FilterExpression
    where
        Wrapped.Output : Collection,
        Range.Output == Swift.Range<Wrapped.Output.Index>
    {
        public typealias Output = Wrapped.Output.SubSequence
        
        public let wrapped: Wrapped
        public let range: Range
        
        public init(wrapped: Wrapped, range: Range) {
            self.wrapped = wrapped
            self.range = range
        }
        
        public func evaluate(_ bindings: FilterBindings) throws -> Output {
            let collection = try wrapped.evaluate(bindings)
            let rangeValue = try range.evaluate(bindings)
            
            guard rangeValue.lowerBound >= collection.startIndex && rangeValue.lowerBound <= collection.endIndex else {
                throw FilterError(.invalidInput("Index \(rangeValue.lowerBound) was not within the valid bounds of the collection (\(collection.startIndex) ... \(collection.endIndex))"))
            }
            guard rangeValue.upperBound >= collection.startIndex && rangeValue.upperBound <= collection.endIndex else {
                throw FilterError(.invalidInput("Index \(rangeValue.upperBound) was not within the valid bounds of the collection (\(collection.startIndex) ... \(collection.endIndex))"))
            }
            
            return collection[rangeValue]
        }
    }
    
    public static func build_subscript<Wrapped, Range>(_ wrapped: Wrapped, _ range: Range) -> CollectionRangeSubscript<Wrapped, Range> {
        CollectionRangeSubscript(wrapped: wrapped, range: range)
    }
}

extension FilterExpressions.CollectionRangeSubscript : CustomStringConvertible {
    public var description: String {
        "CollectionRangeSubscript(wrapped: \(wrapped), range: \(range))"
    }
}

extension FilterExpressions.CollectionRangeSubscript : Sendable where Wrapped : Sendable, Range : Sendable {}

extension FilterExpressions.CollectionRangeSubscript : Codable where Wrapped : Codable, Range : Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(wrapped)
        try container.encode(range)
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.wrapped = try container.decode(Wrapped.self)
        self.range = try container.decode(Range.self)
    }
}

extension FilterExpressions.CollectionRangeSubscript : StandardFilterExpression where Wrapped : StandardFilterExpression, Range : StandardFilterExpression {}

extension FilterExpressions {
    public struct CollectionContainsCollection<
        Base : FilterExpression,
        Other : FilterExpression
    > : FilterExpression
    where
        Base.Output : Collection,
        Other.Output : Collection,
        Base.Output.Element == Other.Output.Element,
        Base.Output.Element : Equatable
    {
        
        public typealias Output = Bool
        
        public let base: Base
        public let other: Other
        
        public init(base: Base, other: Other) {
            self.base = base
            self.other = other
        }
        
        public func evaluate(_ bindings: FilterBindings) throws -> Bool {
            try base.evaluate(bindings).contains(try other.evaluate(bindings))
        }
    }
    
    public static func build_contains<Base, Other>(_ base: Base, _ other: Other) -> CollectionContainsCollection<Base, Other> {
        CollectionContainsCollection(base: base, other: other)
    }
}

extension FilterExpressions.CollectionContainsCollection : CustomStringConvertible {
    public var description: String {
        "CollectionContainsCollection(base: \(base), other: \(other))"
    }
}

extension FilterExpressions.CollectionContainsCollection : Sendable where Base : Sendable, Other : Sendable {}

extension FilterExpressions.CollectionContainsCollection : Codable where Base : Codable, Other : Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(base)
        try container.encode(other)
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.base = try container.decode(Base.self)
        self.other = try container.decode(Other.self)
    }
}

extension FilterExpressions.CollectionContainsCollection : StandardFilterExpression where Base : StandardFilterExpression, Other : StandardFilterExpression {}
