import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/data/services/monetization_service.dart';
import 'package:methna_app/app/data/services/subscription_service.dart';
import 'package:methna_app/core/utils/helpers.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  static Future<void> _handleSubscribe(BuildContext context, MonetizationService monetization, String plan, int days) async {
    final result = await monetization.purchaseSubscription(plan, days, 'app_purchase_${DateTime.now().millisecondsSinceEpoch}');
    if (result) {
      Helpers.showSnackbar(message: 'Successfully subscribed to ${plan.capitalize}!');
      Get.find<SubscriptionService>().fetchMySubscription();
    } else {
      Helpers.showSnackbar(message: 'Subscription failed. Please try again.', isError: true);
    }
  }

  static Future<void> _handleCancel(BuildContext context, SubscriptionService subscription) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('cancel_subscription'.tr),
        content: Text('cancel_sub_confirm'.tr),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text('keep'.tr)),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('cancel'.tr, style: const TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final success = await subscription.cancelSubscription();
      if (success) {
        Helpers.showSnackbar(message: 'Subscription cancelled');
      } else {
        Helpers.showSnackbar(message: 'Failed to cancel', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final monetization = Get.find<MonetizationService>();
    final subscription = Get.find<SubscriptionService>();

    // Fetch latest status
    monetization.fetchStatus();
    monetization.fetchActivePlans();
    subscription.fetchMySubscription();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, size: 20),
          onPressed: () => Get.back(),
        ),
        title: Text('subscription'.tr, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Current plan badge
          Obx(() => Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.darkGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(LucideIcons.award, color: AppColors.premium, size: 48),
                const SizedBox(height: 12),
                Text(
                  '${subscription.currentPlan.value == 'free' ? 'Free' : subscription.currentPlan.value.capitalize!} Plan',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  subscription.isPremium ? 'You have ${subscription.daysRemaining} days remaining' : 'Upgrade to unlock all features',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatItem(label: 'Likes Left', value: monetization.isUnlimitedLikes.value ? '∞' : '${monetization.remainingLikes.value}', color: AppColors.like),
                    Container(width: 1, height: 30, color: Colors.white24),
                    _StatItem(label: 'Plan', value: subscription.currentPlan.value.capitalize ?? 'Free', color: AppColors.gold),
                    Container(width: 1, height: 30, color: Colors.white24),
                    _StatItem(label: 'Boosted', value: monetization.isBoosted.value ? 'Yes' : 'No', color: AppColors.boost),
                  ],
                ),
              ],
            ),
          )),

          const SizedBox(height: 24),

          // Plans
          const Text('Choose Your Plan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),

          Obx(() {
            if (monetization.activePlans.isEmpty) {
              return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
            }
            return Column(
              children: monetization.activePlans.map((plan) {
                final isDarkTheme = isDark;
                final planName = plan['name']?.toString().toUpperCase() ?? 'PLAN';
                final isGold = planName == 'GOLD' || planName == 'PLATINUM';
                final color = isGold ? AppColors.premium : AppColors.primary;
                final icon = isGold ? LucideIcons.star : LucideIcons.heart;
                
                final rawFeatures = plan['features'] as List<dynamic>? ?? [];
                final displayFeatures = rawFeatures.map((f) => f.toString().replaceAll('_', ' ').capitalize!).toList();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _PlanCard(
                    name: 'Methna ${planName.capitalize}',
                    price: '\$${plan['price']}',
                    period: '/${plan['durationDays']} days',
                    color: color,
                    icon: icon,
                    features: displayFeatures,
                    isPopular: isGold,
                    isDark: isDarkTheme,
                    onTap: () => _handleSubscribe(context, monetization, plan['name'], plan['durationDays'] ?? 30),
                  ),
                );
              }).toList(),
            );
          }),

          // Yearly savings
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.piggyBank, color: AppColors.success, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Save 40% with yearly plan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      Text('Premium: \$5.99/mo • Gold: \$11.99/mo',
                          style: TextStyle(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Boost section
          const Text('Boosts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _BoostOption(count: 1, price: '\$2.99', isDark: isDark)),
              const SizedBox(width: 10),
              Expanded(child: _BoostOption(count: 5, price: '\$9.99', isDark: isDark, isBestValue: true)),
              const SizedBox(width: 10),
              Expanded(child: _BoostOption(count: 10, price: '\$14.99', isDark: isDark)),
            ],
          ),

          const SizedBox(height: 24),

          // Cancel subscription (if active)
          Obx(() => subscription.isPremium
              ? Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OutlinedButton(
                    onPressed: () => _handleCancel(context, subscription),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('cancel_subscription'.tr),
                  ),
                )
              : const SizedBox()),

          // Restore purchases
          Center(
            child: TextButton(
              onPressed: () {},
              child: const Text('Restore Purchases', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),

          const SizedBox(height: 8),
          Text(
            'Subscriptions auto-renew unless cancelled at least 24 hours before the end of the current period.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: isDark ? AppColors.textHintDark : AppColors.textHintLight),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String name;
  final String price;
  final String period;
  final Color color;
  final IconData icon;
  final List<String> features;
  final bool isPopular;
  final bool isDark;
  final VoidCallback onTap;

  const _PlanCard({required this.name, required this.price, required this.period,
      required this.color, required this.icon, required this.features,
      required this.isPopular, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: isPopular ? Border.all(color: color, width: 2) : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          if (isPopular)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: const Text('MOST POPULAR', textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1)),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 28),
                    const SizedBox(width: 10),
                    Text(name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
                    const Spacer(),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(text: price, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                          TextSpan(text: period, style: TextStyle(fontSize: 13,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...features.map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(LucideIcons.checkCircle, color: color, size: 18),
                          const SizedBox(width: 10),
                          Text(f, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    )),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Subscribe Now', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
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

class _BoostOption extends StatelessWidget {
  final int count;
  final String price;
  final bool isDark;
  final bool isBestValue;
  const _BoostOption({required this.count, required this.price, required this.isDark, this.isBestValue = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.dividerLight,
          borderRadius: BorderRadius.circular(14),
          border: isBestValue ? Border.all(color: AppColors.boost, width: 2) : null,
        ),
        child: Column(
          children: [
            if (isBestValue)
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.boost, borderRadius: BorderRadius.circular(6)),
                child: const Text('BEST', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
              ),
            const Icon(LucideIcons.zap, color: AppColors.boost, size: 28),
            const SizedBox(height: 4),
            Text('$count', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Text(price, style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
          ],
        ),
      ),
    );
  }
}

