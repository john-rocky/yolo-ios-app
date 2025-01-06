import UIKit
import Vision
import AVFoundation

public class YOLOView: UIView, VideoCaptureDelegate{
    
    
    func onPredict(result: YOLOResult) {
//        let predictions = result.boxes
        showBoxes(predictions: result)
//        var boxes: [Box] = []
//        for prediction in predictions {
//            let rect = prediction["box"] as! CGRect
//            let bestClass = prediction["label"] as! String
//            let confidence = CGFloat(prediction["confidence"] as! VNConfidence)
//            let index = self.predictor.labels.firstIndex(of: bestClass) ?? 0
//            let invertBox = CGRect(x: rect.minX, y: 1-rect.maxY, width: rect.width, height: rect.height)
//            let imageBox = VNImageRectForNormalizedRect(invertBox, Int(1280), Int(720))
//            let box = Box(index: index, cls: bestClass, conf: Float(confidence), xywh: imageBox, xywhn: invertBox)
//            boxes.append(box)
//        }
        let speed = result.speed
        var fps: Double = 0
        if let fpsResult = result.fps {
            fps = fpsResult
        }
        DispatchQueue.main.async {
            self.labelFPS.text = String(format: "%.1f FPS - %.1f ms", fps, speed)  // t2 seconds to ms
        }
//        let result = YOLOResult(orig_shape: CGSize(width: 1280, height: 720), boxes: boxes, speed: <#Double#>)
        onDetection?(result)
    }
    
    var onDetection: ((YOLOResult) -> Void)?
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
    public var slider: UISlider!
    public var labelSlider: UILabel!
    public var sliderConf: UISlider!
    public var labelSliderConf: UILabel!
    public var sliderIoU: UISlider!
    public var labelSliderIoU: UILabel!
    public var labelName: UILabel!
    public var labelFPS: UILabel!
    public var labelZoom: UILabel!
    public var activityIndicator: UIActivityIndicatorView!
    public var toolBar: UIToolbar!
    public var playButton: UIBarButtonItem!
    public var pauseButton: UIBarButtonItem!
    public var switchCameraButton: UIBarButtonItem!
    
    private let minimumZoom: CGFloat = 1.0
    private let maximumZoom: CGFloat = 10.0
    private var lastZoomFactor: CGFloat = 1.0
    
    public init(
        frame: CGRect,
        modelPathOrName: String,
        task: YOLOTask) {
            
            switch task {
            case .detect:
                predictor = ObjectDetector(modelPathOrName: modelPathOrName)
            }
            self.videoCapture = VideoCapture()
            videoCapture.predictor = predictor
            super.init(frame: frame)
            self.setUpBoundingBoxViews()
            self.setupUI()
            self.videoCapture.delegate = self
            start(position: .back)
                        
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(orientationDidChange),
                name: UIDevice.orientationDidChangeNotification,
                object: nil
            )
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
                        self.layer.insertSublayer(previewLayer, at: 0)
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
    
