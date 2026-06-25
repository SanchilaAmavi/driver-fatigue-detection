import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectionService {
  FaceDetector? _faceDetector;

  FaceDetectionService() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableLandmarks: true,
        enableContours: true,
        enableTracking: true,
        performanceMode: FaceDetectorMode.accurate,
        minFaceSize: 0.15,
      ),
    );
  }

  Future<Face?> processCameraImage(
    CameraImage image,
    int sensorOrientation,
  ) async {
    try {
      final InputImage inputImage = image.format.group == ImageFormatGroup.yuv420
          ? _buildNv21InputImage(image, sensorOrientation)
          : _buildBgraInputImage(image, sensorOrientation);

      final faces = await _faceDetector!.processImage(inputImage);
      if (faces.isEmpty) return null;

      faces.sort((a, b) =>
          (b.boundingBox.width * b.boundingBox.height)
              .compareTo(a.boundingBox.width * a.boundingBox.height));
      return faces.first;
    } catch (e) {
      // ignore: avoid_print
      print('Face detection error: $e');
      return null;
    }
  }

  // ✅ Properly handles row/pixel stride instead of naive concatenation
  InputImage _buildNv21InputImage(CameraImage image, int sensorOrientation) {
    final nv21 = _yuv420ToNv21(image);

    return InputImage.fromBytes(
      bytes: nv21,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: _rotationFromSensorOrientation(sensorOrientation),
        format: InputImageFormat.nv21,
        bytesPerRow: image.width, // NV21 output is tightly packed
      ),
    );
  }

  InputImage _buildBgraInputImage(CameraImage image, int sensorOrientation) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: _rotationFromSensorOrientation(sensorOrientation),
        format: InputImageFormat.bgra8888,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  // ✅ Converts Android's YUV_420_888 (3 planes, possibly padded) into
  // a tightly-packed NV21 buffer (Y plane + interleaved VU plane).
  Uint8List _yuv420ToNv21(CameraImage image) {
    final int width = image.width;
    final int height = image.height;

    final Plane yPlane = image.planes[0];
    final Plane uPlane = image.planes[1];
    final Plane vPlane = image.planes[2];

    final int ySize = width * height;
    final int uvSize = width * height ~/ 2;
    final Uint8List nv21 = Uint8List(ySize + uvSize);

    // --- Copy Y plane row by row, stripping any row padding ---
    int destOffset = 0;
    for (int row = 0; row < height; row++) {
      final int srcOffset = row * yPlane.bytesPerRow;
      nv21.setRange(
        destOffset,
        destOffset + width,
        yPlane.bytes,
        srcOffset,
      );
      destOffset += width;
    }

    // --- Interleave V and U planes into NV21's VU order ---
    final int uvRowStride = uPlane.bytesPerRow;
    final int uvPixelStride = uPlane.bytesPerPixel ?? 2;
    final int vRowStride = vPlane.bytesPerRow;
    final int vPixelStride = vPlane.bytesPerPixel ?? 2;

    int uvIndex = ySize;
    for (int row = 0; row < height ~/ 2; row++) {
      final int uRowStart = row * uvRowStride;
      final int vRowStart = row * vRowStride;
      for (int col = 0; col < width ~/ 2; col++) {
        final int uIndex = uRowStart + col * uvPixelStride;
        final int vIndex = vRowStart + col * vPixelStride;
        nv21[uvIndex++] = vPlane.bytes[vIndex]; // V first
        nv21[uvIndex++] = uPlane.bytes[uIndex]; // U second
      }
    }

    return nv21;
  }

  InputImageRotation _rotationFromSensorOrientation(int orientation) {
    switch (orientation) {
      case 90:  return InputImageRotation.rotation90deg;
      case 180: return InputImageRotation.rotation180deg;
      case 270: return InputImageRotation.rotation270deg;
      default:  return InputImageRotation.rotation0deg;
    }
  }

  void dispose() {
    _faceDetector?.close();
  }
}
