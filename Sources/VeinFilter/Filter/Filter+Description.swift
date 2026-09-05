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

import Foundation

package struct DebugStringConversionState {
    private var variables: [FilterExpressions.VariableID : String]
    private var nextVariable = 1
    private var captures: [String] = []
    private var nextCapture = 1

    var captureDecl: String {
        captures.joined(separator: "\n")
    }

    init(_ variables: [FilterExpressions.VariableID]) {
        self.variables = Dictionary(uniqueKeysWithValues: variables.enumerated().map {
            ($1, "input\($0 + 1)")
        })
    }

    subscript(_ variable: FilterExpressions.VariableID) -> String {
        variables[variable] ?? "unknownVariable\(variable.id)"
    }

    mutating func setupVariable(_ variable: FilterExpressions.VariableID) {
        variables[variable] = "variable\(nextVariable)"
        nextVariable += 1
    }

    mutating func addCapture(_ value: Any) -> String {
        let valueConstruction = switch value as Any {
        case Optional<Any>.none: "nil"
        case let b as Bool: "\(b)"
        case let i as any Numeric: "\(i)"
        case let s as String: "\"\(s.replacing("\"", with: "\\\""))\""
        case let d as Date: "<Date \(d.timeIntervalSince1970)>"
        case let d as Data: "<Data \(d.base64EncodedString())>"
        case let u as UUID: "<UUID \(u.uuidString)>"
        default: "<\(_typeName(type(of: value))): \(String(describing: value).replacing("\n", with: ", "))>"
        }
        captures.append("capture\(nextCapture) (\(_typeName(type(of: value)))): \(valueConstruction)")
        defer { nextCapture += 1 }
        return "capture\(nextCapture)"
    }
}

extension String {
    fileprivate func indentedWithinClosure() -> String {
        var startIndex = self.startIndex
        var endIndex = self.endIndex
        if self.starts(with: "(") {
            self.formIndex(after: &startIndex)
        }
        if self.hasSuffix(")") {
            self.formIndex(before: &endIndex)
        }
        return String(self[startIndex ..< endIndex].replacing("\n", with: "\n    "))
    }
}

extension AnyKeyPath {
    fileprivate var debugStringWithoutType: String {
        let pieces = "\(self)".split(separator: ".")
        var idx = pieces.endIndex - 1
        while idx > pieces.startIndex && !pieces[idx].hasSuffix(">") {
            idx -= 1
        }
        return "." + pieces[(idx + 1)...].joined(separator: ".")
    }
}

package protocol DebugStringConvertibleFilterExpression : StandardFilterExpression {
    func debugString(state: inout DebugStringConversionState) -> String
}

extension FilterExpressions.Variable : DebugStringConvertibleFilterExpression {
    package func debugString(state: inout DebugStringConversionState) -> String {
        state[self.key]
    }
}

extension FilterExpressions.KeyPath : DebugStringConvertibleFilterExpression where Root : DebugStringConvertibleFilterExpression {
    package func debugString(state: inout DebugStringConversionState) -> String {
        root.debugString(state: &state) + keyPath.debugStringWithoutType
    }
}

extension FilterExpressions.Value : DebugStringConvertibleFilterExpression where Self : StandardFilterExpression {
    package func debugString(state: inout DebugStringConversionState) -> String {
        state.addCapture(value)
    }
}

extension FilterExpressions.Conjunction : DebugStringConvertibleFilterExpression where LHS : DebugStringConvertibleFilterExpression, RHS : DebugStringConvertibleFilterExpression {
    package func debugString(state: inout DebugStringConversionState) -> String {
        "(\(lhs.debugString(state: &state)) && \(rhs.debugString(state: &state)))"
    }
}

extension FilterExpressions.Disjunction : DebugStringConvertibleFilterExpression where LHS : DebugStringConvertibleFilterExpression, RHS : DebugStringConvertibleFilterExpression {
    package func debugString(state: inout DebugStringConversionState) -> String {
        "(\(lhs.debugString(state: &state)) || \(rhs.debugString(state: &state)))"
    }
}

extension FilterExpressions.Equal : DebugStringConvertibleFilterExpression where LHS : DebugStringConvertibleFilterExpression, RHS : DebugStringConvertibleFilterExpression {
    package func debugString(state: inout DebugStringConversionState) -> String {
        "(\(lhs.debugString(state: &state)) == \(rhs.debugString(state: &state)))"
    }
}

