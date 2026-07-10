import 'dart:io';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:methna_app/app/controllers/signup_controller.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_radii.dart';
import 'package:methna_app/app/theme/app_shadows.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/app/theme/app_text_styles.dart';
import 'package:methna_app/core/widgets/datify_shell.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SelfieVerificationScreen extends StatefulWidget {
  const SelfieVerificationScreen({super.key});

  @override
  State<SelfieVerificationScreen> createState() =>
      _SelfieVerificationScreenState();
}

class _SelfieVerificationScreenState extends State<SelfieVerificationScreen> {
  final SignupController controller = Get.find<SignupController>();

  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  bool _isInitializing = true;
  bool _isProcessing = false;
  bool _faceDetected = false;
  String _statusMessage = 'position_face_oval'.tr;
  bool _isCapturingSelfie = false;

  // Detection states
  bool _isCentered = false;
  bool _isCorrectDistance = false;

  // Safety net: on-device auto-detection can fail to line up (lighting,
  // camera-orientation edge cases on some devices/OS versions) and leave
  // the capture button permanently disabled. After a grace period, offer a
  // manual override so the screen can never get stuck — the backend still
  // performs the real selfie verification after upload.
  bool _showManualCaptureOption = false;
  Timer? _manualCaptureTimer;

  bool get _canCapture => _faceDetected && _isCentered && _isCorrectDistance;

  @override
  void initState() {
    super.initState();
    controller.syncStep(AppRoutes.signupSelfie);
    _initializeCamera();
    _initializeFaceDetector();
    _manualCaptureTimer = Timer(const Duration(seconds: 8), () {
      if (!mounted || _canCapture) return;
      setState(() => _showManualCaptureOption = true);
    });
  }

  void _initializeFaceDetector() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _cameraController!.initialize();

      if (!mounted) return;

      setState(() => _isInitializing = false);

