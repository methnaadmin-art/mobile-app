import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:methna_app/app/data/services/monetization_service.dart';
import 'package:methna_app/app/data/services/subscription_service.dart';
import 'package:methna_app/app/routes/app_routes.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/core/utils/helpers.dart';
import 'package:methna_app/core/widgets/settings_flow.dart';

/// "Our Packages" subscription screen — brand identity.
///
/// The screen is intentionally self-contained: it only reads from
/// [MonetizationService.activePlans] / [SubscriptionService] and calls the
/// existing [MonetizationService.purchaseSubscription] pipeline so all
/// Google Play billing hooks remain intact.
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  static const Color _primaryBrand = Color(0xFF6E3DFB);

  late final MonetizationService _monetization;
  late final SubscriptionService _subscription;
  Timer? _countdownTicker;

  /// Which billing cycle is currently selected in the 3-way toggle.
  _BillingCycleFilter _cycle = _BillingCycleFilter.monthly;

  bool get _purchasesAvailable => _monetization.supportsInAppPurchases;

  @override
  void initState() {
    super.initState();
    _monetization = Get.find<MonetizationService>();
    _subscription = Get.find<SubscriptionService>();
    _countdownTicker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.wait([
        _monetization.fetchStatus(),
        _monetization.fetchActivePlans(),
        _monetization.fetchEntitlements(),
      ]);
      // Ensure Google Play ProductDetails are loaded so we can render real
      // localized store prices (e.g. "US$4.99", "2,99 €") instead of the
      // backend's raw numeric price.
      if (_purchasesAvailable) {
        await _monetization.ensureStorePricesLoaded();
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTicker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SettingsSimplePageScaffold(
      title: 'Our Packages',
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [Color(0xFF1A1018), Color(0xFF0F0A10)]
                : const [Color(0xFFFFF5F7), Color(0xFFFFFFFF)],
          ),
        ),
        child: Obx(() {
          final plans = _filteredPlans();
          return RefreshIndicator(
            color: _primaryBrand,
            onRefresh: () async {
              await Future.wait([
                _monetization.fetchActivePlans(),
                _monetization.fetchStatus(),
              ]);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                _PackagesCard(
                  isDark: isDark,
                  cycle: _cycle,
                  onCycleChanged: (c) => setState(() => _cycle = c),
                  plans: plans,
                  purchasesAvailable: _purchasesAvailable,
                  isCurrentPlan: _monetization.isExactPlanCurrent,
                  onSelectPlan: _openPlanDetail,
                  onCreateCustom: _openCustomSummary,
                ),
                const SizedBox(height: 20),
                _ActiveSubscriptionStrip(
                  isDark: isDark,
                  monetization: _monetization,
                  subscription: _subscription,
                ),
                if (_purchasesAvailable) ...[
                  const SizedBox(height: 14),
                  _RestorePurchasesButton(
                    isDark: isDark,
                    monetization: _monetization,
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }

  // ─── Plan filtering ────────────────────────────────────────────

  List<Map<String, dynamic>> _filteredPlans() {
    final all = _monetization.activePlans.toList();
    // Exclude free plans — they don't belong on a paid-packages screen.
    final paid = all.where((p) {
      final code = _codeOf(p);
      final price = _priceOf(p);
      return code.isNotEmpty && code != 'free' && price > 0;
    }).toList();

    final matching = paid.where((p) => _matchesCycle(p, _cycle)).toList();

    // If filtering kills everything (admin didn't tag cycles), show an empty
    // state rather than mixing cycles, so the toggle is meaningful.
    matching.sort((a, b) => _priceOf(a).compareTo(_priceOf(b)));
    return matching;
  }

  static bool _matchesCycle(Map<String, dynamic> plan, _BillingCycleFilter f) {
    final cycle = (plan['billingCycle'] ?? plan['billing_cycle'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    final days =
        (plan['durationDays'] ?? plan['duration_days'] ?? 0) as num? ?? 0;

    switch (f) {
      case _BillingCycleFilter.weekly:
        if (cycle == 'weekly') return true;
        return days >= 6 && days <= 10;
      case _BillingCycleFilter.monthly:
        if (cycle == 'monthly') return true;
        return days >= 25 && days <= 35;
      case _BillingCycleFilter.yearly:
        if (cycle == 'yearly' || cycle == 'annual') return true;
        return days >= 300;
    }
  }

  // ─── Navigation ────────────────────────────────────────────────

  void _openPlanDetail(Map<String, dynamic> plan) {
    Get.to<void>(
      () => _PlanDetailScreen(
        plan: plan,
        monetization: _monetization,
        subscription: _subscription,
      ),
      fullscreenDialog: false,
      transition: Transition.rightToLeft,
    );
  }

  void _openCustomSummary() {
    final plans = _filteredPlans();
    if (plans.isEmpty) {
      Helpers.showSnackbar(
        message: 'No packages available right now. Pull to refresh.',
        isError: true,
      );
      return;
    }
    // Open the premium chooser anchored on the top-tier plan.
    final top = plans.reduce((a, b) => _priceOf(a) >= _priceOf(b) ? a : b);
    _openPlanDetail(top);
  }

  // ─── Plan field accessors (defensive) ─────────────────────────

  static String _codeOf(Map<String, dynamic> plan) {
    final raw = (plan['code'] ?? plan['planCode'] ?? plan['id'] ?? '')
        .toString();
    return raw.trim().toLowerCase();
  }

  static double _priceOf(Map<String, dynamic> plan) {
    final raw = plan['price'] ?? plan['amount'] ?? plan['cost'];
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw) ?? 0;
    return 0;
  }
}

// ════════════════════════════════════════════════════════════════════
//  PACKAGES CARD (top card with title + toggle + plan rows + CTA)
// ════════════════════════════════════════════════════════════════════

class _PackagesCard extends StatelessWidget {
  const _PackagesCard({
    required this.isDark,
    required this.cycle,
    required this.onCycleChanged,
    required this.plans,
    required this.purchasesAvailable,
    required this.isCurrentPlan,
    required this.onSelectPlan,
    required this.onCreateCustom,
  });

  final bool isDark;
  final _BillingCycleFilter cycle;
  final ValueChanged<_BillingCycleFilter> onCycleChanged;
  final List<Map<String, dynamic>> plans;
  final bool purchasesAvailable;
  final bool Function(Map<String, dynamic> plan) isCurrentPlan;
  final ValueChanged<Map<String, dynamic>> onSelectPlan;
  final VoidCallback onCreateCustom;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1C1A28) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1A1626);
    final textMuted = isDark ? Colors.white70 : const Color(0xFF6A6780);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Our Packages',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            purchasesAvailable
                ? 'Pick the plan that fits you best. Cancel anytime.'
                : 'Review plan benefits and your current subscription status.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: textMuted, height: 1.45),
          ),
          const SizedBox(height: 18),
          _CycleSegmentedToggle(
            isDark: isDark,
            cycle: cycle,
            onChanged: onCycleChanged,
          ),
          const SizedBox(height: 18),
          if (!purchasesAvailable) ...[
            _IosPurchaseNotice(isDark: isDark),
            const SizedBox(height: 14),
          ],
          if (plans.isEmpty)
            _EmptyPlansPlaceholder(isDark: isDark)
          else
            ...List.generate(plans.length, (i) {
              final p = plans[i];
              final tone = _toneForIndex(i);
              return Padding(
                padding: EdgeInsets.only(
                  bottom: i == plans.length - 1 ? 0 : 12,
                ),
                child: _PackageRow(
                  isDark: isDark,
                  dotColor: tone,
                  title: _planName(p),
                  subtitle: _planSubtitle(p),
                  priceText: purchasesAvailable ? _priceLabel(p) : 'Benefits',
                  isCurrent: isCurrentPlan(p),
                  onTap: () => onSelectPlan(p),
                ),
              );
            }),
          if (purchasesAvailable) ...[
            const SizedBox(height: 22),
            _BrandButton(
              label: 'Choose the Subscription',
              icon: Icons.workspace_premium_rounded,
              onPressed: onCreateCustom,
              filled: false,
            ),
          ],
        ],
      ),
    );
  }

  Color _toneForIndex(int i) {
    const tones = [
      Color(0xFF6E3DFB),
      Color(0xFFA78BFA),
      Color(0xFFC4B5FD),
      Color(0xFFEDE9FE),
    ];
    return tones[i % tones.length];
  }

  String _planName(Map<String, dynamic> p) {
    final raw =
        (p['name'] ?? p['displayName'] ?? p['title'] ?? p['code'] ?? 'Plan')
            .toString();
    return raw.trim().isEmpty ? 'Plan' : raw.trim();
  }

  String _planSubtitle(Map<String, dynamic> p) {
    final desc = (p['tagline'] ?? p['subtitle'] ?? p['description'] ?? '')
        .toString()
        .trim();
    if (desc.isNotEmpty) return desc;
    final days = (p['durationDays'] ?? p['duration_days'] ?? 0) as num? ?? 0;
    if (days >= 300) return 'Best value';
    if (days >= 25) return 'Standard';
    if (days >= 6) return 'Starter';
    return '';
  }

  String _priceLabel(Map<String, dynamic> p) {
    // Prefer the Google Play store-localized price (e.g. "US$4.99",
    // "2,99 €") so the user sees the exact price they will be charged
    // in their Google account currency.
    final storePrice = _storeLocalizedPrice(p);
    if (storePrice != null) return storePrice;

    final price = _SubscriptionScreenState._priceOf(p);
    if (price <= 0) return 'Free';
    final currency = (p['currency'] ?? 'USD').toString().toUpperCase();
    final symbol = _currencySymbol(currency);
    final whole = price.truncate();
    final hasFraction = price - whole != 0;
    final formatted = hasFraction ? price.toStringAsFixed(2) : '$whole';
    return '$symbol$formatted';
  }

  static String? _storeLocalizedPrice(Map<String, dynamic> p) {
    if (!Get.isRegistered<MonetizationService>()) return null;
    try {
      return Get.find<MonetizationService>().localizedPriceForPlan(p);
    } catch (_) {
      return null;
    }
  }

  String _currencySymbol(String code) {
    if (code == 'EUR') return 'EUR ';
    if (code == 'GBP') return 'GBP ';
    switch (code) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return '';
    }
  }
}

