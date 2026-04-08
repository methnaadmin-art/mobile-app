import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:methna_app/app/data/services/socket_service.dart';
import 'package:methna_app/app/data/services/message_queue_service.dart';

/// Network connectivity status
enum ConnectivityStatus { online, offline, checking }

/// Connectivity monitoring service with auto-reconnect support.
/// Handles network changes, airplane mode, and app lifecycle.
class ConnectivityService extends GetxService with WidgetsBindingObserver {
  final Rx<ConnectivityStatus> status = ConnectivityStatus.checking.obs;
  final RxBool isOnline = false.obs;

  Timer? _checkTimer;
  Timer? _reconnectTimer;
  Timer? _resumeCheckTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const Duration _checkInterval = Duration(seconds: 30);
  bool _initialized = false;
  bool _hasResolvedInitialState = false;

  Future<ConnectivityService> init() async {
    if (_initialized) return this;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    _startPeriodicCheck();
    Future.delayed(const Duration(milliseconds: 900), () {
      _checkConnectivity();
    });
    return this;
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _checkTimer?.cancel();
    _reconnectTimer?.cancel();
    _resumeCheckTimer?.cancel();
    super.onClose();
  }

  // ─── App Lifecycle ─────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resumeCheckTimer?.cancel();
      debugPrint('[Connectivity] App resumed - scheduling connectivity check');
      _resumeCheckTimer = Timer(const Duration(milliseconds: 600), () {
        debugPrint('[Connectivity] App resumed - checking connectivity');
        _onAppResumed();
      });
    } else if (state == AppLifecycleState.paused) {
      _resumeCheckTimer?.cancel();
      debugPrint('[Connectivity] App paused');
    }
  }

  void _onAppResumed() {
    _checkConnectivity().then((_) {
      if (isOnline.value) {
        _reconnectServices();
      }
    });
  }

  // ─── Connectivity Check ────────────────────────────────────

  Future<bool> _checkConnectivity() async {
    status.value = ConnectivityStatus.checking;
    try {
      // Try DNS lookup to verify actual internet connectivity
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 5));

      final connected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      _updateStatus(connected);
      return connected;
    } on SocketException catch (_) {
      _updateStatus(false);
      return false;
    } on TimeoutException catch (_) {
      _updateStatus(false);
      return false;
    } catch (e) {
      debugPrint('[Connectivity] Check error: $e');
      _updateStatus(false);
      return false;
    }
  }

  void _updateStatus(bool connected) {
    final isFirstResolution = !_hasResolvedInitialState;
    final wasOnline = isOnline.value;
    isOnline.value = connected;
    status.value = connected
        ? ConnectivityStatus.online
        : ConnectivityStatus.offline;

    if (isFirstResolution) {
      _hasResolvedInitialState = true;
      return;
    }

    if (connected && !wasOnline) {
      debugPrint('[Connectivity] Network restored');
      _onNetworkRestored();
    } else if (!connected && wasOnline) {
      debugPrint('[Connectivity] Network lost');
      _onNetworkLost();
    }
  }

  void _startPeriodicCheck() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(_checkInterval, (_) => _checkConnectivity());
  }

  // ─── Network State Changes ─────────────────────────────────

  void _onNetworkRestored() {
    _reconnectAttempts = 0;
    _reconnectServices();
    _flushMessageQueue();
  }

  void _onNetworkLost() {
    _reconnectTimer?.cancel();
    // Socket will handle its own disconnection
  }

  void _reconnectServices() {
    try {
      final socket = Get.find<SocketService>();
      if (!socket.isConnected.value) {
        debugPrint('[Connectivity] Reconnecting socket...');
        socket.connect();
      }
    } catch (e) {
      debugPrint('[Connectivity] Reconnect error: $e');
    }
  }

  void _flushMessageQueue() {
    try {
      final queue = Get.find<MessageQueueService>();
      if (queue.pendingCount > 0) {
        debugPrint(
          '[Connectivity] Flushing ${queue.pendingCount} queued messages',
        );
        queue.flushQueue();
      }
    } catch (e) {
      debugPrint('[Connectivity] Queue flush error: $e');
    }
  }

  // ─── Exponential Backoff Reconnect ─────────────────────────

  void scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('[Connectivity] Max reconnect attempts reached');
      return;
    }

    _reconnectTimer?.cancel();

    // Exponential backoff: 1s, 2s, 4s, 8s, 16s, 32s (max 32s)
    final delay = Duration(seconds: _calculateBackoffDelay());
    debugPrint(
      '[Connectivity] Scheduling reconnect in ${delay.inSeconds}s (attempt ${_reconnectAttempts + 1})',
    );

    _reconnectTimer = Timer(delay, () async {
      _reconnectAttempts++;
      final connected = await _checkConnectivity();
      if (connected) {
        _reconnectServices();
      } else {
        scheduleReconnect();
      }
    });
  }

  int _calculateBackoffDelay() {
    // Exponential backoff with jitter: base * 2^attempt + random(0-1s)
    const baseDelay = 1;
    const maxDelay = 32;
    final exponential = baseDelay * (1 << _reconnectAttempts);
    return exponential.clamp(baseDelay, maxDelay);
  }

  // ─── Public API ────────────────────────────────────────────

  /// Force a connectivity check
  Future<bool> checkNow() => _checkConnectivity();

  /// Reset reconnect attempts (call after successful connection)
  void resetReconnectAttempts() {
    _reconnectAttempts = 0;
  }

  /// Get current attempt count
  int get reconnectAttempts => _reconnectAttempts;
}
