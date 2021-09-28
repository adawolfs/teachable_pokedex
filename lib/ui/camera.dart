import 'dart:async';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
// import 'package:tflite/tflite.dart';

typedef void Callback(List<dynamic> list);

class Camera extends StatefulWidget {
  Camera({Key? key}) : super(key: key);

  @override
  _CameraState createState() => _CameraState();
}

class _CameraState extends State<Camera> {
  CameraController? cameraController;
  Future<void>? _initializeControllerFuture;
  bool isDetecting = false;
  List cameras = [];
  int selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _initCameras();
  }

  void _initCameras() {
    availableCameras().then((value) {
      cameras = value;
      print(cameras);
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
      await cameraController!.dispose();
    }
    // Crear un nuevo controllador para la camara
    // Este objeto permite interactuar con las librerias nativas en dispositivos moviles
    cameraController =
        CameraController(cameraDescription, ResolutionPreset.max);

    // Inicializar el controlador y configurar la camara
    _initializeControllerFuture = cameraController?.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }
  // !SECTION InitCamera

  // !SECTION Detection
  // SECTION Mostrar la Camara
  @override
  Widget build(BuildContext context) {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return Container();
    }
    return CameraPreview(cameraController!);
  }
}
