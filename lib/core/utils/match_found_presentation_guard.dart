class MatchFoundPresentationGuard {
  MatchFoundPresentationGuard._();

  static const Duration _cooldown = Duration(seconds: 2);

  static String _lastUserId = '';
  static DateTime? _lastPresentedAt;

  static bool shouldPresent(String? userId) {
    final normalizedUserId = (userId ?? '').trim();
    final lastPresentedAt = _lastPresentedAt;
    final now = DateTime.now();

    if (lastPresentedAt != null &&
        now.difference(lastPresentedAt) <= _cooldown &&
        normalizedUserId.isNotEmpty &&
        normalizedUserId == _lastUserId) {
      return false;
    }

    _lastUserId = normalizedUserId;
    _lastPresentedAt = now;
    return true;
  }
}
