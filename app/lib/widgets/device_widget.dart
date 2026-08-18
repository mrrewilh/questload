import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/app_theme.dart';
import 'device_art.dart';

/// The device hero: headset center, controllers upright at its sides
/// (right one mirrored), charge pills under each, on a spotlight card.
class QLDeviceWidget extends StatelessWidget {
  final String headsetSvg;
  final String controllerSvg;
  final int? headsetBattery;
  final int? leftBattery;
  final int? rightBattery;

  const QLDeviceWidget({
    super.key,
    required this.headsetSvg,
    required this.controllerSvg,
    this.headsetBattery,
    this.leftBattery,
    this.rightBattery,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.ql;
    final tint = ColorFilter.mode(c.textPrimary, BlendMode.srcIn);

    Widget art(String path, double width, {bool flip = false}) {
      final svg = SvgPicture.asset(path, width: width, colorFilter: tint);
      return flip ? Transform.flip(flipX: true, child: svg) : svg;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(36, 30, 36, 26),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.cardBorder),
        gradient: RadialGradient(
          radius: 0.95,
          colors: [c.surfaceLight, c.surface],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final hs = (w * 0.3).clamp(170.0, 250.0);
          final con = hs * 0.55;
          final height = hs + 74;
          return SizedBox(
            height: height,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: Column(
                    children: [
                      art(headsetSvg, hs),
                      const SizedBox(height: 16),
                      QLBatteryPill(percent: headsetBattery),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  bottom: 0,
                  child: Column(
                    children: [
                      art(controllerSvg, con),
                      const SizedBox(height: 14),
                      QLBatteryPill(percent: leftBattery),
                    ],
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Column(
                    children: [
                      art(controllerSvg, con, flip: true),
                      const SizedBox(height: 14),
                      QLBatteryPill(percent: rightBattery),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