extension FilterExpressions.NotEqual : DebugStringConvertibleFilterExpression where LHS : DebugStringConvertibleFilterExpression, RHS : DebugStringConvertibleFilterExpression {
    package func debugString(state: inout DebugStringConversionState) -> String {
        "(\(lhs.debugString(state: &state)) != \(rhs.debugString(state: &state)))"
    }
}

extension FilterExpressions.Arithmetic : DebugStringConvertibleFilterExpression where LHS : DebugStringConvertibleFilterExpression, RHS : DebugStringConvertibleFilterExpression {
    package func debugString(state: inout DebugStringConversionState) -> String {
        let op = switch self.op {
        case .add: "+"
        case .multiply: "*"
        case .subtract: "-"
        }
        return "(\(lhs.debugString(state: &state)) \(op) \(rhs.debugString(state: &state)))"
    }
}

extension FilterExpressions.Comparison : DebugStringConvertibleFilterExpression where LHS : DebugStringConvertibleFilterExpression, RHS : DebugStringConvertibleFilterExpression {
    package func debugString(state: inout DebugStringConversionState) -> String {
        let op = switch self.op {
        case .greaterThan: ">"
        case .greaterThanOrEqual: ">="
        case .lessThan: "<"
        case .lessThanOrEqual: "<="
        }
        return "(\(lhs.debugString(state: &state)) \(op) \(rhs.debugString(state: &state)))"
    }
}

extension FilterExpressions.UnaryMinus : DebugStringConvertibleFilterExpression where Wrapped : DebugStringConvertibleFilterExpression {
    package func debugString(state: inout DebugStringConversionState) -> String {
        "-\(wrapped.debugString(state: &state))"
    }
}

extension FilterExpressions.SequenceMinimum : DebugStringConvertibleFilterExpression where Elements : DebugStringConvertibleFilterExpression {
    package func debugString(state: inout DebugStringConversionState) -> String {
        "\(elements.debugString(state: &state)).min()"
    }
}

extension FilterExpressions.SequenceMaximum : DebugStringConvertibleFilterExpression where Elements : DebugStringConvertibleFilterExpression {
    package func debugString(state: inout DebugStringConversionState) -> String {
        "\(elements.debugString(state: &state)).max()"
    }
}

extension FilterExpressions.ClosedRange : DebugStringConvertibleFilterExpression where LHS : DebugStringConvertibleFilterExpression, RHS : DebugStringConvertibleFilterExpression {
    package func debugString(state: inout DebugStringConversionState) -> String {
        "(\(lower.debugString(state: &state)) ... \(upper.debugString(state: &state)))"
    }
}

extension FilterExpressions.Range : DebugStringConvertibleFilterExpression where LHS : DebugStringConvertibleFilterExpression, RHS : DebugStringConvertibleFilterExpression {
    package func debugString(state: inout DebugStringConversionState) -> String {
        "(\(lower.debugString(state: &state)) ..< \(upper.debugString(state: &state)))"
    }
}

extension FilterExpressions.Conditional : DebugStringConvertibleFilterExpression where Test : DebugStringConvertibleFilterExpression, If : DebugStringConvertibleFilterExpression, Else : DebugStringConvertibleFilterExpression {
    package func debugString(state: inout DebugStringConversionState) -> String {
        """
        if \(test.debugString(state: &state)) {
            \(trueBranch.debugString(state: &state).indentedWithinClosure())
        } else {
            \(falseBranch.debugString(state: &state).indentedWithinClosure())
        }
        """
    }
}

extension FilterExpressions.CollectionIndexSubscript : DebugStringConvertibleFilterExpression where Wrapped : DebugStringConvertibleFilterExpression, Index : DebugStringConvertibleFilterExpression {
    package func debugString(state: inout DebugStringConversionState) -> String {
        "\(wrapped.debugString(state: &state))[\(index.debugString(state: &state))]"
    }
}

extension FilterExpressions.CollectionRangeSubscript : DebugStringConvertibleFilterExpression where Wrapped : DebugStringConvertibleFilterExpression, Range : DebugStringConvertibleFilterExpression {
    package func debugString(state: inout DebugStringConversionState) -> String {
        "\(wrapped.debugString(state: &state))[\(range.debugString(state: &state))]"
    }
}

extension FilterExpressions.CollectionContainsCollection : DebugStringConvertibleFilterExpression where Base : DebugStringConvertibleFilterExpression, Other : DebugStringConvertibleFilterExpression {
    package func debugString(state: inout DebugStringConversionState) -> String {
        "\(base.debugString(state: &state)).contains(\(other.debugString(state: &state)))"
    }
}

