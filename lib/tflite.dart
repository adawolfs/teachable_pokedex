import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite/tflite.dart';

const String mobile = "MobileNet";
const String ssd = "SSD MobileNet";
const String yolo = "Tiny YOLOv2";
const String deeplab = "DeepLab";
const String posenet = "PoseNet";

class TFLiteTest extends StatefulWidget {
  TFLiteTest({Key key}) : super(key: key);

  @override
  _TFLiteTestState createState() => _TFLiteTestState();
}

class _TFLiteTestState extends State<TFLiteTest> {
  bool _busy = false;
  File _image;
  List _recognitions;
  String _model = mobile;
  double _imageHeight;
  double _imageWidth;

  Future predictImage(File image) async {
    if (image == null) return;

    switch (_model) {
      case yolo:
        await yolov2Tiny(image);
        break;
      /*
      case ssd:
        await ssdMobileNet(image);
        break;
      case deeplab:
        await segmentMobileNet(image);
        break;
      case posenet:
        await poseNet(image);
        break;
        */
      default:
        await recognizeImage(image);
      // await recognizeImageBinary(image);
    }

    new FileImage(image)
        .resolve(new ImageConfiguration())
        .addListener(ImageStreamListener((ImageInfo info, bool _) {
      setState(() {
        _imageHeight = info.image.height.toDouble();
        _imageWidth = info.image.width.toDouble();
      });
    }));

    setState(() {
      _image = image;
      _busy = false;
    });
  }

  @override
  void initState() {
    super.initState();

    _busy = true;

    loadModel().then((val) {
      setState(() {
        _busy = false;
      });
    });
  }

  Future loadModel() async {
    Tflite.close();
    try {
      String res;
      switch (_model) {
        case yolo:
          res = await Tflite.loadModel(
            model: "assets/yolov2_tiny.tflite",
            labels: "assets/yolov2_tiny.txt",
            // useGpuDelegate: true,
          );
          break;
        case ssd:
          res = await Tflite.loadModel(
            model: "assets/ssd_mobilenet.tflite",
            labels: "assets/ssd_mobilenet.txt",
            // useGpuDelegate: true,
          );
          break;
        case deeplab:
          res = await Tflite.loadModel(
            model: "assets/deeplabv3_257_mv_gpu.tflite",
            labels: "assets/deeplabv3_257_mv_gpu.txt",
            // useGpuDelegate: true,
          );
          break;
        case posenet:
          res = await Tflite.loadModel(
            model: "assets/posenet_mv1_075_float_from_checkpoints.tflite",
            // useGpuDelegate: true,
          );
          break;
        default:
          res = await Tflite.loadModel(
            model: "assets/mobilenet_v1_1.0_224.tflite",
            labels: "assets/mobilenet_v1_1.0_224.txt",
            // useGpuDelegate: true,
          );
      }
      print(res);
    } on PlatformException {
      print('Failed to load model.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Container(),
    );
  }

  Future recognizeImage(File image) async {
    int startTime = new DateTime.now().millisecondsSinceEpoch;
    var recognitions = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 6,
      threshold: 0.05,
      imageMean: 127.5,
      imageStd: 127.5,
    );
    setState(() {
      _recognitions = recognitions;
    });
    int endTime = new DateTime.now().millisecondsSinceEpoch;
    print("Inference took ${endTime - startTime}ms");
  }

  Future recognizeImageBinary(File image) async {
    int startTime = new DateTime.now().millisecondsSinceEpoch;
    var imageBytes = (await rootBundle.load(image.path)).buffer;
    img.Image oriImage = img.decodeJpg(imageBytes.asUint8List());
    img.Image resizedImage = img.copyResize(oriImage, height: 224, width: 224);
    var recognitions = await Tflite.runModelOnBinary(
      binary: imageToByteListFloat32(resizedImage, 224, 127.5, 127.5),
      numResults: 6,
      threshold: 0.05,
    );
    setState(() {
      _recognitions = recognitions;
    });
    int endTime = new DateTime.now().millisecondsSinceEpoch;
    print("Inference took ${endTime - startTime}ms");
  }

  Uint8List imageToByteListFloat32(
      img.Image image, int inputSize, double mean, double std) {
    var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;
    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (img.getRed(pixel) - mean) / std;
        buffer[pixelIndex++] = (img.getGreen(pixel) - mean) / std;
        buffer[pixelIndex++] = (img.getBlue(pixel) - mean) / std;
      }
    }
    return convertedBytes.buffer.asUint8List();
  }

  Future yolov2Tiny(File image) async {
    int startTime = new DateTime.now().millisecondsSinceEpoch;
    var recognitions = await Tflite.detectObjectOnImage(
      path: image.path,
      model: "YOLO",
      threshold: 0.3,
      imageMean: 0.0,
      imageStd: 255.0,
      numResultsPerClass: 1,
    );
    // var imageBytes = (await rootBundle.load(image.path)).buffer;
    // img.Image oriImage = img.decodeJpg(imageBytes.asUint8List());
    // img.Image resizedImage = img.copyResize(oriImage, 416, 416);
    // var recognitions = await Tflite.detectObjectOnBinary(
    //   binary: imageToByteListFloat32(resizedImage, 416, 0.0, 255.0),
    //   model: "YOLO",
    //   threshold: 0.3,
    //   numResultsPerClass: 1,
    // );
    setState(() {
      _recognitions = recognitions;
    });
    int endTime = new DateTime.now().millisecondsSinceEpoch;
    print("Inference took ${endTime - startTime}ms");
  }
}
