import 'package:flutter/material.dart';

import '../core/app_theme.dart';

String headsetSvgForModel(String? model) {
  if (model == null) return 'assets/headsets/unknown.svg';
  final m = model.toLowerCase();
  if (m.contains('quest 3s') || m.contains('quest3s')) {
    return 'assets/headsets/metaquest3s.svg';
  }
  if (m.contains('quest 3') || m.contains('quest3')) {
    return 'assets/headsets/metaquest3.svg';
  }
  if (m.contains('quest pro') || m.contains('questpro')) {
    return 'assets/headsets/metaquestpro.svg';
  }
  if (m.contains('quest 2') ||
      m.contains('quest2') ||
      m.contains('oculus quest 2')) {
    return 'assets/headsets/oculusquest2.svg';
  }
  if (m.contains('quest 1') ||
      m.contains('quest1') ||
      m.contains('oculus quest')) {
    return 'assets/headsets/oculusquest1.svg';
  }
  return 'assets/headsets/unknown.svg';
}

String controllerSvgForModel(String? model) {
  if (model == null) return 'assets/controller/touchplus.svg';
  final m = model.toLowerCase();
  if (m.contains('quest pro') || m.contains('questpro')) {
    return 'assets/controller/touchpro.svg';
  }
  if (m.contains('quest 3s') || m.contains('quest3s')) {
    return 'assets/controller/touchplus.svg';
  }
  if (m.contains('quest 3') || m.contains('quest3')) {
    return 'assets/controller/touchplus.svg';
  }
  if (m.contains('quest 2') || m.contains('quest2')) {
    return 'assets/controller/touch.svg';
  }
  if (m.contains('quest 1') || m.contains('quest1')) {
    return 'assets/controller/otouch.svg';
  }
  return 'assets/controller/touchplus.svg';
}

/// Minimal charge pill: four dots + percent.
class QLBatteryPill extends StatelessWidget {
  final int? percent;

  const QLBatteryPill({super.key, this.percent});

  @override
  Widget build(BuildContext context) {
    final c = context.ql;
    final pct = percent;
    final n = pct == null ? 0 : (pct / 25).ceil().clamp(0, 4);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: c.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 4; i++)
            Container(
              width: 4,
              height: 10,
              margin: const EdgeInsets.only(right: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1),
                color: i < n
                    ? (pct != null && pct < 20 ? c.warning : c.accent)
                    : c.cardBorder,
              ),
            ),
          const SizedBox(width: 6),
          Text(
            pct == null ? '—' : '$pct%',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: c.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
