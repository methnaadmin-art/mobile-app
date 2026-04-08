import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/controllers/settings_controller.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_radii.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/app/theme/app_text_styles.dart';
import 'package:methna_app/core/widgets/animated_empty_state.dart';
import 'package:methna_app/core/widgets/custom_text_field.dart';
import 'package:methna_app/core/widgets/settings_flow.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final SettingsController controller = Get.find<SettingsController>();
  final RxString searchQuery = ''.obs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchFaqContent();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSimplePageScaffold(
      title: 'faq'.tr,
      body: Obx(() {
        final query = searchQuery.value.trim().toLowerCase();
        final items = controller.faqItems.where((item) {
          final question = (item['question'] ?? '').toString().toLowerCase();
          final answer = (item['answer'] ?? '').toString().toLowerCase();
          if (query.isEmpty) return true;
          return question.contains(query) || answer.contains(query);
        }).toList();

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.fetchFaqContent,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            children: [
              CustomTextField(
                hint: 'search_faqs'.tr,
                prefixIcon: Icons.search_rounded,
                onChanged: (value) => searchQuery.value = value,
              ),
              const SizedBox(height: AppSpacing.md),
              if (controller.isLoadingFaq.value && controller.faqItems.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else if (items.isEmpty)
                _FaqEmptyState(
                  message: controller.faqError.value.isNotEmpty
                      ? controller.faqError.value
                      : 'no_faqs_found'.tr,
                )
              else
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _FaqTile(
                      question: item['question']?.toString() ?? '',
                      answer: item['answer']?.toString() ?? '',
                      initiallyExpanded: query.isEmpty && items.first == item,
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }
}

class _FaqEmptyState extends StatelessWidget {
  final String message;

  const _FaqEmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return AnimatedEmptyState(
      lottieAsset: 'assets/animations/empty.json',
      title: 'no_faqs_found'.tr,
      subtitle: message,
      fallbackIcon: Icons.help_outline_rounded,
      fallbackColor: AppColors.primary,
      width: 168,
    );
  }
}

class _FaqTile extends StatefulWidget {
  final String question;
  final String answer;
  final bool initiallyExpanded;

  const _FaqTile({
    required this.question,
    required this.answer,
    this.initiallyExpanded = false,
  });

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  late bool expanded;

  @override
  void initState() {
    super.initState();
    expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceGlassDark : Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: expanded
              ? AppColors.primary.withValues(alpha: 0.24)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => expanded = !expanded),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    expanded
                        ? Icons.remove_circle_outline_rounded
                        : Icons.add_circle_outline_rounded,
                    color: expanded
                        ? AppColors.primary
                        : (isDark
                              ? AppColors.textHintDark
                              : AppColors.textHintLight),
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.answer,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
