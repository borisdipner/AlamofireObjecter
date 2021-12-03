// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AlamofireObjecter",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "AlamofireObjecter",
            targets: ["AlamofireObjecter"]),
    ],
    dependencies: [
        .package(name: "Alamofire", url: "https://github.com/Alamofire/Alamofire.git", from: Version(stringLiteral: "5.4.0")),
        .package(name: "ObjectMapper", url: "https://github.com/tristanhimmelman/ObjectMapper.git", from: Version(stringLiteral: "4.1.0"))
    ],
    targets: [
        .target(
            name: "AlamofireObjecter",
            dependencies: ["Alamofire", "ObjectMapper"]),
        .testTarget(
            name: "AlamofireObjecterTests",
            dependencies: ["AlamofireObjecter"]),
    ]
)
