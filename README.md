# 🔥 Ultralytics-Mobile

**Ultralytics-Mobile** is a lightweight, multi-platform library — supporting **Swift**, **Kotlin**, **Java**, and **Dart** — designed to make using **YOLO11** and other YOLO-based models on mobile devices seamless and intuitive. This library supports **object detection**, **segmentation**, **classification**, **pose estimation**, **oriented bounding box detection**, and more — all in real-time or on single images. Compatible with **iOS**, **Android**, and **Flutter**.

---

## 🚀 Features

- **Comprehensive Model Support**: Leverage YOLO11 and other YOLO-based models for:
  - Object Detection
  - Image Segmentation (Todo)
  - Classification (Todo)
  - Pose Estimation (Todo)
  - Oriented Bounding Box Detection (Todo)
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

let model = YOLO("yolo11n", task: .detect)
let result = model(someUIImage)
```

#### Android (Kotlin)
```kotlin
import ultralytics_mobile.YOLO
import ultralytics_mobile.Task

val model = YOLO("yolo11n", task = Task.DETECT)
val result = model(someBitmap)
```

#### Flutter (Dart)
```dart
import 'package:ultralytics_mobile/ultralytics_mobile.dart';

final model = YOLO("yolo11n", task: Task.detect);
final result = model(someImage);
```

---

### Real-Time Camera Inference

#### iOS (UIKit)
```swift
import ultralytics_mobile

let yoloView = YOLOView("yolo11n", task: .detect)
view.addSubview(yoloView)
```

#### iOS (SwiftUI)
```swift
import ultralytics_mobile

struct ContentView: View {
    var body: some View {
        YOLOCamera(
                   modelPath: "yolo11n",
                   task: .detect,
                   cameraPosition: .back
               )
    }
}
```

#### Android (Jetpack Compose)
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
