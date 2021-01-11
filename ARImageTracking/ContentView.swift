//
//  ContentView.swift
//  ARImageTracking
//
//  Created by Qi on 8/1/21.
//

import ARKit
import SwiftUI
import RealityKit

//Displays as a SwiftUI View
struct ContentView : View {
    var body: some View {
        return ARViewContainer().edgesIgnoringSafeArea(.all)
    }
}

struct ARViewContainer: UIViewRepresentable {
    var arView = ARView(frame: .zero)

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, ARSessionDelegate{
        var parent: ARViewContainer
        var videoPlayer: AVPlayer!
        
        init(parent: ARViewContainer) {
            self.parent = parent
        }
        
        func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            guard let imageAnchor = anchors[0] as? ARImageAnchor else {
                print("Problems loading anchor.")
                return
            }
            
            //Assigns video to be overlaid
            guard let path = Bundle.main.path(forResource: "iphonevideo", ofType: "mp4") else {
                print("Unable to find video file.")
                return
            }
            
            let videoURL = URL(fileURLWithPath: path)
            let playerItem = AVPlayerItem(url: videoURL)
            videoPlayer = AVPlayer(playerItem: playerItem)
            let videoMaterial = VideoMaterial(avPlayer: videoPlayer)
            
            //Sets the aspect ratio of the video to be played, and the corner radius of the video
            let videoPlane = ModelEntity(mesh: .generatePlane(width: 3, depth: 6.5, cornerRadius: 0.3), materials: [videoMaterial])
            
            //Assigns reference image that will be detected
            if let imageName = imageAnchor.name, imageName  == "xs" {
                let anchor = AnchorEntity(anchor: imageAnchor)
                //Adds specified video to the anchor
                anchor.addChild(videoPlane)
                parent.arView.scene.addAnchor(anchor)
            }
        }
        
        //Checks for tracking status
        func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
            guard let imageAnchor = anchors[0] as? ARImageAnchor else {
                print("Problems loading anchor.")
                return
            }
            
            //Plays/pauses the video when tracked/loses tracking
            if imageAnchor.isTracked {
                videoPlayer.play()
            } else {
                videoPlayer.pause()
            }
        }
    }
    
    func makeUIView(context: Context) -> ARView {
        guard let referenceImages = ARReferenceImage.referenceImages(
                    inGroupNamed: "AR Resources", bundle: nil) else {
                    fatalError("Missing expected asset catalog resources.")
                }
        
        //Assigns coordinator to delegate the AR View
        arView.session.delegate = context.coordinator
        
        let configuration = ARImageTrackingConfiguration()
        configuration.isAutoFocusEnabled = true
        configuration.trackingImages = referenceImages
        configuration.maximumNumberOfTrackedImages = 1
        
        //Enables People Occulusion on supported iOS Devices
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
            configuration.frameSemantics.insert(.personSegmentationWithDepth)
        } else {
            print("People Segmentation not enabled.")
        }

        arView.session.run(configuration)
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}

