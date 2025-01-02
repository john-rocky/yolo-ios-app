package com.ultralytics.ultralytics_yolo.classify;

public class ClassifiedObject {
    public final String label;
    public final float confidence;
    public final int index;

    public ClassifiedObject(String label, int index, float confidence) {
        this.label = label;
        this.index = index;
        this.confidence = confidence;
    }
}