extension FilterExpressions.ConditionalCast : DebugStringConvertibleFilterExpression where Input : DebugStringConvertibleFilterExpression {
    package func debugString(state: inout DebugStringConversionState) -> String {
        "(\(input.debugString(state: &state)) as? \(_typeName(Desired.self)))"
    }
}

extension FilterExpressions.ForceCast : DebugStringConvertibleFilterExpression where Input : DebugStringConvertibleFilterExpression {
    package func debugString(state: inout DebugStringConversionState) -> String {
        "(\(input.debugString(state: &state)) as! \(_typeName(Desired.self)))"
    }
}

extension FilterExpressions.TypeCheck : DebugStringConvertibleFilterExpression where Input : DebugStringConvertibleFilterExpression {
    package func debugString(state: inout DebugStringConversionState) -> String {
        "(\(input.debugString(state: &state)) is \(_typeName(Desired.self)))"
    }
}

extension FilterExpressions.ForcedUnwrap : DebugStringConvertibleFilterExpression where Inner : DebugStringConvertibleFilterExpression {
    package func debugString(state: inout DebugStringConversionState) -> String {
        "\(inner.debugString(state: &state))!"
    }
}

extension FilterExpressions.OptionalFlatMap : DebugStringConvertibleFilterExpression where LHS : DebugStringConvertibleFilterExpression, RHS : DebugStringConvertibleFilterExpression {
    package func debugString(state: inout DebugStringConversionState) -> String {
        state.setupVariable(variable.key)
        return """
            \(wrapped.debugString(state: &state)).flatMap({ \(state[variable.key]) in
                \(transform.debugString(state: &state).indentedWithinClosure())
            })
            """
    }
}

extension FilterExpressions.DictionaryKeySubscript : DebugStringConvertibleFilterExpression where Wrapped : DebugStringConvertibleFilterExpression, Key : DebugStringConvertibleFilterExpression {
    package func debugString(state: inout DebugStringConversionState) -> String {
        "\(wrapped.debugString(state: &state))[\(key.debugString(state: &state))]"
    }
}

extension FilterExpressions.DictionaryKeyDefaultValueSubscript : DebugStringConvertibleFilterExpression where Wrapped : DebugStringConvertibleFilterExpression, Key : DebugStringConvertibleFilterExpression, Default : DebugStringConvertibleFilterExpression {
    package func debugString(state: inout DebugStringConversionState) -> String {
        "\(wrapped.debugString(state: &state))[\(key.debugString(state: &state)), default: \(self.default.debugString(state: &state))]"
    }
}

extension FilterExpressions.FloatDivision : DebugStringConvertibleFilterExpression where LHS : DebugStringConvertibleFilterExpression, RHS : DebugStringConvertibleFilterExpression {
    package func debugString(state: inout DebugStringConversionState) -> String {
        "(\(lhs.debugString(state: &state)) / \(rhs.debugString(state: &state)))"
    }
}

extension FilterExpressions.IntDivision : DebugStringConvertibleFilterExpression where LHS : DebugStringConvertibleFilterExpression, RHS : DebugStringConvertibleFilterExpression {
    package func debugString(state: inout DebugStringConversionState) -> String {
        "(\(lhs.debugString(state: &state)) / \(rhs.debugString(state: &state)))"
    }
}

extension FilterExpressions.IntRemainder : DebugStringConvertibleFilterExpression where LHS : DebugStringConvertibleFilterExpression, RHS : DebugStringConvertibleFilterExpression {
    package func debugString(state: inout DebugStringConversionState) -> String {
        "(\(lhs.debugString(state: &state)) % \(rhs.debugString(state: &state)))"
    }
}

extension FilterExpressions.Negation : DebugStringConvertibleFilterExpression where Wrapped : DebugStringConvertibleFilterExpression {
    package func debugString(state: inout DebugStringConversionState) -> String {
        "!\(wrapped.debugString(state: &state))"
    }
}

extension FilterExpressions.NilCoalesce : DebugStringConvertibleFilterExpression where LHS : DebugStringConvertibleFilterExpression, RHS: DebugStringConvertibleFilterExpression {
    package func debugString(state: inout DebugStringConversionState) -> String {
        "(\(lhs.debugString(state: &state)) ?? \(rhs.debugString(state: &state)))"
    }
}

extension FilterExpressions.NilLiteral : DebugStringConvertibleFilterExpression {
    package func debugString(state: inout DebugStringConversionState) -> String {
        "nil"
    }
}

extension FilterExpressions.RangeExpressionContains : DebugStringConvertibleFilterExpression where RangeExpression : DebugStringConvertibleFilterExpression, Element : DebugStringConvertibleFilterExpression {
    package func debugString(state: inout DebugStringConversionState) -> String {
        "\(range.debugString(state: &state)).contains(\(element.debugString(state: &state)))"
    }
}

