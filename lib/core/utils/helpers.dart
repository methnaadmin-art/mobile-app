import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/core/widgets/animated_icons.dart';
import 'package:methna_app/core/widgets/login_success_animation.dart';

class Helpers {
  Helpers._();

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const <String, dynamic>{};
  }

  static String? _firstNonEmptyText(Iterable<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }
    return null;
  }

  static String _humanizeActionRequired(String? raw) {
    final normalized = (raw ?? '').trim().toUpperCase();
    if (normalized.isEmpty) return '';

    switch (normalized) {
      case 'REUPLOAD_IDENTITY_DOCUMENT':
        return 'Upload your identity document again.';
      case 'RETAKE_SELFIE':
        return 'Retake your selfie verification.';
      case 'UPLOAD_MARRIAGE_DOCUMENT':
        return 'Upload your marital status document.';
      case 'VERIFY_PHONE':
        return 'Verify your phone number.';
      case 'VERIFY_EMAIL':
        return 'Verify your email address.';
      case 'CONTACT_SUPPORT':
        return 'Contact support for assistance.';
      case 'WAIT_FOR_REVIEW':
        return 'Wait for the moderation review to complete.';
      default:
        return normalized
            .toLowerCase()
            .split('_')
            .map(
              (part) => part.isEmpty
                  ? part
                  : '${part[0].toUpperCase()}${part.substring(1)}',
            )
            .join(' ');
    }
  }

  /// Get localized back icon (chevrons flip in RTL)
  static IconData get backIcon => Get.locale?.languageCode == 'ar'
      ? LucideIcons.chevronRight
      : LucideIcons.chevronLeft;

  /// Get localized forward icon
  static IconData get nextIcon => Get.locale?.languageCode == 'ar'
      ? LucideIcons.chevronLeft
      : LucideIcons.chevronRight;

  /// Extract a user-friendly error message from any exception (especially Dio)
  static String extractErrorMessage(dynamic e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'connection_timeout'.tr;
        case DioExceptionType.connectionError:
          return 'no_internet'.tr;
        case DioExceptionType.badResponse:
          final data = e.response?.data;
          final map = _asMap(data);
          final messageMap = _asMap(map['message']);
          final errorDetail = _firstNonEmptyText([
            map['detail'],
            map['error'],
            map['reason'],
            map['statusReason'],
            map['status_reason'],
            map['supportMessage'],
            map['support_message'],
            map['moderationReasonText'],
            map['moderation_reason_text'],
            messageMap['detail'],
            messageMap['error'],
            messageMap['reason'],
            messageMap['statusReason'],
            messageMap['status_reason'],
            messageMap['supportMessage'],
            messageMap['support_message'],
            messageMap['moderationReasonText'],
            messageMap['moderation_reason_text'],
          ]);

          final actionRequired = _firstNonEmptyText([
            map['actionRequired'],
            map['action_required'],
            messageMap['actionRequired'],
            messageMap['action_required'],
          ]);
          final actionText = _humanizeActionRequired(actionRequired);

          final rawMessage = map['message'];
          if (rawMessage is List && rawMessage.isNotEmpty) {
            return rawMessage.join(', ');
          }
          if (rawMessage is String && rawMessage.trim().isNotEmpty) {
            return rawMessage.trim();
          }

          if (messageMap.isNotEmpty) {
            final nestedMessage = _firstNonEmptyText([
              messageMap['message'],
              messageMap['reason'],
              messageMap['supportMessage'],
              messageMap['support_message'],
              messageMap['moderationReasonText'],
              messageMap['moderation_reason_text'],
            ]);
            if (nestedMessage != null && nestedMessage.isNotEmpty) {
              if (actionText.isNotEmpty && !nestedMessage.contains(actionText)) {
                return '$nestedMessage Next step: $actionText';
              }
              return nestedMessage;
            }
          }

          if (errorDetail != null && errorDetail.isNotEmpty) {
            if (actionText.isNotEmpty && !errorDetail.contains(actionText)) {
              return '$errorDetail Next step: $actionText';
            }
            return errorDetail;
          }

          final status = e.response?.statusCode ?? 0;
          if (status == 401) {
            return 'invalid_credentials'.tr;
          }
          if (status == 403) {
            if (actionText.isNotEmpty) {
              return 'Access restricted. Next step: $actionText';
            }
            return 'access_denied'.tr;
          }
          if (status == 404) {
            return 'not_found'.tr;
          }
          if (status == 409) {
            return data?['message']?.toString() ?? 'conflict_error'.tr;
          }
          if (status == 429) {
            return 'too_many_requests'.tr;
          }
          if (status >= 500) {
            return 'server_error'.tr;
          }
          return 'something_went_wrong'.tr;
        case DioExceptionType.cancel:
          return 'request_cancelled'.tr;
        default:
          return 'no_internet'.tr;
      }
    }
    // For non-Dio exceptions, show the actual message in debug builds
    if (e is Exception) {
      final msg = e.toString();
      debugPrint('[extractErrorMessage] Non-Dio error: $msg');
    }
    return 'something_went_wrong'.tr;
  }

  /// Format date to readable string
  static String formatDate(DateTime? date, {String pattern = 'MMM dd, yyyy'}) {
    if (date == null) return '';
    return intl.DateFormat(pattern).format(date);
  }

  /// Format time ago (e.g. "2h ago", "Just now")
  static String timeAgo(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) {
      return 'just_now'.tr;
    }
    if (diff.inMinutes < 60) {
      return 'minutes_ago'.trParams({'count': '${diff.inMinutes}'});
    }
    if (diff.inHours < 24) {
      return 'hours_ago'.trParams({'count': '${diff.inHours}'});
    }
    if (diff.inDays < 7) {
      return 'days_ago'.trParams({'count': '${diff.inDays}'});
    }
    if (diff.inDays < 30) {
      return 'weeks_ago'.trParams({'count': '${(diff.inDays / 7).floor()}'});
    }
    return formatDate(date);
  }

  /// Calculate age from date of birth
  static int calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  /// Format distance (e.g. "2.5 km")
  static String formatDistance(double? km) {
    if (km == null) {
      return '';
    }
    if (km < 1) {
      return 'meters_away'.trParams({'count': '${(km * 1000).round()}'});
    }
    return 'km_away'.trParams({'distance': km.toStringAsFixed(1)});
  }

  /// Show snackbar
  static void showSnackbar({
    required String message,
    String? title,
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (Get.context == null) {
      debugPrint(
        '[SNACKBAR SKIPPED - NO CONTEXT] ${title ?? (isError ? "Error" : "Success")}: $message',
      );
      return;
    }
    Get.snackbar(
      '',
      '',
      titleText: Text(
        title ?? (isError ? 'error'.tr : 'success'.tr),
        style: TextStyle(
          color: isError ? AppColors.primaryDark : AppColors.secondary,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
      messageText: Text(
        message,
        style: TextStyle(
          color: isError ? AppColors.primaryDark : AppColors.secondary,
          fontSize: 14,
          height: 1.3,
        ),
      ),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primarySurface,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: duration,
      icon: Icon(
        isError ? LucideIcons.alertCircle : LucideIcons.checkCircle2,
        color: isError ? AppColors.primaryDark : AppColors.primary,
      ),
    );
  }

  /// Show loading dialog
  static void showLoading({String? message}) {
    if (Get.context == null) {
      debugPrint('[LOADING SKIPPED - NO CONTEXT] $message');
      return;
    }
    Get.dialog(
      PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: Get.isDarkMode ? const Color(0xFF1E1E2E) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              message ?? 'loading'.tr,
              style: Get.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Hide loading dialog
  static void hideLoading() {
    if (Get.isDialogOpen ?? false) Get.back();
  }

  /// Show beautiful Lottie animated dialog
  static void showLottieDialog({
    required String lottieAsset,
    required String title,
    required String message,
    String? confirmText,
    VoidCallback? onConfirm,
    bool showCancelButton = false,
    bool barrierDismissible = true,
  }) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Get.isDarkMode ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 72,
                width: 72,
                decoration: BoxDecoration(
                  color: Get.theme.primaryColor.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  lottieAsset.toLowerCase().contains('error')
                      ? LucideIcons.alertCircle
                      : LucideIcons.info,
                  color: Get.theme.primaryColor,
                  size: 34,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Get.isDarkMode
                      ? Colors.white
                      : const Color(0xFF1A1626),
                ),
              ),
              const SizedBox(height: 12),

              // Message
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Get.isDarkMode
                      ? Colors.white.withValues(alpha: 0.8)
                      : const Color(0xFF6B6478),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              // Action Buttons
              if (showCancelButton)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Get.isDarkMode
                              ? Colors.white
                              : const Color(0xFF1A1626),
                          side: BorderSide(color: Get.theme.dividerColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'cancel'.tr,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Get.back();
                          if (onConfirm != null) onConfirm();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Get.theme.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          confirmText ?? 'ok'.tr,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Get.back();
                      if (onConfirm != null) onConfirm();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Get.theme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Text(
                      confirmText ?? 'ok'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      barrierDismissible: barrierDismissible,
    );
  }

  static void showLoginSuccessDialog({
    required String title,
    required String message,
    bool barrierDismissible = false,
  }) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 26),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: Get.isDarkMode
                  ? const [AppColors.secondaryDark, AppColors.canvasDark]
                  : const [AppColors.primarySurface, AppColors.surfaceLight],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Get.isDarkMode
                  ? AppColors.primaryDark
                  : AppColors.borderLight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.primaryDark.withValues(alpha: 0.18),
                  ),
                ),
                child: Text(
                  'Secure sign in',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Get.isDarkMode
                        ? AppColors.textPrimaryDark
                        : AppColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const LoginSuccessAnimation(),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Get.isDarkMode
                      ? Colors.white
                      : const Color(0xFF1A1626),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: Get.isDarkMode
                      ? Colors.white.withValues(alpha: 0.82)
                      : const Color(0xFF6B6478),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Get.isDarkMode
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.white.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Preparing your experience...',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Get.isDarkMode
                        ? AppColors.textPrimaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: barrierDismissible,
    );
  }

  /// Build animated icon for dialog based on asset name
  static Widget _buildDialogIcon(String assetName) {
    final lower = assetName.toLowerCase();
    if (lower.contains('success') ||
        lower.contains('check') ||
        lower.contains('done')) {
      return const AnimatedCheckIcon(size: 120, color: AppColors.primary);
    } else if (lower.contains('error') ||
        lower.contains('fail') ||
        lower.contains('warning')) {
      return const AnimatedErrorIcon(size: 120, color: AppColors.primaryDark);
    } else if (lower.contains('heart') ||
        lower.contains('like') ||
        lower.contains('match')) {
      return const AnimatedHeartIcon(size: 120);
    } else if (lower.contains('search') || lower.contains('discover')) {
      return const AnimatedSearchIcon(size: 120);
    } else if (lower.contains('location') || lower.contains('map')) {
      return const AnimatedLocationIcon(size: 120);
    } else if (lower.contains('chat') || lower.contains('message')) {
      return const AnimatedChatIcon(size: 120);
    } else if (lower.contains('bell') || lower.contains('notif')) {
      return const AnimatedBellIcon(size: 120);
    } else if (lower.contains('star') || lower.contains('sparkle')) {
      return const AnimatedSparkleIcon(size: 120);
    }
    return const AnimatedCheckIcon(size: 120);
  }

  /// Truncate string
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Get initials from name
  static String getInitials(String? firstName, [String? lastName]) {
    String initials = '';
    if (firstName != null && firstName.isNotEmpty) initials += firstName[0];
    if (lastName != null && lastName.isNotEmpty) initials += lastName[0];
    return initials.toUpperCase();
  }

  /// Format time (e.g. "2:30 PM")
  static String formatTime(DateTime? date) {
    if (date == null) return '';
    return intl.DateFormat('h:mm a').format(date);
  }

  /// Format number with K/M suffix
  static String formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  /// Capitalize first letter of a string
  static String capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Get country flag emoji from country name
  static String getCountryFlag(String? countryName) {
    if (countryName == null || countryName.isEmpty) return '🌍';

    final name = countryName.toLowerCase().trim();

    // Common mappings
    final Map<String, String> flags = {
      'algeria': '🇩🇿',
      'morocco': '🇲🇦',
      'tunisia': '🇹🇳',
      'libya': '🇱🇾',
      'egypt': '🇪🇬',
      'france': '🇫🇷',
      'canada': '🇨🇦',
      'usa': '🇺🇸',
      'united states': '🇺🇸',
      'united kingdom': '🇬🇧',
      'uk': '🇬🇧',
      'germany': '🇩🇪',
      'spain': '🇪🇸',
      'italy': '🇮🇹',
      'saudi arabia': '🇸🇦',
      'uae': '🇦🇪',
      'qatar': '🇶🇦',
      'kuwait': '🇰🇼',
      'turkey': '🇹🇷',
      'syria': '🇸🇾',
      'lebanon': '🇱🇧',
      'jordan': '🇯🇴',
      'palestine': '🇵🇸',
    };

    return flags[name] ?? '🌍';
  }

  /// Alias for getCountryFlag
  static String countryToEmoji(String? countryName) =>
      getCountryFlag(countryName);

  /// Parse hex color string to Color object
  static Color parseColor(String hexColor) {
    try {
      hexColor = hexColor.replaceAll('#', '');
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      return const Color(0xFFE91E63); // Default to primary pink
    }
  }
}
