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

@Suite("#Filter Macro Language Tokens")
private struct FilterMacroLanguageTokenTests {
    @Test func conditional() {
        AssertFilterExpansion(
            """
            #Filter<Object, Object, Object> { inputA, inputB, inputC in
                inputA ? inputB : inputC
            }
            """,
            """
            VeinFilter.Filter3<Object, Object, Object>({ inputA, inputB, inputC in
                FilterExpressions.build_Conditional(
                    FilterExpressions.build_Arg(inputA),
                    FilterExpressions.build_Arg(inputB),
                    FilterExpressions.build_Arg(inputC)
                )
            })
            """
        )
    }
    
    @Test func typeCheck() {
        AssertFilterExpansion(
            """
            #Filter<Object> { input in
                input is Int
            }
            """,
            """
            VeinFilter.Filter1<Object>({ input in
                FilterExpressions.TypeCheck<_, Int>(
                    FilterExpressions.build_Arg(input)
                )
            })
            """
        )
    }
    
    @Test func conditionalCast() {
        AssertFilterExpansion(
            """
            #Filter<Object> { input in
                (input as? Bool) == true
            }
            """,
            """
            VeinFilter.Filter1<Object>({ input in
                FilterExpressions.build_Equal(
                    lhs: FilterExpressions.ConditionalCast<_, Bool>(
                        FilterExpressions.build_Arg(input)
                    ),
                    rhs: FilterExpressions.build_Arg(true)
                )
            })
            """
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object> { input in
                (input as Bool) == true
            }
            """,
            """
            VeinFilter.Filter1<Object>({ input in
                FilterExpressions.build_Equal(
                    lhs: FilterExpressions.ForceCast<_, Bool>(
                        FilterExpressions.build_Arg(input)
                    ),
                    rhs: FilterExpressions.build_Arg(true)
                )
            })
            """
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object> { input in
                (input as! Bool) == true
            }
            """,
            """
            VeinFilter.Filter1<Object>({ input in
                FilterExpressions.build_Equal(
                    lhs: FilterExpressions.ForceCast<_, Bool>(
                        FilterExpressions.build_Arg(input)
                    ),
                    rhs: FilterExpressions.build_Arg(true)
                )
            })
            """
        )
    }
    
