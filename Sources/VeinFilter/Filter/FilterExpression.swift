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

#if canImport(Synchronization) && (!canImport(Darwin) || FOUNDATION_FRAMEWORK)
internal import Synchronization
#endif

public protocol FilterExpression<Output> {
    associatedtype Output
    
    func evaluate(_ bindings: FilterBindings) throws -> Output
}

// Only Foundation should add conformances to this protocol
public protocol StandardFilterExpression<Output> : FilterExpression, Codable, Sendable {}

public struct FilterError: Error, Hashable, CustomDebugStringConvertible {
    internal enum _Error: Hashable, Sendable {
        case undefinedVariable
        case forceUnwrapFailure(String?)
        case forceCastFailure(String?)
        case invalidInput(String?)
    }
    
    private let _error: _Error
    
    internal init(_ error: _Error) {
        _error = error
    }
    
    public var debugDescription: String {
        switch _error {
        case .undefinedVariable:
            return "Encountered an undefined variable"
        case .forceUnwrapFailure(let string):
            return string ?? "Attempted to force unwrap a nil value"
        case .forceCastFailure(let string):
            return string ?? "Failed to cast a value to the desired type"
        case .invalidInput(let string):
            return string ?? "The inputs to this expression are invalid"
        }
    }
    
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        switch lhs._error {
        case .undefinedVariable:
            return rhs == .undefinedVariable
        case .forceCastFailure(_):
            if case .forceCastFailure(_) = rhs._error {
                return true
            }
            return false
        case .forceUnwrapFailure(_):
            if case .forceUnwrapFailure(_) = rhs._error {
                return true
            }
            return false
        case .invalidInput(_):
            if case .invalidInput(_) = rhs._error {
                return true
            }
            return false
        }
    }
    
    public static let undefinedVariable = Self(.undefinedVariable)
    public static let forceUnwrapFailure = Self(.forceUnwrapFailure(nil))
    public static let forceCastFailure = Self(.forceCastFailure(nil))
    public static let invalidInput = Self(.invalidInput(nil))
}

extension FilterExpressions {
    public struct VariableID: Hashable, Codable, Sendable {
        let id: UInt
        #if canImport(Synchronization) && (!canImport(Darwin) || FOUNDATION_FRAMEWORK)
        private static let nextID = Atomic<UInt>(0)
        #else
        private static let nextID = LockedState(initialState: UInt(0))
        #endif
        
        init() {
            #if canImport(Synchronization) && (!canImport(Darwin) || FOUNDATION_FRAMEWORK)
            self.id = Self.nextID.wrappingAdd(1, ordering: .relaxed).oldValue
            #else
            self.id = Self.nextID.withLock { value in
                defer {
                    (value, _) = value.addingReportingOverflow(1)
                }
                return value
            }
            #endif
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(id)
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let decodedID = try container.decode(UInt.self)
#if FOUNDATION_FRAMEWORK
            if let newVariable = _ThreadLocal[.FilterArchivingState]?.createVariable(for: decodedID) {
                self = newVariable
                return
            }
#endif // FOUNDATION_FRAMEWORK
            self.id = decodedID
        }
    }
    
    public struct Variable<Output> : StandardFilterExpression {
        public let key: VariableID
        
        public init() {
            self.key = VariableID()
        }
        
        public func evaluate(_ bindings: FilterBindings) throws -> Output {
            if let value = bindings[self] {
                return value
            }
            throw FilterError.undefinedVariable
        }
    }
    
    public struct KeyPath<Root : FilterExpression, Output> : FilterExpression {
        public let root: Root
        public let keyPath: Swift.KeyPath<Root.Output, Output> & Sendable
        
        public init(root: Root, keyPath: Swift.KeyPath<Root.Output, Output> & Sendable) {
            keyPath._validateForFilterUsage()
            self.root = root
            self.keyPath = keyPath
        }
        
        public func evaluate(_ bindings: FilterBindings) throws -> Output {
            return try root.evaluate(bindings)[keyPath: keyPath as Swift.KeyPath<Root.Output, Output>]
        }
    }

    public struct Value<Output> : FilterExpression {
        public let value: Output
        
        public init(_ value: Output) {
            self.value = value
        }
        
        public func evaluate(_ bindings: FilterBindings) -> Output {
            return self.value
        }
    }
    
    public static func build_Arg<T>(_ arg: T) -> Value<T> {
        Value(arg)
    }
    
    public static func build_Arg<T: FilterExpression>(_ arg: T) -> T {
        arg
    }
    
    /* public */
    @usableFromInline static func build_KeyPath<Root, Value>(root: Root, keyPath: Swift.KeyPath<Root.Output, Value>) -> FilterExpressions.KeyPath<Root, Value> {
        KeyPath(root: root, keyPath: keyPath._unsafeAssumeSendable)
    }
    
    // A temporary workaround to a compiler bug that changes the ABI when adding the & Sendable constraint
    // Should be removed and the above function should be made public when rdar://131764614 is resolved
    @_alwaysEmitIntoClient
    public static func build_KeyPath<Root, Value>(root: Root, keyPath: Swift.KeyPath<Root.Output, Value> & Sendable) -> FilterExpressions.KeyPath<Root, Value> {
        FilterExpressions.build_KeyPath(root: root, keyPath: keyPath as Swift.KeyPath<Root.Output, Value>)
    }
}

