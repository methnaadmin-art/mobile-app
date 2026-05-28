import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/controllers/profile_controller.dart';
import 'package:methna_app/app/data/models/user_model.dart';
import 'package:methna_app/core/utils/helpers.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

/// About Tab with detailed profile information
class ProfileAboutTab extends StatelessWidget {
  final UserModel user;

  const ProfileAboutTab({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final cardBg = isDark ? AppColors.cardDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final profile = user.profile;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Info Section
          _SectionCard(
            title: 'basic_information'.tr,
            icon: LucideIcons.user,
            cardBg: cardBg,
            borderColor: borderColor,
            textColor: textColor,
            children: [
              _InfoRow(
                icon: LucideIcons.calendar,
                label: 'age'.tr,
                value: profile != null
                    ? profile.age.toString()
                    : 'not_specified'.tr,
                textColor: textColor,
              ),
              _InfoRow(
                icon: LucideIcons.mapPin,
                label: 'location'.tr,
                value: (() {
                  final city = profile?.city?.trim() ?? '';
                  final country = profile?.country?.trim() ?? '';
                  final location = [city, country]
                      .where((part) => part.isNotEmpty)
                      .join(', ');
                  return location.isEmpty ? 'not_specified'.tr : location;
                })(),
                textColor: textColor,
              ),
              _InfoRow(
                icon: LucideIcons.heart,
                label: 'marital_status'.tr,
                value: _formatMaritalStatus(profile?.maritalStatus),
                textColor: textColor,
              ),
              _InfoRow(
                icon: LucideIcons.graduationCap,
                label: 'education'.tr,
                value: _formatEducation(profile?.education),
                textColor: textColor,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Professional Info Section
          _SectionCard(
            title: 'professional_information'.tr,
            icon: LucideIcons.briefcase,
            cardBg: cardBg,
            borderColor: borderColor,
            textColor: textColor,
            children: [
              _InfoRow(
                icon: LucideIcons.user,
                label: 'job_title'.tr,
                value: profile?.jobTitle ?? 'not_specified'.tr,
                textColor: textColor,
              ),
              _InfoRow(
                icon: LucideIcons.building,
                label: 'company'.tr,
                value: profile?.company ?? 'not_specified'.tr,
                textColor: textColor,
              ),
              _InfoRow(
                icon: LucideIcons.ruler,
                label: 'height'.tr,
                value: profile?.height != null
                    ? '${profile!.height} cm'
                    : 'not_specified'.tr,
                textColor: textColor,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Faith & Religion Section
          _SectionCard(
            title: 'faith_and_religion'.tr,
            icon: LucideIcons.moon,
            cardBg: cardBg,
            borderColor: borderColor,
            textColor: textColor,
            children: [
              _InfoRow(
                icon: LucideIcons.users,
                label: 'sect'.tr,
                value: _formatSect(profile?.sect),
                textColor: textColor,
              ),
              _InfoRow(
                icon: LucideIcons.star,
                label: 'religious_level'.tr,
                value: _formatReligiousLevel(profile?.religiousLevel),
                textColor: textColor,
              ),
              _InfoRow(
                icon: LucideIcons.clock,
                label: 'prayer_frequency'.tr,
                value: _formatPrayerFrequency(profile?.prayerFrequency),
                textColor: textColor,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Bio Section
          if (profile?.bio?.isNotEmpty == true)
            _SectionCard(
              title: 'about_me'.tr,
              icon: LucideIcons.fileText,
              cardBg: cardBg,
              borderColor: borderColor,
              textColor: textColor,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    profile!.bio!,
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 20),

          // Interests Section
          if (profile?.interests?.isNotEmpty == true)
            _SectionCard(
              title: 'interests'.tr,
              icon: LucideIcons.heart,
              cardBg: cardBg,
              borderColor: borderColor,
              textColor: textColor,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profile!.interests!.map((interest) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        Helpers.capitalizeFirst(interest),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),

          const SizedBox(height: 20),

          // Edit Profile Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Get.find<ProfileController>().openEditProfile(),
              icon: const Icon(LucideIcons.edit, size: 18),
              label: Text('edit_profile'.tr),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMaritalStatus(String? status) {
    switch (status) {
      case 'never_married':
        return 'never_married'.tr;
      case 'divorced':
        return 'divorced'.tr;
      case 'widowed':
        return 'widowed'.tr;
      case 'married':
        return 'married'.tr;
      default:
        return 'not_specified'.tr;
    }
  }

  String _formatEducation(String? education) {
    switch (education) {
      case 'high_school':
        return 'high_school'.tr;
      case 'bachelors':
        return 'bachelors'.tr;
      case 'masters':
        return 'masters'.tr;
      case 'phd':
        return 'phd'.tr;
      case 'other':
        return 'other'.tr;
      default:
        return 'not_specified'.tr;
    }
  }

  String _formatSect(String? sect) {
    switch (sect) {
      case 'sunni':
        return 'sunni'.tr;
      case 'shia':
        return 'shia'.tr;
      case 'ibadi':
        return 'ibadi'.tr;
      case 'other':
        return 'other'.tr;
      default:
        return 'not_specified'.tr;
    }
  }

  String _formatReligiousLevel(String? level) {
    switch (level) {
      case 'very_practicing':
        return 'very_practicing'.tr;
      case 'practicing':
        return 'practicing'.tr;
      case 'moderate':
        return 'moderate'.tr;
      case 'liberal':
        return 'liberal'.tr;
      default:
        return 'not_specified'.tr;
    }
  }

  String _formatPrayerFrequency(String? frequency) {
    switch (frequency) {
      case 'actively_practicing':
        return 'actively_practicing'.tr;
      case 'occasionally':
        return 'occasionally'.tr;
      case 'not_practicing':
        return 'not_practicing'.tr;
      default:
        return 'not_specified'.tr;
    }
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color cardBg;
  final Color borderColor;
  final Color textColor;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.cardBg,
    required this.borderColor,
    required this.textColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 20, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          
          // Section content
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color textColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: secondaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: secondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor,
                    fontWeight: FontWeight.w600,
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
