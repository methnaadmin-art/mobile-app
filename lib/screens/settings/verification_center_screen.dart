import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:methna_app/app/data/models/user_model.dart';
import 'package:methna_app/app/data/services/auth_service.dart';
import 'package:methna_app/app/data/services/monetization_service.dart';
import 'package:methna_app/app/data/services/storage_service.dart';
import 'package:methna_app/app/data/services/verification_service.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/core/utils/helpers.dart';
import 'package:methna_app/core/widgets/settings_flow.dart';

class VerificationCenterScreen extends StatefulWidget {
  const VerificationCenterScreen({super.key});

  @override
  State<VerificationCenterScreen> createState() =>
      _VerificationCenterScreenState();
}

class _VerificationCenterScreenState extends State<VerificationCenterScreen> {
  final VerificationService verification = Get.find<VerificationService>();
  final MonetizationService monetization = Get.find<MonetizationService>();
  final AuthService auth = Get.find<AuthService>();
  final StorageService storage = Get.find<StorageService>();
  final ImagePicker _picker = ImagePicker();

  bool _busy = false;
  bool _startingBackgroundCheck = false;
  String _backgroundStatus = 'not_started';

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    await verification.fetchVerificationStatus();
    await verification.fetchTrustScore();
    final background = await monetization.fetchBackgroundCheckStatus();
    final status = _normalizeBackgroundStatus(
      background?['status'] ??
          background?['state'] ??
          background?['verificationStatus'] ??
          background?['result'],
    );

    await _syncCurrentUserTrustAndBackground(status);

