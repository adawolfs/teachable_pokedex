import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:teachable_pokedex/Label.dart';
import 'package:teachable_pokedex/Camera.dart';
import 'package:teachable_pokedex/PokeEntry.dart';
import 'package:tflite/tflite.dart';

class HomeScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  HomeScreen(this.cameras);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CameraController controller;
  List<dynamic> _recognitions;
  bool _stopCamera = false;
  int _imageHeight = 0;
  int _imageWidth = 0;
  bool _model_loaded = false;
  Camera camera;

  @override
  void initState() {
    super.initState();

    loadModel();
  }

  loadModel() async {
    String result;
    result = await Tflite.loadModel(
        labels: "assets/pokedex.txt", model: "assets/pokedex.tflite");
    print(result);
    setState(() {
      _model_loaded = true;
    });
  }

  startStream() {
    setState(() {
      _stopCamera = false;
    });
  }

  onSelectModel() {
    loadModel();
  }

  setRecognitions(recognitions) {
    print(recognitions);
    /*controller.stopImageStream();*/
    setState(() {
      _recognitions = recognitions;
      _stopCamera = true;
    });
    /*if (_stopCamera) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PokeEntry(recognitions[0])),
      ).then((value) {
        camera.startImageStream();
        setState(() {
          _stopCamera = false;
        });
      });
    }*/
  }

  Widget _createLabels() {
    return Labels(_recognitions == null ? [] : _recognitions);
  }

  @override
  Widget build(BuildContext context) {
    Size screen = MediaQuery.of(context).size;
    controller = new CameraController(
      widget.cameras[0],
      ResolutionPreset.high,
    );
    camera = Camera(widget.cameras, setRecognitions);
    return Scaffold(
      body: !_model_loaded
          ? Container()
          : Stack(
              children: [
                GestureDetector(
                  child: camera,
                  onTap: () {
                    print("tap");
                    setState(() {
                      _stopCamera = false;
                    });
                  },
                ),
                _createLabels(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          onSelectModel();
        },
        child: Icon(Icons.photo_camera),
      ),
    );
  }
}
