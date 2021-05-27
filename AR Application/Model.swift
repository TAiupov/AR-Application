//
//  Model.swift
//  AR Application
//
//  Created by Тагир Аюпов on 2021-05-26.
//

import UIKit
import RealityKit
import Combine

class Model {
    var modelName: String
    var image: UIImage
    var modelEntity: ModelEntity?
    
    private var cancellable: AnyCancellable? = nil
    
    init(modelName: String) {
        self.modelName = modelName
        self.image = UIImage(named: modelName)!
        let fileName = modelName + ".usdz"
        self.cancellable = ModelEntity.loadModelAsync(named: fileName).sink(receiveCompletion: { MTLAutoreleasedComputePipelineReflection in
            print("DEBUG: Unable to load modelEntity")
        }, receiveValue: { modelEntity in
            self.modelEntity = modelEntity
        })
    }
    
}
