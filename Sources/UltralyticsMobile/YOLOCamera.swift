import SwiftUI
import AVFoundation

struct YOLOCamera: View {
    @State private var yoloResult: YOLOResult?
    
    let modelPath: String
    let task: YOLOTask
    let cameraPosition: AVCaptureDevice.Position
    
    var body: some View {
        ZStack {
            YOLOViewRepresentable(
                modelPathOrName: modelPath,
                task: task,
                cameraPosition: cameraPosition
            ) { result in
                self.yoloResult = result
            }
            
            if let boxes = yoloResult?.boxes {
                VStack {
                    Text("Count: \(boxes.count)")
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    Spacer()
                }
                .padding()
            }
        }
    }
}

struct YOLOViewRepresentable: UIViewRepresentable {
    let modelPathOrName: String
    let task: YOLOTask
    let cameraPosition: AVCaptureDevice.Position
    let onDetection: ((YOLOResult) -> Void)?
    
    func makeUIView(context: Context) -> YOLOView {
        let yoloView = YOLOView(
            frame: .zero,
            modelPathOrName: modelPathOrName,
            task: task
        )
        return yoloView
    }
    
    func updateUIView(_ uiView: YOLOView, context: Context) {
        uiView.onDetection = onDetection
    }
}
