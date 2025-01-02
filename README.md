# 🔥 ultralytics-mobile

**ultralytics-mobile** is a lightweight, multi-platform library — supporting **Swift**, **Kotlin**, **Java**, and **Dart** — designed to make using **YOLO11** and other YOLO-based models on mobile devices seamless and intuitive. This library supports **object detection**, **segmentation**, **classification**, **pose estimation**, **oriented bounding box detection**, and more — all in real-time or on single images. Compatible with **iOS**, **Android**, and **Flutter**.

---

## 🚀 Features

- **Comprehensive Model Support**: Leverage YOLO11 and other YOLO-based models for:
  - Object Detection
  - Image Segmentation
  - Classification
  - Pose Estimation
  - Oriented Bounding Box Detection
- **Simple API**: Perform complex tasks with just a few lines of code.
- **Real-Time Capabilities**: Effortlessly set up a real-time camera-based inference view.
- **Multi-Platform Support**  
  - **iOS**: Swift + UIKit / SwiftUI  
  - **Android**: Kotlin + Jetpack / Java + XML  
  - **Flutter**: Dart
- **Flexible Outputs**: Bounding boxes, masks, confidence scores, class probabilities, poses, oriented boxes, and annotated images.
- **Preloaded Models**: Access lightweight YOLO variants (e.g., `yolo11n`).

---

## 📦 Installation

### iOS (Swift Package Manager)

Add the package to your `Package.swift` file:
```swift
dependencies: [
    .package(url: "https://github.com/ultralytics/ultralytics-mobile.git", from: "1.0.0")
]
```

### Android (Gradle via JitPack)

1. Add JitPack to your `repositories` in your root `build.gradle`:
```gradle
allprojects {
    repositories {
        maven { url 'https://jitpack.io' }
    }
}
```

2. Add the dependency to your module-level `build.gradle`:
```gradle
dependencies {
    implementation 'com.github.ultralytics:ultralytics-mobile:1.0.0'
}
```

### Flutter (pub.dev)

Add this dependency to your `pubspec.yaml`:
```yaml
dependencies:
  ultralytics_mobile: ^1.0.0
```
Then run:
```bash
flutter pub get
```

---

## 🛠️ Usage

### Single Image Inference

#### iOS (Swift)
```swift
import ultralytics_mobile

// Object detection example
let model = YOLO("yolo11n", task: .detect)
let detectionResult = model(someUIImage)
print(detectionResult.box)
print(detectionResult.conf)

// Segmentation example
let segModel = YOLO("yolo11n", task: .segment)
let segmentationResult = segModel(someUIImage)
print(segmentationResult.mask)

// Classification example
let clsModel = YOLO("yolo11n", task: .classify)
let classificationResult = clsModel(someUIImage)
print(classificationResult.conf)
print(classificationResult.classLabel)

// Pose estimation example
let poseModel = YOLO("yolo11n", task: .pose)
let poseResult = poseModel(someUIImage)
print(poseResult.keypoints)

// Oriented bounding box detection example
let obbModel = YOLO("yolo11n", task: .obb)
let obbResult = obbModel(someUIImage)
print(obbResult.orientedBox)
```

#### Android (Kotlin)
```kotlin
import ultralytics_mobile.YOLO
import ultralytics_mobile.Task

// Object detection example
val model = YOLO("yolo11n", task = Task.DETECT)
val detectionResult = model(someBitmap)
println(detectionResult.box)
println(detectionResult.conf)

// Segmentation example
val segModel = YOLO("yolo11n", task = Task.SEGMENT)
val segmentationResult = segModel(someBitmap)
println(segmentationResult.mask)

// Classification example
val clsModel = YOLO("yolo11n", task = Task.CLASSIFY)
val classificationResult = clsModel(someBitmap)
println(classificationResult.conf)
println(classificationResult.classLabel)

// Pose estimation example
val poseModel = YOLO("yolo11n", task = Task.POSE)
val poseResult = poseModel(someBitmap)
println(poseResult.keypoints)

// Oriented bounding box detection example
val obbModel = YOLO("yolo11n", task = Task.OBB)
val obbResult = obbModel(someBitmap)
println(obbResult.orientedBox)
```