// ════════════════════════════════════════════════════════════════════
//  SEGMENTED TOGGLE (Monthly / Yearly pill)
// ════════════════════════════════════════════════════════════════════

enum _BillingCycleFilter { weekly, monthly, yearly }

class _CycleSegmentedToggle extends StatelessWidget {
  const _CycleSegmentedToggle({
    required this.isDark,
    required this.cycle,
    required this.onChanged,
  });

  final bool isDark;
  final _BillingCycleFilter cycle;
  final ValueChanged<_BillingCycleFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final trackBg = isDark ? const Color(0xFF2A2435) : const Color(0xFFEDE9FE);
    return Container(
      decoration: BoxDecoration(
        color: trackBg,
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _segment(
            label: 'Weekly',
            selected: cycle == _BillingCycleFilter.weekly,
            onTap: () => onChanged(_BillingCycleFilter.weekly),
          ),
          _segment(
            label: 'Monthly',
            selected: cycle == _BillingCycleFilter.monthly,
            onTap: () => onChanged(_BillingCycleFilter.monthly),
          ),
          _segment(
            label: 'Yearly',
            selected: cycle == _BillingCycleFilter.yearly,
            onTap: () => onChanged(_BillingCycleFilter.yearly),
          ),
        ],
      ),
    );
  }

  Widget _segment({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF6E3DFB) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFF6E3DFB).withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              color: selected
                  ? Colors.white
                  : (isDark ? Colors.white70 : const Color(0xFF6A6780)),
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
//  SINGLE PACKAGE ROW
// ════════════════════════════════════════════════════════════════════

