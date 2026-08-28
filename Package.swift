// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "VeinFilter",
    platforms: [.macOS(.v13), .iOS(.v16), .tvOS(.v16), .macCatalyst(.v16), .visionOS(.v1)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "VeinFilter",
            targets: ["VeinFilter"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swiftlang/swift-syntax",
            "602.0.0"..."610.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "VeinFilter",
            dependencies: ["VeinFilterMacros"]
        ),
        .macro(
            name: "VeinFilterMacros",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),
        .testTarget(
            name: "VeinFilterTests",
            dependencies: ["VeinFilter"]
        ),
        .testTarget(
            name: "VeinFilterMacroTests",
            dependencies: [
                "VeinFilterMacros",
                "VeinFilter"
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
