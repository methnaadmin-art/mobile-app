import 'package:methna_app/app/data/models/user_model.dart';
import 'package:methna_app/app/routes/app_routes.dart';

bool _hasText(String? value) => value?.trim().isNotEmpty ?? false;

String _normalizedStatusValue(dynamic value) {
  return value?.toString().trim().toLowerCase() ?? '';
}

String? _normalizeRestrictedAccountStatus(String? rawStatus) {
  final status = _normalizedStatusValue(rawStatus);
  switch (status) {
    case 'pending_verification':
    case 'pending verification':
    case 'pending-review':
    case 'pending_review':
    case 'under_review':
    case 'under review':
    case 'under-review':
    case 'in_review':
    case 'in-review':
    case 'review':
      return 'pending_verification';
    case 'rejected':
    case 'verification_rejected':
    case 'declined':
    case 'denied':
    case 'reverify_required':
      return 'rejected';
    case 'banned':
    case 'blacklisted':
    case 'blocked_permanently':
      return 'banned';
    case 'suspended':
    case 'disabled':
    case 'frozen':
      return 'suspended';
    case 'deactivated':
    case 'inactive':
      return 'deactivated';
    case 'closed':
    case 'account_closed':
    case 'account-closed':
      return 'closed';
    default:
      return null;
  }
}

String? _firstNonEmptyStatus(Iterable<dynamic> values) {
  for (final value in values) {
    final normalized = _normalizeRestrictedAccountStatus(value?.toString());
    if (normalized != null) {
      return normalized;
    }
  }
  return null;
}

Map<String, dynamic> _mapFrom(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const <String, dynamic>{};
}

List<Map<String, dynamic>> _candidatePayloadMaps(dynamic raw) {
  final root = _mapFrom(raw);
  if (root.isEmpty) return const <Map<String, dynamic>>[];

  final nestedData = _mapFrom(root['data']);
  final nestedResult = _mapFrom(root['result']);

  return <Map<String, dynamic>>[
    root,
    _mapFrom(root['user']),
    nestedData,
    _mapFrom(nestedData['user']),
    nestedResult,
    _mapFrom(nestedResult['user']),
    _mapFrom(root['message']),
    _mapFrom(nestedData['message']),
    _mapFrom(nestedResult['message']),
  ].where((entry) => entry.isNotEmpty).toList(growable: false);
}

String? _extractFirstStringField(dynamic raw, List<String> keys) {
  final maps = _candidatePayloadMaps(raw);
  for (final entry in maps) {
    for (final key in keys) {
      final text = entry[key]?.toString().trim() ?? '';
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }
  }
  return null;
}

class PostAuthNavigationTarget {
  const PostAuthNavigationTarget({required this.route, this.arguments});

  final String route;
  final Object? arguments;
}

int _approvedPhotoCount(UserModel user) =>
    user.photos?.where((photo) => photo.url.trim().isNotEmpty).length ?? 0;

const List<String> _signupStepRoutes = [
  AppRoutes.signupUsername,
  AppRoutes.signupGender,
  AppRoutes.signupMaritalStatus,
  AppRoutes.signupProfileDetails,
  AppRoutes.signupBirthday,
  AppRoutes.signupEmailVerification,
  AppRoutes.signupFaithReligion,
  AppRoutes.signupHobbies,
  AppRoutes.signupProfession,
  AppRoutes.signupPhotos,
  AppRoutes.signupSelfie,
  AppRoutes.signupLocation,
];

int _stepIndex(String route) => _signupStepRoutes.indexOf(route);

String _routeForStep(int step) {
  final safe = step.clamp(0, _signupStepRoutes.length - 1);
  return _signupStepRoutes[safe];
}

bool _isLegacyCompleteProfile(UserModel user) {
  final profile = user.profile;
  final completion = profile?.profileCompletionPercentage ?? 0;

  if (profile?.isComplete == true || completion >= 50) {
    return true;
  }

  return profile != null &&
      _hasText(profile.gender) &&
      profile.dateOfBirth != null &&
      _approvedPhotoCount(user) >= 2 &&
      (_hasText(user.selfieUrl) || user.selfieVerified);
}

String _resolveProfileRoute(UserModel user) {
  final profile = user.profile;

  if (_isLegacyCompleteProfile(user)) {
    return AppRoutes.main;
  }

  if (profile == null || !_hasText(profile.gender)) {
    return AppRoutes.signupGender;
  }

  if (profile.dateOfBirth == null) {
    return AppRoutes.signupBirthday;
  }

  if (_approvedPhotoCount(user) < 2) {
    return AppRoutes.signupPhotos;
  }

  if (!_hasText(user.selfieUrl) && !user.selfieVerified) {
    return AppRoutes.signupSelfie;
  }

  return AppRoutes.main;
}

String? resolveRestrictedAccountStatus(UserModel? user) {
  if (user == null) return null;
  return _firstNonEmptyStatus([user.status, user.documentRejectionReason]);
}

String? extractRestrictedAccountReason(dynamic raw) {
  return _extractFirstStringField(raw, [
    'reason',
    'statusReason',
    'status_reason',
    'moderationReasonText',
    'moderation_reason_text',
    'supportMessage',
    'support_message',
    'documentRejectionReason',
    'document_rejection_reason',
    'detail',
    'error',
    'message',
  ]);
}

