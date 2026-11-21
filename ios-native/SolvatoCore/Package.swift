// swift-tools-version: 6.0
// Solvato'nun arayüzden bağımsız çekirdeği: tasarım değerleri ve (aşama 0.3'ten itibaren) puan, seviye, seri, kodlar.
// Yalnızca Foundation kullanır; Linux'ta da derlenir, böylece bulut oturumunda `swift test` ile doğrulanır.
import PackageDescription

let package = Package(
    name: "SolvatoCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "SolvatoCore", targets: ["SolvatoCore"])],
    targets: [
        .target(name: "SolvatoCore", resources: [.copy("Resources/soru-bankasi.json")]),
        .testTarget(
            name: "SolvatoCoreTests",
            dependencies: ["SolvatoCore"],
            resources: [.copy("Fixtures")]
        ),
    ]
)
