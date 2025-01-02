import Foundation
import CoreGraphics
import UIKit

public struct YOLOResult {
    let orig_shape: CGSize
    let boxes: [Box]
    var annotatedImage: UIImage?
//    let masks: [CGImage]
//    let keypoints: [Keypoint]
}

public struct Box {
    let index: Int
    let cls: String
    let conf: Float
    let xywh: CGRect
    let xywhn: CGRect
    
}

public struct Keypoint {
    let position: CGPoint
    let confidence: Float
}
