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
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SelfieVerificationScreen extends StatefulWidget {
  const SelfieVerificationScreen({super.key});

  @override
  State<SelfieVerificationScreen> createState() => _SelfieVerificationScreenState();
}

class _SelfieVerificationScreenState extends State<SelfieVerificationScreen> {
  final SignupController controller = Get.find<SignupController>();
  
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  bool _isInitializing = true;
  bool _isProcessing = false;
  bool _faceDetected = false;
  String _statusMessage = 'position_face_oval'.tr;
  
  // Detection states
  bool _isCentered = false;
  bool _isCorrectDistance = false;
  
  @override
  void initState() {
    super.initState();
    controller.syncStep(AppRoutes.signupSelfie);
    _initializeCamera();
    _initializeFaceDetector();
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
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
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
    _cameraController?.startImageStream((CameraImage image) {
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
          
          // Check centering (simplified)
          final centerX = face.boundingBox.center.dx;
          final centerY = face.boundingBox.center.dy;
          
          // These thresholds are approximate for the ResolutionPreset.medium
          _isCentered = centerX > 100 && centerX < 400 && centerY > 100 && centerY < 600;
          
          // Check distance (bounding box width)
          final width = face.boundingBox.width;
          _isCorrectDistance = width > 150 && width < 350;

          if (!_isCentered) {
            _statusMessage = 'center_your_face'.tr;
          } else if (!_isCorrectDistance) {
            _statusMessage = width < 150 ? 'move_closer'.tr : 'move_further_back'.tr;
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
    final inputImageFormat = InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;
    
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotationValue.fromRawValue(sensorOrientation) ?? InputImageRotation.rotation0deg,
        format: inputImageFormat,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  Future<void> _captureSelfie() async {
    if (!_faceDetected || !_isCentered || !_isCorrectDistance) return;

    try {
      // Pause stream to take photo
      await _cameraController?.stopImageStream();
      final image = await _cameraController?.takePicture();
      
      if (image != null) {
        final file = File(image.path);
        
        // Show scanning effect
        if (!mounted) return;
        _showMatchingFlow(file);
      }
    } catch (e) {
      debugPrint('[Selfie] Capture error: $e');
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
          controller.goToNextStep();
        },
      ),
    );
  }

  @override
  void dispose() {
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: primaryColor),
              const SizedBox(height: 24),
              Text('initializing_camera'.tr, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
            ],
          ),
        ),
      );
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.cameraOff, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text('camera_error'.tr, style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 16)),
              const SizedBox(height: 24),
              TextButton(onPressed: _initializeCamera, child: Text('retry'.tr)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Camera Preview ──
          Positioned.fill(
            child: _cameraController!.value.isInitialized 
                ? AspectRatio(
                    aspectRatio: 1 / _cameraController!.value.aspectRatio,
                    child: CameraPreview(_cameraController!),
                  )
                : Container(color: Colors.black),
          ),

          // ── PREMIUM GLASS OVERLAY ──
          Positioned.fill(
            child: CustomPaint(
              painter: _FaceOvalPainter(
                isVerified: _faceDetected && _isCentered && _isCorrectDistance,
                isDark: isDark,
                primaryColor: primaryColor,
              ),
            ),
          ),

          // ── SCANNING LASER (Conditional) ──
          if (_faceDetected && _isCentered && _isCorrectDistance)
            _ScanningLaser(primaryColor: primaryColor),

          // ── UI CONTENT ──
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Premium Glass Header
                _GlassContainer(
                   child: Row(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       const Icon(LucideIcons.shieldCheck, color: Colors.white, size: 16),
                       const SizedBox(width: 8),
                       Text(
                        'identity_verification_header'.tr.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                     ],
                   ),
                ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2),
                
                const Spacer(),
                
                // Real-time Status Guide
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: _StatusGuide(
                    faceDetected: _faceDetected,
                    isCentered: _isCentered,
                    isCorrectDistance: _isCorrectDistance,
                    statusMessage: _statusMessage,
                    primaryColor: primaryColor,
                  ),
                ).animate().fadeIn(duration: 400.ms),
                
                const SizedBox(height: 48),
                
                // Shutter Button
                _ShutterButton(
                  isEnabled: _faceDetected && _isCentered && _isCorrectDistance,
                  onTap: _captureSelfie,
                ).animate().scale(delay: 300.ms),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
          
          // Back Action
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: ClipOval(
              child: Material(
                color: Colors.black.withValues(alpha: 0.3),
                child: IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassContainer extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;

  const _GlassContainer({required this.child, this.blur = 10, this.opacity = 0.2});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}

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
                  const Icon(LucideIcons.checkCircle, color: Colors.white, size: 20)
                else if (faceDetected)
                  const Icon(LucideIcons.maximize, color: Colors.white70, size: 18)
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

class _ScanningLaserState extends State<_ScanningLaser> with SingleTickerProviderStateMixin {
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
          top: MediaQuery.of(context).size.height * (0.3 + 0.4 * _controller.value),
          left: MediaQuery.of(context).size.width * 0.15,
          right: MediaQuery.of(context).size.width * 0.15,
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              color: widget.primaryColor,
              boxShadow: [
                BoxShadow(color: widget.primaryColor, blurRadius: 15, spreadRadius: 2),
                BoxShadow(color: widget.primaryColor.withValues(alpha: 0.5), blurRadius: 30, spreadRadius: 5),
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

  _FaceOvalPainter({required this.isVerified, required this.isDark, required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.75)
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

    // Draw high-end border
    final borderPaint = Paint()
      ..color = isVerified ? AppColors.verified : Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Outer glow for verified state
    if (isVerified) {
      canvas.drawOval(
        ovalRect.inflate(4),
        Paint()
          ..color = AppColors.verified.withValues(alpha: 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    canvas.drawOval(ovalRect, borderPaint);
    
    // Corner brackets for a "tech" feel
    _drawBrackets(canvas, ovalRect, isVerified ? AppColors.verified : Colors.white54);
  }

  void _drawBrackets(Canvas canvas, Rect rect, Color color) {
    final bracketPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final double length = 30;
    
    // Top Left
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.top + length)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.left + length, rect.top),
      bracketPaint,
    );
    
    // Top Right
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - length, rect.top)
        ..lineTo(rect.right, rect.top)
        ..lineTo(rect.right, rect.top + length),
      bracketPaint,
    );
    
    // Bottom Left
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.bottom - length)
        ..lineTo(rect.left, rect.bottom)
        ..lineTo(rect.left + length, rect.bottom),
      bracketPaint,
    );
    
    // Bottom Right
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - length, rect.bottom)
        ..lineTo(rect.right, rect.bottom)
        ..lineTo(rect.right, rect.bottom - length),
      bracketPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _FaceOvalPainter oldDelegate) => 
      oldDelegate.isVerified != isVerified || oldDelegate.isDark != isDark;
}

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
            color: isEnabled ? Colors.white : Colors.white.withValues(alpha: 0.3),
          ),
          child: Icon(
            LucideIcons.camera,
            color: isEnabled ? Colors.black : Colors.black26,
            size: 32,
          ),
        ),
      ),
    ).animate(target: isEnabled ? 1 : 0)
     .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 200.ms);
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
                  child: Image.file(widget.file, width: 160, height: 160, fit: BoxFit.cover),
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
                        BoxShadow(color: AppColors.primary, blurRadius: 10, spreadRadius: 2),
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
              'match_found'.trParams({'percent': (_progress * 100).toInt().toString()}),
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
