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

@Suite("#Filter Macro Function Calls")
private struct FilterMacroFunctionCallTests {
    @Test func `subscript`() {
        AssertFilterExpansion(
            """
            #Filter<Object> { input in
                input[1]
            }
            """,
            """
            VeinFilter.Filter1<Object>({ input in
                FilterExpressions.build_subscript(
                    FilterExpressions.build_Arg(input),
                    FilterExpressions.build_Arg(1)
                )
            })
            """
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object> { input in
                input[1, default: "Hello"]
            }
            """,
            """
            VeinFilter.Filter1<Object>({ input in
                FilterExpressions.build_subscript(
                    FilterExpressions.build_Arg(input),
                    FilterExpressions.build_Arg(1),
                    default: FilterExpressions.build_Arg("Hello")
                )
            })
            """
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object> { input, input2, input3 in
                input.dictionary[input2 + 1, default: input3 == input2] == false
            }
            """,
            """
            VeinFilter.Filter1<Object>({ input, input2, input3 in
                FilterExpressions.build_Equal(
                    lhs: FilterExpressions.build_subscript(
                        FilterExpressions.build_KeyPath(
                            root: FilterExpressions.build_Arg(input),
                            keyPath: \\.dictionary
                        ),
                        FilterExpressions.build_Arithmetic(
                            lhs: FilterExpressions.build_Arg(input2),
                            rhs: FilterExpressions.build_Arg(1),
                            op: .add
                        ),
                        default: FilterExpressions.build_Equal(
                            lhs: FilterExpressions.build_Arg(input3),
                            rhs: FilterExpressions.build_Arg(input2)
                        )
                    ),
                    rhs: FilterExpressions.build_Arg(false)
                )
            })
            """
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object> { input in
                input[index: 1]
            }
            """,
            diagnostics: ["2:10: The subscript(index:) function is not supported in this filter"]
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object> { input in
                input[1, index: 2, 3, other: 4]
            }
            """,
            diagnostics: ["2:10: The subscript(_:index:_:other:) function is not supported in this filter"]
        )
    }
    
    @Test func contains() {
        AssertFilterExpansion(
            """
            #Filter<Object, Object> { inputA, inputB in
                inputA.contains(inputB)
            }
            """,
            """
            VeinFilter.Filter2<Object, Object>({ inputA, inputB in
                FilterExpressions.build_contains(
                    FilterExpressions.build_Arg(inputA),
                    FilterExpressions.build_Arg(inputB)
                )
            })
            """
        )
        
        AssertFilterExpansion(
            """
            #Filter<String> { input in
                input.contains("foo")
            }
            """,
            """
            VeinFilter.Filter1<String>({ input in
                FilterExpressions.build_contains(
                    FilterExpressions.build_Arg(input),
                    FilterExpressions.build_Arg("foo")
                )
            })
            """
        )
    }
    
