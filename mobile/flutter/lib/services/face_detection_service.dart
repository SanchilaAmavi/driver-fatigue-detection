import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectionService {
  final FaceDetector _faceDetector;

  FaceDetectionService()
      : _faceDetector = FaceDetector(
          options: FaceDetectorOptions(
            enableContours: true,
            enableLandmarks: true,
            enableClassification: true,
            performanceMode: FaceDetectorMode.fast,
          ),
        );

  Future<Face?> processCameraImage(CameraImage image, int rotation) async {
    final inputImage = _cameraImageToInputImage(image, rotation);
    final faces = await _faceDetector.processImage(inputImage);
    return faces.isNotEmpty ? faces.first : null;
  }

  InputImage _cameraImageToInputImage(CameraImage image, int rotation) {
    final bytesBuilder = BytesBuilder(copy: false);
    for (final plane in image.planes) {
      bytesBuilder.add(plane.bytes);
    }
    final bytes = bytesBuilder.takeBytes();

    final imageRotation = InputImageRotationValue.fromRawValue(rotation) ?? InputImageRotation.rotation0deg;
    final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.yuv_420_888;

    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: imageRotation,
      format: inputImageFormat,
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  void dispose() {
    _faceDetector.close();
  }
}
