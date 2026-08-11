import 'dart:ui';

// ─── Window ──────────────────────────────────────────────────────────
const kWindowInitialSize = Size(900, 600);
const kWindowMinSize = Size(480, 360);

// ─── Polling intervals ───────────────────────────────────────────────
const kDevicePollInterval = Duration(seconds: 3);
const kScanInterval = Duration(seconds: 30);
const kThemeBrightnessPoll = Duration(seconds: 3);


// ─── ADB ─────────────────────────────────────────────────────────────
const kDefaultAdbPort = 5555;

const kAdbCommandTimeout = Duration(seconds: 15);
const kAdbConnectTimeout = Duration(seconds: 5);
const kAdbShellTimeout = Duration(seconds: 10);
const kAdbInstallTimeout = Duration(seconds: 120);
const kAdbUninstallTimeout = Duration(seconds: 30);

// ─── mDNS ────────────────────────────────────────────────────────────
const kMdnsTimeoutSeconds = 5;

// ─── Log ─────────────────────────────────────────────────────────────
const kLogMaxEntries = 500;
