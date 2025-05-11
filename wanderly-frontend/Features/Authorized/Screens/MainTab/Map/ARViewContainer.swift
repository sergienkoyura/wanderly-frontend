//
//  ARViewContainer.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 11.05.2025.
//

import SwiftUI
import RealityKit
import ARKit

struct ARViewContainer: UIViewRepresentable {
    let code: Int

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        arView.session.run(config)

        let anchor = AnchorEntity(plane: .horizontal)

        if let coin = try? Entity.loadModel(named: "golden_coin") {
            coin.scale = SIMD3(repeating: 0.1)
            coin.position = SIMD3(x: 0, y: 0.5, z: 0)

            let text = MeshResource.generateText(
                String(format: "%04d", code),
                extrusionDepth: 0.01,
                font: .systemFont(ofSize: 0.2),
                containerFrame: .zero,
                alignment: .center,
                lineBreakMode: .byWordWrapping
            )
            let material = SimpleMaterial(color: .yellow, isMetallic: true)
            let textEntity = ModelEntity(mesh: text, materials: [material])
            textEntity.position = SIMD3(0.2, 0.6, 0)
            textEntity.scale = SIMD3(repeating: 5)

            coin.addChild(textEntity)
            anchor.addChild(coin)
            arView.scene.anchors.append(anchor)
        }

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}
}