class _PackageRow extends StatelessWidget {
  const _PackageRow({
    required this.isDark,
    required this.dotColor,
    required this.title,
    required this.subtitle,
    required this.priceText,
    required this.isCurrent,
    required this.onTap,
  });

  final bool isDark;
  final Color dotColor;
  final String title;
  final String subtitle;
  final String priceText;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rowBg = isDark ? const Color(0xFF241D2F) : const Color(0xFFF4F0FF);
    final border = isCurrent
        ? const Color(0xFF6E3DFB)
        : (isDark ? const Color(0xFF2E2840) : const Color(0xFFEDE9FE));
    final titleColor = isDark ? Colors.white : const Color(0xFF1A1626);
    final subColor = isDark ? Colors.white60 : const Color(0xFF8A849E);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: rowBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border, width: isCurrent ? 1.6 : 1),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: titleColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF6E3DFB,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Current',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6E3DFB),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: subColor),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                priceText,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: isDark ? Colors.white38 : const Color(0xFFCBB0B7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
//  EMPTY STATE
// ════════════════════════════════════════════════════════════════════

class _IosPurchaseNotice extends StatelessWidget {
  const _IosPurchaseNotice({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF241D2F) : const Color(0xFFFFF5F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF3A2D3F) : const Color(0xFFEDE9FE),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.info, color: Color(0xFF6E3DFB), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Purchases are not currently offered on this device. You can still view plan benefits and your active subscription status.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.35,
                color: isDark ? Colors.white70 : const Color(0xFF6A5660),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPlansPlaceholder extends StatelessWidget {
  const _EmptyPlansPlaceholder({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          Icon(
            LucideIcons.packageOpen,
            size: 36,
            color: isDark ? Colors.white38 : const Color(0xFFCBB0B7),
          ),
          const SizedBox(height: 10),
          Text(
            'No packages available',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : const Color(0xFF6A6780),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pull down to refresh.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : const Color(0xFF8A849E),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
//  ACTIVE SUBSCRIPTION STRIP (shown below the packages card)
// ════════════════════════════════════════════════════════════════════

class _ActiveSubscriptionStrip extends StatelessWidget {
  const _ActiveSubscriptionStrip({
    required this.isDark,
    required this.monetization,
    required this.subscription,
  });

  final bool isDark;
  final MonetizationService monetization;
  final SubscriptionService subscription;

  @override
  Widget build(BuildContext context) {
    if (!subscription.isPremium && !monetization.isPremium) {
      return const SizedBox.shrink();
    }

    final plan = _subscriptionDisplayPlanName(
      monetization.currentSubscribedPlanMetadata,
      subscription.currentPlan.value,
    );
    final days = subscription.daysRemaining;
    final bg = isDark ? const Color(0xFF1C1A28) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF16102B);
    final textMuted = isDark ? Colors.white70 : const Color(0xFF6B6680);
    final endDateLabel = _formatSubscriptionDate(subscription.expiresAt.value);
    final remainingLabel = _remainingDaysLabel(days);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF6E3DFB).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF6E3DFB).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              LucideIcons.crown,
              color: Color(0xFF6E3DFB),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active: ${plan.isEmpty ? 'Premium' : plan}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  endDateLabel.isEmpty ? remainingLabel : 'Ends $endDateLabel',
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
                if (days > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    remainingLabel,
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
//  PLAN DETAIL SCREEN  (matches the "Custom Package" screenshot)
// ════════════════════════════════════════════════════════════════════

String _formatSubscriptionDate(DateTime? date) {
  if (date == null) {
    return '';
  }

  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final localDate = date.toLocal();
  return '${localDate.day} ${months[localDate.month - 1]} ${localDate.year}';
}

String _remainingDaysLabel(int days) {
  if (days <= 0) {
    return 'Expires soon';
  }

  return '$days ${days == 1 ? 'day' : 'days'} remaining';
}

String _subscriptionDisplayPlanName(
  Map<String, dynamic>? activePlan,
  String fallbackPlanCode,
) {
  final rawName =
      (activePlan?['name'] ??
              activePlan?['displayName'] ??
              activePlan?['title'] ??
              activePlan?['code'] ??
              fallbackPlanCode)
          .toString()
          .trim();
  if (rawName.isEmpty) {
    return 'Premium';
  }

  final cleaned = rawName.replaceAll('_', ' ').replaceAll('-', ' ').trim();
  if (cleaned.isEmpty) {
    return 'Premium';
  }

  return cleaned
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
      .join(' ');
}

class _SubscriptionTimelineCard extends StatelessWidget {
  const _SubscriptionTimelineCard({
    required this.isDark,
    required this.durationDays,
    required this.subscription,
  });

  final bool isDark;
  final int durationDays;
  final SubscriptionService subscription;

  @override
  Widget build(BuildContext context) {
    final remainingDays = subscription.daysRemaining;
    final endDateLabel = _formatSubscriptionDate(subscription.expiresAt.value);
    final textPrimary = isDark ? Colors.white : const Color(0xFF16102B);
    final textMuted = isDark ? Colors.white70 : const Color(0xFF6B6680);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1520) : const Color(0xFFFFF5F7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF2E2840) : const Color(0xFFEDE9FE),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your subscription',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          _SubscriptionFactRow(
            label: 'Duration',
            value: durationDays > 0
                ? '$durationDays ${durationDays == 1 ? 'day' : 'days'}'
                : 'Not available',
            textPrimary: textPrimary,
            textMuted: textMuted,
          ),
          const SizedBox(height: 8),
          _SubscriptionFactRow(
            label: 'Ends',
            value: endDateLabel.isEmpty ? 'Not available' : endDateLabel,
            textPrimary: textPrimary,
            textMuted: textMuted,
          ),
          const SizedBox(height: 8),
          _SubscriptionFactRow(
            label: 'Remaining',
            value: _remainingDaysLabel(remainingDays),
            textPrimary: textPrimary,
            textMuted: textMuted,
          ),
        ],
      ),
    );
  }
}

class _SubscriptionFactRow extends StatelessWidget {
  const _SubscriptionFactRow({
    required this.label,
    required this.value,
    required this.textPrimary,
    required this.textMuted,
  });

