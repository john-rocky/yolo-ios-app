package com.ultralytics.ultralytics_yolo.detect;

import static com.ultralytics.ultralytics_yolo.camera_preview.TfliteCameraPreview.CAMERA_PREVIEW_SIZE;

import android.content.Context;
import android.content.res.AssetFileDescriptor;
import android.content.res.AssetManager;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Matrix;
import android.os.Handler;
import android.os.Looper;

import android.util.Log;

import androidx.camera.core.ImageProxy;

import com.ultralytics.ultralytics_yolo.ImageUtils;
import com.ultralytics.ultralytics_yolo.PredictorException;
import com.ultralytics.ultralytics_yolo.models.LocalModel;
import com.ultralytics.ultralytics_yolo.models.YoloModel;

import org.tensorflow.lite.Interpreter;
import org.tensorflow.lite.gpu.CompatibilityList;
import org.tensorflow.lite.gpu.GpuDelegate;

import org.tensorflow.lite.support.metadata.MetadataExtractor;
import org.tensorflow.lite.support.metadata.schema.ModelMetadata;

import org.yaml.snakeyaml.Yaml;

import java.io.ByteArrayOutputStream;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.MappedByteBuffer;
import java.nio.channels.FileChannel;

import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;

public class TfliteDetector extends Detector {

    static {
        System.loadLibrary("ultralytics");
    }


    private static final long FPS_INTERVAL_MS = 1000; // Update FPS every 1 second
    private static final int NUM_BYTES_PER_CHANNEL = 4;

    private final Handler handler = new Handler(Looper.getMainLooper());
    private Matrix transformationMatrix;
    private Bitmap pendingBitmapFrame;

    private int numClasses;
    private int frameCount = 0;
    private double confidenceThreshold = 0.15f;
    private double iouThreshold = 0.45f;
    private int numItemsThreshold = 30;
    private Interpreter interpreter;
    private Object[] inputArray;
    private int outputShape2;
    private int outputShape3;
    private float[][] output;
    private long lastFpsTime = System.currentTimeMillis();
    private Map<Integer, Object> outputMap;

    private ObjectDetectionResultCallback objectDetectionResultCallback;
    private FloatResultCallback inferenceTimeCallback;
    private FloatResultCallback fpsRateCallback;

    public TfliteDetector(Context context) {
        super(context);

    }

    @Override
    public void loadModel(YoloModel yoloModel, boolean useGpu) throws Exception {
        Log.d("TfliteDetector", "start loading");

        if (yoloModel instanceof LocalModel) {
            final LocalModel localModel = (LocalModel) yoloModel;

            if (localModel.modelPath == null || localModel.modelPath.isEmpty()) {
                 Log.d("TfliteDetector", "Model path or metadata path is empty");
                throw new Exception("Model path or metadata path is empty.");
            }

            final AssetManager assetManager = context.getAssets();

            numClasses = labels.size();
            Log.d("TfliteDetector", "label❤️");

            MappedByteBuffer modelFile;
            try {
                modelFile = loadModelFile(assetManager, localModel.modelPath);
                Log.d("TfliteDetector", "model");

            } catch (Exception e) {
                Log.d("TfliteDetector", "Failed to load model file: " + e.getMessage());

                throw new PredictorException("Failed to load model file: " + e.getMessage());
            }

            try {
                MetadataExtractor metadataExtractor = new MetadataExtractor(modelFile);
                ModelMetadata modelMetadata = metadataExtractor.getModelMetadata();
                if (modelMetadata != null) {
                    Log.d("TfliteDetector", "Model metadata retrieved successfully.");
                }

                Set<String> associatedFiles = metadataExtractor.getAssociatedFileNames();
                if (associatedFiles != null && !associatedFiles.isEmpty()) {
                    for (String fileName : associatedFiles) {
                        InputStream inputStream = metadataExtractor.getAssociatedFile(fileName);
                        if (inputStream != null) {
                            ByteArrayOutputStream buffer = new ByteArrayOutputStream();
                            byte[] tmp = new byte[1024];
                            int read;
                            while ((read = inputStream.read(tmp)) != -1) {
                                buffer.write(tmp, 0, read);
                            }
                            byte[] fileContent = buffer.toByteArray();
                            String fileString = new String(fileContent, StandardCharsets.UTF_8);
                            Log.d("TfliteDetector", "Associated file: " + fileName + "\n" + fileString);

                            try {
                                Yaml yaml = new Yaml();
                                Map<String, Object> data = yaml.load(fileString);
                                if (data != null && data.containsKey("names")) {
                                    Map<Integer, String> names = (Map<Integer, String>) data.get("names");
                                    labels.clear();
                                    labels.addAll(names.values());
                                    numClasses = labels.size();
                                    Log.d("TfliteDetector", "Labels loaded from metadata: " + labels);
                                }
                            } catch (Exception parseEx) {
                                Log.e("TfliteDetector", "Failed to parse labels from metadata: " + parseEx.getMessage());
                            }
                        }
                    }
                }
            } catch (IOException e) {
                Log.e("TfliteDetector", "Failed to extract metadata: " + e.getMessage());
            }

            try {
                initDelegate(modelFile, useGpu);
                Log.d("TfliteDetector", "initdelegate");
                int[] inputShape = interpreter.getInputTensor(0).shape(); // [1, height, width, 3]
                int modelInputHeight = inputShape[1];
                int modelInputWidth = inputShape[2];

                this.INPUT_SIZE = modelInputHeight;

                pendingBitmapFrame = Bitmap.createBitmap(INPUT_SIZE, INPUT_SIZE, Bitmap.Config.ARGB_8888);
                transformationMatrix = ImageUtils.getTransformationMatrix(CAMERA_PREVIEW_SIZE.getWidth(), CAMERA_PREVIEW_SIZE.getHeight(),
                INPUT_SIZE, INPUT_SIZE, 90, false);

                Log.d("FlutterApp", "🍰 Model loaded successfully with metadata and dynamic input size 🍰");
            } catch (Exception e) {
                Log.d("FlutterApp", "🍰 Error model: " + e.getMessage());

                throw new PredictorException("Error model: " + e.getMessage());
            }
        }
    }

