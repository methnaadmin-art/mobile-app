import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:methna_app/core/widgets/datify_shell.dart';
import '../../../core/theme/premium_theme.dart';

/// Premium Settings Screen - Grouped sections with tap animations
class PremiumSettingsScreen extends StatelessWidget {
  const PremiumSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: DatifyBackground(
        compact: true,
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 20,
                  left: 24,
                  right: 24,
                  bottom: 20,
                ),
                child: Row(
                  children: [
                    _GlassIconButton(
                      icon: LucideIcons.chevronLeft,
                      onTap: () => Get.back(),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'settings'.tr,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Account Section
            _buildSectionTitle('account'.tr),
            SliverToBoxAdapter(
              child: _SettingsCard(
                items: [
                  _SettingsItem(
                    icon: LucideIcons.user,
                    iconColor: AppTheme.gold,
                    title: 'edit_profile'.tr,
                    subtitle: 'settings_update_info'.tr,
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: LucideIcons.image,
                    iconColor: const Color(0xFF6E3DFB),
                    title: 'my_photos'.tr,
                    subtitle: 'manage_your_photos'.tr,
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: LucideIcons.shield,
                    iconColor: AppTheme.success,
                    title: 'privacy'.tr,
                    subtitle: 'control_visibility'.tr,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Preferences Section
            _buildSectionTitle('preferences'.tr),
            SliverToBoxAdapter(
              child: _SettingsCard(
                items: [
                  _SettingsItem(
                    icon: LucideIcons.bell,
                    iconColor: const Color(0xFF8B5CF6),
                    title: 'notifications'.tr,
                    subtitle: 'manage_alerts'.tr,
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: LucideIcons.globe,
                    iconColor: const Color(0xFFA78BFA),
                    title: 'language'.tr,
                    subtitle: 'english'.tr,
                    showArrow: true,
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: LucideIcons.moon,
                    iconColor: const Color(0xFF6E3DFB),
                    title: 'dark_mode'.tr,
                    subtitle: 'always_on'.tr,
                    showArrow: true,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Premium Section
            _buildSectionTitle('premium'.tr),
            SliverToBoxAdapter(
              child: _SettingsCard(
                items: [
                  _SettingsItem(
                    icon: LucideIcons.crown,
                    iconColor: AppTheme.gold,
                    title: 'upgrade_to_premium'.tr,
                    subtitle: 'unlock_all_features'.tr,
                    isPremium: true,
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: LucideIcons.zap,
                    iconColor: const Color(0xFF8B5CF6),
                    title: 'boost_profile'.tr,
                    subtitle: 'get_more_visibility'.tr,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Support Section
            _buildSectionTitle('support'.tr),
            SliverToBoxAdapter(
              child: _SettingsCard(
                items: [
                  _SettingsItem(
                    icon: LucideIcons.helpCircle,
                    iconColor: AppTheme.white70,
                    title: 'help_center'.tr,
                    subtitle: 'get_assistance'.tr,
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: LucideIcons.fileText,
                    iconColor: AppTheme.white70,
                    title: 'terms_of_service'.tr,
                    subtitle: 'read_our_terms'.tr,
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: LucideIcons.lock,
                    iconColor: AppTheme.white70,
                    title: 'privacy_policy'.tr,
                    subtitle: 'how_we_protect_you'.tr,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),

            // Logout Button
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: PremiumButton(
                  onTap: () {},
                  isOutlined: true,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        LucideIcons.logOut,
                        size: 18,
                        color: AppTheme.error,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'logout'.tr,
                        style: const TextStyle(color: AppTheme.error),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(left: 24, bottom: 12),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: AppTheme.gold,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<_SettingsItem> items;

  const _SettingsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Column(
              children: [
                if (index > 0)
                  Divider(color: AppTheme.white10, height: 1, indent: 72),
                _SettingsRow(item: item, index: index),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _SettingsRow extends StatefulWidget {
  final _SettingsItem item;
  final int index;

  const _SettingsRow({required this.item, required this.index});

  @override
  State<_SettingsRow> createState() => _SettingsRowState();
}

class _SettingsRowState extends State<_SettingsRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _controller.forward().then((_) => _controller.reverse());
        widget.item.onTap();
      },
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: widget.item.isPremium
                  ? BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.gold.withValues(alpha: 0.1),
                          AppTheme.gold.withValues(alpha: 0.05),
                        ],
                      ),
                    )
                  : null,
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: widget.item.iconColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      widget.item.icon,
                      color: widget.item.iconColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.item.title,
                          style: TextStyle(
                            color: widget.item.isPremium
                                ? AppTheme.gold
                                : Colors.white,
                            fontSize: 15,
                            fontWeight: widget.item.isPremium
                                ? FontWeight.w800
                                : FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.item.subtitle,
                          style: const TextStyle(
                            color: AppTheme.white50,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Arrow
                  if (widget.item.showArrow)
                    const Icon(
                      LucideIcons.chevronRight,
                      color: AppTheme.white50,
                      size: 20,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(duration: 400.ms, delay: (widget.index * 80).ms);
  }
}

class _SettingsItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showArrow;
  final bool isPremium;

  _SettingsItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showArrow = true,
    this.isPremium = false,
  });
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.white10),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