      // Start processing stream
      _startImageStream();
    } catch (e) {
      debugPrint('[Selfie] Camera init error: $e');
      setState(() => _isInitializing = false);
    }
  }

  void _startImageStream() {
    final camera = _cameraController;
    if (camera == null || !camera.value.isInitialized) return;
    if (camera.value.isStreamingImages) return;

    camera.startImageStream((CameraImage image) {
      if (_isProcessing) return;
      _isProcessing = true;
      _processImage(image);
    });
  }

  Future<void> _processImage(CameraImage image) async {
    if (_faceDetector == null) return;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      final faces = await _faceDetector!.processImage(inputImage);

      if (!mounted) return;

      setState(() {
        if (faces.isEmpty) {
          _faceDetected = false;
          _isCentered = false;
          _isCorrectDistance = false;
          _statusMessage = 'no_face_detected_status'.tr;
        } else {
          final face = faces.first;
          _faceDetected = true;

          // Device-safe checks based on current frame size.
          final frameWidth = image.width.toDouble();
          final frameHeight = image.height.toDouble();

          final centerX = face.boundingBox.center.dx.clamp(0.0, frameWidth);
          final centerY = face.boundingBox.center.dy.clamp(0.0, frameHeight);
          final centerOffsetX = (centerX - (frameWidth / 2)).abs();
          final centerOffsetY = (centerY - (frameHeight / 2)).abs();

          _isCentered = centerOffsetX <= frameWidth * 0.22 &&
              centerOffsetY <= frameHeight * 0.26;

          final widthRatio = face.boundingBox.width / frameWidth;
          _isCorrectDistance = widthRatio >= 0.22 && widthRatio <= 0.58;

          if (!_isCentered) {
            _statusMessage = 'center_your_face'.tr;
          } else if (!_isCorrectDistance) {
            _statusMessage = widthRatio < 0.22
                ? 'move_closer'.tr
                : 'move_further_back'.tr;
          } else {
            _statusMessage = 'verified_hold_still'.tr;
          }
        }
      });
    } catch (e) {
      debugPrint('[Selfie] Stream processing error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  InputImage _inputImageFromCameraImage(CameraImage image) {
    final sensorOrientation = _cameraController!.description.sensorOrientation;
    final inputImageFormat =
        InputImageFormatValue.fromRawValue(image.format.raw) ??
        InputImageFormat.nv21;

    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation:
            InputImageRotationValue.fromRawValue(sensorOrientation) ??
            InputImageRotation.rotation0deg,
        format: inputImageFormat,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  Future<void> _captureSelfie({bool force = false}) async {
    if (!force && (!_faceDetected || !_isCentered || !_isCorrectDistance)) {
      return;
    }
    if (_isCapturingSelfie) return;

    try {
      if (mounted) {
        setState(() => _isCapturingSelfie = true);
      }

      // Pause stream to take photo
      await _cameraController?.stopImageStream();
      final image = await _cameraController?.takePicture();

      if (image != null) {
        final file = File(image.path);

        // Show scanning effect
        if (!mounted) return;
        _showMatchingFlow(file);
      } else {
        if (mounted) {
          setState(() => _isCapturingSelfie = false);
        }
        _startImageStream();
      }
    } catch (e) {
      debugPrint('[Selfie] Capture error: $e');
      if (mounted) {
        setState(() => _isCapturingSelfie = false);
      }
      _startImageStream();
    }
  }

  void _showMatchingFlow(File file) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _MatchingDialog(
        file: file,
        onComplete: () {
          controller.setSelfie(file);
          Get.back(); // Close dialog
          unawaited(
            controller.goToNextStep().whenComplete(() {
              if (!mounted) return;
              if (Get.currentRoute == AppRoutes.signupSelfie) {
                setState(() => _isCapturingSelfie = false);
                _startImageStream();
              }
            }),
          );
        },
      ),
    );

    if (!mounted) return;
    if (Get.currentRoute == AppRoutes.signupSelfie && _isCapturingSelfie) {
      setState(() => _isCapturingSelfie = false);
      _startImageStream();
    }
  }

  @override
  void dispose() {
    _manualCaptureTimer?.cancel();
    if (_cameraController?.value.isStreamingImages ?? false) {
      _cameraController?.stopImageStream();
    }
    _cameraController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final primaryColor = AppColors.primary;

    if (_isInitializing) {
      return Scaffold(
        backgroundColor: bgColor,
        body: DatifyBackground(
          compact: true,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: primaryColor),
                const SizedBox(height: 24),
                Text(
                  'initializing_camera'.tr,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Scaffold(
        backgroundColor: bgColor,
        body: DatifyBackground(
          compact: true,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.cameraOff, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'camera_error'.tr,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: _initializeCamera,
                  child: Text('retry'.tr),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Camera Preview ──
          Positioned.fill(child: _buildCameraPreview()),

          // ── PREMIUM GLASS OVERLAY ──
          Positioned.fill(
            child: CustomPaint(
              painter: _FaceOvalPainter(
                isVerified: _canCapture,
                isDark: isDark,
                primaryColor: primaryColor,
              ),
            ),
          ),

          // ── SCANNING LASER (Conditional) ──

          // ── UI CONTENT ──
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    0,
                  ),
                  child: Row(
                    children: [
                      DatifyBackButton(onTap: () => Get.back()),
                      const Spacer(),
                      const DatifyHeaderBadge(text: '11 / 12'),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'selfie_verification'.tr,
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ).animate().fadeIn(duration: 320.ms),
                const SizedBox(height: AppSpacing.xs),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Text(
                    'selfie_desc_short'.tr,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ).animate().fadeIn(duration: 360.ms),

                const Spacer(),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadii.xxl),
                    ),
                    boxShadow: AppShadows.surface(false),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _canCapture ? 'face_aligned'.tr : 'align_your_face'.tr,
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: AppColors.textPrimaryLight,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _statusMessage,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _GuideRow(label: 'face_visible'.tr, done: _faceDetected),
                      const SizedBox(height: AppSpacing.sm),
                      _GuideRow(
                        label: 'centered_in_frame'.tr,
                        done: _isCentered,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _GuideRow(
                        label: 'good_distance'.tr,
                        done: _isCorrectDistance,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _canCapture && !_isCapturingSelfie
                              ? _captureSelfie
                              : null,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            backgroundColor: AppColors.primary,
                            disabledBackgroundColor: const Color(0xFFE7DDFB),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadii.pill),
                            ),
                          ),
                          child: Text(
                            _isCapturingSelfie
                              ? 'capture_selfie'.tr
                                : (_canCapture
                                      ? 'capture_selfie'.tr
                                      : 'align_your_face'.tr),
                            style: AppTextStyles.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      if (_showManualCaptureOption && !_canCapture) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Center(
                          child: TextButton(
                            onPressed: _isCapturingSelfie
                                ? null
                                : () => _captureSelfie(force: true),
                            child: Text(
                              'capture_selfie_anyway'.tr,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      Center(
                        child: Text(
                          'selfie_privacy_note'.tr,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 420.ms).slideY(begin: 0.12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    final camera = _cameraController;
    if (camera == null || !camera.value.isInitialized) {
      return Container(color: Colors.black);
    }

    final previewSize = camera.value.previewSize;
    if (previewSize == null) {
      return CameraPreview(camera);
    }

    final screenSize = MediaQuery.of(context).size;
    final screenAspectRatio = screenSize.width / screenSize.height;
    final previewAspectRatio = previewSize.height / previewSize.width;
    final scale = previewAspectRatio / screenAspectRatio;

    return ClipRect(
      child: Transform.scale(
        scale: scale < 1 ? 1 / scale : scale,
        child: Center(child: CameraPreview(camera)),
      ),
    );
  }
}

class _GuideRow extends StatelessWidget {
  final String label;
  final bool done;

  const _GuideRow({required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: done ? AppColors.primary : const Color(0xFFF2ECFB),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(
            done ? LucideIcons.check : LucideIcons.dot,
            size: done ? 13 : 16,
            color: done ? Colors.white : AppColors.textHintLight,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimaryLight,
            ),
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _GlassContainer extends StatelessWidget {
  final Widget child;

  const _GlassContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ignore: unused_element
class _StatusGuide extends StatelessWidget {
  final bool faceDetected;
  final bool isCentered;
  final bool isCorrectDistance;
  final String statusMessage;
  final Color primaryColor;

  const _StatusGuide({
    required this.faceDetected,
    required this.isCentered,
    required this.isCorrectDistance,
    required this.statusMessage,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool allValid = faceDetected && isCentered && isCorrectDistance;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Container(
            key: ValueKey(statusMessage),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              color: allValid
                  ? AppColors.verified.withValues(alpha: 0.9)
                  : Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (allValid)
                  const Icon(
                    LucideIcons.checkCircle,
                    color: Colors.white,
                    size: 20,
                  )
                else if (faceDetected)
                  const Icon(
                    LucideIcons.maximize,
                    color: Colors.white70,
                    size: 18,
                  )
                else
                  const Icon(LucideIcons.user, color: Colors.white70, size: 18),
                const SizedBox(width: 10),
                Text(
                  statusMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ScanningLaser extends StatefulWidget {
  final Color primaryColor;
  const _ScanningLaser({required this.primaryColor});

  @override
  State<_ScanningLaser> createState() => _ScanningLaserState();
}

class _ScanningLaserState extends State<_ScanningLaser>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          top:
              MediaQuery.of(context).size.height *
              (0.3 + 0.4 * _controller.value),
          left: MediaQuery.of(context).size.width * 0.15,
          right: MediaQuery.of(context).size.width * 0.15,
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              color: widget.primaryColor,
              boxShadow: [
                BoxShadow(
                  color: widget.primaryColor,
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: widget.primaryColor.withValues(alpha: 0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FaceOvalPainter extends CustomPainter {
  final bool isVerified;
  final bool isDark;
  final Color primaryColor;

  _FaceOvalPainter({
    required this.isVerified,
    required this.isDark,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.64)
      ..style = PaintingStyle.fill;

    // Adjust oval size to be more "portrait" friendly
    final ovalWidth = size.width * 0.72;
    final ovalHeight = size.height * 0.48;

    final ovalRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.45), // Shifted up slightly
      width: ovalWidth,
      height: ovalHeight,
    );

    final path = Path.combine(
      PathOperation.difference,
      Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
      Path()..addOval(ovalRect),
    );

    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = isVerified
          ? primaryColor
          : Colors.white.withValues(alpha: 0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    if (isVerified) {
      canvas.drawOval(
        ovalRect.inflate(4),
        Paint()
          ..color = primaryColor.withValues(alpha: 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    canvas.drawOval(ovalRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _FaceOvalPainter oldDelegate) =>
      oldDelegate.isVerified != isVerified || oldDelegate.isDark != isDark;
}

// ignore: unused_element
class _ShutterButton extends StatelessWidget {
  final bool isEnabled;
  final VoidCallback onTap;

  const _ShutterButton({required this.isEnabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
          onTap: isEnabled ? onTap : null,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isEnabled
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.3),
              ),
              child: Icon(
                LucideIcons.camera,
                color: isEnabled ? Colors.black : Colors.black26,
                size: 32,
              ),
            ),
          ),
        )
        .animate(target: isEnabled ? 1 : 0)
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.1, 1.1),
          duration: 200.ms,
        );
  }
}

class _MatchingDialog extends StatefulWidget {
  final File file;
  final VoidCallback onComplete;

  const _MatchingDialog({required this.file, required this.onComplete});

  @override
  State<_MatchingDialog> createState() => _MatchingDialogState();
}

class _MatchingDialogState extends State<_MatchingDialog> {
  double _progress = 0.0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startMatching();
  }

  void _startMatching() {
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        _progress += 0.02;
        if (_progress >= 1.0) {
          _progress = 1.0;
          _timer.cancel();
          Future.delayed(const Duration(milliseconds: 500), widget.onComplete);
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(80),
                  child: Image.file(
                    widget.file,
                    width: 160,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
                ),
                // Scanning beam
                Positioned(
                  top: 160 * _progress,
                  child: Container(
                    width: 160,
                    height: 2,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary,
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'analyzing_identity'.tr,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              'match_found'.trParams({
                'percent': (_progress * 100).toInt().toString(),
              }),
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
