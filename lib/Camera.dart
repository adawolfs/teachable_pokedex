import 'dart:async';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite/tflite.dart';

typedef void Callback(List<dynamic> list);

class Camera extends StatefulWidget {
  final Callback setRecognitions;
  final double size;
  Camera(this.setRecognitions, this.size, {Key key}) : super(key: key);

  @override
  _CameraState createState() => _CameraState();
}

class _CameraState extends State<Camera> {
  CameraController cameraController;
  Future<void> _initializeControllerFuture;
  bool isDetecting = false;
  List cameras;
  int selectedCameraIndex;

  @override
  void initState() {
    super.initState();
    _initCameras();
  }

  void _initCameras() {
    availableCameras().then((value) {
      cameras = value;
      if (cameras.length > 0) {
        setState(() {
          selectedCameraIndex = 0;
        });
        initCamera(cameras[selectedCameraIndex]).then((value) {});
      } else {
        print('No camera available');
      }
    }).catchError((e) {
      print('Error : ${e.code}');
    });
  }

  // SECTION InitCamera
  Future initCamera(CameraDescription cameraDescription) async {
    // Si ya existe un controlador entonces soltar los recursos de la camara
    if (cameraController != null) {
      await cameraController.dispose();
    }
    // Crear un nuevo controllador para la camara
    // Este objeto permite interactuar con las librerias nativas en dispositivos moviles
    cameraController =
        CameraController(cameraDescription, ResolutionPreset.medium);

    // Inicializar el controlador y configurar la camara
    _initializeControllerFuture = cameraController.initialize().then((_) {
      // Configuracion de la camara
      cameraController.setFocusMode(FocusMode.locked);
      cameraController.setFocusPoint(Offset(0.5, 0.5));
      // Evitar el iniciar el streaming más de una vez
      if (cameraController.value.isStreamingImages) return;
      // Iniciar el streaming de imagenes desde la camara y predecir sobre ella
      cameraController.startImageStream((CameraImage img) {
        _imagePrediction(img);
      });
    });
  }
  // !SECTION InitCamera

  // SECTION Detection
  void _imagePrediction(CameraImage img) {
    // Retornar si existe una detección en proceso.
    if (isDetecting) return;
    int startTime = new DateTime.now().millisecondsSinceEpoch;
    isDetecting = true;
    // NOTE Ejecutar modelo y obtener predicción
    Tflite.runModelOnFrame(
      bytesList: img.planes.map((plane) {
        return plane.bytes;
      }).toList(),
      imageHeight: img.height,
      imageWidth: img.width,
      imageMean: 127.5,
      imageStd: 127.5,
      numResults: 4,
      threshold: 0.5,
    ).then((recognitions) {
      int endTime = new DateTime.now().millisecondsSinceEpoch;
      print("Detection took ${endTime - startTime}");
      // Una vez obtenida una predicción detener el streaming
      if (cameraController.value.isStreamingImages) {
        cameraController.stopImageStream();
      }
      // NOTE Ejecutal "Callback"
      widget.setRecognitions(recognitions);
      isDetecting = false;
    }).timeout(Duration(seconds: 5), onTimeout: () {
      // Una vez obtenida una predicción detener el streaming
      if (cameraController.value.isStreamingImages) {
        cameraController.stopImageStream();
      }
      widget.setRecognitions(null);
      isDetecting = false;
    });
    // });
    // !SECTION Detection
  }

  // SECTION Mostrar la Camara
  Widget cameraPreview() {
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          // NOTE Una vez se cumpla el "future" mostar la camara
          return FittedBox(
            fit: BoxFit.fill,
            child: Container(
              width: widget.size,
              height: cameraController.value.aspectRatio,
              child: CameraPreview(cameraController),
            ),
          );
        } else {
          // NOTE De lo contrario mostrar un "loading"
          return Center(
            child: Container(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return cameraPreview();
  }
  // !SECTION Mostrar la Camara
}
