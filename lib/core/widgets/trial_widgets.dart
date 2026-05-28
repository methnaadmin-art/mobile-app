import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import '../services/trial_manager.dart';
import '../../app/data/services/monetization_service.dart';
import '../../app/data/services/auth_service.dart';
import '../../app/routes/app_routes.dart';

/// TrialGate - Widget that gates premium features based on trial status
/// Usage:
/// ```dart
/// TrialGate(
///   child: PremiumButton(...), // The premium feature
///   fallback: FreeAlternative(...), // What to show if not premium
///   onBlocked: () => showPremiumDialog(), // Optional callback when blocked
/// )
/// ```
class TrialGate extends StatelessWidget {
  final Widget child;
  final Widget? fallback;
  final VoidCallback? onBlocked;
  final bool showLockIcon;

  const TrialGate({
    super.key,
    required this.child,
    this.fallback,
    this.onBlocked,
    this.showLockIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Canonical premium check: backend/service entitlement first.
      bool canAccess = false;
      try {
        canAccess = Get.find<MonetizationService>().isPremium;
      } catch (_) {}

      if (!canAccess) {
        try {
          canAccess = Get.find<AuthService>().currentUser.value?.isPremium ?? false;
        } catch (_) {}
      }

      // Trial can still unlock premium UI while active.
      if (!canAccess) {
        canAccess = trialManager.isTrialActive;
      }
      
      if (canAccess) {
        return child;
      }
      
      // Show fallback or locked version
      if (fallback != null) {
        return GestureDetector(
          onTap: () => _handleBlocked(context),
          child: Stack(
            children: [
              Opacity(
                opacity: 0.5,
                child: IgnorePointer(child: fallback),
              ),
              if (showLockIcon)
                Positioned.fill(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        LucideIcons.lock,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      }
      
      // Show upgrade prompt
      return GestureDetector(
        onTap: () => _handleBlocked(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.crown, size: 16, color: const Color(0xFF4F26D9)),
              const SizedBox(width: 8),
              Text(
                'premium_feature'.tr,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
  
  void _handleBlocked(BuildContext context) {
    onBlocked?.call();
    _showPremiumRequiredBottomSheet(context);
  }
  
  void _showPremiumRequiredBottomSheet(BuildContext context) {
    Get.bottomSheet(
      const _TrialExpiredSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

/// Trial Banner - Shows remaining trial time or premium status
class TrialBanner extends StatelessWidget {
  final bool showInAppBar;
  final VoidCallback? onTap;

  const TrialBanner({
    super.key,
    this.showInAppBar = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      bool hasActivePremium = false;
      try {
        hasActivePremium = Get.find<MonetizationService>().isPremium;
      } catch (_) {}
      if (!hasActivePremium) {
        try {
          hasActivePremium =
              Get.find<AuthService>().currentUser.value?.isPremium ?? false;
        } catch (_) {}
      }

      // Active premium entitlement - show premium badge
      if (hasActivePremium) {
        return _buildPremiumBadge();
      }
      
      // Trial active - show countdown
      if (trialManager.isTrialActive) {
        return _buildTrialCountdown();
      }
      
      // Trial expired - show upgrade prompt
      if (trialManager.isTrialExpired) {
        return _buildExpiredPrompt();
      }
      
      // No trial (shouldn't happen) - show free badge
      return const SizedBox.shrink();
    });
  }
  
  Widget _buildPremiumBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6E3DFB), Color(0xFFA78BFA)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6E3DFB).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.crown, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            'premium'.tr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTrialCountdown() {
    final hours = trialManager.hoursRemaining;
    final isUrgent = hours < 6; // Less than 6 hours remaining
    
    return GestureDetector(
      onTap: onTap ?? () => Get.toNamed(AppRoutes.subscription),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isUrgent ? const Color(0xFFF4F0FF) : const Color(0xFFF4F0FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isUrgent ? const Color(0xFFA78BFA) : const Color(0xFFA78BFA),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.timer,
              size: 14,
              color: isUrgent ? const Color(0xFF4F26D9) : const Color(0xFF4F26D9),
            ),
            const SizedBox(width: 6),
            Text(
              '${trialManager.formattedTimeRemaining} ${'remaining'.tr}',
              style: TextStyle(
                color: isUrgent ? const Color(0xFF4F26D9) : const Color(0xFF4F26D9),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildExpiredPrompt() {
    return GestureDetector(
      onTap: onTap ?? () => Get.toNamed(AppRoutes.subscription),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.lock, size: 14, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              'upgrade_now'.tr,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Trial Expired Bottom Sheet
class _TrialExpiredSheet extends StatelessWidget {
  const _TrialExpiredSheet();

  @override
  Widget build(BuildContext context) {
    final isExpired = trialManager.isTrialExpired;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6E3DFB), Color(0xFFA78BFA)],
                ),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                LucideIcons.crown,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            
            // Title
            Text(
              isExpired ? 'trial_ended'.tr : 'premium_required'.tr,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            
            // Description
            Text(
              isExpired 
                ? 'trial_ended_desc'.tr
                : 'premium_required_desc'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            
            // Features list
            _buildFeatureRow(LucideIcons.heart, 'unlimited_likes'.tr),
            _buildFeatureRow(LucideIcons.rotateCcw, 'rewind_swipes'.tr),
            _buildFeatureRow(LucideIcons.award, 'send_compliments'.tr),
            _buildFeatureRow(LucideIcons.eye, 'see_who_liked_you'.tr),
            _buildFeatureRow(LucideIcons.zap, 'boost_profile'.tr),
            const SizedBox(height: 24),
            
            // CTA Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Get.back();
                  Get.toNamed(AppRoutes.subscription);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6E3DFB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'upgrade_to_premium'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Maybe later
            TextButton(
              onPressed: () => Get.back(),
              child: Text(
                'maybe_later'.tr,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeatureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6E3DFB).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF6E3DFB)),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          const Icon(
            LucideIcons.check,
            size: 16,
            color: Color(0xFF6E3DFB),
          ),
        ],
      ),
    );
  }
}

/// Trial Welcome Dialog - Shown on first app open during trial
class TrialWelcomeDialog extends StatelessWidget {
  const TrialWelcomeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Celebration icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6E3DFB), Color(0xFFA78BFA)],
                ),
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6E3DFB).withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                LucideIcons.gift,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              'trial_welcome_title'.tr,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            
            Text(
              'trial_welcome_desc'.trParams({'days': '2'}),
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Features
            _buildFeatureItem(LucideIcons.heart, 'unlimited_likes_feature'.tr),
            _buildFeatureItem(LucideIcons.rotateCcw, 'rewind_feature'.tr),
            _buildFeatureItem(LucideIcons.award, 'compliments_feature'.tr),
            _buildFeatureItem(LucideIcons.eye, 'see_likes_feature'.tr),
            const SizedBox(height: 24),
            
            // CTA
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  trialManager.markTrialWelcomeShown();
                  Get.back();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6E3DFB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'start_trial'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF6E3DFB)),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
