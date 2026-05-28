import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/data/services/api_service.dart';

class BackendWaitPanel extends StatelessWidget {
  final String message;

  const BackendWaitPanel({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 260),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class BackendRequestOverlay extends StatelessWidget {
  final Widget child;
  final bool blockInteractions;

  const BackendRequestOverlay({
    super.key,
    required this.child,
    this.blockInteractions = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ApiService>()) {
      return child;
    }

    final api = Get.find<ApiService>();

    return Obx(() {
      final visible = api.activeInteractiveRequests.value > 0;
      if (!visible || !blockInteractions) {
        return child;
      }

      return Stack(
        fit: StackFit.expand,
        children: [
          child,
          ColoredBox(
            color: Colors.black.withValues(alpha: 0.08),
            child: const SizedBox.expand(),
          ),
        ],
      );
    });
  }
}
