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

@Suite("#Filter Macro Basics")
private struct FilterMacroBasicTests {
    @Test func simple() {
        AssertFilterExpansion(
            """
            #Filter<Object> { input in
                return true
            }
            """,
            """
            VeinFilter.Filter1<Object>({ input in
                return FilterExpressions.build_Arg(
                    true
                )
            })
            """
        )
    }
    
    @Test func implicitReturn() {
        AssertFilterExpansion(
            """
            #Filter<Object> { input in
                true
            }
            """,
            """
            VeinFilter.Filter1<Object>({ input in
                FilterExpressions.build_Arg(
                    true
                )
            })
            """
        )
    }
    
    @Test func inferredGenerics() {
        AssertFilterExpansion(
            """
            #Filter { input in
                true
            }
            """,
            """
            VeinFilter.Filter1({ input in
                FilterExpressions.build_Arg(
                    true
                )
            })
            """
        )
    }
    
    @Test func shorthandArgumentNames() {
        AssertFilterExpansion(
            """
            #Filter<Object> {
                $0
            }
            """,
            """
            VeinFilter.Filter1<Object>({
                FilterExpressions.build_Arg(
                    $0
                )
            })
            """
        )
    }
    
    @Test func explicitClosureArgumentTypes() {
        AssertFilterExpansion(
            """
            #Filter<Int, String> { (a: Int, b: String) -> Bool in
                true
            }
            """,
            """
            VeinFilter.Filter2<Int, String>({ (a: FilterExpressions.Variable<Int>, b: FilterExpressions.Variable<String>) in
                FilterExpressions.build_Arg(
                    true
                )
            })
            """
        )
    }
    
    @Test func diagnoseMissingTrailingClosure() {
        AssertFilterExpansion(
            """
            #Filter
            """,
            diagnostics: ["1:1: #Filter macro expansion requires a trailing closure"]
        )
        AssertFilterExpansion(
            """
            #Filter<Object>
            """,
            diagnostics: ["1:1: #Filter macro expansion requires a trailing closure"]
        )
        AssertFilterExpansion(
            """
            #Filter<Object>(myClosure)
            """,
            diagnostics: ["1:1: #Filter macro expansion requires a trailing closure"]
        )
        AssertFilterExpansion(
            """
            #Filter<Object>({
                return true
            })
            """,
            diagnostics: [
                DiagnosticTest(
                    "1:1: #Filter macro expansion requires a trailing closure",
                    fixIts: [
                        DiagnosticTest.FixItTest(
                            "Use a trailing closure instead of a function parameter",
                            result: """
                                    #Filter<Object> {
                                        return true
                                    }
                                    """
                        )
                    ]
                )
            ]
        )
    }
    
    @Test func keyPath() {
        AssertFilterExpansion(
            """
            #Filter<Object> {
                $0.foo
            }
            """,
            """
            VeinFilter.Filter1<Object>({
                FilterExpressions.build_KeyPath(
                    root: FilterExpressions.build_Arg($0),
                    keyPath: \\.foo
                )
            })
            """
        )
        AssertFilterExpansion(
            """
            #Filter<Object> { input in
                input.foo
            }
            """,
            """
            VeinFilter.Filter1<Object>({ input in
                FilterExpressions.build_KeyPath(
                    root: FilterExpressions.build_Arg(input),
                    keyPath: \\.foo
                )
            })
            """
        )
        AssertFilterExpansion(
            """
            #Filter<Object> {
                $0.foo.bar
            }
            """,
            """
            VeinFilter.Filter1<Object>({
                FilterExpressions.build_KeyPath(
                    root: FilterExpressions.build_KeyPath(
                        root: FilterExpressions.build_Arg($0),
                        keyPath: \\.foo
                    ),
                    keyPath: \\.bar
                )
            })
            """
        )
    }
    
    @Test func comments() {
        AssertFilterExpansion(
            """
            // comment
            #Filter<Object> { input in // comment
                return true // comment
            } // comment
            """,
            """
            // comment
            VeinFilter.Filter1<Object>({ input in
                return FilterExpressions.build_Arg(
                    true // comment
                )
            }) // comment
            """
        )
    }
}
