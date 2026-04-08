import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:methna_app/app/controllers/signup_controller.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/core/widgets/datify_shell.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// ML Kit Selfie Verification Screen
/// Compares face features between uploaded photos and selfie
class MLSelfieVerificationScreen extends StatefulWidget {
  const MLSelfieVerificationScreen({super.key});

  @override
  State<MLSelfieVerificationScreen> createState() =>
      _MLSelfieVerificationScreenState();
}

class _MLSelfieVerificationScreenState
    extends State<MLSelfieVerificationScreen> {
  final SignupController controller = Get.find<SignupController>();
  final ImagePicker _imagePicker = ImagePicker();
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: true,
      enableContours: true,
      enableTracking: true,
      minFaceSize: 0.15,
    ),
  );

  File? _selfieImage;
  bool _isProcessing = false;
  bool _verificationComplete = false;
  double _similarityScore = 0.0;
  String _verificationStatus = '';
  List<Face> _detectedFaces = [];

  @override
  void dispose() {
    _faceDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final cardBg = isDark ? AppColors.cardDark : Colors.white;
    final textColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 76,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16, top: 6, bottom: 6),
          child: DatifyBackButton(onTap: () => Get.back()),
        ),
        title: Text(
          'verify_identity'.tr,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: DatifyBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Instructions
              _InstructionCard(
                title: 'selfie_verification'.tr,
                description: 'selfie_desc'.tr,
                icon: LucideIcons.shieldCheck,
                textColor: textColor,
                cardBg: cardBg,
              ),

              const SizedBox(height: 24),

              // Current photos preview
              if (controller.selectedPhotos.isNotEmpty)
                _PhotosPreview(controller.selectedPhotos.take(3).toList()),

              const SizedBox(height: 24),

              // Selfie capture area
              _SelfieCaptureArea(
                selfieImage: _selfieImage,
                onCapture: _captureSelfie,
                isProcessing: _isProcessing,
                textColor: textColor,
                cardBg: cardBg,
              ),

              const SizedBox(height: 24),

              // Verification results
              if (_verificationComplete)
                _VerificationResults(
                  similarityScore: _similarityScore,
                  status: _verificationStatus,
                  textColor: textColor,
                  cardBg: cardBg,
                ),

              const SizedBox(height: 32),

              // Action buttons
              if (!_verificationComplete)
                _ActionButtons(
                  canContinue: _verificationComplete && _similarityScore > 0.7,
                  onSkip: () => _skipVerification(),
                  onContinue: () => _continueSignup(),
                  textColor: textColor,
                )
              else
                _CompletionActions(
                  similarityScore: _similarityScore,
                  onRetry: () => _retryVerification(),
                  onContinue: () => _continueSignup(),
                  textColor: textColor,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _captureSelfie() async {
    try {
      setState(() => _isProcessing = true);

      final picked = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 72,
        preferredCameraDevice: CameraDevice.front,
      );

      if (picked != null) {
        final selfieFile = File(picked.path);

        // Detect faces in selfie
        final inputImage = InputImage.fromFilePath(picked.path);
        final faces = await _faceDetector.processImage(inputImage);

        if (faces.isEmpty) {
          Get.snackbar('no_face_detected'.tr, 'no_face_desc'.tr);
          setState(() => _isProcessing = false);
          return;
        }

        if (faces.length > 1) {
          Get.snackbar('multiple_faces'.tr, 'multiple_faces_desc'.tr);
          setState(() => _isProcessing = false);
          return;
        }

        // Perform verification with existing photos
        final score = await _performFaceVerification(selfieFile, faces.first);

        setState(() {
          _selfieImage = selfieFile;
          _detectedFaces = faces;
          _similarityScore = score;
          _verificationComplete = true;
          _verificationStatus = _getVerificationStatus(score);
          _isProcessing = false;
        });

        // Set selfie in controller
        controller.setSelfie(selfieFile);
      }
    } catch (e) {
      debugPrint('[MLSelfie] Error: $e');
      Get.snackbar(
        'error'.tr,
        'capture_failed'.trParams({'error': e.toString()}),
      );
      setState(() => _isProcessing = false);
    }
  }

  Future<double> _performFaceVerification(
    File selfieFile,
    Face selfieFace,
  ) async {
    if (controller.selectedPhotos.isEmpty) return 0.0;

    double maxSimilarity = 0.0;

    // Compare selfie with each uploaded photo
    for (int i = 0; i < controller.selectedPhotos.length && i < 3; i++) {
      try {
        final photoFile = controller.selectedPhotos[i];
        final inputImage = InputImage.fromFilePath(photoFile.path);
        final faces = await _faceDetector.processImage(inputImage);

        if (faces.isNotEmpty) {
          final photoFace = faces.first;
          final similarity = _calculateFaceSimilarity(selfieFace, photoFace);
          maxSimilarity = maxSimilarity > similarity
              ? maxSimilarity
              : similarity;
        }
      } catch (e) {
        debugPrint('[MLSelfie] Error processing photo $i: $e');
      }
    }

    return maxSimilarity;
  }

  double _calculateFaceSimilarity(Face face1, Face face2) {
    // Simplified similarity calculation based on face landmarks
    // In production, you'd use more sophisticated algorithms
    double similarity = 0.0;
    int comparisons = 0;

    // Compare face rotation
    if (face1.headEulerAngleY != null && face2.headEulerAngleY != null) {
      final angleDiff = (face1.headEulerAngleY! - face2.headEulerAngleY!).abs();
      similarity += (1.0 - (angleDiff / 90.0)).clamp(0.0, 1.0);
      comparisons++;
    }

    // Compare face size (rough estimate)
    if (face1.boundingBox.width > 0 && face2.boundingBox.width > 0) {
      final sizeRatio = (face1.boundingBox.width / face2.boundingBox.width);
      final sizeSimilarity = 1.0 - (sizeRatio - 1.0).abs();
      similarity += sizeSimilarity.clamp(0.0, 1.0);
      comparisons++;
    }

    // Add more sophisticated comparisons here in production
    // - Face landmark positions
    // - Face contours
    // - Classification results (smiling, eyes open, etc.)

    return comparisons > 0 ? similarity / comparisons : 0.0;
  }

  String _getVerificationStatus(double score) {
    if (score >= 0.8) {
      return 'verification_excellent'.tr;
    } else if (score >= 0.6) {
      return 'verification_good'.tr;
    } else if (score >= 0.4) {
      return 'verification_fair'.tr;
    } else {
      return 'verification_poor'.tr;
    }
  }

  void _skipVerification() {
    controller.setSelfie(File('')); // Empty file to indicate skipped
    _continueSignup();
  }

  void _retryVerification() {
    setState(() {
      _selfieImage = null;
      _verificationComplete = false;
      _similarityScore = 0.0;
      _verificationStatus = '';
      _detectedFaces.clear();
    });
  }

  void _continueSignup() {
    controller.goToNextStep();
  }
}