    @Test func ifExpressions() {
        AssertFilterExpansion(
            """
            #Filter<Object> { input in
                if input {
                    return input
                } else {
                    return input.foo
                }
            }
            """,
            """
            VeinFilter.Filter1<Object>({ input in
                FilterExpressions.build_Conditional(
                    FilterExpressions.build_Arg(input),
                    FilterExpressions.build_Arg(
                        input
                    ),
                    FilterExpressions.build_KeyPath(
                        root: FilterExpressions.build_Arg(input),
                        keyPath: \\.foo
                    )
                )
            })
            """
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object, Object> { input, inputB in
                if input.foo, input.abc && input.xyz {
                    input.bar && input.baz
                } else {
                    inputB.foobar
                }
            }
            """,
            """
            VeinFilter.Filter2<Object, Object>({ input, inputB in
                FilterExpressions.build_Conditional(
                    FilterExpressions.build_Conjunction(
                        lhs: FilterExpressions.build_KeyPath(
                            root: FilterExpressions.build_Arg(input),
                            keyPath: \\.foo
                        ),
                        rhs: FilterExpressions.build_Conjunction(
                            lhs: FilterExpressions.build_KeyPath(
                                root: FilterExpressions.build_Arg(input),
                                keyPath: \\.abc
                            ),
                            rhs: FilterExpressions.build_KeyPath(
                                root: FilterExpressions.build_Arg(input),
                                keyPath: \\.xyz
                            )
                        )
                    ),
                    FilterExpressions.build_Conjunction(
                        lhs: FilterExpressions.build_KeyPath(
                            root: FilterExpressions.build_Arg(input),
                            keyPath: \\.bar
                        ),
                        rhs: FilterExpressions.build_KeyPath(
                            root: FilterExpressions.build_Arg(input),
                            keyPath: \\.baz
                        )
                    ),
                    FilterExpressions.build_KeyPath(
                        root: FilterExpressions.build_Arg(inputB),
                        keyPath: \\.foobar
                    )
                )
            })
            """
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object> { input in
                if input.foo {
                    if input.bar {
                        input.baz
                    } else {
                        input.foobar
                    }
                } else {
                    if input.bar {
                        input.foobar
                    } else {
                        input.baz
                    }
                }
            }
            """,
            """
            VeinFilter.Filter1<Object>({ input in
                FilterExpressions.build_Conditional(
                    FilterExpressions.build_KeyPath(
                        root: FilterExpressions.build_Arg(input),
                        keyPath: \\.foo
                    ),
                    FilterExpressions.build_Conditional(
                        FilterExpressions.build_KeyPath(
                            root: FilterExpressions.build_Arg(input),
                            keyPath: \\.bar
                        ),
                        FilterExpressions.build_KeyPath(
                            root: FilterExpressions.build_Arg(input),
                            keyPath: \\.baz
                        ),
                        FilterExpressions.build_KeyPath(
                            root: FilterExpressions.build_Arg(input),
                            keyPath: \\.foobar
                        )
                    ),
                    FilterExpressions.build_Conditional(
                        FilterExpressions.build_KeyPath(
                            root: FilterExpressions.build_Arg(input),
                            keyPath: \\.bar
                        ),
                        FilterExpressions.build_KeyPath(
                            root: FilterExpressions.build_Arg(input),
                            keyPath: \\.foobar
                        ),
                        FilterExpressions.build_KeyPath(
                            root: FilterExpressions.build_Arg(input),
                            keyPath: \\.baz
                        )
                    )
                )
            })
            """
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object> { input in
                if #available(macOS 14, *) {
                    input.foo
                } else {
                    input.bar
                }
            }
            """,
            diagnostics: ["2:8: Availability conditions are not supported in this filter"]
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object?> { input in
                if let nonOpt = input {
                    nonOpt.foo
                } else {
                    true
                }
            }
            """,
            """
            VeinFilter.Filter1<Object?>({ input in
                FilterExpressions.build_NilCoalesce(
                    lhs: FilterExpressions.build_flatMap(
                        FilterExpressions.build_Arg(input)
                    ) { nonOpt in
                        FilterExpressions.build_KeyPath(
                            root: FilterExpressions.build_Arg(nonOpt),
                            keyPath: \\.foo
                        )
                    },
                    rhs: FilterExpressions.build_Arg(
                        true
                    )
                )
            })
            """
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object?> { input in
                if let nonOpt = input, let nonOpt2 = nonOpt.foo {
                    nonOpt2
                } else {
                    true
                }
            }
            """,
            """
            VeinFilter.Filter1<Object?>({ input in
                FilterExpressions.build_NilCoalesce(
                    lhs: FilterExpressions.build_flatMap(
                        FilterExpressions.build_Arg(input)
                    ) { nonOpt in
                        FilterExpressions.build_flatMap(
                            FilterExpressions.build_KeyPath(
                                root: FilterExpressions.build_Arg(nonOpt),
                                keyPath: \\.foo
                            )
                        ) { nonOpt2 in
                            FilterExpressions.build_Arg(
                                nonOpt2
                            )
                        }
                    },
                    rhs: FilterExpressions.build_Arg(
                        true
                    )
                )
            })
            """
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object> { input in
                if let nonOpt = input.foo?.bar {
                    nonOpt.baz
                } else {
                    true
                }
            }
            """,
            """
            VeinFilter.Filter1<Object>({ input in
                FilterExpressions.build_NilCoalesce(
                    lhs: FilterExpressions.build_flatMap(
                        FilterExpressions.build_flatMap(
                            FilterExpressions.build_KeyPath(
                                root: FilterExpressions.build_Arg(input),
                                keyPath: \\.foo
                            )
                        ) {
                            FilterExpressions.build_KeyPath(
                                root: FilterExpressions.build_Arg($0),
                                keyPath: \\.bar
                            )
                        }
                    ) { nonOpt in
                        FilterExpressions.build_KeyPath(
                            root: FilterExpressions.build_Arg(nonOpt),
                            keyPath: \\.baz
                        )
                    },
                    rhs: FilterExpressions.build_Arg(
                        true
                    )
                )
            })
            """
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object?> { input in
                if case .enumcase(let assocval) = input.foo {
                    assocval
                } else {
                    true
                }
            }
            """,
            diagnostics: ["2:8: Matching pattern conditions are not supported in this filter"]
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object?> { input in
                if let nonOpt = input, nonOpt.foo == 2 {
                    nonOpt.bar
                } else {
                    true
                }
            }
            """,
            diagnostics: ["2:8: Mixing optional bindings with other conditions is not supported in this filter"]
        )
    }
    
    @Test func nilLiterals() {
        AssertFilterExpansion(
            """
            #Filter<Object?> { input in
                input == nil
            }
            """,
            """
            VeinFilter.Filter1<Object?>({ input in
                FilterExpressions.build_Equal(
                    lhs: FilterExpressions.build_Arg(input),
                    rhs: FilterExpressions.build_NilLiteral()
                )
            })
            """
        )
    }
    
    @Test func diagnoseDeclarations() {
        AssertFilterExpansion(
            """
            #Filter<Object> { input in
                let foo = input
                return foo
            }
            """,
            diagnostics: ["3:5: Filter body may only contain one expression"]
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object> { input in
                var foo = input
                return foo
            }
            """,
            diagnostics: ["3:5: Filter body may only contain one expression"]
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object> { input in
                struct Foo {}
                return true
            }
            """,
            diagnostics: ["3:5: Filter body may only contain one expression"]
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object> { input in
                class Foo {}
                return true
            }
            """,
            diagnostics: ["3:5: Filter body may only contain one expression"]
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object> { input in
                protocol Foo {}
                return true
            }
            """,
            diagnostics: ["3:5: Filter body may only contain one expression"]
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object> { input in
                func bar() {}
                return foo
            }
            """,
            diagnostics: ["3:5: Filter body may only contain one expression"]
        )
    }
    
    @Test func diagnoseMiscellaneousStatements() {
        AssertFilterExpansion(
            """
            #Filter<Object> { input in
                for _ in 0 ..< 2 {
                    return true
                }
            }
            """,
            diagnostics: ["2:5: For-in loops are not supported in this filter"]
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object> { input in
                while true {
                    return true
                }
            }
            """,
            diagnostics: ["2:5: While loops are not supported in this filter"]
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object> { input in
                repeat {
                    return true
                } while true
            }
            """,
            diagnostics: ["2:5: Repeat-while loops are not supported in this filter"]
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object> { input in
                do {
                    let foo = "hello"
                    return true
                }
            }
            """,
            diagnostics: ["4:9: Filter body may only contain one expression"]
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object> { input in
                do {
                    return input
                }
            }
            """,
            """
            VeinFilter.Filter1<Object>({ input in
                return FilterExpressions.build_Arg(
                    input
                )
            })
            """
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object> { input in
                do {
                    return true
                } while true
            }
            """,
            diagnostics: ["4:7: Filter body may only contain one expression"]
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object> { input in
                switch input {
                default: return true
                }
            }
            """,
            diagnostics: ["2:5: Switch expressions are not supported in this filter"]
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object> { input in
                do {
                    return try input.foo
                } catch {
                    return false
                }
            }
            """,
            diagnostics: ["4:7: Catch clauses are not supported in this filter"]
        )
    }
}
