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
import VeinFilter

// MARK: - Stubs

@inline(never)
fileprivate func _blackHole<T>(_ t: T) {}

@inline(never)
@available(macOS 13, iOS 16, watchOS 9, tvOS 16, *)
fileprivate func _blackHoleExplicitInput(_ filter: Filter1<Int>) {}

// MARK: - Tests

@Suite("#Filter Macro Usage")
private struct PredicateMacroUsageTests {
    @available(macOS 14, iOS 17, watchOS 10, tvOS 17, *)
    @Test func usage() {
        _blackHole(#Filter<Bool> {
            return $0
        })
        _blackHole(#Filter<Bool> { input in
            return true
        })
        _blackHole(#Filter<Bool> { input in
            return input
        })
        _blackHole(#Filter<Bool> { input in
            return input && input
        })
        _blackHoleExplicitInput(#Filter { input in
            return true
        })
    }
}
