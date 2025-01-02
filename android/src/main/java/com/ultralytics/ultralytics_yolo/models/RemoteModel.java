package com.ultralytics.ultralytics_yolo.models;

public class RemoteModel extends YoloModel {
    public final String modelUrl;
    public final String labelsUrl;

    public RemoteModel(String modelUrl, String task) {
        super.task = task;
        this.modelUrl = modelUrl;
        labelsUrl = null;
    }

    public RemoteModel(String modelUrl, String labelsUrl, String task) {
        super.task = task;
        this.modelUrl = modelUrl;
        this.labelsUrl = labelsUrl;
    }
}
