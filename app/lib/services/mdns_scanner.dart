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

  /// Scan for Quest VR devices on the local network.
  Future<List<MdnsDiscoveredDevice>> scan({
    int timeoutSeconds = kMdnsTimeoutSeconds,
  }) async {
    // Strategy 1: pure Dart mDNS (no ADB server, no auto-connect)
    try {
      final devices = await _scanWithMDns(timeoutSeconds);
      if (devices.isNotEmpty) return devices;
    } on TimeoutException {
      // Expected when no devices respond — not an error
      LogService.info('mDNS: no devices found within timeout');
    } catch (e) {
      LogService.error('mDNS scan failed: $e');
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

  /// Pure Dart mDNS discovery using the [`multicast_dns`] package.
  ///
  /// Queries for `_adb-tls-connect._tcp.local` — the service type Quest
  /// wireless debugging advertises. No ADB server is involved so there is
  /// no risk of auto-connecting to discovered devices.
  Future<List<MdnsDiscoveredDevice>> _scanWithMDns(int timeoutSeconds) async {
    final results = <MdnsDiscoveredDevice>[];
    final client = MDnsClient();

    try {
      await client.start();
      final serviceName = '_adb-tls-connect._tcp.local';

      await for (final ptr in client
          .lookup<PtrResourceRecord>(
            ResourceRecordQuery.serverPointer(serviceName),
          )
          .timeout(Duration(seconds: timeoutSeconds))) {
        // Resolve SRV record to get port and target hostname
        try {
          await for (final srv in client
              .lookup<SrvResourceRecord>(
                ResourceRecordQuery.service(ptr.domainName),
              )
              .timeout(Duration(seconds: timeoutSeconds ~/ 2))) {
            // Resolve IPv4 address
            String? ip;

            await for (final addr in client
                .lookup<IPAddressResourceRecord>(
                  ResourceRecordQuery.addressIPv4(srv.target),
                )
                .timeout(Duration(seconds: timeoutSeconds ~/ 2))) {
              ip = addr.address.address;
              break;
            }

            // Fallback: try IPv6 if IPv4 not found
            if (ip == null) {
              await for (final addr in client
                  .lookup<IPAddressResourceRecord>(
                    ResourceRecordQuery.addressIPv6(srv.target),
                  )
                  .timeout(Duration(seconds: timeoutSeconds ~/ 2))) {
                ip = addr.address.address;
                break;
              }
            }

            if (ip != null) {
              results.add(MdnsDiscoveredDevice(
                ip: ip,
                port: srv.port,
                name: ptr.domainName,
              ));
            }
          }
        } on TimeoutException {
          // Skip if SRV resolution times out for this entry
        } catch (e) {
          LogService.error('mDNS: unexpected SRV error: $e');
        }
      }
    } finally {
      client.stop();
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

    final lines = await process.stdout
        .transform(const SystemEncoding().decoder)
        .transform(const LineSplitter())
        .where((line) => line.startsWith('='))
        .toList()
        .timeout(Duration(seconds: timeoutSeconds + 2));

    process.kill();

    for (final line in lines) {
      // =;interface;protocol;name;type;domain;hostname;ip;port;txt
      final parts = line.split(';');
      if (parts.length >= 9) {
        final ip = parts[7];
        final port = int.tryParse(parts[8]) ?? kDefaultAdbPort;
        results.add(MdnsDiscoveredDevice(
          ip: ip,
          port: port,
          name: parts[3],
        ));
      }
    }

    return results;
  }

  void stop() {
    // nothing to stop
  }
}
