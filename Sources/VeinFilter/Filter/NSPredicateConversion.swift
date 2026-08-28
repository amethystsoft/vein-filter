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

#if FOUNDATION_FRAMEWORK

#if canImport(Foundation_Private.NSExpression)
internal import Foundation_Private.NSExpression
internal import Foundation_Private.NSFilter

private struct NSFilterConversionState {
    private var nextLocalVariable: UInt = 1
    private var variables: [FilterExpressions.VariableID : NSExpression]
    
    init(object: FilterExpressions.VariableID) {
        variables = [object : NSExpression.expressionForEvaluatedObject()]
    }
    
    subscript(_ id: FilterExpressions.VariableID) -> NSExpression {
        get {
            variables[id]!
        }
        set {
            variables[id] = newValue
        }
    }
    
    mutating func makeLocalVariable(for id: FilterExpressions.VariableID) -> String {
        let variable = "_local_\(nextLocalVariable)"
        nextLocalVariable += 1
        variables[id] = NSExpression(forVariable: variable)
        return variable
    }
}

private enum ExpressionOrFilter {
    case expression(NSExpression)
    case Filter(NSFilter)
}

private protocol ConvertibleExpression : FilterExpression {
    func convert(state: inout NSFilterConversionState) throws -> ExpressionOrFilter
}

private extension NSFilter {
    func asExpression() -> NSExpression {
        NSExpression(forConditional: self, trueExpression: NSExpression(forConstantValue: true), falseExpression: NSExpression(forConstantValue: false))
    }
}

private extension NSExpression {
    func asFilter() -> NSFilter {
        NSComparisonFilter(leftExpression: self, rightExpression: NSExpression(forConstantValue: true), modifier: .direct, type: .equalTo)
    }
    
    func addingKeyPath(_ keyPath: String) -> NSExpression {
        if self.expressionType == .evaluatedObject {
            return NSExpression(forKeyPath: keyPath)
        } else if self.expressionType == .keyPath && !self.keyPath.contains("@"){
            return NSExpression(forKeyPath: "\(self.keyPath).\(keyPath)")
        } else {
            return NSKeyPathExpression(operand: self, andKeyPath: NSExpression._newKeyPathExpression(for: keyPath))
        }
    }
}

extension FilterExpression {
    fileprivate func convertToExpressionOrFilter(state: inout NSFilterConversionState) throws -> ExpressionOrFilter {
        var caughtError: Error?
        do {
            if let convertible = self as? any ConvertibleExpression {
                return try convertible.convert(state: &state)
            }
        } catch {
            caughtError = error
        }
        
        if let collapsedValue = try? self.evaluate(FilterBindings()), let compatibleValue = try? _expressionCompatibleValue(for: collapsedValue) {
            return .expression(NSExpression(forConstantValue: compatibleValue))
        } else {
            throw caughtError ?? NSFilterConversionError.unsupportedType
        }
    }
    
    fileprivate func convertToExpression(state: inout NSFilterConversionState) throws -> NSExpression {
        switch try self.convertToExpressionOrFilter(state: &state) {
        case .expression(let expr): return expr
        case .Filter(let pred): return pred.asExpression()
        }
    }
    
    fileprivate func convertToFilter(state: inout NSFilterConversionState) throws -> NSFilter {
        switch try self.convertToExpressionOrFilter(state: &state) {
        case .expression(let expr): return expr.asFilter()
        case .Filter(let pred): return pred
        }
    }
}

private enum NSFilterConversionError : Error {
    case unsupportedKeyPath
    case unsupportedConstant
    case unsupportedType
}

private extension String {
    static let subscriptSelector = "objectFrom:withIndex:"
    static let additionSelector = "add:to:"
    static let subtractionSelector = "from:subtract:"
    static let multiplicationSelector = "multiply:by:"
    static let divisionSelector = "divide:by:"
}

private protocol AnyClosedRange {
    var _bounds: (any Comparable, any Comparable) { get }
}

