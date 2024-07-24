import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class ObjectDetection {
  Interpreter? _interpreter;

  ObjectDetection() {
    _loadModel();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter =
          await Interpreter.fromAsset('assets/tflite/ssd_mobilenet.tflite');
    } catch (e) {
      print("Failed to load model: $e");
    }
  }

  bool isModelLoaded() {
    return _interpreter != null;
  }

  Future<List<dynamic>> detectObjects(Uint8List imageData) async {
    if (_interpreter == null) {
      throw Exception("Model not loaded");
    }

    var input = imageData.buffer.asUint8List();
    var output = List.filled(10, 0.0).reshape([1, 10]);

    _interpreter!.run(input, output);

    return output[0];
  }
}
