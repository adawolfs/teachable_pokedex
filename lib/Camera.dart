import 'dart:async';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';
import 'dart:math' as math;

typedef void Callback(List<dynamic> list);

class Camera extends StatefulWidget {
  final List<CameraDescription> cameras;
  final Callback setRecognitions;
  CameraController controller;
  Camera(this.cameras, this.setRecognitions);

  @override
  _CameraState createState() => new _CameraState();
}

class _CameraState extends State<Camera> {
  bool isDetecting = false;

  @override
  void initState() {
    super.initState();

    if (widget.cameras == null || widget.cameras.length < 1) {
      print('No camera is found');
    } else {
      widget.controller = new CameraController(
        widget.cameras[0],
        ResolutionPreset.high,
      );
      widget.controller.initialize().then((_) {
        if (!mounted) {
          return;
        }
        setState(() {});

        widget.controller.startImageStream((CameraImage img) {
          // SECTION Detection
          if (!isDetecting) {
            isDetecting = true;
            Timer(Duration(seconds: 2), () {
              int startTime = new DateTime.now().millisecondsSinceEpoch;

              // NOTE Ejecutar modelo y obtener predicción
              Tflite.runModelOnFrame(
                bytesList: img.planes.map((plane) {
                  return plane.bytes;
                }).toList(),
                imageHeight: img.height,
                imageWidth: img.width,
                imageMean: 127.5,
                imageStd: 127.5,
                numResults: 2,
                threshold: 0.4,
              ).then((recognitions) {
                int endTime = new DateTime.now().millisecondsSinceEpoch;
                print("Detection took ${endTime - startTime}");
                // NOTE Ejecutal "Callback"
                widget.setRecognitions(recognitions);
                isDetecting = false;
              });
            });
          }
          // !SECTION Detection
        });
      });
    }
  }

  @override
  void dispose() {
    widget.controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller == null || !widget.controller.value.isInitialized) {
      return Container();
    }

/*
    var tmp = MediaQuery.of(context).size;
    var screenH = math.max(tmp.height, tmp.width);
    var screenW = math.min(tmp.height, tmp.width);
    tmp = widget.controller.value.previewSize;
    var previewH = math.max(tmp.height, tmp.width);
    var previewW = math.min(tmp.height, tmp.width);
    var screenRatio = screenH / screenW;
    var previewRatio = previewH / previewW;
    return OverflowBox(
      maxHeight:
          screenRatio > previewRatio ? screenH : screenW / previewW * previewH,
      maxWidth:
          screenRatio > previewRatio ? screenH / previewH * previewW : screenW,
      child: CameraPreview(controller),
    );*/
    return CameraPreview(widget.controller);
  }
}
