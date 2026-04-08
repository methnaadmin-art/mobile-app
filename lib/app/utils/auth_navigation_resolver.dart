import 'package:methna_app/app/data/models/user_model.dart';
import 'package:methna_app/app/routes/app_routes.dart';

bool _hasText(String? value) => value?.trim().isNotEmpty ?? false;

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

String resolvePostAuthRoute(UserModel user, {String? draftRoute}) {
  final resolvedRoute = _resolveProfileRoute(user);
  if (draftRoute == null || draftRoute.isEmpty) {
    return resolvedRoute;
  }

  final resolvedStep = _stepIndex(resolvedRoute);
  final draftStep = _stepIndex(draftRoute);

  // Non-signup routes should never be overridden by draft data.
  if (resolvedStep == -1 || draftStep == -1) {
    return resolvedRoute;
  }

  // If the user is authenticated, OTP is already verified; never resume <= OTP.
  final safeDraftStep = draftStep <= 5 ? 6 : draftStep;
  final mergedStep = safeDraftStep > resolvedStep ? safeDraftStep : resolvedStep;
  return _routeForStep(mergedStep);
}
