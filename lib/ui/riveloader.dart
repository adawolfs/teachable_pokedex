import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart';
import 'package:teachable_pokedex/camera.dart';

class RiveLoader extends StatefulWidget {
  RiveLoader({Key? key}) : super(key: key);

  @override
  _RiveLoaderState createState() => _RiveLoaderState();
}

class _RiveLoaderState extends State<RiveLoader> {
  bool get isPlaying => _controller?.isActive ?? false;

  Artboard? _controls;
  Artboard? _screen;
  Artboard? _lights;
  Artboard? _background;
  bool _artboardLoaded = false;

  StateMachineController? _controller;
  SMIInput<bool>? _start;
  SMIInput<double>? _progress;

  @override
  void initState() {
    super.initState();
    print("InitState " + DateTime.now().toString());

    // Load the animation file from the bundle, note that you could also
    // download this. The RiveFile just expects a list of bytes.
    rootBundle.load('rive/pokedex.riv').then(
      (data) async {
        // Load the RiveFile from the binary data.
        final file = RiveFile.import(data);

        final controls = file.artboardByName('controls');
        final lights = file.artboardByName('lights');
        final screen = file.artboardByName('screen');
        final background = file.artboardByName('base');
        print("Rive Asset Loaded " + DateTime.now().toString());
        setState(() {
          _controls = controls;
          _lights = lights;
          _screen = screen;
          _background = background;
          _artboardLoaded = true;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF760000),
      body: Center(
        child: _artboardLoaded
            ? SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: Stack(
                  children: <Widget>[
                    Positioned(
                      bottom: 0,
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height,
                        width: MediaQuery.of(context).size.width,
                        child: Rive(
                          artboard: _background!,
                          fit: BoxFit.fitWidth,
                          alignment: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height,
                        width: MediaQuery.of(context).size.width,
                        child: Rive(
                          artboard: _lights!,
                          fit: BoxFit.fitWidth,
                          alignment: Alignment.topCenter,
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        Flexible(flex: 2, child: Container()),
                        Flexible(
                            flex: 3, fit: FlexFit.loose, child: _drawScreen()),
                        Flexible(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.only(left: 30, right: 30),
                            child: Rive(
                              artboard: _controls!,
                              fit: BoxFit.contain,
                              alignment: Alignment.topCenter,
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              )
            : const SizedBox(),
      ),
    );
  }

  Widget _drawScreen() {
    return Container(
      padding: const EdgeInsets.only(left: 30, right: 20),
      child: Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: 11 / 10,
              child: Container(
                margin: const EdgeInsets.fromLTRB(10, 10, 20, 55),
                color: Colors.black,
                child: Camera((r) {}, 280),
              ),
            ),
          ),
          Rive(
            artboard: _screen!,
            fit: BoxFit.contain,
            alignment: Alignment.topCenter,
          ),
        ],
      ),
    );
  }
}
