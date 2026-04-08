import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/data/services/api_service.dart';
import 'package:methna_app/app/theme/app_colors.dart';
import 'package:methna_app/app/theme/app_radii.dart';
import 'package:methna_app/app/theme/app_spacing.dart';
import 'package:methna_app/app/theme/app_text_styles.dart';
import 'package:methna_app/core/constants/api_constants.dart';
import 'package:methna_app/core/utils/helpers.dart';
import 'package:methna_app/core/widgets/animated_empty_state.dart';
import 'package:methna_app/core/widgets/custom_button.dart';
import 'package:methna_app/core/widgets/custom_text_field.dart';
import 'package:methna_app/core/widgets/settings_flow.dart';

class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  final ApiService _api = Get.find<ApiService>();
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final RxInt _selectedTab = 0.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool isLoadingTickets = false.obs;
  final RxList<Map<String, dynamic>> myTickets = <Map<String, dynamic>>[].obs;

  @override
  void initState() {
    super.initState();
    _fetchMyTickets();
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;
    isSubmitting.value = true;
    try {
      await _api.post(
        ApiConstants.supportTickets,
        data: {
          'subject': _subjectCtrl.text.trim(),
          'message': _messageCtrl.text.trim(),
        },
      );
      _subjectCtrl.clear();
      _messageCtrl.clear();
      Helpers.showSnackbar(message: 'ticket_submitted'.tr);
      _selectedTab.value = 1;
      _fetchMyTickets();
    } catch (e) {
      Helpers.showSnackbar(
        message: Helpers.extractErrorMessage(e),
        isError: true,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> _fetchMyTickets() async {
    isLoadingTickets.value = true;
    try {
      final response = await _api.get(ApiConstants.myTickets);
      final data = response.data;
      final list = data is Map
          ? (data['tickets'] ?? [])
          : (data is List ? data : []);
      myTickets.value = List<Map<String, dynamic>>.from(list);
    } catch (_) {
    } finally {
      isLoadingTickets.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSimplePageScaffold(
      title: 'contact_support'.tr,
      body: Obx(
        () => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          children: [
            SettingsSegmentedControl(
              labels: ['new_ticket'.tr, 'my_tickets'.tr],
              selectedIndex: _selectedTab.value,
              onSelected: (index) => _selectedTab.value = index,
            ),
            const SizedBox(height: AppSpacing.md),
            if (_selectedTab.value == 0) _buildForm() else _buildTickets(),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          SettingsPlainListCard(
            children: [
              SettingsPlainTile(title: 'response_time_note'.tr),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          CustomTextField(
            controller: _subjectCtrl,
            label: 'subject'.tr,
            hint: 'subject'.tr,
            validator: (v) => (v == null || v.trim().length < 3)
                ? 'subject_min_chars'.tr
                : null,
          ),
          const SizedBox(height: AppSpacing.md),
          CustomTextField(
            controller: _messageCtrl,
            label: 'message'.tr,
            hint: 'report_hint'.tr,
            validator: (v) => (v == null || v.trim().length < 10)
                ? 'message_min_chars'.tr
                : null,
            maxLines: 6,
            textInputAction: TextInputAction.newline,
          ),
          const SizedBox(height: AppSpacing.lg),
          Obx(
            () => CustomButton(
              text: 'submit_ticket'.tr,
              isLoading: isSubmitting.value,
              onPressed: isSubmitting.value ? null : _submitTicket,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTickets() {
    return Obx(() {
      if (isLoadingTickets.value) {
        return const Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      }

      if (myTickets.isEmpty) {
        return AnimatedEmptyState(
          lottieAsset: 'assets/animations/no_support_tickets.json',
          title: 'no_tickets_yet'.tr,
          subtitle: 'no_tickets_desc'.tr,
          fallbackIcon: Icons.support_agent_rounded,
          fallbackColor: AppColors.primary,
          primaryActionLabel: 'refresh'.tr,
          onPrimaryAction: _fetchMyTickets,
          width: 174,
        );
      }

      return Column(
        children: myTickets
            .map(
              (ticket) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _TicketCard(ticket: ticket),
              ),
            )
            .toList(growable: false),
      );
    });
  }
}

class _TicketCard extends StatelessWidget {
  final Map<String, dynamic> ticket;

  const _TicketCard({required this.ticket});

  Color _statusColor(String status) {
    switch (status) {
      case 'open':
        return const Color(0xFFFF9800);
      case 'in_progress':
        return const Color(0xFF2196F3);
      case 'resolved':
        return const Color(0xFF4CAF50);
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'open':
        return 'ticket_open'.tr;
      case 'in_progress':
        return 'ticket_in_progress'.tr;
      case 'resolved':
        return 'ticket_resolved'.tr;
      case 'closed':
        return 'ticket_closed'.tr;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final secondaryColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final status = ticket['status']?.toString() ?? 'open';
    final created = ticket['createdAt'] != null
        ? DateTime.tryParse(ticket['createdAt'])
        : null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceGlassDark : Colors.white,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ticket['subject']?.toString() ?? '',
                  style: AppTextStyles.titleMedium.copyWith(color: textColor),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: _statusColor(status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  _statusLabel(status),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: _statusColor(status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            ticket['message']?.toString() ?? '',
            style: AppTextStyles.bodySmall.copyWith(color: secondaryColor),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if ((ticket['adminReply']?.toString() ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              ticket['adminReply'].toString(),
              style: AppTextStyles.bodySmall.copyWith(color: textColor),
            ),
          ],
          if (created != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              Helpers.timeAgo(created),
              style: AppTextStyles.bodySmall.copyWith(color: secondaryColor),
            ),
          ],
        ],
      ),
    );
  }
}
