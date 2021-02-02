import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:smart_flare/actors/smart_flare_actor.dart';
import 'package:smart_flare/smart_flare.dart';
import 'package:teachable_pokedex/Camera.dart';
import 'package:tflite/tflite.dart';
import 'dart:math';

import 'package:vibration/vibration.dart';

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

const String POKEDEX = "pokedex";
const String CAMERA = "camera";
const String DATA = "data";
const String IDLE = "idle";
const String FLUTTER_DEX_FILE = "assets/FlutterDex.flr";

const String ANIMATION_IDLE = "idle";
const String ANIMATION_LIGHTS = "blue_light";

class _FlareFlutterDexState extends State<FlareFlutterDex> {
  // SECTION: APPLICATON SETUP
  // NOTE: Application State
  List<dynamic> _recognitions;
  bool _modelLoaded;
  bool _speaking;
  String _pokemonDetected;
  String _display;
  String _upperBarAnimation;

  // NOTE: Camera instance
  Camera camera;
  FlutterTts flutterTts = FlutterTts();

  // NOTE: Init State
  @override
  void initState() {
    super.initState();
    _modelLoaded = false;
    _speaking = false;
    _pokemonDetected = "";
    _display = IDLE;
    _upperBarAnimation = ANIMATION_IDLE;

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
      _modelLoaded = true;
    });
  }

  void changeScene() {
    setState(() {
      widget.randomScene();
    });
  }

  setRecognitions(recognitions) {
    setState(() {
      _recognitions = recognitions;
      _display = DATA;
      _upperBarAnimation = ANIMATION_IDLE;
      _pokemonDetected = _recognitions[0]["label"];
    });

    // Says pokemon name
    speak(_pokemonDetected).then((_) {
      camera.controller.stopImageStream();
      camera.controller.dispose();
    });
  }

  // NOTE Manages the speak actions
  Future<dynamic> speak(say) async {
    if (!_speaking) {
      _speaking = true;
      flutterTts.speak(say).then((_) {
        _speaking = false;
      });
    }
  }

  Widget _idleScreen() {
    return Container();
  }

  // NOTE Data Backed?
  Widget _data() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Text(
        _pokemonDetected,
        style: TextStyle(fontSize: 20),
      ),
    );
  }

  // NOTE Load Display Content
  Widget _loadDisplay() {
    Widget newDisplay;
    switch (_display) {
      case IDLE:
        newDisplay = _idleScreen();
        break;
      case DATA:
        newDisplay = _data();
        break;
      case CAMERA:
        camera = Camera(widget.cameras, setRecognitions);
        return camera;
        break;
      default:
        newDisplay = _idleScreen();
    }
    return newDisplay;
  }

  // !SECTION
  // SECTION APPLICATION UI DEFINITION
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        FlareActor(
          FLUTTER_DEX_FILE,
          artboard: "back",
        ),
        Positioned(
          top: 0,
          child: Container(
            width: 360,
            height: 138,
            child: FlareActor(
              FLUTTER_DEX_FILE,
              artboard: "upper_bar",
              animation: _upperBarAnimation,
            ),
          ),
        ),
        Positioned(
          top: 160,
          left: 20,
          child: _displayFrame(),
        ),
        //JoyStick
        Positioned(
          top: 550,
          left: 160,
          child: _joystick(),
        ),
        // Main Buttons
        Positioned(
          top: 450,
          left: 20,
          child: Row(
            children: <Widget>[
              _blueButton(),
              _greenButton(),
              _redButton(),
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
              FLUTTER_DEX_FILE,
              artboard: "yellow_screen",
            ),
          ),
        ),
      ],
    );
  }

  Widget _displayFrame() {
    return Stack(
      children: <Widget>[
        Container(
          color: Colors.white,
          margin: EdgeInsets.all(30),
          //padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
          width: 280,
          height: 200,
          child: _loadDisplay(),
        ),
        Container(
          width: 330,
          height: 280,
          child: FlareActor(
            FLUTTER_DEX_FILE,
            artboard: "screen",
          ),
        ),
      ],
    );
  }

  Widget _redButton() {
    return Container(
      width: 100,
      height: 50,
      child: SmartFlareActor(
        filename: FLUTTER_DEX_FILE,
        artboard: "red_button",
        width: 100,
        height: 50,
        activeAreas: [
          ActiveArea(
            area: Rect.fromLTWH(0, 0, 100, 100),
            debugArea: false,
            onAreaTapped: () {
              print("red button");
              Vibration.vibrate(duration: 40);
              setState(() {
                _display = IDLE;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _greenButton() {
    return Container(
      width: 100,
      height: 50,
      child: SmartFlareActor(
        filename: FLUTTER_DEX_FILE,
        artboard: "green_button",
        width: 100,
        height: 50,
        activeAreas: [
          ActiveArea(
            area: Rect.fromLTWH(0, 0, 100, 100),
            debugArea: false,
            onAreaTapped: () {
              print("green button");
              Vibration.vibrate(duration: 40);
              setState(() {
                _display = IDLE;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _joystick() {
    return Container(
      width: 180,
      height: 180,
      child: SmartFlareActor(
        filename: FLUTTER_DEX_FILE,
        artboard: "arrows",
        height: 200,
        width: 200,
        activeAreas: [
          // UP
          RelativeActiveArea(
              area: Rect.fromLTWH(0.35, 0, 0.20, 0.4),
              debugArea: true,
              onAreaTapped: () => {print("up")}),
          // RIGHT
          RelativeActiveArea(
              area: Rect.fromLTWH(0.55, 0.35, 0.35, 0.2),
              debugArea: true,
              onAreaTapped: () => {print("right")}),
          // LEFT
          RelativeActiveArea(
              area: Rect.fromLTWH(0, 0.35, 0.35, 0.2),
              debugArea: true,
              onAreaTapped: () => {print("left")}),
          // Down
          RelativeActiveArea(
              area: Rect.fromLTWH(0.35, 0.5, 0.20, 0.4),
              debugArea: true,
              onAreaTapped: () => {print("down")}),
        ],
      ),
    );
  }

  // NOTE Blue Button
  Widget _blueButton() {
    return Container(
      width: 100,
      height: 100,
      child: SmartFlareActor(
        filename: FLUTTER_DEX_FILE,
        artboard: "blue_button",
        startingAnimation: 'idle',
        width: 100,
        height: 100,
        activeAreas: [
          ActiveArea(
            area: Rect.fromLTWH(0, 0, 100, 100),
            debugArea: false,
            animationName: 'push',
            onAreaTapped: () {
              print("blue button CAMERA");
              Vibration.vibrate(duration: 40);
              if (_display != CAMERA) {
                setState(() {
                  _display = CAMERA;
                  _upperBarAnimation = ANIMATION_LIGHTS;
                });
              }
            },
          ),
        ],
      ),
    );
    // !SECTION Starts UI definition
  }
}
