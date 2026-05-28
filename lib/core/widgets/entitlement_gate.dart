import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/data/services/monetization_service.dart';

/// Widget that conditionally shows its [child] only if the user
/// has the required entitlement. Otherwise shows [lockedChild] or nothing.
///
/// Usage:
/// ```dart
/// EntitlementGate(
///   feature: 'invisibleMode',
///   child: InvisibleModeToggle(),
///   lockedChild: UpgradePrompt(feature: 'Invisible Mode'),
/// )
/// ```
class EntitlementGate extends StatelessWidget {
  final String feature;
  final Widget child;
  final Widget? lockedChild;
  final bool fallbackToPremiumOnUnknown;

  const EntitlementGate({
    super.key,
    required this.feature,
    required this.child,
    this.lockedChild,
    this.fallbackToPremiumOnUnknown = true,
  });

  @override
  Widget build(BuildContext context) {
    final monetization = Get.find<MonetizationService>();
    return Obx(() {
      final hasAccess = monetization.hasEntitlement(
        feature,
        fallbackToPremiumOnUnknown: fallbackToPremiumOnUnknown,
      );
      if (hasAccess) return child;
      return lockedChild ?? const SizedBox.shrink();
    });
  }
}

/// Shows a premium upgrade prompt when the user doesn't have access.
class UpgradePrompt extends StatelessWidget {
  final String feature;
  final VoidCallback? onUpgrade;

  const UpgradePrompt({
    super.key,
    required this.feature,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onUpgrade ?? () => Get.toNamed('/settings/subscription'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.primaryColor.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 16, color: theme.primaryColor),
            const SizedBox(width: 8),
            Text(
              'upgrade_to_unlock'.tr,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
