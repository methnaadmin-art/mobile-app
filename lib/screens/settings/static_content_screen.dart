import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/data/services/content_service.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_radii.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/app/theme/app_text_styles.dart';
import 'package:methna_app/core/constants/app_constants.dart';
import 'package:methna_app/core/widgets/settings_flow.dart';

class StaticContentScreen extends StatelessWidget {
  final String title;
  final String contentType;

  const StaticContentScreen({
    super.key,
    required this.title,
    required this.contentType,
  });

  @override
  Widget build(BuildContext context) {
    final contentService = Get.find<ContentService>();
    return SettingsSimplePageScaffold(
      title: title,
      subtitle: _subtitleForType(contentType),
      body: FutureBuilder<String>(
        future: _loadContent(contentService),
        builder: (context, snapshot) {
          final isDark = Theme.of(context).brightness == Brightness.dark;

          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceGlassDark : Colors.white,
                    borderRadius: BorderRadius.circular(AppRadii.xl),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x10000000),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  ),
                ),
              ],
            );
          }

          final content = (snapshot.data ?? '').trim();

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceGlassDark : Colors.white,
                  borderRadius: BorderRadius.circular(AppRadii.xl),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x10000000),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: SelectableText(
                  content.isEmpty ? _fallbackContent(contentType) : content,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    height: 1.7,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<String> _loadContent(ContentService contentService) async {
    final payload = await contentService.fetchContent(contentType);
    final content = payload?['content']?.toString().trim() ?? '';
    if (content.isNotEmpty) return content;
    return _fallbackContent(contentType);
  }

  String? _subtitleForType(String type) {
    switch (type) {
      case 'terms':
        return 'Read this before approving in signup.';
      case 'privacy':
        return 'How your data and profile visibility are handled.';
      default:
        return null;
    }
  }

  String _fallbackContent(String type) {
    switch (type) {
      case 'terms':
        return '''Terms of Service

By using Methna, you agree to use the app lawfully, respectfully, and honestly.

Accounts that violate community, safety, fraud, harassment, or verification rules may be restricted, suspended, or removed.

You are responsible for the accuracy of your profile, uploaded media, and activity inside the app.

Full Terms: ${AppConstants.termsUrl}
Support: ${AppConstants.supportEmail}''';
      case 'privacy':
        return '''Privacy Policy

Methna processes account, profile, location, and usage information to provide matching, safety, notifications, and support.

You can control privacy settings in the app and request account deletion from Settings.

Full Privacy Policy: ${AppConstants.privacyPolicyUrl}
Privacy contact: ${AppConstants.privacyEmail}''';
      default:
        return 'Content unavailable right now.';
    }
  }
}
