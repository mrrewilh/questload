import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../core/app_theme.dart';
import '../l10n/app_localizations.dart';

/// Result of the update-available dialog.
enum UpdateChoice { download, later }

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
    return AlertDialog(
      backgroundColor: c.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/update.svg',
            width: 88,
            height: 88,
            colorFilter: ColorFilter.mode(c.accent, BlendMode.srcIn),
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
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _skip,
            onChanged: (v) => setState(() => _skip = v ?? false),
            title: Text(l.updateRemindNever, style: Theme.of(context).textTheme.bodySmall),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(UpdateChoice.later),
          child: Text(l.updateLater),
        ),
        FilledButton(
          onPressed: () {
            if (_skip) {
              Navigator.of(context).pop('skip');
            } else {
              Navigator.of(context).pop(UpdateChoice.download);
            }
          },
          child: Text(widget.canDownload ? l.updateDownload : l.updateContinue),
        ),
      ],
    );
  }
}

/// Asks to apply a downloaded update by restarting. Windows only.
Future<bool> showApplyUpdateDialog(BuildContext context) async {
  final l = AppLocalizations.of(context)!;
  final c = context.ql;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: c.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(l.updateApplyTitle),
      content: Text(l.updateApplyText),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l.updateLater),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l.updateRestartNow),
        ),
      ],
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
  final c = context.ql;
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: c.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(l.updateWhatNew),
      content: SizedBox(
        width: 380,
        child: SingleChildScrollView(
          child: Text(
            body.isEmpty ? l.updateNoChangelog : body,
            style: Theme.of(ctx).textTheme.bodyMedium,
          ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l.close),
        ),
      ],
    ),
  );
}
