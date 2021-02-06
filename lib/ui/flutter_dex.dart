import 'package:flare_flutter/flare_actor.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:smart_flare/actors/smart_flare_actor.dart';
import 'package:smart_flare/smart_flare.dart';
import 'package:teachable_pokedex/Camera.dart';
import 'package:teachable_pokedex/ui/data_screen.dart';
import 'package:teachable_pokedex/ui/sounds.dart';
import 'package:tflite/tflite.dart';
import 'package:vibration/vibration.dart';

// NOTE Screen States
const String POKEDEX = "pokedex";
const String CAMERA = "camera";
const String DATA = "data";
const String IDLE = "idle";

// NOTE Animations
const String ANIMATION_IDLE = "idle";
const String ANIMATION_LIGHTS = "blue_light";

// NOTE Rive File with UI
const String FLUTTER_DEX_FILE = "assets/FlutterDex.flr";
// NOTE TensorFlowLite Model
const String TFLITE_MODEL = "assets/converted_tflite/model_unquant.tflite";
const String TFLITE_LABELS = "assets/converted_tflite/labels.txt";
//const String TFLITE_MODEL = "assets/pokedex.tflite";
// const String TFLITE_LABELS = "assets/pokedex.txt";

// NOTE Debug vas
const bool ENABLE_SMARTFLARE_DEBUG = false;

class FlareFlutterDex extends StatefulWidget {
  final List<CameraDescription> cameras;
  FlareFlutterDex(this.cameras);

  @override
  _FlareFlutterDexState createState() => _FlareFlutterDexState();
}

class _FlareFlutterDexState extends State<FlareFlutterDex> {
  // SECTION: APPLICATON SETUP
  // NOTE: Application State
  List<dynamic> _recognitions;
  bool _modelLoaded;
  bool _speaking;
  bool _iteracting;
  String _display;
  String _upperBarAnimation;
  dynamic _pokemonDetected;

  // NOTE: Camera instance
  Camera camera;
  CameraController controller;
  FlutterTts flutterTts = FlutterTts();

  // NOTE: Init State
  @override
  void initState() {
    super.initState();
    _initializeVars();
    loadModel();
    loadSounds();
    loadVoice();
  }

  void _initializeVars() {
    _modelLoaded = false;
    _speaking = false;
    _iteracting = false;
    _display = IDLE;
    _upperBarAnimation = ANIMATION_IDLE;
    _pokemonDetected = "";
  }

  loadVoice() async {
    await flutterTts.awaitSpeakCompletion(true);
  }

  loadModel() async {
    String result;
    result = await Tflite.loadModel(
      labels: TFLITE_LABELS,
      model: TFLITE_MODEL,
    );
    print(result);
    setState(() {
      _modelLoaded = true;
    });
  }

  // SECTION Callback para manejar las predicciónes
  void setRecognitions(recognitions) {
    if (_iteracting == true) return;
    _iteracting = true;

    setState(() {
      _recognitions = recognitions;
      _display = DATA;
      if (_recognitions.isEmpty) {
        dynamic data = {};
        data["index"] = 10;
        _pokemonDetected = data;
      } else {}
    });
    _pokemonDetected = _recognitions[0];
  }
  // !SECTION Callback para manejar las predicciónes

  // NOTE Manages the speak actions
  Future<dynamic> speak(say) async {
    if (!_speaking) {
      _speaking = true;
      return flutterTts.speak(say).then((_) {
        _speaking = false;
      });
    }
  }

  // NOTE Pantalla en "blanco"
  Widget _idleScreen() {
    return Container();
  }

  void _endDataInteraction() {
    setState(() {
      _iteracting = false;
      _upperBarAnimation = ANIMATION_IDLE;
      _display = IDLE;
    });
  }

  // NOTE Data Backed?
  Widget _data() {
    // Pokemon at index
    int pokemonIndex = _pokemonDetected['index'];
    return DataScreen(pokemonIndex, speak, _endDataInteraction);
  }

  // NOTE Load Display Content
  Widget _loadDisplay(double size) {
    Widget newDisplay;
    switch (_display) {
      case IDLE:
        newDisplay = _idleScreen();
        break;
      case DATA:
        print("data");
        playSound(RECOGNITION);
        newDisplay = _data();
        break;
      case CAMERA:
        playSound(OPEN_CAMERA);
        if (camera == null) {
          camera = Camera(setRecognitions, size);
        }
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

  // NOTE Widget que dibuja el marco de la pantalla y su contenido
  Widget _displayFrame() {
    return Stack(
      children: <Widget>[
        Container(
          color: Colors.black,
          margin: EdgeInsets.all(30),
          //padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
          width: 280,
          height: 200,
          child: _loadDisplay(280),
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
            debugArea: ENABLE_SMARTFLARE_DEBUG,
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
            debugArea: ENABLE_SMARTFLARE_DEBUG,
            onAreaTapped: () {
              print("green button");
              Vibration.vibrate(duration: 40);
              setState(() {
                _initializeVars();
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
              debugArea: ENABLE_SMARTFLARE_DEBUG,
              onAreaTapped: () => {print("up")}),
          // RIGHT
          RelativeActiveArea(
              area: Rect.fromLTWH(0.55, 0.35, 0.35, 0.2),
              debugArea: ENABLE_SMARTFLARE_DEBUG,
              onAreaTapped: () => {print("right")}),
          // LEFT
          RelativeActiveArea(
              area: Rect.fromLTWH(0, 0.35, 0.35, 0.2),
              debugArea: ENABLE_SMARTFLARE_DEBUG,
              onAreaTapped: () => {print("left")}),
          // Down
          RelativeActiveArea(
              area: Rect.fromLTWH(0.35, 0.5, 0.20, 0.4),
              debugArea: ENABLE_SMARTFLARE_DEBUG,
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
            debugArea: ENABLE_SMARTFLARE_DEBUG,
            animationName: 'push',
            onAreaTapped: () {
              print("blue button CAMERA");
              Vibration.vibrate(duration: 40);
              if (_display != CAMERA && !_iteracting) {
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
