// ─── Polling intervals ───────────────────────────────────────────────
const kDevicePollInterval = Duration(seconds: 3);
const kScanInterval = Duration(seconds: 30);
const kThemeBrightnessPoll = Duration(seconds: 3);
// How often the device view re-reads charge levels.
const kDeviceBatteryRefresh = Duration(seconds: 30);
// Custom device names are capped so they never swallow the whole bar.
const kDeviceNameMaxLength = 20;

// ─── ADB ─────────────────────────────────────────────────────────────
const kDefaultAdbPort = 5555;

const kAdbCommandTimeout = Duration(seconds: 15);
const kAdbConnectTimeout = Duration(seconds: 5);
const kAdbShellTimeout = Duration(seconds: 10);
const kAdbInstallTimeout = Duration(seconds: 120);
const kAdbUninstallTimeout = Duration(seconds: 30);

// ─── mDNS ────────────────────────────────────────────────────────────
const kMdnsTimeoutSeconds = 3;

// ─── Log ─────────────────────────────────────────────────────────────
const kLogMaxEntries = 500;

// ─── Updates ──────────────────────────────────────────────────────────
// The manifest is attached to the latest release on the main repo once
// it goes public; until then the check silently finds nothing.
const kUpdateManifestUrl =
    'https://gitlab.com/api/v4/projects/qload%2Fquestload/releases/permalink/latest';
// Changelog files, pulled at build time from the public changelog repo and
// shipped inside the app. Shown once after an update.
const kChangelogFileName = 'CHANGELOG.md';
