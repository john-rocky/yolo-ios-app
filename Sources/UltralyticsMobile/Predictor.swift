import Vision
import CoreImage

@MainActor
protocol ResultsListener {
    func on(predictions: [[String:Any]])
}

@MainActor
protocol InferenceTimeListener {
    func on(inferenceTime: Double)
}

@MainActor
protocol FpsRateListener {
    func on(fpsRate: Double)
}

protocol Predictor{
    func predict(sampleBuffer: CMSampleBuffer, orientation:CGImagePropertyOrientation, onResultsListener: ResultsListener?, onInferenceTime: InferenceTimeListener?, onFpsRate: FpsRateListener?)
    func predictOnImage(image: CIImage) -> YOLOResult
    var labels: [String] { get set }
}

enum PredictorError: Error{
    case invalidTask
    case noLabelsFound
    case invalidUrl
    case modelFileNotFound
}
