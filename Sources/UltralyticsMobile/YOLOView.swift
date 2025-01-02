import UIKit
import Vision
import AVFoundation

public class YOLOView: UIView{
    
    public var onDetection: ((YOLOResult) -> Void)?
    private let videoCapture: VideoCapture
    private var busy = false
    private var currentBuffer: CVPixelBuffer?
    var framesDone = 0
    var t0 = 0.0  // inference start
    var t1 = 0.0  // inference dt
    var t2 = 0.0  // inference dt smoothed
    var t3 = CACurrentMediaTime()  // FPS start
    var t4 = 0.0  // FPS dt smoothed
    var task = YOLOTask.detect
    var predictor: Predictor!
    var colors: [String: UIColor] = [:]
    var classes: [String] = []
    let maxBoundingBoxViews = 100
    var boundingBoxViews = [BoundingBoxView]()
    
    public init(
        frame: CGRect,
        modelPathOrName: String,
        task: YOLOTask) {
            
            switch task {
            case .detect:
                predictor = ObjectDetector(modelPathOrName: modelPathOrName)
            }
            self.videoCapture = VideoCapture()
            super.init(frame: frame)
            self.setUpBoundingBoxViews()
            self.videoCapture.delegate = self
            start(position: .back)
        }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func start(position: AVCaptureDevice.Position){
        if !busy {
            busy = true
            
            videoCapture.setUp(sessionPreset: .photo, position: position) { success in
                // .hd4K3840x2160 or .photo (4032x3024)  Warning: 4k may not work on all devices i.e. 2019 iPod
                if success {
                    // Add the video preview into the UI.
                    if let previewLayer = self.videoCapture.previewLayer {
                        self.layer.addSublayer(previewLayer)
                        self.videoCapture.previewLayer?.frame = self.bounds  // resize preview layer
                        for box in self.boundingBoxViews {
                            box.addToLayer(previewLayer)
                        }
                    }
                    // Once everything is set up, we can start capturing live video.
                    self.videoCapture.start()
                    
                    self.busy = false
                }
            }
        }
    }
    
    public func stop(){
        videoCapture.stop()
    }
    
    public func resume(){
        videoCapture.start()
    }
    