    if (!mounted) return;
    setState(() {
      _backgroundStatus = status;
    });
  }

  Future<ImageSource?> _pickSource() {
    return showSettingsChoiceSheet<ImageSource>(
      context: context,
      title: 'choose_source'.tr,
      options: [
        SettingsSheetOption(value: ImageSource.camera, title: 'take_photo'.tr),
        SettingsSheetOption(
          value: ImageSource.gallery,
          title: 'choose_from_gallery'.tr,
        ),
      ],
    );
  }

  Future<String?> _pickDocumentType() {
    return showSettingsChoiceSheet<String>(
      context: context,
      title: 'choose_id_document'.tr,
      options: [
        SettingsSheetOption(value: 'passport', title: 'passport'.tr),
        SettingsSheetOption(value: 'national_id', title: 'national_id_doc'.tr),
        SettingsSheetOption(
          value: 'driving_license',
          title: 'drivers_license'.tr,
        ),
      ],
    );
  }

  Future<void> _pickAndUpload({
    required Future<VerificationUploadResult> Function(File file) upload,
    required String successMessage,
    Future<void> Function()? afterUpload,
    bool cameraOnly = false,
  }) async {
    if (_busy) return;
    final source = cameraOnly ? ImageSource.camera : await _pickSource();
    if (source == null) return;

    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 78,
      maxWidth: 1280,
    );
    if (picked == null) return;

    setState(() => _busy = true);
    try {
      final result = await upload(File(picked.path));
      if (!result.success) {
        Helpers.showSnackbar(
          message: result.errorMessage ?? 'upload_failed'.tr,
          isError: true,
        );
        return;
      }
      if (afterUpload != null) {
        await afterUpload();
      }
      Helpers.showSnackbar(message: successMessage);
      await _refreshAll();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _pickAndUploadIdentityDocument() async {
    if (_busy) return;
    if (_normalizedVerificationStatus(verification.idDocStatus.value) ==
        'verified') {
      Helpers.showSnackbar(message: 'identity_verified'.tr);
      return;
    }

    final documentType = await _pickDocumentType();
    if (documentType == null) return;

    final source = await _pickSource();
    if (source == null) return;

    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1800,
    );
    if (picked == null) return;

    setState(() => _busy = true);
    try {
      final result = await verification.uploadIdDocument(
        File(picked.path),
        documentType: documentType,
      );
      if (!result.success) {
        Helpers.showSnackbar(
          message: result.errorMessage ?? 'identity_upload_failed'.tr,
          isError: true,
        );
        return;
      }

      Helpers.showSnackbar(message: 'identity_uploaded_review'.tr);
      await _refreshAll();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _startBackgroundCheck() async {
    if (_startingBackgroundCheck) return;
    if (!_canStartBackgroundCheck(_backgroundStatus)) {
      Helpers.showSnackbar(message: 'background_check_wait_status'.tr);
      return;
    }

    setState(() => _startingBackgroundCheck = true);
    try {
      final user = auth.currentUser.value;
      final fullName = '${user?.firstName ?? ''} ${user?.lastName ?? ''}'
          .trim();
      final dob = user?.profile?.dateOfBirth?.toIso8601String().split('T')[0];

      if (fullName.isEmpty || dob == null || dob.isEmpty) {
        Helpers.showSnackbar(
          message: 'complete_profile_first'.tr,
          isError: true,
        );
        return;
      }

      final result = await monetization.initiateBackgroundCheck(
        fullName: fullName,
        dateOfBirth: dob,
        consentGiven: true,
      );
      if (result == null) {
        Helpers.showSnackbar(message: 'bg_check_failed'.tr, isError: true);
        return;
      }
      Helpers.showSnackbar(message: 'bg_check_started'.tr);
      await _refreshAll();
    } finally {
      if (mounted) {
        setState(() => _startingBackgroundCheck = false);
      }
    }
  }

  String _normalizeBackgroundStatus(dynamic value) {
    final status = value?.toString().trim().toLowerCase() ?? '';
    switch (status) {
      case 'approved':
      case 'clear':
      case 'cleared':
      case 'passed':
      case 'verified':
        return 'verified';
      case 'pending':
      case 'processing':
      case 'submitted':
      case 'in_review':
      case 'in-review':
      case 'in_progress':
      case 'under_review':
      case 'requested':
        return 'in_review';
      case 'declined':
      case 'rejected':
      case 'denied':
        return 'rejected';
      case 'failed':
      case 'error':
        return 'failed';
      case 'not_started':
      case 'not-started':
      case 'none':
      case '':
        return 'not_started';
      default:
        return status;
    }
  }

  bool _canStartBackgroundCheck(String status) {
    final normalized = _normalizeBackgroundStatus(status);
    return normalized == 'not_started' ||
        normalized == 'failed' ||
        normalized == 'rejected';
  }

  String _backgroundStatusLabel(String status) {
    switch (_normalizeBackgroundStatus(status)) {
      case 'verified':
        return 'background_status_verified'.tr;
      case 'in_review':
        return 'background_status_in_review'.tr;
      case 'rejected':
        return 'background_status_rejected'.tr;
      case 'failed':
        return 'background_status_failed'.tr;
      case 'not_started':
        return 'background_status_not_started'.tr;
      default:
        return _humanizeStatus(status);
    }
  }

  Future<void> _syncCurrentUserTrustAndBackground(String status) async {
    final current = auth.currentUser.value;
    if (current == null) return;

    final normalizedCurrent = _normalizeBackgroundStatus(
      current.backgroundCheckStatus,
    );
    final normalizedNext = _normalizeBackgroundStatus(status);
    final nextTrustScore = verification.trustScore.value;

    if (normalizedCurrent == normalizedNext &&
        current.trustScore == nextTrustScore) {
      return;
    }

    final updatedJson = Map<String, dynamic>.from(current.toJson())
      ..['backgroundCheckStatus'] = normalizedNext
      ..['trustScore'] = nextTrustScore;

    if (normalizedNext == 'verified') {
      updatedJson['backgroundCheckedAt'] = DateTime.now().toIso8601String();
    }

    final updatedUser = UserModel.fromJson(updatedJson);
    auth.currentUser.value = updatedUser;
    await storage.saveUser(updatedUser.toJson());
  }

  String _humanizeStatus(String value) {
    if (value.isEmpty) return 'not_started'.tr;
    return value
        .split('_')
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  Color _identityStatusColor(String value) {
    switch (value) {
      case 'verified':
        return const Color(0xFF12805C);
      case 'pending_review':
        return const Color(0xFF6E3DFB);
      case 'reverify_required':
        return const Color(0xFF4F26D9);
      default:
        return const Color(0xFF5F5A68);
    }
  }

  String _identityHeadline() {
    switch (verification.idDocStatus.value) {
      case 'verified':
        return 'identity_verified'.tr;
      case 'pending_review':
        return 'identity_review_in_progress'.tr;
      case 'reverify_required':
        return 'reupload_your_identity'.tr;
      default:
        return 'identity_not_verified'.tr;
    }
  }

  String _identitySupportingText() {
    final reason = verification.idDocRejectionReason.value.trim();
    switch (verification.idDocStatus.value) {
      case 'verified':
        return 'id_approved_desc'.tr;
      case 'pending_review':
        return 'id_pending_desc'.tr;
      case 'reverify_required':
        return reason.isNotEmpty ? reason : 'id_reverify_desc'.tr;
      default:
        return 'id_not_verified_desc'.tr;
    }
  }

  String _identityActionLabel() {
    switch (verification.idDocStatus.value) {
      case 'verified':
        return '';
      case 'pending_review':
        return 'replace_document'.tr;
      case 'reverify_required':
        return 'reupload_identity'.tr;
      default:
        return 'upload_identity_doc'.tr;
    }
  }

  String _prettyDocumentType(String value) {
    if (value.isEmpty) return 'identity_document'.tr;
    return value
        .split('_')
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  String _normalizedVerificationStatus(String value) {
    final status = value.trim().toLowerCase();
    switch (status) {
      case 'approved':
      case 'verified':
      case 'complete':
      case 'completed':
      case 'success':
        return 'verified';
      case 'pending':
      case 'pending_review':
      case 'under_review':
      case 'in_review':
      case 'submitted':
      case 'processing':
        return 'pending_review';
      case 'rejected':
      case 'declined':
      case 'denied':
        return 'rejected';
      case 'reverify_required':
        return 'reverify_required';
      case '':
      case 'not_uploaded':
      case 'not_started':
        return 'not_uploaded';
      default:
        return status;
    }
  }

  Color _verificationStatusColor(String value) {
    switch (_normalizedVerificationStatus(value)) {
      case 'verified':
        return const Color(0xFF12805C);
      case 'pending_review':
        return const Color(0xFF6E3DFB);
      case 'rejected':
      case 'reverify_required':
        return const Color(0xFF4F26D9);
      default:
        return const Color(0xFF5F5A68);
    }
  }

  String _verificationStatusLabel(String value) {
    switch (_normalizedVerificationStatus(value)) {
      case 'verified':
        return 'Verified';
      case 'pending_review':
        return 'Pending review';
      case 'rejected':
        return 'Rejected';
      case 'reverify_required':
        return 'Re-upload required';
      default:
        return 'Not uploaded';
    }
  }

  String _selfieSupportingText() {
    switch (_normalizedVerificationStatus(verification.selfieStatus.value)) {
      case 'verified':
        return 'Your uploaded selfie has been approved.';
      case 'pending_review':
        return 'Your uploaded selfie is waiting for review.';
      case 'rejected':
      case 'reverify_required':
        return 'Please upload a clearer selfie so the team can verify your identity.';
      default:
        return 'Upload a clear selfie so reviewers can confirm your identity.';
    }
  }

  String _maritalSupportingText() {
    final rejectionReason = verification.marriageCertRejectionReason.value
        .trim();
    switch (_normalizedVerificationStatus(
      verification.marriageCertStatus.value,
    )) {
      case 'verified':
        return 'Your marital status document has been approved.';
      case 'pending_review':
        return 'Your marital status document is waiting for review.';
      case 'rejected':
      case 'reverify_required':
        return rejectionReason.isNotEmpty
            ? rejectionReason
            : 'Please upload a clearer marital status document.';
      default:
        return 'Upload your marital status document for review.';
    }
  }

  Widget _buildVerificationPreview({
    required String localPath,
    required String remoteUrl,
    required IconData placeholderIcon,
    required String placeholderLabel,
  }) {
    final hasLocal =
        localPath.trim().isNotEmpty && File(localPath).existsSync();
    final hasRemote = remoteUrl.trim().isNotEmpty;

    if (hasLocal) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.file(
          File(localPath),
          width: 112,
          height: 112,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildPreviewPlaceholder(
            placeholderIcon: placeholderIcon,
            placeholderLabel: placeholderLabel,
          ),
        ),
      );
    }

    if (hasRemote) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.network(
          remoteUrl,
          width: 112,
          height: 112,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildPreviewPlaceholder(
            placeholderIcon: placeholderIcon,
            placeholderLabel: placeholderLabel,
          ),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return SizedBox(
              width: 112,
              height: 112,
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
        ),
      );
    }

    return _buildPreviewPlaceholder(
      placeholderIcon: placeholderIcon,
      placeholderLabel: placeholderLabel,
    );
  }

  Widget _buildPreviewPlaceholder({
    required IconData placeholderIcon,
    required String placeholderLabel,
  }) {
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(placeholderIcon, color: AppColors.primary, size: 30),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              placeholderLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF5F5A68),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard({
    required String title,
    required String status,
    required String supportingText,
    required String localPath,
    required String remoteUrl,
    required String actionLabel,
    required VoidCallback? onPressed,
    required IconData placeholderIcon,
    required String placeholderLabel,
  }) {
    final statusColor = _verificationStatusColor(status);
    final isVerified = _normalizedVerificationStatus(status) == 'verified';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16131F) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: statusColor.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVerificationPreview(
            localPath: localPath,
            remoteUrl: remoteUrl,
            placeholderIcon: placeholderIcon,
            placeholderLabel: placeholderLabel,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _verificationStatusLabel(status),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  supportingText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    height: 1.45,
                  ),
                ),
                if (!isVerified) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onPressed,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(actionLabel),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSimplePageScaffold(
      title: 'verification_center'.tr,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refreshAll,
        child: Obx(
          () => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            children: [
              Obx(
                () => Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF16131F)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: _identityStatusColor(
                        verification.idDocStatus.value,
                      ).withValues(alpha: 0.22),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _identityStatusColor(
                                verification.idDocStatus.value,
                              ).withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              verification.idDocStatus.value == 'verified'
                                  ? Icons.verified_rounded
                                  : verification.idDocStatus.value ==
                                        'reverify_required'
                                  ? Icons.assignment_late_rounded
                                  : Icons.badge_rounded,
                              color: _identityStatusColor(
                                verification.idDocStatus.value,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _identityHeadline(),
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _humanizeStatus(
                                    verification.idDocStatus.value,
                                  ),
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: _identityStatusColor(
                                          verification.idDocStatus.value,
                                        ),
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        _identitySupportingText(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                          height: 1.45,
                        ),
                      ),
                      if (verification.idDocType.value.trim().isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Selected document: ${_prettyDocumentType(verification.idDocType.value)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                      if (_normalizedVerificationStatus(
                            verification.idDocStatus.value,
                          ) !=
                          'verified') ...[
                        const SizedBox(height: AppSpacing.lg),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _busy
                                ? null
                                : _pickAndUploadIdentityDocument,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(_identityActionLabel()),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Obx(
                () => _buildVerificationCard(
                  title: 'selfie_verification'.tr,
                  status: verification.selfieStatus.value,
                  supportingText: _selfieSupportingText(),
                  localPath: verification.selfieLocalPath.value,
                  remoteUrl: verification.selfiePreviewUrl.value,
                  actionLabel: verification.selfieUploaded.value
                      ? 'Replace selfie'
                      : 'Upload selfie',
                  onPressed: _busy
                      ? null
                      : () => _pickAndUpload(
                          upload: verification.uploadSelfie,
                          successMessage: 'selfie_uploaded'.tr,
                          cameraOnly: true,
                          afterUpload: () async {
                            await verification.verifySelfie();
                          },
                        ),
                  placeholderIcon: Icons.face_retouching_natural_rounded,
                  placeholderLabel: 'No selfie uploaded yet',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Obx(
                () => _buildVerificationCard(
                  title: 'marital_status_doc'.tr,
                  status: verification.marriageCertStatus.value,
                  supportingText: _maritalSupportingText(),
                  localPath: verification.marriageCertLocalPath.value,
                  remoteUrl: verification.marriageCertPreviewUrl.value,
                  actionLabel: verification.marriageCertUploaded.value
                      ? 'Replace document'
                      : 'Upload document',
                  onPressed: _busy
                      ? null
                      : () => _pickAndUpload(
                          upload: verification.uploadMarriageCert,
                          successMessage: 'marriage_cert_uploaded'.tr,
                        ),
                  placeholderIcon: Icons.description_rounded,
                  placeholderLabel: 'No document uploaded yet',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SettingsPlainListCard(
                children: [
                  SettingsPlainTile(
                    title: 'trust_score'.tr,
                    value: '${verification.trustScore.value}',
                  ),
                  SettingsPlainTile(
                    title: 'background_check'.tr,
                    value: _backgroundStatusLabel(_backgroundStatus),
                    onTap: _startingBackgroundCheck
                        ? null
                        : () async {
                            if (!_canStartBackgroundCheck(_backgroundStatus)) {
                              Helpers.showSnackbar(
                                message: 'background_check_wait_status'.tr,
                              );
                              return;
                            }
                            await _startBackgroundCheck();
                          },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SettingsSectionLabel(text: 'notes'.tr),
              SettingsPlainListCard(
                children: [
                  SettingsPlainTile(title: 'identity_approval_note'.tr),
                  SettingsPlainTile(
                    title: verification.idDocStatus.value == 'reverify_required'
                        ? 'reverify_note'.tr
                        : 'status_update_note'.tr,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
