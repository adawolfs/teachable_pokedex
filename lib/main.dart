import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:teachable_pokedex/HomeScreen.dart';

import 'package:teachable_pokedex/ui/flutter_dex.dart';

List<CameraDescription> cameras;

Future<Null> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Error $e.code \n Error Message: $e.message');
  }

  runApp(new MainScreen());
}

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // home: HomeScreen(cameras),
      home: FlareFlutterDex(cameras),
    );
  }
}
