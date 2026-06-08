import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/data/services/consumable_service.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/core/widgets/app_card.dart';
import 'package:methna_app/core/widgets/datify_shell.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ConsumableService _consumableService =
      Get.isRegistered<ConsumableService>()
      ? Get.find<ConsumableService>()
      : Get.put(ConsumableService());

  static const List<(String label, IconData icon, String type)> _tabs = [
    ('Likes', Icons.favorite_rounded, 'likes_pack'),
    ('Compliments', Icons.forum_rounded, 'compliments_pack'),
    ('Boosts', Icons.flash_on_rounded, 'boosts_pack'),
  ];

  bool get _purchasesAvailable =>
      !GetPlatform.isWeb &&
      (GetPlatform.isAndroid || GetPlatform.isIOS || GetPlatform.isMacOS);

  bool get _isAppleStorePlatform => GetPlatform.isIOS || GetPlatform.isMacOS;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    final initialType = args is Map
        ? (args['initialType'] ?? args['type'])?.toString()
        : args?.toString();
    final initialIndex = _tabs.indexWhere((tab) => tab.$3 == initialType);
    _tabController =
        TabController(
          length: _tabs.length,
          vsync: this,
          initialIndex: initialIndex < 0 ? 0 : initialIndex,
        )..addListener(() {
          if (!_tabController.indexIsChanging && mounted) {
            setState(() {});
          }
        });
    _consumableService.fetchProducts();
    _consumableService.fetchBalances();
  }

  Future<void> _refreshShop() async {
    final tasks = [
      _consumableService.fetchProducts(),
      _consumableService.fetchBalances(),
      if (_purchasesAvailable)
        _consumableService.retryPendingPurchaseVerification(),
    ];
    await Future.wait(tasks);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = _toneForType(_tabs[_tabController.index].$3);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DatifyBackground(
        compact: true,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(accent, isDark),
              Obx(() => _buildBalanceStrip(isDark)),
              Obx(() => _buildStoreStatusBanner(isDark)),
              _buildTabSelector(accent, isDark),
              Expanded(
                child: Obx(
                  () => TabBarView(
                    controller: _tabController,
                    children: [
                      _buildProductGrid(
                        _consumableService.visibleLikesPacks,
                        'likes_pack',
                        isDark,
                      ),
                      _buildProductGrid(
                        _consumableService.visibleComplimentsPacks,
                        'compliments_pack',
                        isDark,
                      ),
                      _buildProductGrid(
                        _consumableService.visibleBoostsPacks,
                        'boosts_pack',
                        isDark,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color accent, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => Get.back(),
              icon: Icon(
                Icons.arrow_back_rounded,
                color: isDark ? Colors.white : const Color(0xFF111422),
              ),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            ),
          ),
          const SizedBox(height: 6),
          AppCard(
            radius: 24,
            variant: AppCardVariant.tinted,
            tint: accent,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: isDark ? 0.3 : 0.14),
                  ),
                  child: Icon(
                    Icons.local_mall_rounded,
                    color: accent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Consumables Shop',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF111422),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _purchasesAvailable
                            ? 'Choose your pack and unlock smarter interactions. Max 10 purchases per day.'
                            : 'View your available balances. Purchases are not currently offered on this device.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.72)
                              : const Color(0xFF4A4E61),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreStatusBanner(bool isDark) {
    if (!_purchasesAvailable) {
      final fg = isDark ? Colors.white70 : const Color(0xFF4A4168);
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(18, 8, 18, 2),
        child: AppCard(
          radius: 14,
          variant: AppCardVariant.tinted,
          tint: const Color(0xFF6E3DFB),
          padding: const EdgeInsets.all(12),
          child: Text(
            'Purchases are not currently offered on this device. No checkout is exposed.',
            style: TextStyle(fontWeight: FontWeight.w600, color: fg),
          ),
        ),
      );
    }

    final message = _consumableService.purchaseMessage.value.trim();
    final hasStoreProducts = _consumableService.storeProducts.isNotEmpty;
    final isLoading = _consumableService.isLoading.value;

    if (message.isEmpty && (hasStoreProducts || isLoading)) {
      return const SizedBox.shrink();
    }

    final text = message.isNotEmpty
        ? message
        : _isAppleStorePlatform
        ? 'App Store products are loading. Purchases require App Store Connect products configured.'
        : 'Google Play products are loading. Purchases require a signed Android build with Play Console products configured.';

    final warningFg = isDark ? Colors.white : const Color(0xFF513100);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(18, 8, 18, 2),
      child: AppCard(
        radius: 14,
        variant: AppCardVariant.tinted,
        tint: isDark ? const Color(0xFFFFB55E) : AppColors.warning,
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(fontWeight: FontWeight.w600, color: warningFg),
              ),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: isLoading ? null : _refreshShop,
              icon: Icon(Icons.refresh_rounded, size: 18, color: warningFg),
              label: Text(
                'Retry',
                style: TextStyle(fontWeight: FontWeight.w700, color: warningFg),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceStrip(bool isDark) {
    final b = _consumableService.balances.value;

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 8),
      child: AppCard(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildBalanceItem(
              icon: Icons.favorite_rounded,
              label: 'Likes',
              count: b.likes,
              color: const Color(0xFFE95579),
              isDark: isDark,
            ),
            _buildBalanceItem(
              icon: Icons.forum_rounded,
              label: 'Compliments',
              count: b.compliments,
              color: const Color(0xFF4C74FF),
              isDark: isDark,
            ),
            _buildBalanceItem(
              icon: Icons.flash_on_rounded,
              label: 'Boosts',
              count: b.boosts,
              color: const Color(0xFFF0A035),
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceItem({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.16),
          ),
          child: Icon(icon, size: 19, color: color),
        ),
        const SizedBox(height: 2),
        Text(
          '$count',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF161A28),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark
                ? Colors.white.withValues(alpha: 0.68)
                : const Color(0xFF5B6075),
          ),
        ),
      ],
    );
  }

  Widget _buildTabSelector(Color accent, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 10, 18, 10),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white.withValues(alpha: 0.84),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : const Color(0xFFD7DFFF),
        ),
      ),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final tab = _tabs[index];
          final selected = _tabController.index == index;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: index == _tabs.length - 1 ? 0 : 6,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(13),
                  onTap: () => _tabController.animateTo(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13),
                      gradient: selected
                          ? LinearGradient(
                              colors: [
                                accent.withValues(alpha: 0.86),
                                accent.withValues(alpha: 0.66),
                              ],
                            )
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tab.$2,
                          size: 17,
                          color: selected
                              ? Colors.white
                              : isDark
                              ? Colors.white.withValues(alpha: 0.72)
                              : const Color(0xFF434A60),
                        ),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            tab.$1,
                            maxLines: 1,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: selected
                                  ? Colors.white
                                  : isDark
                                  ? Colors.white.withValues(alpha: 0.72)
                                  : const Color(0xFF434A60),
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
        }),
      ),
    );
  }

  Widget _buildProductGrid(
    List<ConsumableProduct> products,
    String type,
    bool isDark,
  ) {
    if (!_purchasesAvailable) {
      return _buildPurchasesUnavailableState(type, isDark);
    }

    if (_consumableService.isLoading.value && products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final tone = _toneForType(type);

    if (products.isEmpty) {
      // Wrap the empty state in a scrollable so RefreshIndicator still
      // triggers when the catalogue for this tab is empty.
      return RefreshIndicator(
        color: tone,
        onRefresh: _refreshShop,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: Center(
                child: Text(
                  'No ${_typeLabel(type)} packs available yet',
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.68)
                        : const Color(0xFF5C637A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final sorted = List<ConsumableProduct>.from(products)
      ..sort((a, b) => b.quantity.compareTo(a.quantity));

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 760
            ? 3
            : constraints.maxWidth >= 520
            ? 2
            : 1;

        return RefreshIndicator(
          color: tone,
          onRefresh: _refreshShop,
          child: GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 120),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisExtent: crossAxisCount == 1 ? 212 : 236,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              return _buildProductCard(
                product: sorted[index],
                tone: tone,
                isDark: isDark,
                highlighted: index == 0 && sorted.length > 1,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPurchasesUnavailableState(String type, bool isDark) {
    final tone = _toneForType(type);
    return RefreshIndicator(
      color: tone,
      onRefresh: _refreshShop,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 24, 18, 120),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.9),
              border: Border.all(
                color: tone.withValues(alpha: isDark ? 0.35 : 0.22),
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.lock_outline_rounded, color: tone, size: 30),
                const SizedBox(height: 10),
                Text(
                  '${_typeLabel(type)} packs are not currently available',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF111422),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'This screen shows your current balances only. There is no purchase or external checkout path on this device.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.68)
                        : const Color(0xFF5C637A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard({
    required ConsumableProduct product,
    required Color tone,
    required bool isDark,
    required bool highlighted,
  }) {
    final storeProductId = _consumableService.storeProductIdFor(product);
    final storeProduct = _consumableService.storeProducts[storeProductId];
    final canPurchase =
        _purchasesAvailable &&
        storeProductId.isNotEmpty &&
        storeProduct != null &&
        _consumableService.storeAvailable.value &&
        !_consumableService.isVerifying.value;
    final priceText =
        storeProduct?.price ??
        '\$${product.price.toStringAsFixed(product.price.truncateToDouble() == product.price ? 0 : 2)}';

    return AppCard(
      radius: 20,
      variant: AppCardVariant.tinted,
      tint: tone,
      padding: const EdgeInsets.all(14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: tone.withValues(alpha: highlighted ? 0.4 : 0.14),
            width: highlighted ? 1.4 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tone.withValues(alpha: isDark ? 0.26 : 0.16),
                  ),
                  child: Text(
                    product.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                const Spacer(),
                if (highlighted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: tone.withValues(alpha: 0.2),
                    ),
                    child: Text(
                      'Best value',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: tone,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              product.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF121625),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '+${product.quantity} ${product.typeLabel}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.78)
                    : const Color(0xFF50576E),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  _consumableService.isVerifying.value
                      ? 'Verifying…'
                      : priceText,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: tone,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 40,
                  child: FilledButton(
                    onPressed: canPurchase
                        ? () => _purchaseProduct(product)
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: tone,
                      disabledBackgroundColor: tone.withValues(alpha: 0.3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Buy',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _purchaseProduct(ConsumableProduct product) async {
    final success = await _consumableService.buyConsumable(product);
    if (!mounted) return;

    Get.snackbar(
      success ? 'Purchase complete' : 'Purchase unavailable',
      success
          ? '${product.quantity} ${product.typeLabel.toLowerCase()} added to your balance.'
          : (_consumableService.purchaseMessage.value.isNotEmpty
                ? _consumableService.purchaseMessage.value
                : 'Please try again later.'),
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'likes_pack':
        return 'likes';
      case 'compliments_pack':
        return 'compliments';
      case 'boosts_pack':
        return 'boosts';
      default:
        return type;
    }
  }

  Color _toneForType(String type) {
    switch (type) {
      case 'likes_pack':
        return const Color(0xFFE95579);
      case 'compliments_pack':
        return const Color(0xFF4C74FF);
      case 'boosts_pack':
        return const Color(0xFFF0A035);
      default:
        return AppColors.primary;
    }
  }
}
