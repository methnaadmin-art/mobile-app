import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class UploadImageOptimizer {
  UploadImageOptimizer._();

  static int _nonce = 0;

  static Future<File> optimizeProfilePhoto(File source) {
    return _compress(
      source,
      quality: 68,
      minWidth: 1280,
      minHeight: 1280,
    );
  }

  static Future<File> optimizeSelfie(File source) {
    return _compress(
      source,
      quality: 70,
      minWidth: 1080,
      minHeight: 1080,
    );
  }

  static Future<File> optimizeDocument(File source) {
    return _compress(
      source,
      quality: 82,
      minWidth: 1800,
      minHeight: 1800,
    );
  }

  static Future<File> _compress(
    File source, {
    required int quality,
    required int minWidth,
    required int minHeight,
  }) async {
    try {
      if (!await source.exists()) {
        return source;
      }

      final tmpDir = await getTemporaryDirectory();
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final outputPath = p.join(tmpDir.path, 'upload_${stamp}_${_nonce++}.jpg');

      final compressedXFile = await FlutterImageCompress.compressAndGetFile(
        source.absolute.path,
        outputPath,
        format: CompressFormat.jpeg,
        quality: quality.clamp(40, 95).toInt(),
        minWidth: minWidth,
        minHeight: minHeight,
        autoCorrectionAngle: true,
        keepExif: false,
        numberOfRetries: 2,
      );

      if (compressedXFile == null) {
        return source;
      }

      final compressedFile = File(compressedXFile.path);
      final originalBytes = await source.length();
      final compressedBytes = await compressedFile.length();

      // Keep the original if compression did not reduce payload size.
      if (compressedBytes <= 0 || compressedBytes >= originalBytes) {
        return source;
      }

      return compressedFile;
    } catch (e) {
      debugPrint('[UploadImageOptimizer] Compression failed: $e');
      return source;
    }
  }
}