    @Override
    public float[][] predict(Bitmap bitmap) {
        try {
            Bitmap resizedBitmap = Bitmap.createScaledBitmap(bitmap, INPUT_SIZE, INPUT_SIZE, true);
            setInput(resizedBitmap);
            return runInference();
        } catch (Exception e) {
            return new float[0][];
        }
    }

    @Override
    public void setConfidenceThreshold(float confidence) {
        this.confidenceThreshold = confidence;
    }

    @Override
    public void setIouThreshold(float iou) {
        this.iouThreshold = iou;
    }

    @Override
    public void setNumItemsThreshold(int numItems) {
        this.numItemsThreshold = numItems;
    }

    @Override
    public void setObjectDetectionResultCallback(ObjectDetectionResultCallback callback) {
        objectDetectionResultCallback = callback;
    }

    @Override
    public void setInferenceTimeCallback(FloatResultCallback callback) {
        inferenceTimeCallback = callback;
    }

    @Override
    public void setFpsRateCallback(FloatResultCallback callback) {
        fpsRateCallback = callback;
    }

    private MappedByteBuffer loadModelFile(AssetManager assetManager, String modelPath) throws IOException {

        if (modelPath.startsWith("flutter_assets")) {
            AssetFileDescriptor fileDescriptor = assetManager.openFd(modelPath);
            FileInputStream inputStream = new FileInputStream(fileDescriptor.getFileDescriptor());
            FileChannel fileChannel = inputStream.getChannel();
            long startOffset = fileDescriptor.getStartOffset();
            long declaredLength = fileDescriptor.getDeclaredLength();
            return fileChannel.map(FileChannel.MapMode.READ_ONLY, startOffset, declaredLength);

        } else {
            FileInputStream inputStream = new FileInputStream(modelPath);
            FileChannel fileChannel = inputStream.getChannel();
            long declaredLength = fileChannel.size();
            return fileChannel.map(FileChannel.MapMode.READ_ONLY, 0, declaredLength);
        }
    }

    private void initDelegate(MappedByteBuffer buffer, boolean useGpu) {
        Interpreter.Options interpreterOptions = new Interpreter.Options();
        try {
            CompatibilityList compatibilityList = new CompatibilityList();
            if (compatibilityList.isDelegateSupportedOnThisDevice()) {
                GpuDelegate.Options delegateOptions = compatibilityList.getBestOptionsForThisDevice();
                GpuDelegate gpuDelegate = new GpuDelegate(delegateOptions.setQuantizedModelsAllowed(true));
                interpreterOptions.addDelegate(gpuDelegate);
                Log.d("FlutterApp", "🐶 GPU delegate used 🐶");
            } else {
                interpreterOptions.setNumThreads(4);
                Log.d("FlutterApp", "🐍 CPU fallback 🐍");
            }

            Log.d("FlutterApp", "Is this device supported: " + compatibilityList.isDelegateSupportedOnThisDevice());
            Log.d("FlutterApp", "Device compatibility info: " + compatibilityList);

            this.interpreter = new Interpreter(buffer, interpreterOptions);
        } catch (Exception e) {
            interpreterOptions = new Interpreter.Options();
            interpreterOptions.setNumThreads(4);
            this.interpreter = new Interpreter(buffer, interpreterOptions);
        }

        int[] outputShape = interpreter.getOutputTensor(0).shape();
        outputShape2 = outputShape[1];
        outputShape3 = outputShape[2];
        output = new float[outputShape2][outputShape3];
    }

