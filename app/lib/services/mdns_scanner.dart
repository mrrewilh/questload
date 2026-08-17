import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:multicast_dns/multicast_dns.dart';

import 'device_service.dart';
import 'log_service.dart';
import '../core/constants.dart';

/// Discovers Quest VR devices on the local network via mDNS.
///
/// Strategy:
/// 1. [`multicast_dns`] Dart package — pure mDNS, no ADB server, works everywhere
/// 2. `avahi-browse` on Linux (fallback if mDNS fails)
class MdnsScanner {
  MDnsClient? _client;

  /// Scan for Quest VR devices on the local network.
  Future<List<MdnsDiscoveredDevice>> scan({
    int timeoutSeconds = kMdnsTimeoutSeconds,
  }) async {
    // Strategy 1: pure Dart mDNS over a persistent client — it stays alive
    // across scans so its cache warms up from the devices' own announcements
    // and repeat scans return instantly instead of re-querying cold.
    try {
      final client = await _ensureClient();
      if (client != null) {
        final devices = await _scanWithMDns(client, timeoutSeconds);
        if (devices.isNotEmpty) return devices;
      }
    } catch (e) {
      LogService.error('mDNS scan failed: $e');
      // Sockets are likely stale (network change) — drop the client so the
      // next scan starts a fresh one.
      stop();
    }

    // Strategy 2: avahi-browse on Linux (fallback)
    if (Platform.isLinux) {
      try {
        final hasAvahi = await Process.run('which', ['avahi-browse']);
        if (hasAvahi.exitCode == 0) {
          return await _scanWithAvahi(timeoutSeconds);
        }
        LogService.info('avahi-browse not found on system');
      } catch (e) {
        LogService.error('avahi-browse check failed: $e');
      }
    }

    return [];
  }

  /// Starts the mDNS client once and keeps it alive. Null when it can't
  /// start (e.g. no network interface).
  Future<MDnsClient?> _ensureClient() async {
    if (_client != null) return _client;
    final client = MDnsClient();
    try {
      await client.start();
      _client = client;
    } catch (e) {
      LogService.error('mDNS client start failed: $e');
    }
    return _client;
  }

  /// Pure Dart mDNS discovery using the [`multicast_dns`] package.
  /// [client] must already be started — it's kept alive between scans.
  Future<List<MdnsDiscoveredDevice>> _scanWithMDns(
    MDnsClient client,
    int timeoutSeconds,
  ) async {
    final results = <MdnsDiscoveredDevice>[];
    final serviceName = '_adb-tls-connect._tcp.local';

    await for (final ptr in client.lookup<PtrResourceRecord>(
      ResourceRecordQuery.serverPointer(serviceName),
      timeout: Duration(seconds: timeoutSeconds),
    )) {
      // Resolve SRV record to get port and target hostname
      try {
        await for (final srv in client.lookup<SrvResourceRecord>(
          ResourceRecordQuery.service(ptr.domainName),
          timeout: Duration(seconds: timeoutSeconds ~/ 2),
        )) {
          // Resolve IPv4 address
          String? ip;

          await for (final addr in client.lookup<IPAddressResourceRecord>(
            ResourceRecordQuery.addressIPv4(srv.target),
            timeout: Duration(seconds: timeoutSeconds ~/ 2),
          )) {
            ip = addr.address.address;
            break;
          }

          // Fallback: try IPv6 if IPv4 not found
          if (ip == null) {
            await for (final addr in client.lookup<IPAddressResourceRecord>(
              ResourceRecordQuery.addressIPv6(srv.target),
              timeout: Duration(seconds: timeoutSeconds ~/ 2),
            )) {
              ip = addr.address.address;
              break;
            }
          }

          if (ip != null) {
            results.add(
              MdnsDiscoveredDevice(
                ip: ip,
                port: srv.port,
                name: ptr.domainName,
              ),
            );
            // Resolved — don't sit waiting for a second SRV record.
            break;
          }
        }
      } catch (e) {
        LogService.error('mDNS: unexpected SRV error: $e');
      }
    }

    // Deduplicate by IP — same device can appear via multiple PTR records
    final seen = <String>{};
    return results.where((d) => seen.add(d.ip)).toList();
  }

  /// Linux `avahi-browse` fallback.
  Future<List<MdnsDiscoveredDevice>> _scanWithAvahi(int timeoutSeconds) async {
    final results = <MdnsDiscoveredDevice>[];

    final process = await Process.start('avahi-browse', [
      '_adb-tls-connect._tcp',
      '--resolve',
      '--terminate',
      '-p',
    ]);
    // kill in finally so a timeout can't leak the process
    try {
      final lines = await process.stdout
          .transform(const SystemEncoding().decoder)
          .transform(const LineSplitter())
          .where((line) => line.startsWith('='))
          .toList()
          .timeout(Duration(seconds: timeoutSeconds + 2));

      for (final line in lines) {
        // =;interface;protocol;name;type;domain;hostname;ip;port;txt
        final parts = line.split(';');
        if (parts.length >= 9) {
          final ip = parts[7];
          final port = int.tryParse(parts[8]) ?? kDefaultAdbPort;
          results.add(MdnsDiscoveredDevice(ip: ip, port: port, name: parts[3]));
        }
      }
      return results;
    } finally {
      process.kill();
    }
  }

  /// Stops the persistent client, if any.
  void stop() {
    _client?.stop();
    _client = null;
  }
}
