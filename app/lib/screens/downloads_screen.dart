import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../l10n/app_localizations.dart';
import '../core/app_theme.dart';

/// Visual-only placeholder — no backend logic.
/// Download system will be designed from scratch when needed.
class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = context.ql;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 180,
              height: 180,
              child: SvgPicture.asset(
                'assets/mascot/sleeping.svg',
                colorFilter: ColorFilter.mode(
                  c.textMuted.withValues(alpha: 0.3),
                  BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            Text(l.noDownloads, style: textTheme.bodyMedium),
            const SizedBox(height: 4.0),
            SizedBox(
              height: 36.0,
              child: Center(
                child: Text(
                  l.downloadManagerComingSoon,
                  style: textTheme.bodySmall,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