class _InstructionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color textColor;
  final Color cardBg;

  const _InstructionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.textColor,
    required this.cardBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotosPreview extends StatelessWidget {
  final List<File> photos;

  const _PhotosPreview(this.photos);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'your_photos'.tr,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: photos.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return Container(
                width: 60,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.file(
                    photos[index],
                    fit: BoxFit.cover,
                    cacheWidth: 200, // Very small preview
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SelfieCaptureArea extends StatelessWidget {
  final File? selfieImage;
  final VoidCallback onCapture;
  final bool isProcessing;
  final Color textColor;
  final Color cardBg;

  const _SelfieCaptureArea({
    required this.selfieImage,
    required this.onCapture,
    required this.isProcessing,
    required this.textColor,
    required this.cardBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: selfieImage != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.file(selfieImage!, fit: BoxFit.cover),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.camera,
                  size: 48,
                  color: AppColors.primary.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 16),
                Text(
                  'take_selfie'.tr,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'front_camera_desc'.tr,
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: isProcessing ? null : onCapture,
                  icon: isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(LucideIcons.camera),
                  label: Text(
                    isProcessing ? 'processing'.tr : 'capture_selfie'.tr,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _VerificationResults extends StatelessWidget {
  final double similarityScore;
  final String status;
  final Color textColor;
  final Color cardBg;

  const _VerificationResults({
    required this.similarityScore,
    required this.status,
    required this.textColor,
    required this.cardBg,
  });

  @override
  Widget build(BuildContext context) {
    final scoreColor = similarityScore >= 0.7
        ? AppColors.success
        : similarityScore >= 0.4
        ? AppColors.warning
        : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                similarityScore >= 0.7
                    ? LucideIcons.checkCircle
                    : LucideIcons.alertCircle,
                color: scoreColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'verification_results'.tr,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'match_score'.tr,
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor.withValues(alpha: 0.7),
                    ),
                  ),
                  Text(
                    '${(similarityScore * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: scoreColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: similarityScore,
                backgroundColor: textColor.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            status,
            style: TextStyle(fontSize: 14, color: textColor, height: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final bool canContinue;
  final VoidCallback onSkip;
  final VoidCallback onContinue;
  final Color textColor;

  const _ActionButtons({
    required this.canContinue,
    required this.onSkip,
    required this.onContinue,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: onSkip,
            child: Text(
              'skip_for_now'.tr,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.6),
                fontSize: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: canContinue ? onContinue : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Text(
              'continue_text'.tr,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}

class _CompletionActions extends StatelessWidget {
  final double similarityScore;
  final VoidCallback onRetry;
  final VoidCallback onContinue;
  final Color textColor;

  const _CompletionActions({
    required this.similarityScore,
    required this.onRetry,
    required this.onContinue,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (similarityScore < 0.7)
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onRetry,
              child: Text(
                'retake_selfie'.tr,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        if (similarityScore < 0.7) const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: onContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Text(
              similarityScore >= 0.7
                  ? 'complete_verification'.tr
                  : 'continue_anyway'.tr,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}
