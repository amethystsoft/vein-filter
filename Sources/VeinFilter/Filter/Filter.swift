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

public struct Filter1<Input1> : Sendable {
    public let expression : any StandardFilterExpression<Bool>
    public let variable: (FilterExpressions.Variable<Input1>)
    
    public init(_ builder: (FilterExpressions.Variable<Input1>) -> any StandardFilterExpression<Bool>) {
        self.variable = (FilterExpressions.Variable<Input1>())
        self.expression = builder(variable)
    }
    
    public func evaluate(_ input: Input1) throws -> Bool {
        try expression.evaluate(
            .init((variable, input))
        )
    }
}

public struct Filter2<Input1, Input2> : Sendable {
    public let expression : any StandardFilterExpression<Bool>
    public let variables: (FilterExpressions.Variable<Input1>, FilterExpressions.Variable<Input2>)
    
    public init(_ builder: (FilterExpressions.Variable<Input1>, FilterExpressions.Variable<Input2>) -> any StandardFilterExpression<Bool>) {
        let v1 = FilterExpressions.Variable<Input1>()
        let v2 = FilterExpressions.Variable<Input2>()
        self.variables = (v1, v2)
        self.expression = builder(v1, v2)
    }
    
    public func evaluate(_ input1: Input1, _ input2: Input2) throws -> Bool {
        try expression.evaluate(
            .init(
                (variables.0, input1),
                (variables.1, input2)
            )
        )
    }
}

public struct Filter3<Input1, Input2, Input3> : Sendable {
    public let expression : any StandardFilterExpression<Bool>
    public let variables: (FilterExpressions.Variable<Input1>, FilterExpressions.Variable<Input2>, FilterExpressions.Variable<Input3>)
    
    public init(_ builder: (FilterExpressions.Variable<Input1>, FilterExpressions.Variable<Input2>, FilterExpressions.Variable<Input3>) -> any StandardFilterExpression<Bool>) {
        let v1 = FilterExpressions.Variable<Input1>()
        let v2 = FilterExpressions.Variable<Input2>()
        let v3 = FilterExpressions.Variable<Input3>()
        self.variables = (v1, v2, v3)
        self.expression = builder(v1, v2, v3)
    }
    
    public func evaluate(_ input1: Input1, _ input2: Input2, _ input3: Input3) throws -> Bool {
        try expression.evaluate(
            .init(
                (variables.0, input1),
                (variables.1, input2),
                (variables.2, input3)
            )
        )
    }
}

@freestanding(expression)
public macro Filter<Input1>(_ body: (Input1) -> Bool) -> Filter1<Input1> = #externalMacro(module: "VeinFilterMacros", type: "FilterMacro")

@freestanding(expression)
public macro Filter<Input1, Input2>(_ body: (Input1, Input2) -> Bool) -> Filter2<Input1, Input2> = #externalMacro(module: "VeinFilterMacros", type: "FilterMacro")

@freestanding(expression)
public macro Filter<Input1, Input2, Input3>(_ body: (Input1, Input2, Input3) -> Bool) -> Filter3<Input1, Input2, Input3> = #externalMacro(module: "VeinFilterMacros", type: "FilterMacro")

extension Filter1 {
    private init(value: Bool) {
        self.variable = (FilterExpressions.Variable<Input1>())
        self.expression = FilterExpressions.Value(value)
    }
    
    public static var `true`: Self {
        Self(value: true)
    }
    
    public static var `false`: Self {
        Self(value: false)
    }
}

extension Filter2 {
    private init(value: Bool) {
        self.variables = (
            FilterExpressions.Variable<Input1>(),
            FilterExpressions.Variable<Input2>()
        )
        self.expression = FilterExpressions.Value(value)
    }
    
    public static var `true`: Self {
        Self(value: true)
    }
    
    public static var `false`: Self {
        Self(value: false)
    }
}

extension Filter3 {
    private init(value: Bool) {
        self.variables = (
            FilterExpressions.Variable<Input1>(),
            FilterExpressions.Variable<Input2>(),
            FilterExpressions.Variable<Input3>()
        )
        self.expression = FilterExpressions.Value(value)
    }
    
    public static var `true`: Self {
        Self(value: true)
    }
    
    public static var `false`: Self {
        Self(value: false)
    }
}



// Namespace for operator expressions
@frozen public enum FilterExpressions {}

extension FilterExpressions : Sendable {}

extension Sequence {
    public func filter(_ Filter: Filter1<Element>) throws -> [Element] {
        try self.filter {
            try Filter.evaluate($0)
        }
    }
}
