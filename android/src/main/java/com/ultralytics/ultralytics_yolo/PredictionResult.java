package com.ultralytics.ultralytics_yolo;

public abstract class PredictionResult {
    public final double inferenceTime;
    public final double fpsRate;
    protected PredictionResult(double inferenceTime, double fpsRate) {
        this.inferenceTime = inferenceTime;
        this.fpsRate = fpsRate;
    }
}
