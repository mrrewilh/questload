
import '../core/constants.dart';

/// Result of an ADB connection attempt.
class AdbConnectResult {
  final bool success;
  final String? serial;
  final String? error;

  const AdbConnectResult({
    required this.success,
    this.serial,
    this.error,
  });

  @override
  String toString() => 'AdbConnectResult(success: $success, serial: $serial, error: $error)';
}

/// Result of an ADB pairing attempt (Android 11+ wireless debugging).
class AdbPairResult {
  final bool success;
  final String? error;
  final String? connectIp;
  final int? connectPort;

  const AdbPairResult({
    required this.success,
    this.error,
    this.connectIp,
    this.connectPort,
  });

  @override
  String toString() => 'AdbPairResult(success: $success, error: $error)';
}

/// Abstract interface for Quest device operations.
///
/// Every platform (desktop ADB over TCP, Quest VR direct, Android phone ADB)
/// provides its own implementation.  App code never imports concrete
class MdnsDiscoveredDevice {
  final String ip;
  final int port;
  final String? name;
  final String? model;

  const MdnsDiscoveredDevice({
    required this.ip,
    this.port = kDefaultAdbPort,
    this.name,
    this.model,
  });

  @override
  String toString() => 'MdnsDiscoveredDevice($ip:$port, $name)';
}
