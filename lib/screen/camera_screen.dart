import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:object_detect/model/object_detection.dart';
import 'dart:typed_data';

class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? cameras;
  ObjectDetection? _objectDetection;
  String _detectedObjects = "No Objects";

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeObjectDetection();
  }

  Future<void> _initializeObjectDetection() async {
    _objectDetection = ObjectDetection();
    await Future.delayed(Duration(seconds: 2));
  }

  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    _controller = CameraController(cameras![0], ResolutionPreset.high);
    await _controller!.initialize();
    _controller!.startImageStream((CameraImage image) {
      _processCameraImage(image);
    });
    setState(() {});
  }

  void _processCameraImage(CameraImage image) async {
    if (_objectDetection == null || !_objectDetection!.isModelLoaded()) {
      return;
    }

    Uint8List imageData = _convertCameraImage(image);
    List<dynamic> objects = await _objectDetection!.detectObjects(imageData);
    setState(() {
      _detectedObjects = objects.toString();
    });
  }

  Uint8List _convertCameraImage(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel!;

    Uint8List yBuffer = image.planes[0].bytes;
    Uint8List uBuffer = image.planes[1].bytes;
    Uint8List vBuffer = image.planes[2].bytes;

    var img = Uint8List(width * height * 3);

    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        int uvIndex = uvPixelStride * (x >> 1) + uvRowStride * (y >> 1);
        int index = y * width + x;

        int yValue = yBuffer[index];
        int uValue = uBuffer[uvIndex];
        int vValue = vBuffer[uvIndex];

        int r = (yValue + 1.370705 * (vValue - 128)).round();
        int g = (yValue - 0.698001 * (vValue - 128) - 0.337633 * (uValue - 128))
            .round();
        int b = (yValue + 1.732446 * (uValue - 128)).round();

        img[index * 3] = r.clamp(0, 255);
        img[index * 3 + 1] = g.clamp(0, 255);
        img[index * 3 + 2] = b.clamp(0, 255);
      }
    }

    return img;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }
    return Stack(
      children: [
        CameraPreview(_controller!),
        Positioned(
          bottom: 16,
          left: 16,
          child: Text(
            _detectedObjects,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              backgroundColor: Colors.black54,
            ),
          ),
        ),
      ],
    );
  }
}
