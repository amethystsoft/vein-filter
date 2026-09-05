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

import Testing

@Suite("#Filter Macro Language Operators")
private struct FilterMacroLanguageOperatorTests {
    @Test func equal() {
        AssertFilterExpansion(
            """
            #Filter<Object, Object> { inputA, inputB in
                inputA == inputB
            }
            """,
            """
            VeinFilter.Filter2<Object, Object>({ inputA, inputB in
                FilterExpressions.build_Equal(
                    lhs: FilterExpressions.build_Arg(inputA),
                    rhs: FilterExpressions.build_Arg(inputB)
                )
            })
            """
        )
    }
    
    @Test func equalExplicitReturn() {
        AssertFilterExpansion(
            """
            #Filter<Object, Object> { inputA, inputB in
                return inputA == inputB
            }
            """,
            """
            VeinFilter.Filter2<Object, Object>({ inputA, inputB in
                return FilterExpressions.build_Equal(
                    lhs: FilterExpressions.build_Arg(inputA),
                    rhs: FilterExpressions.build_Arg(inputB)
                )
            })
            """
        )
    }
    
    @Test func notEqual() {
        AssertFilterExpansion(
            """
            #Filter<Object, Object> { inputA, inputB in
                inputA != inputB
            }
            """,
            """
            VeinFilter.Filter2<Object, Object>({ inputA, inputB in
                FilterExpressions.build_NotEqual(
                    lhs: FilterExpressions.build_Arg(inputA),
                    rhs: FilterExpressions.build_Arg(inputB)
                )
            })
            """
        )
    }
    
