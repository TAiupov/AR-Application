//
//  ContentView.swift
//  AR Application
//
//  Created by Тагир Аюпов on 2021-05-26.
//

import SwiftUI
import RealityKit
import ARKit
import FocusEntity

struct ContentView : View {
    @State private var isPlacementEnabled = false
    @State private var selectedModel: Model?
    @State private var modelConfirmedForPlacement: Model?
    private var models: [Model] = {
        let filemanager = FileManager.default
        
        guard let path = Bundle.main.resourcePath, let files = try? filemanager.contentsOfDirectory(atPath: path) else { return [] }
        
        var availModels: [Model] = []
        for fileName in files where fileName.hasSuffix("usdz") {
            let modelName = fileName.replacingOccurrences(of: ".usdz", with: "")
            let model = Model(modelName: modelName)
            availModels.append(model)
        }
        return availModels
    }()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ARViewContainer(modelConfirmedForPlacement: $modelConfirmedForPlacement)
            
            if isPlacementEnabled {
                PlacementButtonView(isPlacementEnabled: $isPlacementEnabled, selectedModel: $selectedModel, modelConfirmedForPlacement: $modelConfirmedForPlacement)
            } else {
                ModelPickerView(isPlacementEnabled: $isPlacementEnabled, selectedModel: $selectedModel, models: models)
            }
            
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    @Binding var modelConfirmedForPlacement: Model?
    
    func makeUIView(context: Context) -> ARView {
        
        let arView = CustomARView(frame: .zero)
        
        return arView
        
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        
        
        if let model = self.modelConfirmedForPlacement {
            print("DEBUG: Adding Model to the scene \(model.modelName)")
            
            
            if let modelEntity = model.modelEntity {
                let anchorEntity = AnchorEntity(plane: .any)
                anchorEntity.addChild(modelEntity.clone(recursive: true))
                uiView.scene.addAnchor(anchorEntity)
            } else {
                print("DEBUG: Unable to load model Entity \(model.modelName)")
            }

            DispatchQueue.main.async {
                self.modelConfirmedForPlacement = nil
            }
        }
    }
    
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif

class CustomARView: ARView {
    
    enum FocusStyleChoices {
      case classic
      case material
      case color
    }

    /// Style to be displayed in the example
    let focusStyle: FocusStyleChoices = .classic
    var focusEntity: FocusEntity?
    required init(frame frameRect: CGRect) {
      super.init(frame: frameRect)
      self.setupConfig()

      switch self.focusStyle {
      case .color:
        self.focusEntity = FocusEntity(on: self, focus: .plane)
      case .material:
        do {
          let onColor: MaterialColorParameter = try .texture(.load(named: "Add"))
          let offColor: MaterialColorParameter = try .texture(.load(named: "Open"))
          self.focusEntity = FocusEntity(
            on: self,
            style: .colored(
              onColor: onColor, offColor: offColor,
              nonTrackingColor: offColor
            )
          )
        } catch {
          self.focusEntity = FocusEntity(on: self, focus: .classic)
          print("Unable to load plane textures")
          print(error.localizedDescription)
        }
      default:
        self.focusEntity = FocusEntity(on: self, focus: .classic)
      }
    }

    func setupConfig() {
      let config = ARWorldTrackingConfiguration()
      config.planeDetection = [.horizontal, .vertical]
      session.run(config, options: [])
    }

    @objc required dynamic init?(coder decoder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }
}

extension CustomARView: FocusEntityDelegate {
    func toTrackingState() {
        print("tracking")
    }
    func toInitializingState() {
        print("Initializing")
    }
}

struct ModelPickerView: View {
    @Binding var isPlacementEnabled: Bool
    @Binding var selectedModel: Model?
    var models: [Model]
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 30) {
                ForEach(0..<self.models.count) { index in
                    Button(action: {
                        print("Printing \(self.models[index].modelName)")
                        self.isPlacementEnabled = true
                        self.selectedModel = self.models[index]
                    }, label: {
                        Image(uiImage: self.models[index].image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80)
                            .cornerRadius(12)
                    })
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(20)
        .background(Color.black.opacity(0.3))
    }
}

struct PlacementButtonView: View {
    @Binding var isPlacementEnabled: Bool
    @Binding var selectedModel: Model?
    @Binding var modelConfirmedForPlacement: Model?
    var body: some View {
        HStack {
            //Cancel Button
            Button(action: {
                print("DEBUG: Cancel model placement")
                resetPlacementState()
            }, label: {
                Image(systemName: "xmark")
                    .frame(width: 60, height: 60)
                    .font(.title)
                    .background(Color.white.opacity(0.7).cornerRadius(30))
                    .padding(20)
            })
            // Place Button
            Button(action: {
                print("DEBUG: Place Model")
                self.modelConfirmedForPlacement = selectedModel
                resetPlacementState()
            }, label: {
                Image(systemName: "checkmark")
                    .frame(width: 60, height: 60)
                    .font(.title)
                    .background(Color.white.opacity(0.7).cornerRadius(30))
                    .padding(20)
            })
        }
    }
    
    func resetPlacementState() {
        self.isPlacementEnabled = false
        self.selectedModel = nil
    }
}