    @Test func containsWhere() {
        AssertFilterExpansion(
            """
            #Filter<Object> { inputA in
                inputA.contains(where: {
                    $0
                })
            }
            """,
            """
            VeinFilter.Filter1<Object>({ inputA in
                FilterExpressions.build_contains(
                    FilterExpressions.build_Arg(inputA),
                    where: {
                        FilterExpressions.build_Arg(
                            $0
                        )
                    }
                )
            })
            """
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object> { inputA in
                inputA.contains {
                    $0
                }
            }
            """,
            """
            VeinFilter.Filter1<Object>({ inputA in
                FilterExpressions.build_contains(
                    FilterExpressions.build_Arg(inputA)
                ) {
                    FilterExpressions.build_Arg(
                        $0
                    )
                }
            })
            """
        )
    }
    
    @Test func allSatisfy() {
        AssertFilterExpansion(
            """
            #Filter<Object> { inputA in
                inputA.allSatisfy({
                    $0
                })
            }
            """,
            """
            VeinFilter.Filter1<Object>({ inputA in
                FilterExpressions.build_allSatisfy(
                    FilterExpressions.build_Arg(inputA),
                    {
                        FilterExpressions.build_Arg(
                            $0
                        )
                    }
                )
            })
            """
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object> { inputA in
                inputA.allSatisfy {
                    $0
                }
            }
            """,
            """
            VeinFilter.Filter1<Object>({ inputA in
                FilterExpressions.build_allSatisfy(
                    FilterExpressions.build_Arg(inputA)
                ) {
                    FilterExpressions.build_Arg(
                        $0
                    )
                }
            })
            """
        )
    }
    
    @Test func filter() {
        AssertFilterExpansion(
            """
            #Filter<Object> { inputA in
                inputA.filter({
                    $0
                })
            }
            """,
            """
            VeinFilter.Filter1<Object>({ inputA in
                FilterExpressions.build_filter(
                    FilterExpressions.build_Arg(inputA),
                    {
                        FilterExpressions.build_Arg(
                            $0
                        )
                    }
                )
            })
            """
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object> { inputA in
                inputA.filter {
                    $0
                }
            }
            """,
            """
            VeinFilter.Filter1<Object>({ inputA in
                FilterExpressions.build_filter(
                    FilterExpressions.build_Arg(inputA)
                ) {
                    FilterExpressions.build_Arg(
                        $0
                    )
                }
            })
            """
        )
        
        // Ensure that keypath literals are correctly translated into closure arguments
        AssertFilterExpansion(
            """
            #Filter<Object> { inputA in
                inputA.filter(\\Element.foo.bar)
            }
            """,
            """
            VeinFilter.Filter1<Object>({ inputA in
                FilterExpressions.build_filter(
                    FilterExpressions.build_Arg(inputA),
                    {
                        FilterExpressions.build_KeyPath(
                            root: FilterExpressions.build_KeyPath(
                                root: FilterExpressions.build_Arg($0),
                                keyPath: \\.foo
                            ),
                            keyPath: \\.bar
                        )
                    }
                )
            })
            """
        )
        
        // Ensure keypath literal to closure transformation only occurs when argument is a closure type
        // Note: starts(with:) explicitly does not take a closure as its argument
        AssertFilterExpansion(
            """
            #Filter<Object> { inputA in
                inputA.starts(with: \\Element.foo.bar)
            }
            """,
            """
            VeinFilter.Filter1<Object>({ inputA in
                FilterExpressions.build_starts(
                    FilterExpressions.build_Arg(inputA),
                    with: FilterExpressions.build_Arg(\\Element.foo.bar)
                )
            })
            """
        )
        
        AssertFilterExpansion(
            """
            #Filter<[Object]> { inputA in
                inputA.filter(\\.foo!.bar).isEmpty
            }
            """,
            """
            VeinFilter.Filter1<[Object]>({ inputA in
                FilterExpressions.build_KeyPath(
                    root: FilterExpressions.build_filter(
                        FilterExpressions.build_Arg(inputA),
                        {
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
                    ),
                    keyPath: \\.isEmpty
                )
            })
            """
        )
        
        // Key paths with anonymous closure arguments cannot be rewritten into nested closures automatically
        AssertFilterExpansion(
            """
            #Filter<[Object]> { inputA in
                inputA.filter(\\.foo[$0]).isEmpty
            }
            """,
            diagnostics: ["2:19: This key path is not supported here in this filter. Use an explicit closure instead."]
        )
    }
    
    @Test func startsWith() {
        AssertFilterExpansion(
            """
            #Filter<Object> { inputA in
                inputA.starts(with: "foo")
            }
            """,
            """
            VeinFilter.Filter1<Object>({ inputA in
                FilterExpressions.build_starts(
                    FilterExpressions.build_Arg(inputA),
                    with: FilterExpressions.build_Arg("foo")
                )
            })
            """
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object> { inputA in
                inputA.hasPrefix("foo")
            }
            """,
            diagnostics: [
                DiagnosticTest(
                    "2:12: The hasPrefix(_:) function is not supported in this filter",
                    fixIts: [
                        DiagnosticTest.FixItTest(
                            "Use starts(with:)",
                            result: """
                                    inputA.starts(with: "foo")
                                    """
                        )
                    ]
                )
            ]
        )
    }
    
    @Test func min() {
        AssertFilterExpansion(
            """
            #Filter<[Int]> { inputA in
                inputA.min() == 0
            }
            """,
            """
            VeinFilter.Filter1<[Int]>({ inputA in
                FilterExpressions.build_Equal(
                    lhs: FilterExpressions.build_min(
                        FilterExpressions.build_Arg(inputA)
                    ),
                    rhs: FilterExpressions.build_Arg(0)
                )
            })
            """
        )
    }
    
    @Test func max() {
        AssertFilterExpansion(
            """
            #Filter<[Int]> { inputA in
                inputA.max() == 0
            }
            """,
            """
            VeinFilter.Filter1<[Int]>({ inputA in
                FilterExpressions.build_Equal(
                    lhs: FilterExpressions.build_max(
                        FilterExpressions.build_Arg(inputA)
                    ),
                    rhs: FilterExpressions.build_Arg(0)
                )
            })
            """
        )
    }
    
    @Test func localizedStandardContains() {
        AssertFilterExpansion(
            """
            #Filter<String> { inputA in
                inputA.localizedStandardContains("foo")
            }
            """,
            """
            VeinFilter.Filter1<String>({ inputA in
                FilterExpressions.build_localizedStandardContains(
                    FilterExpressions.build_Arg(inputA),
                    FilterExpressions.build_Arg("foo")
                )
            })
            """
        )
        
        AssertFilterExpansion(
            """
            #Filter<String> { inputA in
                inputA.localizedCaseInsensitiveContains("foo")
            }
            """,
            diagnostics: [
                DiagnosticTest(
                    "2:12: The localizedCaseInsensitiveContains(_:) function is not supported in this filter",
                    fixIts: [
                        DiagnosticTest.FixItTest(
                            "Use localizedStandardContains(_:)",
                            result: "inputA.localizedStandardContains(\"foo\")"
                        )
                    ])
            ]
        )
    }
    
    @Test func localizedStandardCompare() {
        AssertFilterExpansion(
            """
            #Filter<String> { inputA in
                inputA.localizedCompare("foo")
            }
            """,
            """
            VeinFilter.Filter1<String>({ inputA in
                FilterExpressions.build_localizedCompare(
                    FilterExpressions.build_Arg(inputA),
                    FilterExpressions.build_Arg("foo")
                )
            })
            """
        )
        
        AssertFilterExpansion(
            """
            #Filter<String> { inputA in
                inputA.localizedCaseInsensitiveCompare("foo")
            }
            """,
            diagnostics: [
                DiagnosticTest(
                    "2:12: The localizedCaseInsensitiveCompare(_:) function is not supported in this filter",
                    fixIts: [
                        DiagnosticTest.FixItTest(
                            "Use localizedCompare(_:)",
                            result: "inputA.localizedCompare(\"foo\")"
                        )
                    ])
            ]
        )
        
        AssertFilterExpansion(
            """
            #Filter<String> { inputA in
                inputA.localizedStandardCompare("foo")
            }
            """,
            diagnostics: [
                DiagnosticTest(
                    "2:12: The localizedStandardCompare(_:) function is not supported in this filter",
                    fixIts: [
                        DiagnosticTest.FixItTest(
                            "Use localizedCompare(_:)",
                            result: "inputA.localizedCompare(\"foo\")"
                        )
                    ])
            ]
        )
    }
    
    @Test func caseInsensitiveCompare() {
        AssertFilterExpansion(
            """
            #Filter<String> { inputA in
                inputA.caseInsensitiveCompare("foo")
            }
            """,
            """
            VeinFilter.Filter1<String>({ inputA in
                FilterExpressions.build_caseInsensitiveCompare(
                    FilterExpressions.build_Arg(inputA),
                    FilterExpressions.build_Arg("foo")
                )
            })
            """
            //diagnostics: ["2:12: The caseInsensitiveCompare(_:) function is not supported in this filter"]
        )
    }
    
    @Test func diagnoseUnsupportedFunction() {
        AssertFilterExpansion(
            """
            #Filter<Object> { inputA in
               globalFunction(inputA)
            }
            """,
            diagnostics: ["2:4: Global functions are not supported in this filter"]
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object, Object> { inputA, inputB in
               inputA.unsupportedFunction(inputB)
            }
            """,
            diagnostics: ["2:11: The unsupportedFunction(_:) function is not supported in this filter"]
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object, Object> { inputA, inputB in
               inputA.unsupportedFunction(label: inputB)
            }
            """,
            diagnostics: ["2:11: The unsupportedFunction(label:) function is not supported in this filter"]
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object, Object> { inputA, inputB in
               inputA.unsupportedFunction { $0 }
            }
            """,
            diagnostics: ["2:11: The unsupportedFunction() function is not supported in this filter"]
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object, Object> { inputA, inputB in
               inputA.unsupportedFunction(inputB) { $0 }
            }
            """,
            diagnostics: ["2:11: The unsupportedFunction(_:) function is not supported in this filter"]
        )
        
        AssertFilterExpansion(
            """
            #Filter<Object, Object> { inputA, inputB in
               inputA.unsupportedFunction(label: inputB) { $0 }
            }
            """,
            diagnostics: ["2:11: The unsupportedFunction(label:) function is not supported in this filter"]
        )
    }
}
