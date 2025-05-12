//
//  ARViewContainer.swift
//  wanderly-frontend
//
//  Created by Yurii Serhiienko on 11.05.2025.
//

import SwiftUI
import RealityKit
import ARKit
import Combine

struct ARViewContainer: UIViewRepresentable {
    let code: Int
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        context.coordinator.arView = arView
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .none // reduce quality
        arView.session.run(config)
        
        let anchor = AnchorEntity(plane: .horizontal)
        
        if let coin = try? Entity.loadModel(named: "golden_coin") {
            coin.name = "coin" // important for hitTest filtering
            coin.scale = SIMD3(repeating: 0.1)
            coin.position = SIMD3(x: 0, y: 0.5, z: 0)
            
            // Add collision so it can be tapped
            coin.generateCollisionShapes(recursive: true)
            
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
        // Add tap recognizer on ARView
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
    
    
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    class Coordinator: NSObject {
        weak var arView: ARView?
        
        @objc func handleTap(_ sender: UITapGestureRecognizer) {
            guard let arView = arView else { return }
            let tapLocation = sender.location(in: arView)
            
            if let entity = arView.entity(at: tapLocation), entity.name == "coin" {
                let rotation = simd_quatf(angle: .pi / 2, axis: SIMD3(0, 1, 0))
                let transform = Transform(
                    scale: entity.transform.scale,
                    rotation: entity.transform.rotation * rotation,
                    translation: entity.transform.translation
                )
                entity.move(to: transform, relativeTo: entity.parent, duration: 1.0, timingFunction: .easeInOut)
            }
        }
    }
}