  final String label;
  final String value;
  final Color textPrimary;
  final Color textMuted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textMuted,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanDetailScreen extends StatefulWidget {
  const _PlanDetailScreen({
    required this.plan,
    required this.monetization,
    required this.subscription,
  });

  final Map<String, dynamic> plan;
  final MonetizationService monetization;
  final SubscriptionService subscription;

  @override
  State<_PlanDetailScreen> createState() => _PlanDetailScreenState();
}

class _PlanDetailScreenState extends State<_PlanDetailScreen> {
  bool _buying = false;
  Timer? _countdownTicker;

  @override
  void initState() {
    super.initState();
    _countdownTicker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.monetization.supportsInAppPurchases) {
        await widget.monetization.ensureStorePricesLoaded();
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTicker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F0A10) : const Color(0xFFFFF5F7);
    final cardBg = isDark ? const Color(0xFF1C1A28) : Colors.white;
    final features = _featuresFor(widget.plan);
    final name = _planName(widget.plan);
    final cycleText = _cycleLabel(widget.plan);
    final purchasesAvailable = widget.monetization.supportsInAppPurchases;
    final priceText = purchasesAvailable
        ? _priceLabel(widget.plan)
        : 'Benefits';

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : const Color(0xFF16102B),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF16102B),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Rose price header ─────────────────────
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6E3DFB), Color(0xFF8B5CF6)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6E3DFB).withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                child: Column(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      priceText,
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1,
                        letterSpacing: -1,
                      ),
                    ),
                    if (cycleText.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        cycleText,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // ─── Feature list ────────────────────────────
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF2E2840)
                          : const Color(0xFFEDE9FE),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: features.isEmpty
                      ? _NoFeatures(isDark: isDark)
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          itemCount: features.length,
                          separatorBuilder: (context, _) => Divider(
                            height: 1,
                            thickness: 1,
                            color: isDark
                                ? const Color(0xFF2A2435)
                                : const Color(0xFFEDE9FE),
                          ),
                          itemBuilder: (_, i) =>
                              _FeatureRow(isDark: isDark, text: features[i]),
                        ),
                ),
              ),
              const SizedBox(height: 14),
              Obx(() {
                final isCurrent = widget.monetization.isExactPlanCurrent(
                  widget.plan,
                );
                if (!isCurrent) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SubscriptionTimelineCard(
                    isDark: isDark,
                    durationDays: _durationDays(widget.plan),
                    subscription: widget.subscription,
                  ),
                );
              }),
              Obx(() {
                final isCurrent = widget.monetization.isExactPlanCurrent(
                  widget.plan,
                );
                if (!purchasesAvailable) {
                  return _IosPurchaseNotice(isDark: isDark);
                }
                if (isCurrent) {
                  return _BrandButton(
                    label: _buying ? 'Opening...' : 'Cancel Plan',
                    icon: _buying ? null : LucideIcons.x,
                    loading: _buying,
                    onPressed: _buying ? null : _handleCancel,
                  );
                }
                final needsStoreProduct =
                    widget.monetization.isAppleStorePurchasePlatform;
                final hasStoreMapping =
                    !needsStoreProduct || _hasAppleStoreMapping(widget.plan);
                final storeProductReady =
                    !needsStoreProduct ||
                    widget.monetization.isStoreProductReadyForPlan(widget.plan);
                final buyLabel = _buying
                    ? 'Processing...'
                    : !hasStoreMapping
                    ? 'Unavailable in App Store'
                    : storeProductReady
                    ? 'Buy It Now'
                    : 'Continue with App Store';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _BrandButton(
                      label: buyLabel,
                      icon: _buying ? null : LucideIcons.shoppingBag,
                      loading: _buying,
                      onPressed: _buying || !hasStoreMapping
                          ? null
                          : _handleBuy,
                    ),
                    if (needsStoreProduct &&
                        hasStoreMapping &&
                        !storeProductReady) ...[
                      const SizedBox(height: 10),
                      Text(
                        'We will load the App Store product for this plan as soon as you continue.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? Colors.white54
                              : const Color(0xFF8A84A3),
                        ),
                      ),
                    ] else if (needsStoreProduct && !hasStoreMapping) ...[
                      const SizedBox(height: 10),
                      Text(
                        'This package is not linked to App Store Connect yet.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? Colors.white54
                              : const Color(0xFF8A84A3),
                        ),
                      ),
                    ],
                  ],
                );
              }),
              const SizedBox(height: 10),
              Text(
                purchasesAvailable
                    ? 'Cancel anytime from your store subscription settings.'
                    : 'No purchase or checkout is available on this device.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.white54 : const Color(0xFF8A84A3),
                ),
              ),
              if (purchasesAvailable) ...[
                const SizedBox(height: 14),
                _SubscriptionTermsDisclosure(isDark: isDark),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── Buy flow ────────────────────────────────────────────────

  Future<void> _handleBuy() async {
    final code = _SubscriptionScreenState._codeOf(widget.plan);
    if (code.isEmpty) {
      Helpers.showSnackbar(message: 'Invalid plan.', isError: true);
      return;
    }

    await Future.wait([
      widget.monetization.fetchStatus(),
      widget.monetization.fetchActivePlans(),
    ]);

    if (widget.monetization.isExactPlanCurrent(widget.plan)) {
      Helpers.showSnackbar(
        message: 'You are already subscribed to this plan.',
        isError: true,
      );
      return;
    }

    setState(() => _buying = true);
    try {
      final days = _durationDays(widget.plan);
      final ok = await widget.monetization.purchaseSubscription(
        code,
        days,
        planMetadata: widget.plan,
      );

      if (!mounted) return;

      if (!ok) {
        Helpers.showSnackbar(
          message:
              widget.monetization.currentPurchaseFailureMessage ??
              'Purchase failed. Please try again.',
          isError: true,
        );
        return;
      }

      await Future.wait([
        widget.monetization.fetchStatus(),
        widget.monetization.fetchActivePlans(),
        widget.monetization.fetchEntitlements(),
      ]);

      if (!mounted) return;
      Helpers.showSnackbar(message: 'Premium is now active. Enjoy!');
      Get.back();
    } finally {
      if (mounted) setState(() => _buying = false);
    }
  }

  // ─── Plan helpers ────────────────────────────────────────────

  String _planName(Map<String, dynamic> p) {
    final raw =
        (p['name'] ?? p['displayName'] ?? p['title'] ?? p['code'] ?? 'Plan')
            .toString();
    return raw.trim().isEmpty ? 'Plan' : raw.trim();
  }

  bool _hasAppleStoreMapping(Map<String, dynamic> plan) {
    final raw =
        (plan['appleProductId'] ??
                plan['iosProductId'] ??
                plan['apple_product_id'] ??
                plan['ios_product_id'] ??
                '')
            .toString()
            .trim();
    return raw.isNotEmpty;
  }

  Future<void> _handleCancel() async {
    setState(() => _buying = true);
    try {
      await widget.monetization.openManageSubscriptionCenter();
    } finally {
      if (mounted) {
        setState(() => _buying = false);
      }
    }
  }

  int _durationDays(Map<String, dynamic> p) {
    final raw = p['durationDays'] ?? p['duration_days'] ?? 0;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw) ?? 30;
    return 30;
  }

  String _priceLabel(Map<String, dynamic> p) {
    final storePrice = widget.monetization.localizedPriceForPlan(p);
    if (storePrice != null && storePrice.isNotEmpty) return storePrice;

    final price = _SubscriptionScreenState._priceOf(p);
    if (price <= 0) return 'Free';
    final currency = (p['currency'] ?? 'USD').toString().toUpperCase();
    final symbol = _currencySymbol(currency);
    final whole = price.truncate();
    final hasFraction = price - whole != 0;
    final formatted = hasFraction ? price.toStringAsFixed(2) : '$whole';
    return '$symbol$formatted';
  }

  String _currencySymbol(String code) {
    if (code == 'EUR') return 'EUR ';
    if (code == 'GBP') return 'GBP ';
    switch (code) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      default:
        return '';
    }
  }

  String _cycleLabel(Map<String, dynamic> p) {
    final cycle = (p['billingCycle'] ?? p['billing_cycle'] ?? '')
        .toString()
        .toLowerCase();
    if (cycle == 'monthly') return 'per month';
    if (cycle == 'yearly') return 'per year';
    if (cycle == 'weekly') return 'per week';
    final days = _durationDays(p);
    if (days >= 300) return 'per year';
    if (days >= 25) return 'per month';
    if (days >= 6) return 'per week';
    return '';
  }

  List<String> _featuresFor(Map<String, dynamic> p) {
    final raw = p['features'] ?? p['benefits'] ?? p['perks'];
    final list = <String>[];
    if (raw is List) {
      for (final item in raw) {
        final text = item.toString().trim();
        if (text.isNotEmpty) list.add(text);
      }
    } else if (raw is Map) {
      raw.forEach((key, value) {
        final enabled =
            value == true || value.toString().toLowerCase() == 'true';
        if (enabled) list.add(_humanize(key.toString()));
      });
    }
    // Sensible default when the backend didn't ship features on the plan.
    if (list.isEmpty) {
      list.addAll(const [
        'Unlimited likes',
        'See who liked you',
        'Advanced filters',
        'Priority in search',
        'Read receipts',
      ]);
    }
    return list;
  }

  String _humanize(String raw) {
    final cleaned = raw
        .replaceAll(RegExp(r'[_\-]+'), ' ')
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (m) => '${m.group(1)} ${m.group(2)}',
        )
        .trim();
    if (cleaned.isEmpty) return raw;
    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.isDark, required this.text});
  final bool isDark;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF16102B),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Decorative "included" switch — always ON, non-interactive.
          _StaticSwitch(on: true),
        ],
      ),
    );
  }
}

