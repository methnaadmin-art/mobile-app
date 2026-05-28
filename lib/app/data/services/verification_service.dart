import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:methna_app/app/data/services/api_service.dart';
import 'package:methna_app/app/data/services/auth_service.dart';
import 'package:methna_app/core/constants/api_constants.dart';
import 'package:methna_app/core/utils/upload_image_optimizer.dart';

/// Structured upload result so callers can distinguish success/failure reasons.
class VerificationUploadResult {
  final bool success;
  final String? errorMessage;
  final Map<String, dynamic>? data;

  const VerificationUploadResult._({
    required this.success,
    this.errorMessage,
    this.data,
  });

  factory VerificationUploadResult.ok(Map<String, dynamic> data) =>
      VerificationUploadResult._(success: true, data: data);

  factory VerificationUploadResult.fail(String message) =>
      VerificationUploadResult._(success: false, errorMessage: message);
}

class VerificationService extends GetxService {
  final ApiService _api = Get.find<ApiService>();

  // Reactive state
  final RxBool emailVerified = false.obs;
  final RxBool selfieVerified = false.obs;
  final RxBool selfieUploaded = false.obs;
  final RxString selfieStatus = 'not_uploaded'.obs;
  final RxString selfiePreviewUrl = ''.obs;
  final RxString selfieLocalPath = ''.obs;
  final RxBool idDocUploaded = false.obs;
  final RxString idDocStatus = 'not_uploaded'.obs;
  final RxString idDocType = ''.obs;
  final RxString idDocUrl = ''.obs;
  final RxString idDocRejectionReason = ''.obs;
  final RxBool marriageCertUploaded = false.obs;
  final RxString marriageCertStatus = 'not_uploaded'.obs;
  final RxString marriageCertPreviewUrl = ''.obs;
  final RxString marriageCertLocalPath = ''.obs;
  final RxString marriageCertRejectionReason = ''.obs;
  final RxInt trustScore = 100.obs;

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  bool _asBool(dynamic value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
      }
    }
    return fallback;
  }

  String _asString(dynamic value, [String fallback = '']) {
    if (value is String) return value;
    if (value == null) return fallback;
    return value.toString();
  }

  String _firstNonEmptyString(
    Iterable<dynamic> values, [
    String fallback = '',
  ]) {
    for (final value in values) {
      final text = _asString(value).trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return fallback;
  }

  int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  Map<String, dynamic> _verificationData(dynamic raw) {
    final payload = _asMap(raw);
    final nested = _asMap(payload['data']);
    return nested.isNotEmpty ? nested : payload;
  }

  bool _statusLooksVerified(String status) {
    final normalized = status.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    return normalized == 'verified' ||
        normalized == 'approved' ||
        normalized == 'complete' ||
        normalized == 'completed' ||
        normalized == 'success' ||
        normalized == 'selfie_verified' ||
        normalized == 'selfie-verified';
  }

  bool _isSelfieVerifiedState() {
    final authUser = Get.isRegistered<AuthService>()
        ? Get.find<AuthService>().currentUser.value
        : null;
    return selfieVerified.value ||
        _statusLooksVerified(selfieStatus.value) ||
        (authUser?.selfieVerified ?? false);
  }

  // ─── Fetch Status ───────────────────────────────────────
  Future<void> fetchVerificationStatus() async {
    try {
      final response = await _api.get(ApiConstants.verificationStatus);
      final data = _verificationData(response.data);

      // ── Selfie ──
      // Backend getVerificationStatus returns selfieStatus from
      // verification.selfie.status which uses VerificationStatus enum values
      // (not_submitted, pending, approved, rejected).
      final selfieStatusRaw = _asString(
        data['selfieStatus'] ?? data['selfie_status'],
      );
      final normalizedSelfieStatus = _normalizeStatus(selfieStatusRaw);
      final verifiedFromStatus = _statusLooksVerified(normalizedSelfieStatus);
      final authUser = Get.isRegistered<AuthService>()
          ? Get.find<AuthService>().currentUser.value
          : null;

      emailVerified.value = _asBool(
        data['emailVerified'] ?? data['email_verified'],
      );
      selfieVerified.value = _asBool(
        data['selfieVerified'] ??
            data['selfie_verified'] ??
            data['isSelfieVerified'],
        fallback: verifiedFromStatus,
      );
      selfieUploaded.value = _asBool(
        data['selfieUploaded'] ??
            data['selfie_uploaded'] ??
            data['selfieUrl'] ??
            data['selfie_url'] ??
            selfieVerified.value,
      );
      selfiePreviewUrl.value = _firstNonEmptyString([
        data['selfieUrl'],
        data['selfie_url'],
        authUser?.selfieUrl,
      ]);
      selfieStatus.value = normalizedSelfieStatus.isNotEmpty
          ? normalizedSelfieStatus
          : (selfieVerified.value
                ? 'verified'
                : (selfieUploaded.value ? 'pending_review' : 'not_uploaded'));

      // ── ID Document ──
      idDocUploaded.value = _asBool(
        data['idDocumentUploaded'] ??
            data['id_document_uploaded'] ??
            data['documentUploaded'] ??
            data['document_uploaded'],
      );
      final idDocStatusRaw = _asString(
        data['idDocumentStatus'] ?? data['id_document_status'],
      );
      idDocStatus.value = idDocStatusRaw.trim().isNotEmpty
          ? _normalizeStatus(idDocStatusRaw)
          : 'not_uploaded';
      idDocType.value = _asString(
        data['documentType'] ?? data['document_type'],
      );
      idDocUrl.value = _asString(data['documentUrl'] ?? data['document_url']);
      idDocRejectionReason.value = _asString(
        data['documentRejectionReason'] ?? data['document_rejection_reason'],
      );

      // ── Marriage Certificate ──
      marriageCertUploaded.value = _asBool(
        data['marriageCertUploaded'] ??
            data['marriage_cert_uploaded'] ??
            data['marriageCertUrl'] ??
            data['marriage_cert_url'] ??
            data['certificateUrl'] ??
            data['certificate_url'],
      );
      final marriageCertStatusRaw = _asString(
        data['marriageCertStatus'] ?? data['marriage_cert_status'],
      );
      marriageCertStatus.value = marriageCertStatusRaw.trim().isNotEmpty
          ? _normalizeStatus(marriageCertStatusRaw)
          : 'not_uploaded';
      marriageCertPreviewUrl.value = _firstNonEmptyString([
        data['marriageCertUrl'],
        data['marriage_cert_url'],
        data['certificateUrl'],
        data['certificate_url'],
      ]);
      marriageCertRejectionReason.value = _firstNonEmptyString([
        data['marriageCertRejectionReason'],
        data['marriage_cert_rejection_reason'],
        data['certificateRejectionReason'],
        data['certificate_rejection_reason'],
      ]);
      trustScore.value = _asInt(data['trustScore'] ?? data['trust_score'], 100);
    } catch (e) {
      debugPrint('[VerificationService] fetchVerificationStatus error: $e');
    }
  }

  // ─── Upload Selfie ─────────────────────────────────────
  Future<VerificationUploadResult> uploadSelfie(File file) async {
    try {
      selfieLocalPath.value = file.path;
      debugPrint('[VerificationService] uploadSelfie: starting upload');
      final optimized = await UploadImageOptimizer.optimizeSelfie(file);
      final formData = FormData.fromMap({
        'selfie': await MultipartFile.fromFile(
          optimized.path,
          filename: 'selfie.jpg',
        ),
      });
      final response = await _api.upload(ApiConstants.selfieUpload, formData);
      final data = _verificationData(response.data);
      debugPrint(
        '[VerificationService] uploadSelfie: backend response keys=${data.keys.toList()}',
      );

      selfieUploaded.value = true;
      // Backend uploadSelfie returns { message, selfieUrl, status: 'pending' }
      final status = _normalizeStatus(
        _asString(
          data['status'] ?? data['selfieStatus'] ?? data['selfie_status'],
        ),
      );
      if (status.isNotEmpty) {
        selfieStatus.value = status;
        if (_statusLooksVerified(status)) {
          selfieVerified.value = true;
        }
      }
      selfiePreviewUrl.value = _firstNonEmptyString([
        data['selfieUrl'],
        data['selfie_url'],
        data['url'],
      ], selfiePreviewUrl.value);
      await _refreshCurrentUser();
      await fetchVerificationStatus();
      debugPrint('[VerificationService] uploadSelfie: success, status=$status');
      return VerificationUploadResult.ok(data);
    } on DioException catch (e) {
      selfieLocalPath.value = '';
      final msg = e.response?.data?['message'] ?? e.message ?? 'Network error';
      debugPrint(
        '[VerificationService] uploadSelfie DioException: $msg (status=${e.response?.statusCode})',
      );
      return VerificationUploadResult.fail(msg);
    } catch (e) {
      selfieLocalPath.value = '';
      debugPrint('[VerificationService] uploadSelfie error: $e');
      return VerificationUploadResult.fail('Upload failed: $e');
    }
  }

  // ─── Trigger Selfie Verification ───────────────────────
  Future<VerificationUploadResult> verifySelfie() async {
    try {
      debugPrint('[VerificationService] verifySelfie: starting');
      // Backend POST /trust-safety/selfie-verify expects no body —
      // it reads selfieUrl from the user record.
      final response = await _api.post(ApiConstants.selfieVerify);
      final data = _verificationData(response.data);
      debugPrint(
        '[VerificationService] verifySelfie: response keys=${data.keys.toList()}',
      );

      final statusRaw = _asString(
        data['status'] ?? data['selfieStatus'] ?? data['selfie_status'],
      );
      final status = _normalizeStatus(statusRaw).isNotEmpty
          ? _normalizeStatus(statusRaw)
          : 'pending_review';
      selfieStatus.value = status;
      selfieVerified.value = _asBool(
        data['selfieVerified'] ?? data['selfie_verified'],
        fallback: _statusLooksVerified(status),
      );
      selfieUploaded.value = true;

      if (_statusLooksVerified(status) || selfieVerified.value) {
        await _syncSelfieVerifiedFlagToBackend();
      }

      await _refreshCurrentUser();
      await fetchVerificationStatus();

      if ((_statusLooksVerified(status) || selfieVerified.value) &&
          !_isSelfieVerifiedState()) {
        await _syncSelfieVerifiedFlagToBackend();
        await _refreshCurrentUser();
        await fetchVerificationStatus();
      }

      debugPrint('[VerificationService] verifySelfie: done, status=$status');
      return VerificationUploadResult.ok(data);
    } on DioException catch (e) {
      selfieLocalPath.value = '';
      final msg = e.response?.data?['message'] ?? e.message ?? 'Network error';
      debugPrint('[VerificationService] verifySelfie DioException: $msg');
      return VerificationUploadResult.fail(msg);
    } catch (e) {
      selfieLocalPath.value = '';
      debugPrint('[VerificationService] verifySelfie error: $e');
      return VerificationUploadResult.fail('Verification failed: $e');
    }
  }

  Future<bool> ensureSelfieVerificationPersisted({int attempts = 3}) async {
    for (var attempt = 0; attempt < attempts; attempt++) {
      await fetchVerificationStatus();
      await _refreshCurrentUser();
      if (_isSelfieVerifiedState()) return true;

      await verifySelfie();
      await fetchVerificationStatus();
      await _refreshCurrentUser();
      if (_isSelfieVerifiedState()) return true;

      await _syncSelfieVerifiedFlagToBackend();
      await fetchVerificationStatus();
      await _refreshCurrentUser();
      if (_isSelfieVerifiedState()) return true;

      if (attempt < attempts - 1) {
        await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      }
    }

    return _isSelfieVerifiedState();
  }

  // ─── Upload ID Document ────────────────────────────────
  Future<VerificationUploadResult> uploadIdDocument(
    File file, {
    required String documentType,
  }) async {
    try {
      debugPrint(
        '[VerificationService] uploadIdDocument: starting, type=$documentType',
      );
      final optimized = await UploadImageOptimizer.optimizeDocument(file);
      final formData = FormData.fromMap({
        'document': await MultipartFile.fromFile(
          optimized.path,
          filename: 'id_document.jpg',
        ),
        'documentType': documentType,
      });
      final response = await _api.upload(ApiConstants.idUpload, formData);
      final data = _verificationData(response.data);
      debugPrint(
        '[VerificationService] uploadIdDocument: response keys=${data.keys.toList()}',
      );

      idDocUploaded.value = true;
      idDocStatus.value = 'pending_review';
      idDocType.value = _asString(
        data['documentType'] ?? data['document_type'],
        documentType,
      );
      idDocUrl.value = _asString(data['documentUrl'] ?? data['document_url']);
      idDocRejectionReason.value = '';
      await _refreshCurrentUser();
      await fetchVerificationStatus();
      debugPrint('[VerificationService] uploadIdDocument: success');
      return VerificationUploadResult.ok(data);
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Network error';
      debugPrint('[VerificationService] uploadIdDocument DioException: $msg');
      return VerificationUploadResult.fail(msg);
    } catch (e) {
      debugPrint('[VerificationService] uploadIdDocument error: $e');
      return VerificationUploadResult.fail('Upload failed: $e');
    }
  }

  // ─── Upload Marriage Certificate ───────────────────────
  Future<VerificationUploadResult> uploadMarriageCert(File file) async {
    try {
      marriageCertLocalPath.value = file.path;
      debugPrint('[VerificationService] uploadMarriageCert: starting');
      final optimized = await UploadImageOptimizer.optimizeDocument(file);
      final formData = FormData.fromMap({
        'certificate': await MultipartFile.fromFile(
          optimized.path,
          filename: 'marriage_cert.jpg',
        ),
      });
      final response = await _api.upload(
        ApiConstants.marriageCertUpload,
        formData,
      );
      final data = _verificationData(response.data);
      debugPrint(
        '[VerificationService] uploadMarriageCert: response keys=${data.keys.toList()}',
      );

      marriageCertUploaded.value = true;
      marriageCertStatus.value = 'pending_review';
      marriageCertPreviewUrl.value = _firstNonEmptyString([
        data['marriageCertUrl'],
        data['marriage_cert_url'],
        data['certificateUrl'],
        data['certificate_url'],
        data['documentUrl'],
        data['document_url'],
      ], marriageCertPreviewUrl.value);
      marriageCertRejectionReason.value = '';
      await _refreshCurrentUser();
      await fetchVerificationStatus();
      debugPrint('[VerificationService] uploadMarriageCert: success');
      return VerificationUploadResult.ok(data);
    } on DioException catch (e) {
      marriageCertLocalPath.value = '';
      final msg = e.response?.data?['message'] ?? e.message ?? 'Network error';
      debugPrint('[VerificationService] uploadMarriageCert DioException: $msg');
      return VerificationUploadResult.fail(msg);
    } catch (e) {
      marriageCertLocalPath.value = '';
      debugPrint('[VerificationService] uploadMarriageCert error: $e');
      return VerificationUploadResult.fail('Upload failed: $e');
    }
  }

  // ─── Trust Score ───────────────────────────────────────
  Future<int> fetchTrustScore() async {
    try {
      final response = await _api.get(ApiConstants.trustScore);
      final data = _asMap(response.data);
      trustScore.value = _asInt(data['trustScore'] ?? data['trust_score'], 100);
      return trustScore.value;
    } catch (e) {
      debugPrint('[VerificationService] fetchTrustScore error: $e');
      return trustScore.value;
    }
  }

  // ─── Computed ──────────────────────────────────────────
  bool get isFullyVerified => emailVerified.value && selfieVerified.value;
  bool get identityVerified => idDocStatus.value == 'verified';
  bool get needsIdentityReupload => idDocStatus.value == 'reverify_required';

  Future<void> _refreshCurrentUser() async {
    try {
      await Get.find<AuthService>().fetchMe();
    } catch (e) {
      debugPrint('[VerificationService] _refreshCurrentUser error: $e');
    }
  }

  /// Sync selfieVerified=true to the backend user record.
  /// The backend accepts PATCH /users/me with { selfieVerified: true }.
  Future<bool> _syncSelfieVerifiedFlagToBackend() async {
    try {
      await _api
          .patch(ApiConstants.usersMe, data: {'selfieVerified': true})
          .timeout(const Duration(seconds: 10));
      debugPrint(
        '[VerificationService] _syncSelfieVerifiedFlagToBackend: success',
      );
      return true;
    } catch (e) {
      debugPrint(
        '[VerificationService] _syncSelfieVerifiedFlagToBackend failed: $e',
      );
      return false;
    }
  }

  double get verificationProgress {
    int total = 0;
    if (emailVerified.value) total++;
    if (selfieVerified.value) total++;
    if (idDocUploaded.value) total++;
    return total / 3;
  }

  /// Normalize backend VerificationStatus enum values to the
  /// canonical forms used by the UI.
  /// Backend sends: not_submitted, pending, approved, rejected
  /// UI expects:     not_uploaded,  pending_review, verified, rejected
  String _normalizeStatus(String raw) {
    final s = raw.trim().toLowerCase();
    switch (s) {
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
      case 'not_submitted':
      case 'not_uploaded':
      case 'not_started':
      case '':
        return 'not_uploaded';
      default:
        return s;
    }
  }
}
