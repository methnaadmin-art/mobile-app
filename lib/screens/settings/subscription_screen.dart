import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:methna_app/app/data/services/monetization_service.dart';
import 'package:methna_app/app/data/services/subscription_service.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_radii.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/app/theme/app_text_styles.dart';
import 'package:methna_app/core/utils/helpers.dart';
import 'package:methna_app/core/widgets/app_card.dart';
import 'package:methna_app/core/widgets/custom_button.dart';
import 'package:methna_app/core/widgets/settings_flow.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  late final MonetizationService monetization;
  late final SubscriptionService subscription;

  @override
  void initState() {
    super.initState();
    monetization = Get.find<MonetizationService>();
    subscription = Get.find<SubscriptionService>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      monetization.fetchStatus();
      monetization.fetchActivePlans();
      subscription.fetchMySubscription();
    });
  }

  static Future<void> _handleSubscribe(
    MonetizationService monetization,
    Map<String, dynamic> plan,
  ) async {
    final planCode = _resolvePlanCode(plan);
    final days = _durationDays(plan);
    final displayName = _planLabel(planCode, plan['name']);
    final subscriptionService = Get.find<SubscriptionService>();

    if (planCode.trim().isEmpty) {
      Helpers.showSnackbar(
        message: 'invalid_plan'.tr,
        isError: true,
      );
      return;
    }

    if (_isNoPaymentPlan(plan, planCode)) {
      final result = await subscriptionService.subscribe(
        planCode,
        durationDays: days,
      );

      if (result) {
        await Future.wait([
          monetization.fetchStatus(),
          monetization.fetchAllLimits(),
          monetization.fetchFeatures(),
          subscriptionService.fetchMySubscription(),
        ]);
        Helpers.showSnackbar(
          message: '${'subscribed_success'.tr} $displayName!',
        );
      } else {
        Helpers.showSnackbar(
          message: 'subscription_failed'.tr,
          isError: true,
        );
      }
      return;
    }

    final result = await monetization.purchaseSubscription(
      planCode,
      days,
      'app_purchase_${DateTime.now().millisecondsSinceEpoch}',
    );

    if (result) {
      Helpers.showSnackbar(
        message: '${'subscribed_success'.tr} $displayName!',
      );
      Get.find<SubscriptionService>().fetchMySubscription();
    } else {
      Helpers.showSnackbar(
        message: 'subscription_failed'.tr,
        isError: true,
      );
    }
  }

  static Future<void> _handleCancel(SubscriptionService subscription) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('cancel_subscription'.tr),
        content: Text('cancel_sub_confirm'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('keep'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(
              'cancel'.tr,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await subscription.cancelSubscription();
      if (success) {
        Helpers.showSnackbar(message: 'subscription_cancelled'.tr);
      } else {
        Helpers.showSnackbar(message: 'cancel_failed'.tr, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSimplePageScaffold(
      title: 'upgrade_membership_title'.tr,
      body: Obx(
        () => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          children: [
            _SubscriptionStatusCard(
              monetization: monetization,
              subscription: subscription,
            ),
            const SizedBox(height: AppSpacing.md),
            if (monetization.activePlans.isEmpty)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else
              ...monetization.activePlans.map((plan) {
                final planCode = _resolvePlanCode(plan);
                final displayName = _planLabel(planCode, plan['name']);
                final durationDays = _durationDays(plan);
                final price = _displayPrice(plan);
                final features = _displayFeatures(plan);
                final popular = durationDays >= 30;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _MembershipPlanCard(
                    planLabel: _durationLabel(durationDays),
                    name: displayName,
                    price: price,
                    period: _periodLabel(durationDays),
                    features: features,
                    isPopular: popular,
                    onTap: () => _handleSubscribe(monetization, plan),
                  ),
                );
              }),
            const SizedBox(height: AppSpacing.md),
            _SubscriptionActionsCard(
              subscription: subscription,
              monetization: monetization,
            ),
          ],
        ),
      ),
    );
  }

  static int _durationDays(Map<String, dynamic> plan) {
    final rawDuration =
        plan['durationDays'] ?? plan['duration'] ?? plan['days'];
    if (rawDuration is int) {
      return rawDuration;
    }
    return int.tryParse(rawDuration?.toString() ?? '') ?? 30;
  }

  static String _resolvePlanCode(Map<String, dynamic> plan) {
    const candidates = ['code', 'slug', 'plan', 'tier', 'name'];
    for (final key in candidates) {
      final value = plan[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  static String _normalizeToken(String raw) => raw
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');

  static String _humanizeToken(String raw) {
    final normalized = raw
        .trim()
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.isEmpty) return '';
    return normalized
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  static String _translatedOrFallback(String key, String fallback) {
    final translated = key.tr;
    if (translated != key) {
      return translated;
    }
    return fallback;
  }

  static String _planLabel(String planCode, dynamic fallbackName) {
    final candidate = planCode.trim().isNotEmpty
        ? planCode
        : (fallbackName?.toString() ?? 'Premium');

    final normalized = _normalizeToken(candidate);
    if (normalized.contains('gold')) {
      return 'gold_plan'.tr;
    }
    if (normalized.contains('premium')) {
      return 'premium_plan'.tr;
    }
    if (normalized.contains('free')) {
      return 'free_plan'.tr;
    }

    switch (normalized) {
      case 'free':
        return 'free_plan'.tr;
      case 'premium':
        return 'premium_plan'.tr;
      case 'gold':
        return 'gold_plan'.tr;
      default:
        final direct = _translatedOrFallback(normalized, '');
        if (direct.isNotEmpty && direct != normalized) {
          return direct;
        }
        final prefixed = 'plan_$normalized';
        final prefixedTranslated = _translatedOrFallback(prefixed, '');
        if (prefixedTranslated.isNotEmpty && prefixedTranslated != prefixed) {
          return prefixedTranslated;
        }
        final fallbackCandidate = fallbackName?.toString().trim() ?? '';
        if (fallbackCandidate.isNotEmpty) {
          return _humanizeToken(fallbackCandidate);
        }
        return _humanizeToken(candidate);
    }
  }

  static String _displayPrice(Map<String, dynamic> plan) {
    final rawPrice =
        plan['price'] ??
        plan['amount'] ??
        plan['monthlyPrice'] ??
        plan['value'];
    if (rawPrice is num) {
      return '\$${rawPrice.toStringAsFixed(rawPrice % 1 == 0 ? 0 : 2)}';
    }
    return '\$${rawPrice ?? '0'}';
  }

  static bool _isNoPaymentPlan(Map<String, dynamic> plan, String planCode) {
    final normalizedCode = _normalizeToken(
      planCode.trim().isNotEmpty ? planCode : (plan['name']?.toString() ?? ''),
    );
    final price = _parsePriceValue(plan);
    final durationDays = _durationDays(plan);

    final isFreePlan =
        normalizedCode == 'free' || normalizedCode.startsWith('free_');
    final isTrialPlan = normalizedCode.contains('trial');
    final isZeroPrice = price != null && price <= 0;

    if (isFreePlan) {
      return true;
    }

    if (isTrialPlan && (isZeroPrice || durationDays <= 3)) {
      return true;
    }

    return false;
  }

  static double? _parsePriceValue(Map<String, dynamic> plan) {
    final rawPrice =
        plan['price'] ??
        plan['amount'] ??
        plan['monthlyPrice'] ??
        plan['value'];

    if (rawPrice is num) {
      return rawPrice.toDouble();
    }

    final asString = rawPrice?.toString().trim();
    if (asString == null || asString.isEmpty) {
      return null;
    }

    final sanitized = asString.replaceAll(RegExp(r'[^0-9\.]'), '');
    if (sanitized.isEmpty) {
      return null;
    }
    return double.tryParse(sanitized);
  }

  static List<String> _displayFeatures(Map<String, dynamic> plan) {
    final rawFeatures = plan['features'];
    final parsedFeatures = rawFeatures is List
      ? rawFeatures.map((feature) => feature.toString()).toList()
        : rawFeatures is Map
        ? rawFeatures.entries
              .where((entry) => entry.value == true)
              .map((entry) => entry.key.toString())
              .toList()
        : const <String>[];

    if (parsedFeatures.isNotEmpty) {
      return parsedFeatures
          .map(_displayFeatureLabel)
          .toList(growable: false);
    }

    final derivedFeatures = <String>[];
    final dailyLikes = _readInt(plan['dailyLikesLimit']);
    final dailyCompliments = _readInt(plan['dailyComplimentsLimit']);
    final monthlyRewinds = _readInt(plan['monthlyRewindsLimit']);
    final weeklyBoosts = _readInt(plan['weeklyBoostsLimit']);

    if (dailyLikes == -1) {
      derivedFeatures.add('unlimited_daily_swipes'.tr);
    } else if (dailyLikes > 0) {
      derivedFeatures.add('$dailyLikes ${'daily_swipes'.tr}');
    }

    if (dailyCompliments > 0) {
      derivedFeatures.add('$dailyCompliments ${'compliment_credits_daily'.tr}');
    }

    if (monthlyRewinds == -1) {
      derivedFeatures.add('unlimited_rewinds'.tr);
    } else if (monthlyRewinds > 0) {
      derivedFeatures.add('$monthlyRewinds ${'rewinds_monthly'.tr}');
    }

    if (weeklyBoosts > 0) {
      derivedFeatures.add('$weeklyBoosts ${'boosts_weekly'.tr}');
    }

    if (derivedFeatures.isNotEmpty) {
      return derivedFeatures;
    }

    return ['plan_benefits_default'.tr];
  }

  static String _durationLabel(int days) {
    if (days >= 365) {
      return 'yearly'.tr;
    }
    if (days >= 30) {
      return 'monthly'.tr;
    }
    return 'daily'.tr;
  }

  static String _periodLabel(int days) {
    if (days >= 365) {
      return 'period_year_short'.tr;
    }
    if (days >= 30) {
      return 'period_month_short'.tr;
    }
    return 'period_day_short'.tr;
  }

  static String _displayFeatureLabel(String rawFeature) {
    final normalized = _normalizeToken(rawFeature);
    if (normalized.isEmpty) {
      return _humanizeToken(rawFeature);
    }

    for (final key in [
      normalized,
      'feature_$normalized',
      'plan_feature_$normalized',
    ]) {
      final translated = key.tr;
      if (translated != key) {
        return translated;
      }
    }

    return _humanizeToken(rawFeature);
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class _SubscriptionStatusCard extends StatelessWidget {
  final MonetizationService monetization;
  final SubscriptionService subscription;

  const _SubscriptionStatusCard({
    required this.monetization,
    required this.subscription,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentPlan = _SubscriptionScreenState._planLabel(
      subscription.currentPlan.value,
      subscription.currentPlan.value,
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceGlassDark : Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const Icon(
              LucideIcons.sparkles,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'your_current_plan'.tr,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  currentPlan,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subscription.isPremium
                      ? '${subscription.daysRemaining} ${'days_remaining_label'.tr}'
                      : 'upgrade_desc'.tr,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          if (subscription.isPremium)
            Text(
              monetization.isUnlimitedLikes.value
                  ? 'unlimited'.tr
                  : '${monetization.remainingLikes.value} ${'likes_left'.tr}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

class _MembershipPlanCard extends StatelessWidget {
  final String planLabel;
  final String name;
  final String price;
  final String period;
  final List<String> features;
  final bool isPopular;
  final VoidCallback onTap;

  const _MembershipPlanCard({
    required this.planLabel,
    required this.name,
    required this.price,
    required this.period,
    required this.features,
    required this.isPopular,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceGlassDark : Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: isPopular
              ? AppColors.primary.withValues(alpha: 0.28)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: isPopular
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  planLabel,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isPopular ? Colors.white : AppColors.primary,
                  ),
                ),
              ),
              if (isPopular) ...[
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'popular'.tr,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            name,
            style: AppTextStyles.headlineSmall.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: price,
                  style: AppTextStyles.displaySmall.copyWith(
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
                TextSpan(
                  text: period,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ...features
              .take(5)
              .map(
                (feature) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          LucideIcons.check,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          feature,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: AppSpacing.sm),
          CustomButton(text: 'continue_btn'.tr, onPressed: onTap),
        ],
      ),
    );
  }
}

class _SubscriptionActionsCard extends StatelessWidget {
  final SubscriptionService subscription;
  final MonetizationService monetization;

  const _SubscriptionActionsCard({
    required this.subscription,
    required this.monetization,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'subscription_actions'.tr,
            style: AppTextStyles.titleMedium.copyWith(
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          CustomButton(
            text: 'sync_subscription'.tr,
            variant: CustomButtonVariant.secondary,
            onPressed: () async {
              final restored = await monetization.restoreSubscriptionState();
              if (restored) {
                Helpers.showSnackbar(
                  message: 'sync_success'.tr,
                );
              } else {
                Helpers.showSnackbar(
                  message: 'no_active_sub'.tr,
                  isError: true,
                );
              }
            },
          ),
          if (subscription.isPremium) ...[
            const SizedBox(height: AppSpacing.sm),
            CustomButton(
              text: 'cancel_subscription'.tr,
              variant: CustomButtonVariant.outline,
              textColor: AppColors.error,
              onPressed: () =>
                  _SubscriptionScreenState._handleCancel(subscription),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            'sub_auto_renew_note'.tr,
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