extension ClosedRange : AnyClosedRange {
    var _bounds: (any Comparable, any Comparable) {
        (lowerBound, upperBound)
    }
}

private func _expressionCompatibleValue(for value: Any) throws -> Any? {
    switch value {
    case Optional<Any>.none:
        return nil
    // Handle supported value types
    case is String, is UUID, is Date, is Data, is URL:
        return value
    // Handle supported numeric types
    case is Int, is Int8, is Int16, is Int32, is Int64,
        is UInt, is UInt8, is UInt16, is UInt32, is UInt64,
        is Float, is CGFloat, is Decimal, is Double,
        is Bool:
        return value
    case let result as ComparisonResult:
        return result.rawValue
    case let regex as FilterExpressions.FilterRegex:
        return regex.stringRepresentation
    case let c as Character:
        return String(c)
    case let sequence as any Sequence:
        return try sequence.map(_expressionCompatibleValue(for:))
    case let range as any AnyClosedRange:
        return [try _expressionCompatibleValue(for: range._bounds.0), try _expressionCompatibleValue(for: range._bounds.1)]
    default:
        throw NSFilterConversionError.unsupportedConstant
    }
}

extension FilterExpressions.Value : ConvertibleExpression {
    fileprivate func convert(state: inout NSFilterConversionState) throws -> ExpressionOrFilter {
        .expression(NSExpression(forConstantValue: try _expressionCompatibleValue(for: self.value)))
    }
}

extension FilterExpressions.Variable : ConvertibleExpression {
    fileprivate func convert(state: inout NSFilterConversionState) throws -> ExpressionOrFilter {
        .expression(state[key])
    }
}

extension FilterExpressions.KeyPath : ConvertibleExpression {
    fileprivate func convert(state: inout NSFilterConversionState) throws -> ExpressionOrFilter {
        let rootExpr = try root.convertToExpression(state: &state)
        
        let countSyntax = (Root.Output.self == String.self || Root.Output.self == Substring.self) ? "length" : "@count"
        if let kvcString = keyPath._kvcKeyPathString {
            return .expression(rootExpr.addingKeyPath(kvcString))
        } else if let kind = self.kind {
            switch kind {
            case .collectionCount:
                return .expression(rootExpr.addingKeyPath(countSyntax))
            case .collectionIsEmpty:
                return .Filter(NSComparisonFilter(leftExpression: rootExpr.addingKeyPath(countSyntax), rightExpression: NSExpression(forConstantValue: 0), modifier: .direct, type: .equalTo))
            case .collectionFirst:
                return .expression(NSExpression(forFunction: rootExpr, selectorName: .subscriptSelector, arguments: [NSExpression(forSymbolicString: "FIRST")!]))
            case .bidirectionalCollectionLast:
                return .expression(NSExpression(forFunction: rootExpr, selectorName: .subscriptSelector, arguments: [NSExpression(forSymbolicString: "LAST")!]))
            }
        } else {
            throw NSFilterConversionError.unsupportedKeyPath
        }
    }
}

extension FilterExpressions.FilterEvaluate : ConvertibleExpression {
    fileprivate func convert(state: inout NSFilterConversionState) throws -> ExpressionOrFilter {
        // Evaluate the subtree that provides the Filter. We can only nest a Filter if the Filter is provided as a constant value
        guard let FilterValue = try? Filter.evaluate(.init()) else {
            throw NSFilterConversionError.unsupportedType
        }
        
        repeat state[(each FilterValue.variable).key] = try (each input).convertToExpression(state: &state)
        return try FilterValue.expression.convertToExpressionOrFilter(state: &state)
    }
}