extension KeyPath {
    package var _unsafeAssumeSendable: KeyPath<Root, Value> & Sendable {
        func _unsafeCast<T, U>(_ t: T) -> U {
            t as! U
        }
        return _unsafeCast(self) as KeyPath<Root, Value> & Sendable
    }
}

extension AnyKeyPath {
    package var _unsafeAssumeSendableAnyKeyPath: AnyKeyPath & Sendable {
        func _unsafeCast<T, U>(_ t: T) -> U {
            t as! U
        }
        return _unsafeCast(self) as AnyKeyPath & Sendable
    }
}

extension FilterExpressions.KeyPath : Codable where Root : Codable {
    private enum CodingKeys : CodingKey {
        case root
        case identifier
    }
    
    public func encode(to encoder: Encoder) throws {
#if FOUNDATION_FRAMEWORK
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(root, forKey: .root)
        guard let identifier = _ThreadLocal[.FilterArchivingState]?.configuration._identifier(for: keyPath) else {
            throw EncodingError.invalidValue(keyPath, .init(codingPath: container.codingPath, debugDescription: "The '\(keyPath.debugDescription)' keypath is not in the provided allowlist"))
        }
        try container.encode(identifier, forKey: .identifier)
#else
        throw EncodingError.invalidValue(self, .init(codingPath: encoder.codingPath, debugDescription: "Encoding FilterExpressions.KeyPath is not supported"))
#endif // FOUNDATION_FRAMEWORK
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
#if FOUNDATION_FRAMEWORK
        root = try container.decode(Root.self, forKey: .root)
        let identifier = try container.decode(String.self, forKey: .identifier)
        guard let anykp = _ThreadLocal[.FilterArchivingState]?.configuration._keyPath(for: identifier, rootType: Root.Output.self) else {
            throw DecodingError.dataCorruptedError(forKey: .identifier, in: container, debugDescription: "A keypath for the '\(identifier)' identifier is not in the provided allowlist")
        }
        guard let kp = anykp as? Swift.KeyPath<Root.Output, Output> else {
            throw DecodingError.dataCorruptedError(forKey: .identifier, in: container, debugDescription: "Key path '\(anykp.debugDescription)' (KeyPath<\(_typeName(type(of: anykp).rootType)), \(_typeName(type(of: anykp).valueType))>) for identifier '\(identifier)' did not match the expression's requirement for KeyPath<\(_typeName(Root.Output.self)), \(_typeName(Output.self))>")
        }
        self.keyPath = kp._unsafeAssumeSendable
#else
        throw DecodingError.dataCorruptedError(forKey: .identifier, in: container, debugDescription: "Decoding FilterExpressions.KeyPath is not supported")
#endif // FOUNDATION_FRAMEWORK
    }
}
extension FilterExpressions.KeyPath : Sendable where Root : Sendable {}

extension FilterExpressions.KeyPath : StandardFilterExpression where Root : StandardFilterExpression {}

extension FilterExpressions.KeyPath : CustomStringConvertible {
    public var description: String {
        "KeyPath(root: \(root), keyPath: \(keyPath))"
    }
}

extension FilterExpressions.Value : Codable where Output : Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        value = try container.decode(Output.self)
    }
}

extension FilterExpressions.Value : Sendable where Output : Sendable {}

extension FilterExpressions.Value : StandardFilterExpression where Output : Codable /*, Output : Sendable*/ {}

extension FilterExpressions.Value : CustomStringConvertible {
    public var description: String {
        var result = "Value<\(_typeName(Output.self))>("
        debugPrint(value, separator: "", terminator: "", to: &result)
        return result + ")"
    }
}

extension FilterExpressions.Variable : CustomStringConvertible {
    public var description: String {
        "Variable(\(key.id))"
    }
}

extension FilterExpressions.KeyPath {
    public enum CommonKeyPathKind : Hashable, Sendable {
        case collectionCount
        case collectionIsEmpty
        case collectionFirst
        case bidirectionalCollectionLast
    }
    
    public var kind: CommonKeyPathKind? {
        guard let collectionType = Root.Output.self as? any Collection.Type else {
            return nil
        }
        return Self.kind(keyPath, collectionType: collectionType)
    }
    
    private static func kind<C: Collection>(_ anyKP: AnyKeyPath, collectionType: C.Type) -> CommonKeyPathKind? {
        let kp = anyKP as! PartialKeyPath<C>
        switch kp {
        case \String.count, \Substring.count, \Array<C.Element>.count:
            return .collectionCount
        case \String.isEmpty, \Substring.isEmpty, \Array<C.Element>.isEmpty:
            return .collectionIsEmpty
        case \Array<C.Element>.first:
            return .collectionFirst
        case \Array<C.Element>.last:
            return .bidirectionalCollectionLast
        default:
            if let hashableElem = C.Element.self as? any Hashable.Type {
                return Self.kind(kp, hashableElementType: hashableElem)
            }
            return nil
        }
    }
    
    private static func kind<C: Collection, Element: Hashable>(_ kp: PartialKeyPath<C>, hashableElementType: Element.Type) -> CommonKeyPathKind? {
        switch kp {
        case \Set<Element>.count:
            return .collectionCount
        case \Set<Element>.isEmpty:
            return .collectionIsEmpty
        default:
            return nil
        }
    }
}
