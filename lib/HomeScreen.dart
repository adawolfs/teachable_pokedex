import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:teachable_pokedex/Label.dart';
import 'package:teachable_pokedex/Camera.dart';
import 'package:tflite/tflite.dart';

class HomeScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  HomeScreen(this.cameras);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _recognitions;
  bool _recognitionChange = false;
  int _imageHeight = 0;
  int _imageWidth = 0;
  bool _model_loaded = false;

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  loadVoice() async {
    FlutterTts flutterTts = FlutterTts();
    await flutterTts.awaitSpeakCompletion(true);
    await flutterTts.speak("Charmander");
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

  onSelectModel() {
    loadModel();
  }

  setRecognitions(recognitions, imageHeight, imageWidth) {
    print(recognitions);
    setState(() {
      _imageHeight = imageHeight;
      _imageWidth = imageWidth;
      _recognitions = recognitions;
      if (_recognitions[0] == recognitions[0]) {
        _recognitionChange = false;
      } else {
        _recognitionChange = true;
      }
    });
  }

  Widget _createLabels() {
    return Labels(
        _recognitions == null ? [] : _recognitions, _recognitionChange);
  }

  @override
  Widget build(BuildContext context) {
    Size screen = MediaQuery.of(context).size;
    return Scaffold(
      body: !_model_loaded
          ? Container()
          : Stack(
              children: [
                Camera(widget.cameras, setRecognitions),
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