#### Android (Java)
```java
// Example Java usage for object detection
YOLO model = new YOLO("yolo11n", Task.DETECT);
Result detectionResult = model.invoke(someBitmap);
System.out.println(detectionResult.getBox());
System.out.println(detectionResult.getConf());
```

#### Flutter (Dart)
```dart
import 'package:ultralytics_mobile/ultralytics_mobile.dart';

// Object detection example
final model = YOLO("yolo11n", task: Task.detect);
final detectionResult = model(someImage);
print(detectionResult.box);
print(detectionResult.conf);

// Segmentation example
final segModel = YOLO("yolo11n", task: Task.segment);
final segmentationResult = segModel(someImage);
print(segmentationResult.mask);

// Classification example
final clsModel = YOLO("yolo11n", task: Task.classify);
final classificationResult = clsModel(someImage);
print(classificationResult.conf);
print(classificationResult.classLabel);

// Pose estimation example
final poseModel = YOLO("yolo11n", task: Task.pose);
final poseResult = poseModel(someImage);
print(poseResult.keypoints);

// Oriented bounding box detection example
final obbModel = YOLO("yolo11n", task: Task.obb);
final obbResult = obbModel(someImage);
print(obbResult.orientedBox);
```

---

### Real-Time Camera Inference

#### iOS (Swift)
```swift
import ultralytics_mobile

// e.g. Real-time object detection
let yoloView = YOLOView("yolo11n", task: .detect)
view.addSubview(yoloView)
```

#### Android (Kotlin)
```kotlin
import ultralytics_mobile.YOLOView
import ultralytics_mobile.Task

val yoloView = YOLOView("yolo11n", task = Task.DETECT)
addContentView(yoloView, ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT)
```

#### Flutter (Dart)
```dart
import 'package:ultralytics_mobile/ultralytics_mobile.dart';

final yoloView = YOLOView("yolo11n", task: Task.detect);
addWidget(yoloView); // Replace with your preferred layout method
```

---

## 📤 Output Format

Depending on the **task**:

- **Object Detection (`.detect`)**  
  - `box`: Bounding box coordinates  
  - `conf`: Confidence score  

- **Segmentation (`.segment`)**  
  - `mask`: Segmentation mask  
  - `conf`: Confidence score  

- **Classification (`.classify`)**  
  - `classLabel`: Predicted class label  
  - `conf`: Confidence score  

- **Pose Estimation (`.pose`)**  
  - `keypoints`: Detected pose keypoints  
  - `conf`: Confidence score  

- **Oriented Bounding Box Detection (`.obb`)**  
  - `orientedBox`: Coordinates or vertices of oriented bounding boxes  
  - `conf`: Confidence score  

- **`annotatedimage`** (optional)  
  - Visual representation of the results drawn on the image

---

## 🧪 Sample Apps

We provide fully functional sample apps for each platform to help you get started:

1. **Single Image Inference**:
   - iOS: Swift (UIKit, SwiftUI)
   - Android: Kotlin (Jetpack), Java (XML)
   - Flutter: Dart

2. **Real-Time Inference** (e.g., object detection, segmentation, etc.):
   - Includes real-time YOLO inference samples for all platforms.

👉 [Explore the Samples](https://github.com/ultralytics/ultralytics-mobile/samples)

---

## 📖 Documentation

For detailed API references and advanced usage guides, check out our [Wiki](https://github.com/ultralytics/ultralytics-mobile/wiki).

---

## 💡 Contributing

We welcome contributions to **ultralytics-mobile**! Here's how you can help:
1. Report bugs or suggest features via [Issues](https://github.com/ultralytics/ultralytics-mobile/issues).
2. Submit pull requests to enhance functionality or fix bugs.
3. Spread the word and star this repo ⭐!

---

## 📜 License

This project is licensed under the **MIT License**. See the [LICENSE](https://github.com/ultralytics/ultralytics-mobile/blob/main/LICENSE) file for details.

---

## 📬 Contact

For questions or support, feel free to [open an issue](https://github.com/ultralytics/ultralytics-mobile/issues) or reach out to our team at **support@ultralytics.com**.

---

### Made with ❤️ by [Ultralytics](https://ultralytics.com)