class _StaticSwitch extends StatelessWidget {
  const _StaticSwitch({required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) {
    final trackColor = on ? const Color(0xFF6E3DFB) : const Color(0xFFCFC7E6);
    return Container(
      width: 42,
      height: 24,
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.all(2),
      child: Align(
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _displayPlanName(
    Map<String, dynamic>? activePlan,
    String fallbackPlanCode,
  ) {
    final rawName =
        (activePlan?['name'] ??
                activePlan?['displayName'] ??
                activePlan?['title'] ??
                activePlan?['code'] ??
                fallbackPlanCode)
            .toString()
            .trim();
    if (rawName.isEmpty) {
      return 'Premium';
    }

    final cleaned = rawName.replaceAll('_', ' ').replaceAll('-', ' ').trim();
    if (cleaned.isEmpty) {
      return 'Premium';
    }

    return cleaned
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
        .join(' ');
  }
}

class _NoFeatures extends StatelessWidget {
  const _NoFeatures({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No feature list provided for this plan.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white60 : const Color(0xFF8A84A3),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
//  RESTORE PURCHASES BUTTON (Apple App Store requirement 3.1.2)
// ════════════════════════════════════════════════════════════════════

class _RestorePurchasesButton extends StatefulWidget {
  const _RestorePurchasesButton({
    required this.isDark,
    required this.monetization,
  });

  final bool isDark;
  final MonetizationService monetization;

  @override
  State<_RestorePurchasesButton> createState() =>
      _RestorePurchasesButtonState();
}

class _RestorePurchasesButtonState extends State<_RestorePurchasesButton> {
  bool _restoring = false;

  Future<void> _handleRestore() async {
    setState(() => _restoring = true);
    try {
      final restored = await widget.monetization.restoreSubscriptionState();
      if (!mounted) return;
      if (restored) {
        Helpers.showSnackbar(message: 'Purchases restored successfully.');
      } else {
        Helpers.showSnackbar(
          message: 'No previous purchases found to restore.',
        );
      }
    } catch (_) {
      if (!mounted) return;
      Helpers.showSnackbar(
        message: 'Could not restore purchases. Please try again.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? Colors.white70 : const Color(0xFF6A6780);
    return Center(
      child: TextButton.icon(
        onPressed: _restoring ? null : _handleRestore,
        icon: _restoring
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: textColor,
                ),
              )
            : Icon(LucideIcons.refreshCcw, size: 15, color: textColor),
        label: Text(
          _restoring ? 'Restoring...' : 'Restore Purchases',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
//  SUBSCRIPTION TERMS DISCLOSURE (Apple App Store requirement 3.1.2a)
// ════════════════════════════════════════════════════════════════════

class _SubscriptionTermsDisclosure extends StatelessWidget {
  const _SubscriptionTermsDisclosure({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? Colors.white54 : const Color(0xFF8A84A3);
    final link = isDark ? const Color(0xFFA78BFA) : const Color(0xFF6E3DFB);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Text(
            'Payment will be charged to your App Store account at '
            'confirmation of purchase. Subscription automatically renews '
            'unless auto-renew is turned off at least 24 hours before the '
            'end of the current period. Your account will be charged for '
            'renewal within 24 hours prior to the end of the current period. '
            'You can manage and cancel your subscriptions by going to your '
            'account settings on the App Store after purchase.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: muted, height: 1.5),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => Get.toNamed(AppRoutes.termsConditions),
                child: Text(
                  'Terms of Use',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: link,
                    decoration: TextDecoration.underline,
                    decorationColor: link,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('•', style: TextStyle(color: muted, fontSize: 10)),
              ),
              GestureDetector(
                onTap: () => Get.toNamed(AppRoutes.privacyPolicy),
                child: Text(
                  'Privacy Policy',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: link,
                    decoration: TextDecoration.underline,
                    decorationColor: link,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════
//  SHARED BRAND BUTTON
// ════════════════════════════════════════════════════════════════════

class _BrandButton extends StatelessWidget {
  const _BrandButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.filled = true,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    final foreground = filled
        ? Colors.white
        : disabled
        ? const Color(0xFFA78BFA)
        : AppColors.primary;
    final borderColor = filled
        ? Colors.transparent
        : disabled
        ? const Color(0xFFD9CCFF)
        : AppColors.primary.withValues(alpha: 0.34);

    return SizedBox(
      height: 54,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: filled ? null : Colors.transparent,
            gradient: filled
                ? LinearGradient(
                    colors: disabled
                        ? const [Color(0xFFC4B5FD), Color(0xFFA78BFA)]
                        : const [Color(0xFF6E3DFB), Color(0xFF8B5CF6)],
                  )
                : null,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(999),
            boxShadow: !filled || disabled
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (loading)
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(foreground),
                      ),
                    )
                  else if (icon != null)
                    Icon(icon, color: foreground, size: 18),
                  if (loading || icon != null) const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: foreground,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
