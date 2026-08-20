import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../widgets/ql_widgets.dart';

/// Result of the update-available dialog.
enum UpdateChoice { download, later, skip }

/// Update available popup: update.svg + skip checkbox + action.
/// No changelog here — that only shows after an update is applied.
class UpdateAvailableDialog extends StatefulWidget {
  final String newVersion;
  final String currentVersion;
  final bool canDownload; // false on Linux — package managers do the work

  const UpdateAvailableDialog({
    super.key,
    required this.newVersion,
    required this.currentVersion,
    required this.canDownload,
  });

  @override
  State<UpdateAvailableDialog> createState() => _UpdateAvailableDialogState();
}

class _UpdateAvailableDialogState extends State<UpdateAvailableDialog> {
  bool _skip = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = context.ql;
    return Center(
      child: QLDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/mascot/update.svg',
              width: 120,
              height: 120,
              colorFilter: ColorFilter.mode(
                c.textMuted.withValues(alpha: 0.3),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l.updateTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              l.updateSubtitle(widget.currentVersion, widget.newVersion),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            QLCheckbox(
              value: _skip,
              label: l.updateRemindNever,
              onChanged: (v) => setState(() => _skip = v),
            ),
          ],
        ),
        leftAction: QLButton(
          label: l.updateLater,
          onPressed: () => Navigator.of(context).pop(UpdateChoice.later),
        ),
        rightAction: QLButton(
          label: widget.canDownload ? l.updateDownload : l.updateContinue,
          onPressed: () => Navigator.of(
            context,
          ).pop(_skip ? UpdateChoice.skip : UpdateChoice.download),
        ),
      ),
    );
  }
}

/// Asks to apply a downloaded update by restarting. Windows only.
Future<bool> showApplyUpdateDialog(BuildContext context) async {
  final l = AppLocalizations.of(context)!;
  final result = await showQLDialog<bool>(
    context: context,
    title: l.updateApplyTitle,
    content: Text(l.updateApplyText),
    leftAction: QLButton(
      label: l.updateLater,
      onPressed: () => Navigator.of(context).pop(false),
    ),
    rightAction: QLButton(
      label: l.updateRestartNow,
      onPressed: () => Navigator.of(context).pop(true),
    ),
  );
  return result ?? false;
}

/// Shown once after an update. The embedded changelog, nothing else.
Future<void> showChangelogDialog(
  BuildContext context, {
  required String body,
}) async {
  final l = AppLocalizations.of(context)!;
  await showQLDialog<void>(
    context: context,
    title: l.updateWhatNew,
    content: ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 400),
      child: SingleChildScrollView(
        child: Text(
          body.isEmpty ? l.updateNoChangelog : body,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    ),
    leftAction: const SizedBox.shrink(),
    rightAction: QLButton(
      label: l.close,
      onPressed: () => Navigator.of(context).pop(),
    ),
  );
}