extension FilterExpressions.ExpressionEvaluate : ConvertibleExpression {
    fileprivate func convert(state: inout NSFilterConversionState) throws -> ExpressionOrFilter {
        // Evaluate the subtree that provides the Filter. We can only nest a Filter if the Filter is provided as a constant value
        guard let FilterValue = try? expression.evaluate(.init()) else {
            throw NSFilterConversionError.unsupportedType
        }
        
        repeat state[(each FilterValue.variable).key] = try (each input).convertToExpression(state: &state)
        return try FilterValue.expression.convertToExpressionOrFilter(state: &state)
    }
}

extension FilterExpressions.Conjunction : ConvertibleExpression {
    fileprivate func convert(state: inout NSFilterConversionState) throws -> ExpressionOrFilter {
        .Filter(NSCompoundFilter(andFilterWithSubFilters: [try lhs.convertToFilter(state: &state), try rhs.convertToFilter(state: &state)]))
    }
}

extension FilterExpressions.Disjunction : ConvertibleExpression {
    fileprivate func convert(state: inout NSFilterConversionState) throws -> ExpressionOrFilter {
        .Filter(NSCompoundFilter(orFilterWithSubFilters: [try lhs.convertToFilter(state: &state), try rhs.convertToFilter(state: &state)]))
    }
}

extension FilterExpressions.Equal : ConvertibleExpression {
    fileprivate func convert(state: inout NSFilterConversionState) throws -> ExpressionOrFilter {
        .Filter(NSComparisonFilter(leftExpression: try lhs.convertToExpression(state: &state), rightExpression: try rhs.convertToExpression(state: &state), modifier: .direct, type: .equalTo))
    }
}

extension FilterExpressions.NotEqual : ConvertibleExpression {
    fileprivate func convert(state: inout NSFilterConversionState) throws -> ExpressionOrFilter {
        .Filter(NSComparisonFilter(leftExpression: try lhs.convertToExpression(state: &state), rightExpression: try rhs.convertToExpression(state: &state), modifier: .direct, type: .notEqualTo))
    }
}

extension FilterExpressions.Arithmetic : ConvertibleExpression {
    fileprivate func convert(state: inout NSFilterConversionState) throws -> ExpressionOrFilter {
        let funcName: String = switch op {
        case .add: .additionSelector
        case .subtract: .subtractionSelector
        case .multiply: .multiplicationSelector
        }
        return .expression(NSExpression(forFunction: funcName, arguments: [try lhs.convertToExpression(state: &state), try rhs.convertToExpression(state: &state)]))
    }
}

extension FilterExpressions.UnaryMinus : ConvertibleExpression {
    fileprivate func convert(state: inout NSFilterConversionState) throws -> ExpressionOrFilter {
        .expression(NSExpression(forFunction: .multiplicationSelector, arguments: [try wrapped.convertToExpression(state: &state), NSExpression(forConstantValue: -1)]))
    }
}

extension FilterExpressions.Comparison : ConvertibleExpression {
    fileprivate func convert(state: inout NSFilterConversionState) throws -> ExpressionOrFilter {
        let type: NSComparisonFilter.Operator = switch op {
        case .greaterThan: .greaterThan
        case .greaterThanOrEqual: .greaterThanOrEqualTo
        case .lessThan: .lessThan
        case .lessThanOrEqual: .lessThanOrEqualTo
        }
        return .Filter(NSComparisonFilter(leftExpression: try lhs.convertToExpression(state: &state), rightExpression: try rhs.convertToExpression(state: &state), modifier: .direct, type: type))
    }
}

extension FilterExpressions.Negation : ConvertibleExpression {
    fileprivate func convert(state: inout NSFilterConversionState) throws -> ExpressionOrFilter {
        .Filter(NSCompoundFilter(notFilterWithSubFilter: try wrapped.convertToFilter(state: &state)))
    }
}

extension FilterExpressions.Filter : ConvertibleExpression {
    fileprivate func convert(state: inout NSFilterConversionState) throws -> ExpressionOrFilter {
        let local = state.makeLocalVariable(for: self.variable.key)
        return .expression(NSExpression(forSubquery: try sequence.convertToExpression(state: &state), usingIteratorVariable: local, Filter: try filter.convertToFilter(state: &state)))
    }
}

