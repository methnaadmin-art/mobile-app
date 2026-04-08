import 'package:flutter/material.dart';
import 'package:methna_app/core/widgets/loading_widget.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Shimmer skeleton screens for instant perceived loading on tab switch
// ═══════════════════════════════════════════════════════════════════════════

/// Profile tab skeleton — body-only, used inside ProfileScreen's Scaffold>SafeArea>Obx
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: [
              const ShimmerLoading(width: 100, height: 28, borderRadius: 8),
              const Spacer(),
              ShimmerLoading(width: 40, height: 40, borderRadius: 20),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Large photo placeholder
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AspectRatio(
            aspectRatio: 1,
            child: ShimmerLoading(borderRadius: 24),
          ),
        ),
        const SizedBox(height: 16),
        // Completion banner
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ShimmerLoading(height: 60, borderRadius: 16),
        ),
        const SizedBox(height: 16),
        // Info sections
        for (int i = 0; i < 3; i++) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: ShimmerLoading(height: 100, borderRadius: 18),
          ),
        ],
      ],
    );
  }
}

/// Users/Discover tab skeleton — body-only, used inside UsersScreen's Scaffold>SafeArea>Obx
class UsersSkeleton extends StatelessWidget {
  const UsersSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              const ShimmerLoading(width: 100, height: 28, borderRadius: 8),
              const Spacer(),
              ShimmerLoading(width: 40, height: 40, borderRadius: 20),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ShimmerLoading(width: 120, height: 18, borderRadius: 6),
        ),
        const SizedBox(height: 12),
        // Horizontal card row
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 4,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) =>
                ShimmerLoading(width: 150, height: 200, borderRadius: 18),
          ),
        ),
        const SizedBox(height: 24),
        // Category chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: List.generate(
              4,
              (_) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ShimmerLoading(width: 70, height: 34, borderRadius: 20),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: 4,
            itemBuilder: (context, index) => ShimmerLoading(borderRadius: 18),
          ),
        ),
      ],
    );
  }
}

/// Chat tab skeleton body — shimmer chat tiles for use inside Expanded/Column
class ChatSkeleton extends StatelessWidget {
  const ChatSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 8,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            ShimmerLoading(width: 52, height: 52, borderRadius: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerLoading(width: 120, height: 14, borderRadius: 6),
                  const SizedBox(height: 8),
                  ShimmerLoading(width: 200, height: 12, borderRadius: 6),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ShimmerLoading(width: 40, height: 12, borderRadius: 6),
          ],
        ),
      ),
    );
  }
}
