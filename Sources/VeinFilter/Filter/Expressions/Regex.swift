//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//
/*
#if compiler(>=5.11)

extension FilterExpressions {
    public struct StringContainsRegex<
        Subject : FilterExpression,
        Regex : FilterExpression
    > : FilterExpression, CustomStringConvertible
    where
        Subject.Output : BidirectionalCollection,
        Subject.Output.SubSequence == Substring,
        Regex.Output : RegexComponent
    {
        public typealias Output = Bool
        
        public let subject: Subject
        public let regex: Regex
        
        public init(subject: Subject, regex: Regex) {
            self.subject = subject
            self.regex = regex
        }
        
        public var description: String {
            "StringContainsRegex(subject: \(subject), regex: \(regex))"
        }
        
        public func evaluate(_ bindings: FilterBindings) throws -> Bool {
            try subject.evaluate(bindings).contains(regex.evaluate(bindings))
        }
    }
    
    @_disfavoredOverload
    public static func build_contains<Subject, Regex>(_ subject: Subject, _ regex: Regex) -> StringContainsRegex<Subject, Regex> {
        StringContainsRegex(subject: subject, regex: regex)
    }
}

extension FilterExpressions {
    public struct FilterRegex: Sendable, Codable, RegexComponent, CustomStringConvertible {
        private struct _Storage: @unchecked Sendable {
            let regex: Regex<AnyRegexOutput>
        }
        
        private let _storage: _Storage
        
        public let stringRepresentation: String
        public var regex: Regex<AnyRegexOutput> { _storage.regex }
        public var description: String { stringRepresentation }
        
        public init?(_ component: some RegexComponent) {
            let regex = Regex<AnyRegexOutput>(component.regex)
            guard let stringRep = regex._literalPattern else {
                return nil
            }
            self._storage = _Storage(regex: regex)
            self.stringRepresentation = stringRep
        }
        
        public init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            self.stringRepresentation = try container.decode(String.self)
            self._storage = _Storage(regex: try Regex<AnyRegexOutput>(self.stringRepresentation))
        }
        
        public func encode(to encoder: any Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(stringRepresentation)
        }
    }
    
    public static func build_Arg(_ component: some RegexComponent) -> Value<FilterRegex> {
        guard let supportedComponent = FilterRegex(component) else {
            fatalError("The provided regular expression is not supported by this Filter")
        }
        return Value(supportedComponent)
    }
}

extension FilterExpressions.StringContainsRegex : Sendable where Subject : Sendable, Regex : Sendable {}

extension FilterExpressions.StringContainsRegex : Codable where Subject : Codable, Regex : Codable {
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(subject)
        try container.encode(regex)
    }
    
    public init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.subject = try container.decode(Subject.self)
        self.regex = try container.decode(Regex.self)
    }
}

extension FilterExpressions.StringContainsRegex : StandardFilterExpression where Subject : StandardFilterExpression, Regex : StandardFilterExpression {}

#endif
*/