String? extractRestrictedAccountStatus(dynamic raw) {
  final maps = _candidatePayloadMaps(raw);
  final values = <dynamic>[];
  for (final map in maps) {
    values.addAll([
      map['accountStatus'],
      map['account_status'],
      map['userStatus'],
      map['user_status'],
      map['moderationStatus'],
      map['moderation_status'],
      map['status'],
      map['state'],
    ]);
  }

  return _firstNonEmptyStatus(values);
}

String? extractRestrictedAccountSupportMessage(dynamic raw) {
  return _extractFirstStringField(raw, [
    'supportMessage',
    'support_message',
    'moderationReasonText',
    'moderation_reason_text',
  ]);
}

String? extractRestrictedAccountActionRequired(dynamic raw) {
  return _extractFirstStringField(raw, [
    'actionRequired',
    'action_required',
  ]);
}

String? extractRestrictedAccountStaffMessage(dynamic raw) {
  return _extractFirstStringField(raw, [
    'staffMessage',
    'staff_message',
    'internalAdminNote',
    'internal_admin_note',
  ]);
}

String? extractRestrictedAccountExpiresAt(dynamic raw) {
  return _extractFirstStringField(raw, [
    'expiresAt',
    'expires_at',
    'moderationExpiresAt',
    'moderation_expires_at',
  ]);
}

Map<String, dynamic>? buildRestrictedAccountArguments(
  UserModel? user, {
  String? fallbackStatus,
  String? fallbackReason,
  String? fallbackSupportMessage,
  String? fallbackActionRequired,
  String? fallbackStaffMessage,
  String? fallbackExpiresAt,
}) {
  final status =
      resolveRestrictedAccountStatus(user) ??
      _normalizeRestrictedAccountStatus(fallbackStatus);
  if (status == null) {
    return null;
  }

  final reason = (fallbackReason?.trim().isNotEmpty ?? false)
      ? fallbackReason!.trim()
      : (user?.supportMessage?.trim().isNotEmpty ?? false)
      ? user!.supportMessage!.trim()
      : (user?.moderationReasonText?.trim().isNotEmpty ?? false)
      ? user!.moderationReasonText!.trim()
      : (user?.statusReason?.trim().isNotEmpty ?? false)
      ? user!.statusReason!.trim()
      : (user?.documentRejectionReason?.trim().isNotEmpty ?? false)
      ? user!.documentRejectionReason!.trim()
      : null;

  final supportMessage = (fallbackSupportMessage?.trim().isNotEmpty ?? false)
      ? fallbackSupportMessage!.trim()
      : (user?.supportMessage?.trim().isNotEmpty ?? false)
      ? user!.supportMessage!.trim()
      : null;

  final actionRequired = (fallbackActionRequired?.trim().isNotEmpty ?? false)
      ? fallbackActionRequired!.trim()
      : (user?.actionRequired?.trim().isNotEmpty ?? false)
      ? user!.actionRequired!.trim()
      : null;

  final staffMessage = (fallbackStaffMessage?.trim().isNotEmpty ?? false)
      ? fallbackStaffMessage!.trim()
      : (user?.internalAdminNote?.trim().isNotEmpty ?? false)
      ? user!.internalAdminNote!.trim()
      : null;

  final expiresAt = (fallbackExpiresAt?.trim().isNotEmpty ?? false)
      ? fallbackExpiresAt!.trim()
      : user?.moderationExpiresAt?.toIso8601String();

  final args = <String, dynamic>{'status': status};
  if (reason != null) {
    args['reason'] = reason;
  }
  if (supportMessage != null) {
    args['supportMessage'] = supportMessage;
  }
  if (actionRequired != null) {
    args['actionRequired'] = actionRequired;
  }
  if (staffMessage != null) {
    args['staffMessage'] = staffMessage;
  }
  if (expiresAt != null) {
    args['expiresAt'] = expiresAt;
  }
  return args;
}

PostAuthNavigationTarget resolvePostAuthNavigation(
  UserModel user, {
  String? draftRoute,
}) {
  final accountStatusArgs = buildRestrictedAccountArguments(user);
  if (accountStatusArgs != null) {
    final restrictedStatus = _normalizeRestrictedAccountStatus(
      accountStatusArgs['status']?.toString(),
    );

    if (restrictedStatus == 'banned') {
      return PostAuthNavigationTarget(
        route: AppRoutes.contactSupport,
        arguments: accountStatusArgs,
      );
    }

    // Suspended users are allowed in-app and shown a non-blocking banner.
    if (restrictedStatus != 'suspended') {
      return PostAuthNavigationTarget(
        route: AppRoutes.accountStatus,
        arguments: accountStatusArgs,
      );
    }
  }

  if (accountStatusArgs != null) {
    return PostAuthNavigationTarget(
      route: AppRoutes.main,
      arguments: accountStatusArgs,
    );
  }

  final resolvedRoute = _resolveProfileRoute(user);
  if (draftRoute == null || draftRoute.isEmpty) {
    return PostAuthNavigationTarget(route: resolvedRoute);
  }

  final resolvedStep = _stepIndex(resolvedRoute);
  final draftStep = _stepIndex(draftRoute);

  if (resolvedStep == -1 || draftStep == -1) {
    return PostAuthNavigationTarget(route: resolvedRoute);
  }

  final safeDraftStep = draftStep <= 5 ? 6 : draftStep;
  final mergedStep = safeDraftStep > resolvedStep
      ? safeDraftStep
      : resolvedStep;
  return PostAuthNavigationTarget(route: _routeForStep(mergedStep));
}

String resolvePostAuthRoute(UserModel user, {String? draftRoute}) {
  return resolvePostAuthNavigation(user, draftRoute: draftRoute).route;
}
