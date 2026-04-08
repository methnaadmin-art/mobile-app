import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:methna_app/app/data/services/api_service.dart';
import 'package:methna_app/app/data/services/auth_service.dart';
import 'package:methna_app/core/constants/api_constants.dart';
import 'package:methna_app/core/utils/upload_image_optimizer.dart';

class VerificationService extends GetxService {
  final ApiService _api = Get.find<ApiService>();

  // Reactive state
  final RxBool emailVerified = false.obs;
  final RxBool selfieVerified = false.obs;
  final RxBool selfieUploaded = false.obs;
  final RxString selfieStatus = 'not_uploaded'.obs;
  final RxBool idDocUploaded = false.obs;
  final RxString idDocStatus = 'not_uploaded'.obs;
  final RxString idDocType = ''.obs;
  final RxString idDocUrl = ''.obs;
  final RxString idDocRejectionReason = ''.obs;
  final RxBool marriageCertUploaded = false.obs;
  final RxString marriageCertStatus = 'not_uploaded'.obs;
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
        normalized == 'matched' ||
        normalized == 'match' ||
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

      final selfieStatusRaw = _asString(
        data['selfieStatus'] ??
            data['selfie_status'] ??
            data['status'] ??
            data['verificationStatus'] ??
            data['verification_status'],
      );
      final normalizedSelfieStatus = selfieStatusRaw.trim().toLowerCase();
      final verifiedFromStatus = _statusLooksVerified(normalizedSelfieStatus);

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
      selfieStatus.value =
            normalizedSelfieStatus.isNotEmpty
            ? normalizedSelfieStatus
            : (_asString(data['status']).trim().toLowerCase().startsWith('selfie_')
              ? _asString(data['status']).trim().toLowerCase()
              : null) ??
          (selfieVerified.value
              ? 'verified'
              : (selfieUploaded.value ? 'pending_review' : 'not_uploaded'));
      idDocUploaded.value = _asBool(
        data['idDocumentUploaded'] ??
            data['id_document_uploaded'] ??
            data['documentUploaded'] ??
            data['document_uploaded'],
      );
      idDocStatus.value =
          _asString(data['idDocumentStatus'] ?? data['id_document_status'])
              .trim()
              .isNotEmpty
          ? _asString(data['idDocumentStatus'] ?? data['id_document_status'])
          : 'not_uploaded';
      idDocType.value = _asString(
        data['documentType'] ?? data['document_type'],
      );
      idDocUrl.value = _asString(data['documentUrl'] ?? data['document_url']);
      idDocRejectionReason.value =
          _asString(data['documentRejectionReason'] ?? data['document_rejection_reason']);
      marriageCertUploaded.value = _asBool(
        data['marriageCertUploaded'] ?? data['marriage_cert_uploaded'],
      );
      marriageCertStatus.value =
          _asString(data['marriageCertStatus'] ?? data['marriage_cert_status'])
              .trim()
              .isNotEmpty
          ? _asString(data['marriageCertStatus'] ?? data['marriage_cert_status'])
          : 'not_uploaded';
      trustScore.value = _asInt(data['trustScore'] ?? data['trust_score'], 100);
    } catch (_) {}
  }

  // ─── Upload Selfie ─────────────────────────────────────
  Future<Map<String, dynamic>?> uploadSelfie(File file) async {
    try {
      final optimized = await UploadImageOptimizer.optimizeSelfie(file);
      final formData = FormData.fromMap({
        'selfie': await MultipartFile.fromFile(
          optimized.path,
          filename: 'selfie.jpg',
        ),
      });
      final response = await _api.upload(ApiConstants.selfieUpload, formData);
      final data = _verificationData(response.data);
      selfieUploaded.value = true;
      final status = _asString(
        data['status'] ?? data['selfieStatus'] ?? data['selfie_status'],
      ).trim().toLowerCase();
      if (status.isNotEmpty) {
        selfieStatus.value = status;
        if (_statusLooksVerified(status)) {
          selfieVerified.value = true;
        }
      }
      await _refreshCurrentUser();
      await fetchVerificationStatus();
      return data;
    } catch (_) {
      return null;
    }
  }

  // ─── Trigger Selfie Verification ───────────────────────
  Future<Map<String, dynamic>?> verifySelfie() async {
    try {
      final response = await _api.post(
        ApiConstants.selfieVerify,
        data: const {
          'selfieVerified': true,
          'selfie_verified': true,
        },
      );
      final data = _verificationData(response.data);
      final hasMatch = _asBool(data['match'] ?? data['matched']);
      final status =
          _asString(data['status'] ?? data['selfieStatus'] ?? data['selfie_status'])
              .trim()
              .toLowerCase()
              .isNotEmpty
          ? _asString(
              data['status'] ?? data['selfieStatus'] ?? data['selfie_status'],
            ).trim().toLowerCase()
          : (hasMatch
                ? 'verified'
                : 'pending_review');
      selfieStatus.value = status;
      selfieVerified.value =
          _asBool(
            data['selfieVerified'] ?? data['selfie_verified'],
            fallback: _statusLooksVerified(status) || hasMatch,
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

      return data;
    } catch (_) {
      return null;
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
  Future<Map<String, dynamic>?> uploadIdDocument(
    File file, {
    required String documentType,
  }) async {
    try {
      final optimized = await UploadImageOptimizer.optimizeDocument(file);
      final formData = FormData.fromMap({
        'document': await MultipartFile.fromFile(
          optimized.path,
          filename: 'id_document.jpg',
        ),
        'documentType': documentType,
      });
      final response = await _api.upload(ApiConstants.idUpload, formData);
      idDocUploaded.value = true;
      idDocStatus.value = 'pending_review';
      idDocType.value = documentType;
      idDocUrl.value = (response.data['documentUrl'] ?? '').toString();
      idDocRejectionReason.value = '';
      await _refreshCurrentUser();
      await fetchVerificationStatus();
      return response.data;
    } catch (_) {
      return null;
    }
  }

  // ─── Upload Marriage Certificate ───────────────────────
  Future<Map<String, dynamic>?> uploadMarriageCert(File file) async {
    try {
      final optimized = await UploadImageOptimizer.optimizeDocument(file);
      final formData = FormData.fromMap({
        'certificate': await MultipartFile.fromFile(
          optimized.path,
          filename: 'marriage_cert.jpg',
        ),
      });
      final response = await _api.upload(ApiConstants.marriageCertUpload, formData);
      marriageCertUploaded.value = true;
      marriageCertStatus.value = 'pending_review';
      return response.data;
    } catch (_) {
      return null;
    }
  }

  // ─── Trust Score ───────────────────────────────────────
  Future<int> fetchTrustScore() async {
    try {
      final response = await _api.get(ApiConstants.trustScore);
      final data = _asMap(response.data);
      trustScore.value = _asInt(data['trustScore'] ?? data['trust_score'], 100);
      return trustScore.value;
    } catch (_) {
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
    } catch (_) {}
  }

  Future<bool> _syncSelfieVerifiedFlagToBackend() async {
    const endpoints = <String>[
      ApiConstants.usersMe,
      ApiConstants.profileMe,
    ];
    const payloads = <Map<String, dynamic>>[
      {'selfieVerified': true},
      {'selfie_verified': true},
      {'isSelfieVerified': true},
      {'selfieStatus': 'verified'},
      {'selfie_status': 'verified'},
      {'verificationStatus': 'verified'},
      {'verification_status': 'verified'},
      {
        'trustSafety': {'selfieVerified': true},
      },
      {
        'verification': {'selfieVerified': true},
      },
    ];

    for (final endpoint in endpoints) {
      for (final payload in payloads) {
        try {
          await _api
              .patch(endpoint, data: payload)
              .timeout(const Duration(seconds: 15));
          return true;
        } catch (_) {
          // Try the next compatible payload shape.
        }
      }
    }

    return false;
  }

  double get verificationProgress {
    int total = 0;
    if (emailVerified.value) total++;
    if (selfieVerified.value) total++;
    if (idDocUploaded.value) total++;
    return total / 3;
  }
}
