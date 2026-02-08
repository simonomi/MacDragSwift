// swift-tools-version: 6.2
import PackageDescription

let package = Package(
	name: "MacDragSwift",
	platforms: [
		.macOS(.v13)
	],
	dependencies: [
		.package(url: "https://github.com/tmandry/AXSwift", from: "0.3.0")
	],
	targets: [
		.executableTarget(
			name: "MacDragSwift",
			dependencies: [
				.product(name: "AXSwift", package: "AXSwift")
			]
		),
	]
)
