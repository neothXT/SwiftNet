// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "CombineNetworking",
	platforms: [
		.macOS(.v10_15),
		.iOS(.v13)
	],
	products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "CombineNetworking",
            targets: ["CombineNetworking"]),
        .library(
            name: "CombineNetworkingMacros",
            targets: ["CombineNetworkingMacros"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0-swift-5.9-DEVELOPMENT-SNAPSHOT-2023-04-25-b"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .macro(
            name: "CNMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .target(
            name: "CombineNetworking",
            dependencies: ["CombineNetworkingMacros"],
			exclude: ["../../CombineNetworking.podspec"]),
        .testTarget(
            name: "CombineNetworkingTests",
            dependencies: ["CombineNetworking"]),
        .target(
            name: "CombineNetworkingMacros",
            dependencies: ["CNMacros"]),
        .testTarget(
            name: "CombineNetworkingMacrosTests",
            dependencies: [
                "CombineNetworkingMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")
            ]
        )
    ]
)
