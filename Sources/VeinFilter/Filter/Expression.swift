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
public struct Expression1<Input, Output>: Sendable {
    public let expression: any StandardFilterExpression<Output>
    public let variable: FilterExpressions.Variable<Input>
    
    public init(_ builder: (FilterExpressions.Variable<Input>) -> any StandardFilterExpression<Output>) {
        let variable = FilterExpressions.Variable<Input>()
        self.variable = variable
        self.expression = builder(variable)
    }
    
    public func evaluate(_ input: Input) throws -> Output {
        try expression.evaluate(
            .init((variable, input))
        )
    }
}

public struct Expression2<Input1, Input2, Output>: Sendable {
    public let expression: any StandardFilterExpression<Output>
    public let variables: (FilterExpressions.Variable<Input1>, FilterExpressions.Variable<Input2>)
    
    public init(_ builder: (FilterExpressions.Variable<Input1>, FilterExpressions.Variable<Input2>) -> any StandardFilterExpression<Output>) {
        let v1 = FilterExpressions.Variable<Input1>()
        let v2 = FilterExpressions.Variable<Input2>()
        self.variables = (v1, v2)
        self.expression = builder(v1, v2)
    }
    
    public func evaluate(_ input1: Input1, _ input2: Input2) throws -> Output {
        try expression.evaluate(
            .init(
                (variables.0, input1),
                (variables.1, input2)
            )
        )
    }
}

public struct Expression3<Input1, Input2, Input3, Output>: Sendable {
    public let expression: any StandardFilterExpression<Output>
    public let variables: (
        FilterExpressions.Variable<Input1>,
        FilterExpressions.Variable<Input2>,
        FilterExpressions.Variable<Input3>
    )
    
    public init(
        _ builder: (
            FilterExpressions.Variable<Input1>,
            FilterExpressions.Variable<Input2>,
            FilterExpressions.Variable<Input3>
        ) -> any StandardFilterExpression<Output>) {
        let v1 = FilterExpressions.Variable<Input1>()
        let v2 = FilterExpressions.Variable<Input2>()
        let v3 = FilterExpressions.Variable<Input3>()
        self.variables = (v1, v2, v3)
        self.expression = builder(v1, v2, v3)
    }
    
    public func evaluate(_ input1: Input1, _ input2: Input2, _ input3: Input3) throws -> Output {
        try expression.evaluate(
            .init(
                (variables.0, input1),
                (variables.1, input2),
                (variables.2, input3)
            )
        )
    }
}
*/