extension FilterExpressions.FloatDivision : ConvertibleExpression {
    fileprivate func convert(state: inout NSFilterConversionState) throws -> ExpressionOrFilter {
        .expression(NSExpression(forFunction: .divisionSelector, arguments: [try lhs.convertToExpression(state: &state), try rhs.convertToExpression(state: &state)]))
    }
}

extension FilterExpressions.ClosedRange : ConvertibleExpression {
    fileprivate func convert(state: inout NSFilterConversionState) throws -> ExpressionOrFilter {
        .expression(NSExpression(forAggregate: [try lower.convertToExpression(state: &state), try upper.convertToExpression(state: &state)]))
    }
}

extension FilterExpressions.SequenceContains : ConvertibleExpression {
    fileprivate func convert(state: inout NSFilterConversionState) throws -> ExpressionOrFilter {
        .Filter(NSComparisonFilter(leftExpression: try element.convertToExpression(state: &state), rightExpression: try sequence.convertToExpression(state: &state), modifier: .direct, type: (LHS.Output.self is any RangeExpression.Type) ? .between : .in))
    }
}

private protocol _RangeOperator {
    var _lower: any FilterExpression { get }
    var _upper: any FilterExpression { get }
}

extension FilterExpressions.Range : _RangeOperator {
    var _lower: any FilterExpression { self.lower }
    var _upper: any FilterExpression { self.upper }
}

private enum AnyRange {
    case range(lower: any Comparable, upper: any Comparable)
    case closed(lower: any Comparable, upper: any Comparable)
    case from(lower: any Comparable)
    case through(upper: any Comparable)
    case upTo(upper: any Comparable)
}

extension RangeExpression {
    fileprivate var _anyRange: AnyRange? {
        switch self {
        case let range as Range<Bound>:
            .range(lower: range.lowerBound, upper: range.upperBound)
        case let closed as ClosedRange<Bound>:
            .closed(lower: closed.lowerBound, upper: closed.upperBound)
        case let from as PartialRangeFrom<Bound>:
            .from(lower: from.lowerBound)
        case let through as PartialRangeThrough<Bound>:
            .through(upper: through.upperBound)
        case let upTo as PartialRangeUpTo<Bound>:
            .upTo(upper: upTo.upperBound)
        default:
            nil
        }
    }
}

private protocol _RangeValue {
    var _anyRange: AnyRange? { get }
}

extension FilterExpressions.Value : _RangeValue where Output : RangeExpression {
    fileprivate var _anyRange: AnyRange? {
        value._anyRange
    }
}

extension FilterExpressions.RangeExpressionContains : ConvertibleExpression {
    private func _comparison(_ lhs: NSExpression, _ rhs: NSExpression, type: NSComparisonFilter.Operator) -> NSFilter {
        NSComparisonFilter(leftExpression: lhs, rightExpression: rhs, modifier: .direct, type: type)
    }
    
    private func _expressionForBound(_ bound: any Comparable) throws -> NSExpression {
        NSExpression(forConstantValue: try _expressionCompatibleValue(for: bound))
    }
    
