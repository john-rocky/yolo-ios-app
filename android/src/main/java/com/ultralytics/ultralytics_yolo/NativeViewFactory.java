//package com.ultralytics.ultralytics_yolo;
//
//import android.app.Activity;
//import android.content.Context;
//
//import androidx.annotation.NonNull;
//import androidx.annotation.Nullable;
//
//import com.ultralytics.ultralytics_yolo.camera_preview.TfliteCameraPreview;
//
//import java.util.Map;
//
//import io.flutter.plugin.common.StandardMessageCodec;
//import io.flutter.plugin.platform.PlatformView;
//import io.flutter.plugin.platform.PlatformViewFactory;
//
//class NativeViewFactory extends PlatformViewFactory {
//    private final TfliteCameraPreview tfliteCameraPreview;
//    private final Activity activity;
//
//    NativeViewFactory(@NonNull Activity activity, TfliteCameraPreview tfliteCameraPreview) {
//        super(StandardMessageCodec.INSTANCE);
//
//        this.activity = activity;
//        this.tfliteCameraPreview = tfliteCameraPreview;
//    }
//
//    @NonNull
//    @Override
//    public PlatformView create(@NonNull Context context, int id, @Nullable Object args) {
//        final Map<String, Object> creationParams = (Map<String, Object>) args;
//        return new NativeView(activity, context, creationParams, tfliteCameraPreview);
//    }
//}