    public void predict(ImageProxy imageProxy, boolean isMirrored) {

        if (interpreter == null || imageProxy == null) {
            return;
        }

        Bitmap bitmap = ImageUtils.toBitmap(imageProxy);
        Canvas canvas = new Canvas(pendingBitmapFrame);
        Matrix cropToFrameTransform = new Matrix();
        transformationMatrix.invert(cropToFrameTransform);
        canvas.drawBitmap(bitmap, transformationMatrix, null);

        handler.post(() -> {
            setInput(pendingBitmapFrame);

            long start = System.currentTimeMillis();
            float[][] result = runInference();
            long end = System.currentTimeMillis();

            // Increment frame count
            frameCount++;

            // Check if it's time to update FPS
            long elapsedMillis = end - lastFpsTime;
            if (elapsedMillis > FPS_INTERVAL_MS) {
                float fps = (float) frameCount / elapsedMillis * 1000.f;
                lastFpsTime = end;
                frameCount = 0;
                if (fpsRateCallback != null) {
                    fpsRateCallback.onResult(fps);
                }
            }

            if (objectDetectionResultCallback != null) {
                objectDetectionResultCallback.onResult(result);
            }
            if (inferenceTimeCallback != null) {
                inferenceTimeCallback.onResult(end - start);
            }
        });
    }

    private void setInput(Bitmap resizedbitmap) {
        ByteBuffer imgData = ByteBuffer.allocateDirect(1 * INPUT_SIZE * INPUT_SIZE * 3 * NUM_BYTES_PER_CHANNEL);
        int[] intValues = new int[INPUT_SIZE * INPUT_SIZE];

        resizedbitmap.getPixels(intValues, 0, resizedbitmap.getWidth(), 0, 0, resizedbitmap.getWidth(), resizedbitmap.getHeight());

        imgData.order(ByteOrder.nativeOrder());
        imgData.rewind();
        for (int i = 0; i < INPUT_SIZE; ++i) {
            for (int j = 0; j < INPUT_SIZE; ++j) {
                int pixelValue = intValues[i * INPUT_SIZE + j];
                float r = (((pixelValue >> 16) & 0xFF)) / 255.0f;
                float g = (((pixelValue >> 8) & 0xFF)) / 255.0f;
                float b = ((pixelValue & 0xFF)) / 255.0f;
                imgData.putFloat(r);
                imgData.putFloat(g);
                imgData.putFloat(b);
            }
        }
        this.inputArray = new Object[]{imgData};
        this.outputMap = new HashMap<>();
        ByteBuffer outData = ByteBuffer.allocateDirect(outputShape2 * outputShape3 * NUM_BYTES_PER_CHANNEL);
        outData.order(ByteOrder.nativeOrder());
        outData.rewind();
        outputMap.put(0, outData);
    }

    private float[][] runInference() {
        if (interpreter != null) {
            interpreter.runForMultipleInputsOutputs(inputArray, outputMap);

            ByteBuffer byteBuffer = (ByteBuffer) outputMap.get(0);
            if (byteBuffer != null) {
                byteBuffer.rewind();

                for (int j = 0; j < outputShape2; ++j) {
                    for (int k = 0; k < outputShape3; ++k) {
                        output[j][k] = byteBuffer.getFloat();
                    }
                }
                Log.d("MYTAG", "x=" + output[0][0] + " y=" + output[1][0] + " w=" + output[2][0] + " h=" + output[3][0]);
                // クラススコア(例: num_classes=6 なら 4..9がスコア)
                for (int c = 4; c < 4 + numClasses; c++) {
                    Log.d("MYTAG", "class" + (c-4) + " score=" + output[c][0]);
                }
                return postprocess(output, outputShape3, outputShape2, (float) confidenceThreshold,
                        (float) iouThreshold, numItemsThreshold, numClasses);
            }
        }
        return new float[0][];
    }

    private native float[][] postprocess(float[][] recognitions, int w, int h,
                                         float confidenceThreshold, float iouThreshold,
                                         int numItemsThreshold, int numClasses);
}
