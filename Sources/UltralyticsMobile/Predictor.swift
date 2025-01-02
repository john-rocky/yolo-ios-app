import Vision
import CoreImage

@MainActor
public protocol ResultsListener {
    func on(predictions: [[String:Any]])
}

@MainActor
public protocol InferenceTimeListener {
    func on(inferenceTime: Double)
}

@MainActor
public protocol FpsRateListener {
    func on(fpsRate: Double)
}

public protocol Predictor{
    func predict(sampleBuffer: CMSampleBuffer, onResultsListener: ResultsListener?, onInferenceTime: InferenceTimeListener?, onFpsRate: FpsRateListener?)
    func predictOnImage(image: CIImage) -> YOLOResult
    var labels: [String] { get set }
}

public enum PredictorError: Error{
    case invalidTask
    case noLabelsFound
    case invalidUrl
    case modelFileNotFound
}