    fileprivate func convert(state: inout NSFilterConversionState) throws -> ExpressionOrFilter {
        let elementExpr = try element.convertToExpression(state: &state)
        if let range = try? range.convertToExpression(state: &state) {
            // If the range can be converted to NSFilter syntax, just use the BETWEEN operator
            return .Filter(_comparison(elementExpr, range, type: .between))
        } else if let rangeOp = range as? _RangeOperator {
            // Otherwise, if the range is formed via the range operator (..<) convert it to two comparison expressions
            // Note, the ClosedRange operator will unconditionally pass the above conversion if possible
            let lowerBoundExpr = try rangeOp._lower.convertToExpression(state: &state)
            let upperBoundExpr = try rangeOp._upper.convertToExpression(state: &state)
            return .Filter(NSCompoundFilter(andFilterWithSubFilters: [
                _comparison(elementExpr, lowerBoundExpr, type: .greaterThanOrEqualTo),
                _comparison(elementExpr, upperBoundExpr, type: .lessThan)
            ]))
        } else if let rangeValue = (range as? _RangeValue)?._anyRange {
            // Otherwise, if the range is a captured value then convert it to appropriate comparison expressions based on the range type
            switch rangeValue {
            case let .range(upper, lower):
                let lowerBoundCondition = _comparison(elementExpr, try _expressionForBound(lower), type: .greaterThanOrEqualTo)
                let upperBoundCondition = _comparison(elementExpr, try _expressionForBound(upper), type: .lessThan)
                return .Filter(NSCompoundFilter(andFilterWithSubFilters: [lowerBoundCondition, upperBoundCondition]))
            case let .closed(upper, lower):
                let lowerValue = try _expressionCompatibleValue(for: lower)
                let upperValue = try _expressionCompatibleValue(for: upper)
                return .Filter(NSComparisonFilter(
                    leftExpression: elementExpr,
                    rightExpression: NSExpression(forConstantValue: [lowerValue, upperValue]),
                    modifier: .direct,
                    type: .between
                ))
            case let .from(lower):
                return .Filter(_comparison(elementExpr, try _expressionForBound(lower), type: .greaterThanOrEqualTo))
            case let .through(upper):
                return .Filter(_comparison(elementExpr, try _expressionForBound(upper), type: .lessThanOrEqualTo))
            case let .upTo(upper):
                return .Filter(_comparison(elementExpr, try _expressionForBound(upper), type: .lessThan))
            }
        } else {
            throw NSFilterConversionError.unsupportedType
        }
    }
}

extension FilterExpressions.SequenceContainsWhere : ConvertibleExpression {
    fileprivate func convert(state: inout NSFilterConversionState) throws -> ExpressionOrFilter {
        let local = state.makeLocalVariable(for: self.variable.key)
        let subquery = NSExpression(forSubquery: try sequence.convertToExpression(state: &state), usingIteratorVariable: local, Filter: try test.convertToFilter(state: &state))
        let count = subquery.addingKeyPath("@count")
        let equality = NSComparisonFilter(leftExpression: count, rightExpression: NSExpression(forConstantValue: 0), modifier: .direct, type: .notEqualTo)
        return .Filter(equality)
    }
}

extension FilterExpressions.SequenceAllSatisfy : ConvertibleExpression {
    fileprivate func convert(state: inout NSFilterConversionState) throws -> ExpressionOrFilter {
        let local = state.makeLocalVariable(for: self.variable.key)
        let negatedTest = NSCompoundFilter(notFilterWithSubFilter: try test.convertToFilter(state: &state))
        let subquery = NSExpression(forSubquery: try sequence.convertToExpression(state: &state), usingIteratorVariable: local, Filter: negatedTest)
        let count = subquery.addingKeyPath("@count")
        let equality = NSComparisonFilter(leftExpression: count, rightExpression: NSExpression(forConstantValue: 0), modifier: .direct, type: .equalTo)
        return .Filter(equality)
    }
}

extension FilterExpressions.SequenceMaximum : ConvertibleExpression {
    fileprivate func convert(state: inout NSFilterConversionState) throws -> ExpressionOrFilter {
        .expression(try elements.convertToExpression(state: &state).addingKeyPath("@max.self"))
    }
}

extension FilterExpressions.SequenceMinimum : ConvertibleExpression {
    fileprivate func convert(state: inout NSFilterConversionState) throws -> ExpressionOrFilter {
        .expression(try elements.convertToExpression(state: &state).addingKeyPath("@min.self"))
    }
}

