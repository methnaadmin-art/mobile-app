import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class UploadImageOptimizer {
  UploadImageOptimizer._();

  static int _nonce = 0;
  static const int _skipCompressionThresholdBytes = 6 * 1024 * 1024;

  static Future<File> optimizeProfilePhoto(File source) {
    return _compress(
      source,
      quality: 96,
      minWidth: 2560,
      minHeight: 2560,
      skipIfUnderBytes: _skipCompressionThresholdBytes,
      keepExif: true,
    );
  }

  static Future<File> optimizeSelfie(File source) {
    return _compress(
      source,
      quality: 90,
      minWidth: 1600,
      minHeight: 1600,
      keepExif: true,
    );
  }

  static Future<File> optimizeDocument(File source) {
    return _compress(
      source,
      quality: 90,
      minWidth: 2200,
      minHeight: 2200,
      keepExif: true,
    );
  }

  static Future<File> _compress(
    File source, {
    required int quality,
    required int minWidth,
    required int minHeight,
    int? skipIfUnderBytes,
    bool keepExif = false,
  }) async {
    try {
      if (!await source.exists()) {
        return source;
      }

      final originalBytes = await source.length();
      if (skipIfUnderBytes != null && originalBytes <= skipIfUnderBytes) {
        return source;
      }

      final ext = p.extension(source.path).toLowerCase();
      final isPng = ext == '.png';
      final outputExt = isPng ? 'png' : 'jpg';
      final outputFormat = isPng ? CompressFormat.png : CompressFormat.jpeg;

      final tmpDir = await getTemporaryDirectory();
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final outputPath = p.join(
        tmpDir.path,
        'upload_${stamp}_${_nonce++}.$outputExt',
      );

      final compressedXFile = await FlutterImageCompress.compressAndGetFile(
        source.absolute.path,
        outputPath,
        format: outputFormat,
        quality: quality.clamp(70, 98).toInt(),
        minWidth: minWidth,
        minHeight: minHeight,
        autoCorrectionAngle: true,
        keepExif: keepExif,
        numberOfRetries: 2,
      );

      if (compressedXFile == null) {
        return source;
      }

      final compressedFile = File(compressedXFile.path);
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
