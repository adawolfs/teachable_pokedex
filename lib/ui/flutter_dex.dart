import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:teachable_pokedex/Camera.dart';
import 'package:tflite/tflite.dart';
import 'dart:math';

class FlareFlutterDex extends StatefulWidget {
  final List<CameraDescription> cameras;
  FlareFlutterDex(this.cameras);

  final List<Widget> scenes = [
    Image.asset("assets/pikachu_sparks.gif"),
    Image.asset("assets/run_forest_run.gif"),
  ];

  void randomScene() {
    var random = Random();
    var index = random.nextInt(scenes.length);
  }

  @override
  _FlareFlutterDexState createState() => _FlareFlutterDexState();
}

class _FlareFlutterDexState extends State<FlareFlutterDex> {
  List<dynamic> _recognitions;
  bool _model_loaded = false;
  Camera camera;
  FlutterTts flutterTts = FlutterTts();
  bool _speaking = false;
  @override
  void initState() {
    super.initState();

    loadModel();
    loadVoice();
  }

  loadVoice() async {
    await flutterTts.awaitSpeakCompletion(true);
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

  void changeScene() {
    setState(() {
      widget.randomScene();
    });
  }

  setRecognitions(recognitions) {
    print(recognitions);
    setState(() {
      _recognitions = recognitions;
    });
    if (!_speaking) {
      _speaking = true;
      flutterTts.speak(_recognitions[0]["label"]).then((_) {
        _speaking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    camera = Camera(widget.cameras, setRecognitions);
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        FlareActor(
          "assets/FlutterDex.flr",
          artboard: "back",
        ),
        Positioned(
          top: 0,
          child: Container(
              width: 360,
              height: 138,
              child: Stack(
                children: [
                  FlareActor(
                    "assets/FlutterDex.flr",
                    artboard: "upper_bar",
                  ),
                  _recognitions != null
                      ? Text("${_recognitions[0]["label"]}")
                      : Container(),
                ],
              )),
        ),
        Positioned(
            top: 160,
            left: 20,
            child: Stack(
              children: <Widget>[
                Container(
                  color: Colors.white,
                  margin: EdgeInsets.all(30),
                  //padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                  width: 280,
                  height: 200,
                  child: camera,
                  //child: widget.scenes[0]
                  // child: OverflowBox(
                  //   maxHeight: 200,
                  //   maxWidth: 250,
                  //   child: camera,
                  // ),
                ),
                Container(
                  // color: Colors.blue,
                  width: 330,
                  height: 280,
                  child: FlareActor(
                    "assets/FlutterDex.flr",
                    artboard: "screen",
                  ),
                ),
              ],
            )),
        Positioned(
          top: 550,
          left: 160,
          child: Container(
            width: 180,
            height: 180,
            child: GestureDetector(
              onTap: () {
                changeScene();
              },
              child: FlareActor(
                "assets/FlutterDex.flr",
                artboard: "arrows",
              ),
            ),
          ),
        ),
        Positioned(
          top: 450,
          left: 20,
          child: Row(
            children: <Widget>[
              Container(
                width: 100,
                height: 100,
                child: FlareActor(
                  "assets/FlutterDex.flr",
                  artboard: "blue_button",
                ),
              ),
              Container(
                width: 100,
                height: 50,
                child: FlareActor(
                  "assets/FlutterDex.flr",
                  artboard: "green_button",
                ),
              ),
              Container(
                width: 100,
                height: 50,
                child: FlareActor(
                  "assets/FlutterDex.flr",
                  artboard: "red_button",
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 550,
          left: 20,
          child: Container(
            width: 140,
            height: 200,
            child: FlareActor(
              "assets/FlutterDex.flr",
              artboard: "yellow_screen",
            ),
          ),
        ),
      ],
    );
  }
}
