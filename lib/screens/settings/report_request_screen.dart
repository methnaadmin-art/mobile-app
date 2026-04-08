import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/controllers/settings_controller.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/core/widgets/animated_empty_state.dart';
import 'package:methna_app/core/widgets/custom_button.dart';
import 'package:methna_app/core/widgets/custom_text_field.dart';
import 'package:methna_app/core/widgets/settings_flow.dart';

class ReportRequestScreen extends StatefulWidget {
  const ReportRequestScreen({super.key});

  @override
  State<ReportRequestScreen> createState() => _ReportRequestScreenState();
}

class _ReportRequestScreenState extends State<ReportRequestScreen> {
  final SettingsController controller = Get.find<SettingsController>();
  final TextEditingController _textController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String _selectedType = 'feedback';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    controller.fetchMyReports(silent: true);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);
    final success = await controller.submitFeedback(
      _selectedType,
      _textController.text.trim(),
    );
    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);
    if (success) {
      Get.back();
    }
  }

  String _reportReasonLabel(dynamic rawReason) {
    final reason = rawReason?.toString().trim().toLowerCase() ?? '';
    switch (reason) {
      case 'fake':
      case 'fake_user':
      case 'fake_profile':
        return 'fake_profile'.tr;
      case 'inappropriate':
      case 'inappropriate_content':
        return 'inappropriate_content'.tr;
      case 'harassment':
      case 'abuse':
        return 'harassment'.tr;
      case 'spam':
        return 'spam'.tr;
      case 'underage':
        return 'underage'.tr;
      case 'feedback':
        return 'general_feedback'.tr;
      case 'bug':
        return 'report_bug'.tr;
      case 'suggestion':
        return 'feature_suggestion'.tr;
      default:
        return 'other'.tr;
    }
  }

  String _reportStatusKey(dynamic rawStatus) {
    final status = rawStatus?.toString().trim().toLowerCase() ?? '';
    switch (status) {
      case 'open':
      case 'new':
      case 'submitted':
      case 'created':
        return 'submitted';
      case 'in_progress':
      case 'in-review':
      case 'in_review':
      case 'pending':
      case 'under_review':
      case 'investigating':
        return 'in_review';
      case 'resolved':
      case 'closed':
      case 'done':
        return 'resolved';
      case 'rejected':
      case 'declined':
      case 'dismissed':
        return 'rejected';
      default:
        return 'submitted';
    }
  }

  String _reportStatusLabel(String statusKey) {
    final key = 'report_status_$statusKey';
    final translated = key.tr;
    if (translated == key) {
      return statusKey.replaceAll('_', ' ');
    }
    return translated;
  }

  Color _reportStatusColor(String statusKey) {
    switch (statusKey) {
      case 'resolved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'in_review':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  String _reportDateLabel(Map<String, dynamic> report) {
    final rawDate =
        report['createdAt'] ??
        report['created_at'] ??
        report['submittedAt'] ??
        report['submitted_at'];
    if (rawDate is! String || rawDate.trim().isEmpty) {
      return '';
    }

    final parsed = DateTime.tryParse(rawDate);
    if (parsed == null) {
      return '';
    }

    final localDate = parsed.toLocal();
    return MaterialLocalizations.of(context).formatShortDate(localDate);
  }

  Widget _buildReportHistorySection() {
    final theme = Theme.of(context);

    return Obx(() {
      final reports = controller.myReports.take(5).toList(growable: false);
      final isLoading = controller.isLoadingMyReports.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'report_history'.tr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                TextButton(
                  onPressed: () => controller.fetchMyReports(),
                  child: Text('refresh'.tr),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (reports.isEmpty)
            AnimatedEmptyState(
              lottieAsset: 'assets/animations/no_support_tickets.json',
              title: 'no_reports_yet'.tr,
              subtitle: 'report_request_desc'.tr,
              fallbackIcon: Icons.report_gmailerrorred_rounded,
              fallbackColor: AppColors.primary,
              primaryActionLabel: 'refresh'.tr,
              onPrimaryAction: controller.fetchMyReports,
              width: 166,
            )
          else
            SettingsPlainListCard(
              children: reports
                  .map((report) {
                    final statusKey = _reportStatusKey(report['status']);
                    final statusColor = _reportStatusColor(statusKey);
                    final dateLabel = _reportDateLabel(report);

                    return SettingsPlainTile(
                      title: _reportReasonLabel(report['reason']),
                      subtitle: dateLabel.isEmpty ? null : dateLabel,
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _reportStatusLabel(statusKey),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SettingsSimplePageScaffold(
        title: 'report_request'.tr,
        subtitle: 'report_request_desc'.tr,
        footer: CustomButton(
          text: 'submit'.tr,
          isLoading: _isSubmitting,
          onPressed: _isSubmitting ? null : _submit,
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            children: [
              SettingsPlainListCard(
                children: [
                  SettingsRadioTile(
                    title: 'general_feedback'.tr,
                    subtitle: 'general_feedback_desc'.tr,
                    selected: _selectedType == 'feedback',
                    onTap: () => setState(() => _selectedType = 'feedback'),
                  ),
                  SettingsRadioTile(
                    title: 'report_bug'.tr,
                    subtitle: 'report_bug_desc'.tr,
                    selected: _selectedType == 'bug',
                    onTap: () => setState(() => _selectedType = 'bug'),
                  ),
                  SettingsRadioTile(
                    title: 'feature_suggestion'.tr,
                    subtitle: 'feature_suggestion_desc'.tr,
                    selected: _selectedType == 'suggestion',
                    onTap: () => setState(() => _selectedType = 'suggestion'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              CustomTextField(
                controller: _textController,
                label: 'description'.tr,
                hint: 'report_hint'.tr,
                maxLines: 7,
                textInputAction: TextInputAction.newline,
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.length < 10) {
                    return 'feedback_min_chars'.tr;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              _buildReportHistorySection(),
            ],
          ),
        ),
      ),
    );
  }
}