extension FilterExpressions.SequenceContains : DebugStringConvertibleFilterExpression where LHS : DebugStringConvertibleFilterExpression, RHS: DebugStringConvertibleFilterExpression {
    package func debugString(state: inout DebugStringConversionState) -> String {
        "\(sequence.debugString(state: &state)).contains(\(element.debugString(state: &state)))"
    }
}

extension FilterExpressions.SequenceStartsWith : DebugStringConvertibleFilterExpression where Base : DebugStringConvertibleFilterExpression, Prefix : DebugStringConvertibleFilterExpression {
    package func debugString(state: inout DebugStringConversionState) -> String {
        "\(base.debugString(state: &state)).starts(with: \(prefix.debugString(state: &state)))"
    }
}

extension FilterExpressions.SequenceContainsWhere : DebugStringConvertibleFilterExpression where LHS : DebugStringConvertibleFilterExpression, RHS : DebugStringConvertibleFilterExpression {
    package func debugString(state: inout DebugStringConversionState) -> String {
        state.setupVariable(variable.key)
        return """
            \(sequence.debugString(state: &state)).contains(where: { \(state[variable.key]) in
                \(test.debugString(state: &state).indentedWithinClosure())
            })
            """
    }
}

extension FilterExpressions.SequenceAllSatisfy : DebugStringConvertibleFilterExpression where LHS : DebugStringConvertibleFilterExpression, RHS : DebugStringConvertibleFilterExpression {
    package func debugString(state: inout DebugStringConversionState) -> String {
        state.setupVariable(variable.key)
        return """
            \(sequence.debugString(state: &state)).allSatisfy({ \(state[variable.key]) in
                \(test.debugString(state: &state).indentedWithinClosure())
            })
            """
    }
}

extension FilterExpressions.Filter : DebugStringConvertibleFilterExpression where LHS : DebugStringConvertibleFilterExpression, RHS : DebugStringConvertibleFilterExpression {
    package func debugString(state: inout DebugStringConversionState) -> String {
        state.setupVariable(variable.key)
        return """
            \(sequence.debugString(state: &state)).filter({ \(state[variable.key]) in
                \(filter.debugString(state: &state).indentedWithinClosure())
            })
            """
    }
}

extension FilterExpressions.StringCaseInsensitiveCompare : DebugStringConvertibleFilterExpression where Root : DebugStringConvertibleFilterExpression, Other : DebugStringConvertibleFilterExpression {
    package func debugString(state: inout DebugStringConversionState) -> String {
        "\(root.debugString(state: &state)).caseInsensitiveCompare(\(other.debugString(state: &state)))"
    }
}

private func createDescription<each Input, Output>(variable: repeat FilterExpressions.Variable<each Input>, expression: some StandardFilterExpression, typeName: String, outputType: Output.Type = Void.self) -> String {
    var variableIDs: [FilterExpressions.VariableID] = []
    repeat variableIDs.append((each variable).key)
    guard let debugConvertible = expression as? any DebugStringConvertibleFilterExpression else {
        fatalError("Internal inconsistency: StandardFilterExpression does not conform to DebugStringConvertibleFilterExpression")
    }
    var inputTypes: [Any.Type] = []
    repeat inputTypes.append((each Input).self)
    let inputTypeNames = inputTypes.map {
        _typeName($0)
    }.joined(separator: ", ")
    var state = DebugStringConversionState(variableIDs)
    let variableNames = variableIDs.map {
        state[$0]
    }.joined(separator: ", ")
    let converted = debugConvertible.debugString(state: &state)
    var result = state.captureDecl.isEmpty ? "" : "\(state.captureDecl)\n"
    var outputTypeName = ""
    if outputType != Void.self {
        outputTypeName = ", \(_typeName(outputType))"
    }
    result.append("""
                    \(typeName)<\(inputTypeNames)\(outputTypeName)> { \(variableNames) in
                        \(converted.indentedWithinClosure())
                    }
                    """)
    return result
}

extension Filter1 : CustomStringConvertible {
    @_optimize(none) // Work around swift optimizer crash (rdar://124533887)
    public var description: String {
        createDescription(variable: variable, expression: expression, typeName: "Filter")
    }
}

extension Filter1 : CustomDebugStringConvertible {
    public var debugDescription: String {
        var variableDesc: [String] = []
        variableDesc.append(variable.description)
        return "\(_typeName(Self.self))(variable: (\(variableDesc.joined(separator: ", "))), expression: \(expression))"
    }
}