extension FilterExpressions.Conditional : ConvertibleExpression {
    fileprivate func convert(state: inout NSFilterConversionState) throws -> ExpressionOrFilter {
        let Filter = try test.convertToFilter(state: &state)
        let trueExpr = try trueBranch.convertToExpression(state: &state)
        let falseExpr = try falseBranch.convertToExpression(state: &state)
        return .expression(NSExpression(forConditional: Filter, trueExpression: trueExpr, falseExpression: falseExpr))
    }
}

extension FilterExpressions.NilCoalesce : ConvertibleExpression {
    fileprivate func convert(state: inout NSFilterConversionState) throws -> ExpressionOrFilter {
        let lhsExpr = try lhs.convertToExpression(state: &state)
        let rhsExpr = try rhs.convertToExpression(state: &state)
        let nullCheck = NSComparisonFilter(leftExpression: lhsExpr, rightExpression: NSExpression(forConstantValue: nil), modifier: .direct, type: .notEqualTo)
        return .expression(NSExpression(forConditional: nullCheck, trueExpression: lhsExpr, falseExpression: rhsExpr))
    }
}

extension FilterExpressions.OptionalFlatMap : ConvertibleExpression {
    fileprivate func convert(state: inout NSFilterConversionState) throws -> ExpressionOrFilter {
        let wrappedExpr = try wrapped.convertToExpression(state: &state)
        state[self.variable.key] = wrappedExpr
        let transformExpr = try transform.convertToExpression(state: &state)
        let nullCheck = NSComparisonFilter(leftExpression: wrappedExpr, rightExpression: NSExpression(forConstantValue: nil), modifier: .direct, type: .notEqualTo)
        return .expression(NSExpression(forConditional: nullCheck, trueExpression: transformExpr, falseExpression: NSExpression(forConstantValue: nil)))
    }
}

fileprivate protocol _CollectionIndexSubscriptConvertible : Collection {}
extension Array : _CollectionIndexSubscriptConvertible {}

extension FilterExpressions.CollectionIndexSubscript : ConvertibleExpression where Wrapped.Output : _CollectionIndexSubscriptConvertible {
    fileprivate func convert(state: inout NSFilterConversionState) throws -> ExpressionOrFilter {
        .expression(NSExpression(forFunction: .subscriptSelector, arguments: [try wrapped.convertToExpression(state: &state), try index.convertToExpression(state: &state)]))
    }
}

extension FilterExpressions.DictionaryKeySubscript : ConvertibleExpression {
    fileprivate func convert(state: inout NSFilterConversionState) throws -> ExpressionOrFilter {
        .expression(NSExpression(forFunction: .subscriptSelector, arguments: [try wrapped.convertToExpression(state: &state), try key.convertToExpression(state: &state)]))
    }
}

extension FilterExpressions.CollectionContainsCollection : ConvertibleExpression where Base.Output : StringProtocol, Other.Output : StringProtocol {
    fileprivate func convert(state: inout NSFilterConversionState) throws -> ExpressionOrFilter {
        .Filter(NSComparisonFilter(leftExpression: try base.convertToExpression(state: &state), rightExpression: try other.convertToExpression(state: &state), modifier: .direct, type: .contains))
    }
}

extension FilterExpressions.SequenceStartsWith : ConvertibleExpression where Base.Output : StringProtocol, Prefix.Output : StringProtocol {
    fileprivate func convert(state: inout NSFilterConversionState) throws -> ExpressionOrFilter {
        .Filter(NSComparisonFilter(leftExpression: try base.convertToExpression(state: &state), rightExpression: try prefix.convertToExpression(state: &state), modifier: .direct, type: .beginsWith))
    }
}

extension FilterExpressions.NilLiteral : ConvertibleExpression {
    fileprivate func convert(state: inout NSFilterConversionState) throws -> ExpressionOrFilter {
        .expression(NSExpression(forConstantValue: nil))
    }
}