    @Test func comparison() {
        AssertFilterExpansion(
            """
            #Filter<Object, Object> { inputA, inputB in
                inputA < inputB
            }
            """,
            """
            VeinFilter.Filter2<Object, Object>({ inputA, inputB in
                FilterExpressions.build_Comparison(
                    lhs: FilterExpressions.build_Arg(inputA),
                    rhs: FilterExpressions.build_Arg(inputB),
                    op: .lessThan
                )
            })
            """
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object, Object> { inputA, inputB in
                inputA <= inputB
            }
            """,
            """
            VeinFilter.Filter2<Object, Object>({ inputA, inputB in
                FilterExpressions.build_Comparison(
                    lhs: FilterExpressions.build_Arg(inputA),
                    rhs: FilterExpressions.build_Arg(inputB),
                    op: .lessThanOrEqual
                )
            })
            """
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object, Object> { inputA, inputB in
                inputA > inputB
            }
            """,
            """
            VeinFilter.Filter2<Object, Object>({ inputA, inputB in
                FilterExpressions.build_Comparison(
                    lhs: FilterExpressions.build_Arg(inputA),
                    rhs: FilterExpressions.build_Arg(inputB),
                    op: .greaterThan
                )
            })
            """
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object, Object> { inputA, inputB in
                inputA >= inputB
            }
            """,
            """
            VeinFilter.Filter2<Object, Object>({ inputA, inputB in
                FilterExpressions.build_Comparison(
                    lhs: FilterExpressions.build_Arg(inputA),
                    rhs: FilterExpressions.build_Arg(inputB),
                    op: .greaterThanOrEqual
                )
            })
            """
        )
    }
    
    @Test func conjunction() {
        AssertFilterExpansion(
            """
            #Filter<Object, Object> { inputA, inputB in
                inputA && inputB
            }
            """,
            """
            VeinFilter.Filter2<Object, Object>({ inputA, inputB in
                FilterExpressions.build_Conjunction(
                    lhs: FilterExpressions.build_Arg(inputA),
                    rhs: FilterExpressions.build_Arg(inputB)
                )
            })
            """
        )
    }
    
    @Test func disjunction() {
        AssertFilterExpansion(
            """
            #Filter<Object, Object> { inputA, inputB in
                inputA || inputB
            }
            """,
            """
            VeinFilter.Filter2<Object, Object>({ inputA, inputB in
                FilterExpressions.build_Disjunction(
                    lhs: FilterExpressions.build_Arg(inputA),
                    rhs: FilterExpressions.build_Arg(inputB)
                )
            })
            """
        )
    }
    
    @Test func arithmetic() {
        AssertFilterExpansion(
            """
            #Filter<Object, Object> { inputA, inputB in
                inputA + inputB
            }
            """,
            """
            VeinFilter.Filter2<Object, Object>({ inputA, inputB in
                FilterExpressions.build_Arithmetic(
                    lhs: FilterExpressions.build_Arg(inputA),
                    rhs: FilterExpressions.build_Arg(inputB),
                    op: .add
                )
            })
            """
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object, Object> { inputA, inputB in
                inputA - inputB
            }
            """,
            """
            VeinFilter.Filter2<Object, Object>({ inputA, inputB in
                FilterExpressions.build_Arithmetic(
                    lhs: FilterExpressions.build_Arg(inputA),
                    rhs: FilterExpressions.build_Arg(inputB),
                    op: .subtract
                )
            })
            """
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object, Object> { inputA, inputB in
                inputA * inputB
            }
            """,
            """
            VeinFilter.Filter2<Object, Object>({ inputA, inputB in
                FilterExpressions.build_Arithmetic(
                    lhs: FilterExpressions.build_Arg(inputA),
                    rhs: FilterExpressions.build_Arg(inputB),
                    op: .multiply
                )
            })
            """
        )
    }
    
    @Test func division() {
        AssertFilterExpansion(
            """
            #Filter<Object, Object> { inputA, inputB in
                inputA / inputB
            }
            """,
            """
            VeinFilter.Filter2<Object, Object>({ inputA, inputB in
                FilterExpressions.build_Division(
                    lhs: FilterExpressions.build_Arg(inputA),
                    rhs: FilterExpressions.build_Arg(inputB)
                )
            })
            """
        )
    }
    
    @Test func remainder() {
        AssertFilterExpansion(
            """
            #Filter<Object, Object> { inputA, inputB in
                inputA % inputB
            }
            """,
            """
            VeinFilter.Filter2<Object, Object>({ inputA, inputB in
                FilterExpressions.build_Remainder(
                    lhs: FilterExpressions.build_Arg(inputA),
                    rhs: FilterExpressions.build_Arg(inputB)
                )
            })
            """
        )
    }
    
    @Test func negation() {
        AssertFilterExpansion(
            """
            #Filter<Object, Object> { inputA, inputB in
                !inputA
            }
            """,
            """
            VeinFilter.Filter2<Object, Object>({ inputA, inputB in
                FilterExpressions.build_Negation(
                    FilterExpressions.build_Arg(inputA)
                )
            })
            """
        )
    }
    
    @Test func unaryMinus() {
        AssertFilterExpansion(
            """
            #Filter<Object, Object> { inputA, inputB in
                -inputA
            }
            """,
            """
            VeinFilter.Filter2<Object, Object>({ inputA, inputB in
                FilterExpressions.build_UnaryMinus(
                    FilterExpressions.build_Arg(inputA)
                )
            })
            """
        )
    }
    
    @Test func nilCoalesce() {
        AssertFilterExpansion(
            """
            #Filter<Object, Object> { inputA, inputB in
                inputA ?? inputB
            }
            """,
            """
            VeinFilter.Filter2<Object, Object>({ inputA, inputB in
                FilterExpressions.build_NilCoalesce(
                    lhs: FilterExpressions.build_Arg(inputA),
                    rhs: FilterExpressions.build_Arg(inputB)
                )
            })
            """
        )
    }
    
    @Test func ranges() {
        AssertFilterExpansion(
            """
            #Filter<Object, Object> { inputA, inputB in
                inputA ..< inputB
            }
            """,
            """
            VeinFilter.Filter2<Object, Object>({ inputA, inputB in
                FilterExpressions.build_Range(
                    lower: FilterExpressions.build_Arg(inputA),
                    upper: FilterExpressions.build_Arg(inputB)
                )
            })
            """
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object, Object> { inputA, inputB in
                inputA ... inputB
            }
            """,
            """
            VeinFilter.Filter2<Object, Object>({ inputA, inputB in
                FilterExpressions.build_ClosedRange(
                    lower: FilterExpressions.build_Arg(inputA),
                    upper: FilterExpressions.build_Arg(inputB)
                )
            })
            """
        )
    }
    
    @Test func optionalChaining() {
        AssertFilterExpansion(
            """
            #Filter<Object?> { inputA in
                inputA?.foo
            }
            """,
            """
            VeinFilter.Filter1<Object?>({ inputA in
                FilterExpressions.build_flatMap(
                    FilterExpressions.build_Arg(inputA)
                ) {
                    FilterExpressions.build_KeyPath(
                        root: FilterExpressions.build_Arg($0),
                        keyPath: \\.foo
                    )
                }
            })
            """
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object?> { inputA in
                inputA.flatMap {
                    $0.foo
                }
            }
            """,
            """
            VeinFilter.Filter1<Object?>({ inputA in
                FilterExpressions.build_flatMap(
                    FilterExpressions.build_Arg(inputA)
                ) {
                    FilterExpressions.build_KeyPath(
                        root: FilterExpressions.build_Arg($0),
                        keyPath: \\.foo
                    )
                }
            })
            """
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object> { inputA in
                inputA.foo?.bar
            }
            """,
            """
            VeinFilter.Filter1<Object>({ inputA in
                FilterExpressions.build_flatMap(
                    FilterExpressions.build_KeyPath(
                        root: FilterExpressions.build_Arg(inputA),
                        keyPath: \\.foo
                    )
                ) {
                    FilterExpressions.build_KeyPath(
                        root: FilterExpressions.build_Arg($0),
                        keyPath: \\.bar
                    )
                }
            })
            """
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object?> { inputA in
                inputA?.foo?.bar
            }
            """,
            """
            VeinFilter.Filter1<Object?>({ inputA in
                FilterExpressions.build_flatMap(
                    FilterExpressions.build_flatMap(
                        FilterExpressions.build_Arg(inputA)
                    ) {
                        FilterExpressions.build_KeyPath(
                            root: FilterExpressions.build_Arg($0),
                            keyPath: \\.foo
                        )
                    }
                ) {
                    FilterExpressions.build_KeyPath(
                        root: FilterExpressions.build_Arg($0),
                        keyPath: \\.bar
                    )
                }
            })
            """
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object> { inputA in
                inputA.foo?.contains(0)
            }
            """,
            """
            VeinFilter.Filter1<Object>({ inputA in
                FilterExpressions.build_flatMap(
                    FilterExpressions.build_KeyPath(
                        root: FilterExpressions.build_Arg(inputA),
                        keyPath: \\.foo
                    )
                ) {
                    FilterExpressions.build_contains(
                        FilterExpressions.build_Arg($0),
                        FilterExpressions.build_Arg(0)
                    )
                }
            })
            """
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object, Object> {
                $0.foo?.contains($1)
            }
            """,
            diagnostics: ["2:11: Optional chaining is not supported here in this filter. Use the flatMap(_:) function explicitly instead."]
        )
        
        // Ensure that operators that become nested in a flatMap due to optional chaining are folded correctly
        AssertFilterExpansion(
            """
            #Filter<Object?> {
                $0?.contains {
                    $0 == "Test"
                } ?? true
            }
            """,
            """
            VeinFilter.Filter1<Object?>({
                FilterExpressions.build_NilCoalesce(
                    lhs: FilterExpressions.build_flatMap(
                        FilterExpressions.build_Arg($0)
                    ) {
                        FilterExpressions.build_contains(
                            FilterExpressions.build_Arg($0)
                        ) {
                            FilterExpressions.build_Equal(
                                lhs: FilterExpressions.build_Arg($0),
                                rhs: FilterExpressions.build_Arg("Test")
                            )
                        }
                    },
                    rhs: FilterExpressions.build_Arg(true)
                )
            })
            """
        )
        
        AssertFilterExpansion(
            """
            #Filter<[Object?]> { objects in
                objects.allSatisfy {
                    $0?.bar == 2
                }
            }
            """,
            """
            VeinFilter.Filter1<[Object?]>({ objects in
                FilterExpressions.build_allSatisfy(
                    FilterExpressions.build_Arg(objects)
                ) {
                    FilterExpressions.build_Equal(
                        lhs: FilterExpressions.build_flatMap(
                            FilterExpressions.build_Arg($0)
                        ) {
                            FilterExpressions.build_KeyPath(
                                root: FilterExpressions.build_Arg($0),
                                keyPath: \\.bar
                            )
                        },
                        rhs: FilterExpressions.build_Arg(2)
                    )
                }
            })
            """
        )
    }
    
    @Test func forceUnwrap() {
        AssertFilterExpansion(
            """
            #Filter<Object?> { inputA in
                inputA!.foo
            }
            """,
            """
            VeinFilter.Filter1<Object?>({ inputA in
                FilterExpressions.build_KeyPath(
                    root: FilterExpressions.build_ForcedUnwrap(
                        FilterExpressions.build_Arg(inputA)
                    ),
                    keyPath: \\.foo
                )
            })
            """
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object> { inputA in
                inputA.foo!.bar
            }
            """,
            """
            VeinFilter.Filter1<Object>({ inputA in
                FilterExpressions.build_KeyPath(
                    root: FilterExpressions.build_ForcedUnwrap(
                        FilterExpressions.build_KeyPath(
                            root: FilterExpressions.build_Arg(inputA),
                            keyPath: \\.foo
                        )
                    ),
                    keyPath: \\.bar
                )
            })
            """
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object?> { inputA in
                inputA!.foo!.bar
            }
            """,
            """
            VeinFilter.Filter1<Object?>({ inputA in
                FilterExpressions.build_KeyPath(
                    root: FilterExpressions.build_ForcedUnwrap(
                        FilterExpressions.build_KeyPath(
                            root: FilterExpressions.build_ForcedUnwrap(
                                FilterExpressions.build_Arg(inputA)
                            ),
                            keyPath: \\.foo
                        )
                    ),
                    keyPath: \\.bar
                )
            })
            """
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object> { inputA in
                inputA.foo!.contains(0)
            }
            """,
            """
            VeinFilter.Filter1<Object>({ inputA in
                FilterExpressions.build_contains(
                    FilterExpressions.build_ForcedUnwrap(
                        FilterExpressions.build_KeyPath(
                            root: FilterExpressions.build_Arg(inputA),
                            keyPath: \\.foo
                        )
                    ),
                    FilterExpressions.build_Arg(0)
                )
            })
            """
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object?> { inputA in
                inputA!.foo?.bar
            }
            """,
            """
            VeinFilter.Filter1<Object?>({ inputA in
                FilterExpressions.build_flatMap(
                    FilterExpressions.build_KeyPath(
                        root: FilterExpressions.build_ForcedUnwrap(
                            FilterExpressions.build_Arg(inputA)
                        ),
                        keyPath: \\.foo
                    )
                ) {
                    FilterExpressions.build_KeyPath(
                        root: FilterExpressions.build_Arg($0),
                        keyPath: \\.bar
                    )
                }
            })
            """
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object?> { inputA in
                inputA?.foo!.bar
            }
            """,
            """
            VeinFilter.Filter1<Object?>({ inputA in
                FilterExpressions.build_flatMap(
                    FilterExpressions.build_Arg(inputA)
                ) {
                    FilterExpressions.build_KeyPath(
                        root: FilterExpressions.build_ForcedUnwrap(
                            FilterExpressions.build_KeyPath(
                                root: FilterExpressions.build_Arg($0),
                                keyPath: \\.foo
                            )
                        ),
                        keyPath: \\.bar
                    )
                }
            })
            """
        )
    }
    
    @Test func diagnoseUnknownOperator() {
        AssertFilterExpansion(
            """
            #Filter<Object, Object> { inputA, inputB in
                inputA & inputB
            }
            """,
            diagnostics: ["2:12: The '&' operator is not supported in this filter"]
        )
    }
}