    func showBoxes(predictions: YOLOResult) {
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
            resultCount = predictions.boxes.count
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
                    let prediction = predictions.boxes[i]
                    rect = prediction.xywhn
                    bestClass = prediction.cls
                    confidence = CGFloat(prediction.conf)
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
                        let transform = CGAffineTransform(scaleX: 1, y: 1).translatedBy(x: offset, y: 1)
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
    
    private func setupUI() {
        labelName = UILabel()
        labelName.text = "Label"
        labelName.textAlignment = .center
        labelName.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        labelName.textColor = .black
        self.addSubview(labelName)
        
        labelFPS = UILabel()
        labelFPS.text = "Label"
        labelFPS.textAlignment = .center
        labelFPS.textColor = .black
        self.addSubview(labelFPS)
        
        labelSlider = UILabel()
        labelSlider.text = "Label"
        labelSlider.textAlignment = .left
        labelSlider.textColor = .black
        self.addSubview(labelSlider)
        
        slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 100
        slider.value = 30
        slider.minimumTrackTintColor = .darkGray
        slider.maximumTrackTintColor = .lightGray.withAlphaComponent(0.5)
        slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        self.addSubview(slider)
        
        labelSliderConf = UILabel()
        labelSliderConf.text = "Label"
        labelSliderConf.textAlignment = .left
        labelSliderConf.textColor = .black
        self.addSubview(labelSliderConf)
        
        sliderConf = UISlider()
        sliderConf.minimumValue = 0
        sliderConf.maximumValue = 1
        sliderConf.value = 0.25
        sliderConf.minimumTrackTintColor = .darkGray
        sliderConf.maximumTrackTintColor = .lightGray.withAlphaComponent(0.5)
        sliderConf.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        self.addSubview(sliderConf)
        
        labelSliderIoU = UILabel()
        labelSliderIoU.text = "Label"
        labelSliderIoU.textAlignment = .left
        labelSliderIoU.textColor = .black
        self.addSubview(labelSliderIoU)

        sliderIoU = UISlider()
        sliderIoU.minimumValue = 0
        sliderIoU.maximumValue = 1
        sliderIoU.value = 0.45
        sliderIoU.minimumTrackTintColor = .darkGray
        sliderIoU.maximumTrackTintColor = .lightGray.withAlphaComponent(0.5)
        sliderIoU.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        self.addSubview(sliderIoU)
        
        labelZoom = UILabel()
        labelZoom.text = "1.00x"
        labelZoom.textColor = .black
        labelZoom.font = UIFont.systemFont(ofSize: 14)
        labelZoom.textAlignment = .center
        self.addSubview(labelZoom)
        
        self.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(pinch)))
    }
    
    public override func layoutSubviews() {
        
        
        let width = bounds.width
        let height = bounds.height
        
        let topMargin: CGFloat = height * 0.06
        
        let titleLabelHeight: CGFloat = height * 0.06
        labelName.frame = CGRect(
            x: 0,
            y: topMargin,
            width: width,
            height: titleLabelHeight
        )
        
        let subLabelHeight: CGFloat = height * 0.04
        labelFPS.frame = CGRect(
            x: 0,
            y: labelName.frame.maxY + 4,
            width: width,
            height: subLabelHeight
        )
        
        let sliderWidth: CGFloat = width * 0.45
        let sliderHeight: CGFloat = height * 0.05
        
        labelSlider.frame = CGRect(
            x: width * 0.05,
            y: labelName.frame.maxY + 10,
            width: sliderWidth,
            height: sliderHeight
        )

        slider.frame = CGRect(
            x: width * 0.05,
            y: labelSlider.frame.maxY + 10,
            width: sliderWidth,
            height: sliderHeight
        )
        
        labelSliderConf.frame = CGRect(
            x: width * 0.05,
            y: slider.frame.maxY + 10,
            width: sliderWidth,
            height: sliderHeight
        )
        
        sliderConf.frame = CGRect(
            x: width * 0.05,
            y: labelSliderConf.frame.maxY + 10,
            width: sliderWidth,
            height: sliderHeight
        )
        
        labelSliderIoU.frame = CGRect(
            x: width * 0.05,
            y: sliderConf.frame.maxY + 10,
            width: sliderWidth,
            height: sliderHeight
        )
        
        sliderIoU.frame = CGRect(
            x: width * 0.05,
            y: labelSliderIoU.frame.maxY + 10,
            width: sliderWidth,
            height: sliderHeight
        )
        
        
        let zoomLabelWidth: CGFloat = width * 0.2
        labelZoom.frame = CGRect(
            x: center.x - zoomLabelWidth / 2,
            y: self.bounds.maxY - 40,
            width: zoomLabelWidth,
            height: height * 0.03
        )
    }
    
    private func setUpOrientationChangeNotification() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(orientationDidChange),
            name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    @objc func orientationDidChange() {
        var orientation: AVCaptureVideoOrientation = .portrait
        switch UIDevice.current.orientation {
        case .portrait:
            orientation = .portrait
        case .portraitUpsideDown:
            orientation = .portraitUpsideDown
        case .landscapeRight:
            orientation = .landscapeLeft
        case .landscapeLeft:
            orientation = .landscapeRight
        default:
          return
        }
        videoCapture.updateVideoOrientation(orientation:orientation)
        //      frameSizeCaptured = false
    }
    
    @objc func sliderChanged(_ sender: Any) {
        
        if let sender = sliderConf {
            if let detector = videoCapture.predictor as? ObjectDetector {
                detector.setNumItemsThreshold(numItems: Int(sender.value))
            }
        }
        let conf = Double(round(100 * sliderConf.value)) / 100
        let iou = Double(round(100 * sliderIoU.value)) / 100
        self.labelSliderConf.text = String(conf) + " Confidence Threshold"
        self.labelSliderIoU.text = String(iou) + " IoU Threshold"
        if let detector = videoCapture.predictor as? ObjectDetector {
            detector.setIouThreshold(iou: iou)
            detector.setConfidenceThreshold(confidence: conf)
            
        }
    }
    
    @objc func pinch(_ pinch: UIPinchGestureRecognizer) {
        guard let device = videoCapture.captureDevice else { return }

      // Return zoom value between the minimum and maximum zoom values
      func minMaxZoom(_ factor: CGFloat) -> CGFloat {
        return min(min(max(factor, minimumZoom), maximumZoom), device.activeFormat.videoMaxZoomFactor)
      }

      func update(scale factor: CGFloat) {
        do {
          try device.lockForConfiguration()
          defer {
            device.unlockForConfiguration()
          }
          device.videoZoomFactor = factor
        } catch {
          print("\(error.localizedDescription)")
        }
      }

      let newScaleFactor = minMaxZoom(pinch.scale * lastZoomFactor)
      switch pinch.state {
      case .began, .changed:
        update(scale: newScaleFactor)
        self.labelZoom.text = String(format: "%.2fx", newScaleFactor)
        self.labelZoom.font = UIFont.preferredFont(forTextStyle: .title2)
      case .ended:
        lastZoomFactor = minMaxZoom(newScaleFactor)
        update(scale: lastZoomFactor)
        self.labelZoom.font = UIFont.preferredFont(forTextStyle: .body)
      default: break
      }
    }  // Pin
}