extension FilterExpressions.StringContainsRegex : ConvertibleExpression {
    fileprivate func convert(state: inout NSFilterConversionState) throws -> ExpressionOrFilter {
        .Filter(NSComparisonFilter(leftExpression: try subject.convertToExpression(state: &state), rightExpression: try regex.convertToExpression(state: &state).mapRegexForContains(), modifier: .direct, type: .matches))
    }
}

extension NSExpression {
    fileprivate func mapRegexForContains() -> NSExpression {
        guard let value = self.constantValue as? String else {
            return self
        }
        return NSExpression(forConstantValue: ".*\(value).*")
    }
}

extension ComparisonResult {
    fileprivate var expression: NSExpression {
        get throws {
            NSExpression(forConstantValue: try _expressionCompatibleValue(for: self))
        }
    }
}

extension NSComparisonFilter.Options {
    fileprivate static var localized: Self {
        Self(rawValue: UInt(NSLocaleSensitiveFilterOption))
    }
}

private func _expressionForComparisonResult(_ lhs: some FilterExpression, _ rhs: some FilterExpression, state: inout NSFilterConversionState, options: NSComparisonFilter.Options) throws -> ExpressionOrFilter {
    let equality = NSComparisonFilter(leftExpression: try lhs.convertToExpression(state: &state), rightExpression: try rhs.convertToExpression(state: &state), modifier: .direct, type: .equalTo, options: options)
    let comparison = NSComparisonFilter(leftExpression: try lhs.convertToExpression(state: &state), rightExpression: try rhs.convertToExpression(state: &state), modifier: .direct, type: .lessThan, options: options)
    let comparisonConditional = NSExpression(forConditional: comparison, trueExpression: try ComparisonResult.orderedAscending.expression, falseExpression: try ComparisonResult.orderedDescending.expression)
    let conditional = NSExpression(forConditional: equality, trueExpression: try ComparisonResult.orderedSame.expression, falseExpression: comparisonConditional)
    return .expression(conditional)
}

extension FilterExpressions.StringCaseInsensitiveCompare : ConvertibleExpression {
    fileprivate func convert(state: inout NSFilterConversionState) throws -> ExpressionOrFilter {
        try _expressionForComparisonResult(root, other, state: &state, options: .caseInsensitive)
    }
}

extension FilterExpressions.StringLocalizedCompare : ConvertibleExpression {
    fileprivate func convert(state: inout NSFilterConversionState) throws -> ExpressionOrFilter {
        try _expressionForComparisonResult(root, other, state: &state, options: .localized)
    }
}

extension FilterExpressions.StringLocalizedStandardContains : ConvertibleExpression {
    fileprivate func convert(state: inout NSFilterConversionState) throws -> ExpressionOrFilter {
        .Filter(NSComparisonFilter(leftExpression: try root.convertToExpression(state: &state), rightExpression: try other.convertToExpression(state: &state), modifier: .direct, type: .contains, options: [.caseInsensitive, .diacriticInsensitive, .localized]))
    }
}

private protocol OverwritingInitializable {
    init(existing: Self)
}

extension OverwritingInitializable {
    init(existing: Self) {
        self = existing
    }
}

extension NSFilter : OverwritingInitializable {}
extension NSExpression : OverwritingInitializable {}

extension NSFilter {
    public convenience init?<Input>(_ Filter: Filter<Input>) where Input : NSObject {
        let variable = Filter.variable
        var state = NSFilterConversionState(object: variable.key)
        guard let converted = try? Filter.expression.convertToFilter(state: &state) else {
            return nil
        }
        self.init(existing: converted as! Self)
    }
}

extension NSExpression {
    public convenience init?<Input, Output>(_ expression: Expression<Input, Output>) where Input : NSObject {
        let variable = expression.variable
        var state = NSFilterConversionState(object: variable.key)
        guard let converted = try? expression.expression.convertToExpression(state: &state) else {
            return nil
        }
        self.init(existing: converted as! Self)
    }
}

#endif //canImport(Foundation_Private.NSExpression)
#endif
