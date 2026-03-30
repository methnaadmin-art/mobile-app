import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:methna_app/core/widgets/animated_icons.dart';

class Helpers {
  Helpers._();
  
  /// Get localized back icon (chevrons flip in RTL)
  static IconData get backIcon =>
      Get.locale?.languageCode == 'ar' ? LucideIcons.chevronRight : LucideIcons.chevronLeft;

  /// Get localized forward icon
  static IconData get nextIcon =>
      Get.locale?.languageCode == 'ar' ? LucideIcons.chevronLeft : LucideIcons.chevronRight;

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
          if (data is Map && data['message'] != null) {
            final msg = data['message'];
            if (msg is List) return msg.join(', ');
            return msg.toString();
          }
          final status = e.response?.statusCode ?? 0;
          if (status == 401) return 'invalid_credentials'.tr;
          if (status == 403) return 'access_denied'.tr;
          if (status == 404) return 'not_found'.tr;
          if (status == 409) return data?['message']?.toString() ?? 'conflict_error'.tr;
          if (status == 429) return 'too_many_requests'.tr;
          if (status >= 500) return 'server_error'.tr;
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

    if (diff.inSeconds < 60) return 'just_now'.tr;
    if (diff.inMinutes < 60) return 'minutes_ago'.trParams({'count': '${diff.inMinutes}'});
    if (diff.inHours < 24) return 'hours_ago'.trParams({'count': '${diff.inHours}'});
    if (diff.inDays < 7) return 'days_ago'.trParams({'count': '${diff.inDays}'});
    if (diff.inDays < 30) return 'weeks_ago'.trParams({'count': '${(diff.inDays / 7).floor()}'});
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
    if (km == null) return '';
    if (km < 1) return 'meters_away'.trParams({'count': '${(km * 1000).round()}'});
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
      debugPrint('[SNACKBAR SKIPPED - NO CONTEXT] ${title ?? (isError ? "Error" : "Success")}: $message');
      return;
    }
    Get.snackbar(
      title ?? (isError ? 'error'.tr : 'success'.tr),
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isError
          ? Colors.red.shade50
          : Colors.green.shade50,
      colorText: isError ? Colors.red.shade800 : Colors.green.shade800,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      duration: duration,
      icon: Icon(
        isError ? LucideIcons.alertCircle : LucideIcons.checkCircle2,
        color: isError ? Colors.red : Colors.green,
      ),
    );
  }

  /// Show loading dialog
  static void showLoading({String? message}) {
    if (Get.context == null) {
      debugPrint('[LOADING SKIPPED - NO CONTEXT] $message');
      return;
    }
    final isDark = Get.isDarkMode;
    Get.dialog(
      PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
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
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(message, style: Get.textTheme.bodyMedium),
                ],
              ],
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
              // Animated Icon Container
              SizedBox(
                height: 120,
                width: 120,
                child: _buildDialogIcon(lottieAsset),
              ),
              const SizedBox(height: 20),
              
              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Get.theme.textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 12),
              
              // Message
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Get.theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
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
                          foregroundColor: Get.theme.textTheme.bodyLarge?.color,
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

  /// Build animated icon for dialog based on asset name
  static Widget _buildDialogIcon(String assetName) {
    final lower = assetName.toLowerCase();
    if (lower.contains('success') || lower.contains('check') || lower.contains('done')) {
      return const AnimatedCheckIcon(size: 120, color: Color(0xFF4CAF50));
    } else if (lower.contains('error') || lower.contains('fail') || lower.contains('warning')) {
      return const AnimatedErrorIcon(size: 120, color: Color(0xFFFF5252));
    } else if (lower.contains('heart') || lower.contains('like') || lower.contains('match')) {
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
  static String countryToEmoji(String? countryName) => getCountryFlag(countryName);

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