    private func predictOnFrame(sampleBuffer: CMSampleBuffer) {
        if currentBuffer == nil, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            currentBuffer = pixelBuffer
            
            /// - Tag: MappingOrientation
            // The frame is always oriented based on the camera sensor,
            // so in most cases Vision needs to rotate it for the model to work as expected.
            let imageOrientation: CGImagePropertyOrientation
            switch UIDevice.current.orientation {
            case .portrait:
                imageOrientation = .up
            case .portraitUpsideDown:
                imageOrientation = .down
            case .landscapeLeft:
                imageOrientation = .left
            case .landscapeRight:
                imageOrientation = .right
            case .unknown:
                print("The device orientation is unknown, the predictions may be affected")
                fallthrough
            default:
                imageOrientation = .up
            }
            
            self.predictor.predict(sampleBuffer: sampleBuffer, orientation: imageOrientation,onResultsListener: self, onInferenceTime: self, onFpsRate: self)
            self.currentBuffer = nil
            
        }
    }
    
    func setUpBoundingBoxViews() {
        // Ensure all bounding box views are initialized up to the maximum allowed.
        while boundingBoxViews.count < maxBoundingBoxViews {
            boundingBoxViews.append(BoundingBoxView())
        }
        
        // Retrieve class labels directly from the CoreML model's class labels, if available.
        if task == .detect {
            classes = predictor.labels
            // Assign random colors to the classes.
            var count = 0
            for label in classes {
                let color = ultralyticsColors[count]
                count += 1
                if count > 19 {
                    count = 0
                }
                if colors[label] == nil {  // if key not in dict
                    colors[label] = color
                }
            }
        }
    }
    
    func showBoxes(predictions: [[String : Any]]) {
        let width = self.bounds.width
        let height = self.bounds.height
        var str = ""
        
        var ratio: CGFloat = 1.0
        
        if videoCapture.captureSession.sessionPreset == .photo {
            ratio = (height / width) / (4.0 / 3.0)
        } else {
            ratio = (height / width) / (16.0 / 9.0)
        }
        
        let date = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        let seconds = calendar.component(.second, from: date)
        let nanoseconds = calendar.component(.nanosecond, from: date)
        let sec_day =
        Double(hour) * 3600.0 + Double(minutes) * 60.0 + Double(seconds) + Double(nanoseconds) / 1E9
        
        var resultCount = 0
        
        switch task {
        case .detect:
            resultCount = predictions.count
        }
        //        self.labelSlider.text = String(resultCount) + " items (max " + String(Int(slider.value)) + ")"
        for i in 0..<boundingBoxViews.count {
            if i < (resultCount) && i < 50 {
                var rect = CGRect.zero
                var label = ""
                var boxColor: UIColor = .white
                var confidence: CGFloat = 0
                var alpha: CGFloat = 0.9
                var innerTexts = ""
                var bestClass = ""
                switch task {
                case .detect:
                    let prediction = predictions[i]
                    rect = prediction["box"] as! CGRect
                    bestClass = prediction["label"] as! String
                    confidence = CGFloat(prediction["confidence"] as! VNConfidence)
                    label = String(format: "%@ %.1f", bestClass, confidence * 100)
                    boxColor = colors[bestClass] ?? UIColor.white
                    alpha = CGFloat((confidence - 0.2) / (1.0 - 0.2) * 0.9)
                }
                var displayRect = rect
                switch UIDevice.current.orientation {
                case .portraitUpsideDown:
                    displayRect = CGRect(
                        x: 1.0 - rect.origin.x - rect.width,
                        y: 1.0 - rect.origin.y - rect.height,
                        width: rect.width,
                        height: rect.height)
                case .landscapeLeft:
                    displayRect = CGRect(
                        x: rect.origin.x,
                        y: rect.origin.y,
                        width: rect.width,
                        height: rect.height)
                case .landscapeRight:
                    displayRect = CGRect(
                        x: rect.origin.x,
                        y: rect.origin.y,
                        width: rect.width,
                        height: rect.height)
                case .unknown:
                    print("The device orientation is unknown, the predictions may be affected")
                    fallthrough
                default: break
                }
                if ratio >= 1 {
                    let offset = (1 - ratio) * (0.5 - displayRect.minX)
                    if task == .detect {
                        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: offset, y: -1)
                        displayRect = displayRect.applying(transform)
                    } else {
                        let transform = CGAffineTransform(translationX: offset, y: 0)
                        displayRect = displayRect.applying(transform)
                    }
                    displayRect.size.width *= ratio
                } else {
                    if task == .detect {
                        let offset = (ratio - 1) * (0.5 - displayRect.maxY)
                        
                        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: offset - 1)
                        displayRect = displayRect.applying(transform)
                    } else {
                        let offset = (ratio - 1) * (0.5 - displayRect.minY)
                        let transform = CGAffineTransform(translationX: 0, y: offset)
                        displayRect = displayRect.applying(transform)
                    }
                    ratio = (height / width) / (3.0 / 4.0)
                    displayRect.size.height /= ratio
                }
                displayRect = VNImageRectForNormalizedRect(displayRect, Int(width), Int(height))
                
                boundingBoxViews[i].show(
                    frame: displayRect, label: label, color: boxColor, alpha: alpha)
                
            } else {
                boundingBoxViews[i].hide()
            }
        }
        
    }
}

extension YOLOView: VideoCaptureDelegate, ResultsListener, InferenceTimeListener, FpsRateListener {
    
    nonisolated func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame: CMSampleBuffer) {
        DispatchQueue.main.async {
            self.predictOnFrame(sampleBuffer: didCaptureVideoFrame)
        }
    }
    
    func on(predictions: [[String : Any]]) {
        showBoxes(predictions: predictions)
        var boxes: [Box] = []
        for prediction in predictions {
            let rect = prediction["box"] as! CGRect
            let bestClass = prediction["label"] as! String
            let confidence = CGFloat(prediction["confidence"] as! VNConfidence)
            let index = self.predictor.labels.firstIndex(of: bestClass) ?? 0
            let invertBox = CGRect(x: rect.minX, y: 1-rect.maxY, width: rect.width, height: rect.height)
            let imageBox = VNImageRectForNormalizedRect(invertBox, Int(1280), Int(720))
            let box = Box(index: index, cls: bestClass, conf: Float(confidence), xywh: imageBox, xywhn: invertBox)
            boxes.append(box)
        }
        let result = YOLOResult(orig_shape: CGSize(width: 1280, height: 720), boxes: boxes)
        onDetection?(result)
    }
    
    func on(inferenceTime: Double) {
        
    }
    
    func on(fpsRate: Double) {
        
    }
    
}
