// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'QuestLoad';

  @override
  String get home => 'Home';

  @override
  String get library => 'Library';

  @override
  String get device => 'Device';

  @override
  String get downloads => 'Downloads';

  @override
  String get settings => 'Settings';

  @override
  String get compactMode => 'Compact Mode';

  @override
  String get sidebar => 'Sidebar';

  @override
  String get toggleLayout => 'Toggle Layout';

  @override
  String get smoothScroll => 'Smooth Scroll';

  @override
  String get smoothScrollOn => 'Silky';

  @override
  String get smoothScrollOff => 'Standard';

  @override
  String get refresh => 'Refresh';

  @override
  String get retry => 'Retry';

  @override
  String get close => 'Close';

  @override
  String get welcome => 'Welcome';

  @override
  String get ready => 'QuestLoad is ready';

  @override
  String get noDevice => 'No device connected';

  @override
  String get connectQuest => 'Connect your Quest via Device page';

  @override
  String get connected => 'Connected';

  @override
  String get battery => 'Battery';

  @override
  String get totalGames => 'Total Games';

  @override
  String get recentGames => 'Recent Games';

  @override
  String get seeAll => 'See All';

  @override
  String get noGamesDb => 'No games in database yet';

  @override
  String get searchGames => 'Search games...';

  @override
  String get all => 'All';

  @override
  String gamesInCat(Object category, Object count) {
    return '$count games in $category';
  }

  @override
  String get noGamesFound => 'No games found';

  @override
  String get connectDevice => 'Connect Device';

  @override
  String get connecting => 'Connecting...';

  @override
  String get connect => 'Connect';

  @override
  String get disconnect => 'Disconnect';

  @override
  String connectFailed(Object ip) {
    return 'Failed to connect to $ip';
  }

  @override
  String get adbStatus => 'ADB';

  @override
  String get connectedDevice => 'Connected Device';

  @override
  String get noDevices => 'No devices found. Connect your Quest via ADB.';

  @override
  String get model => 'Model';

  @override
  String get android => 'Android';

  @override
  String get ip => 'IP';

  @override
  String get serial => 'Serial';

  @override
  String get usb => 'USB';

  @override
  String get package => 'Package';

  @override
  String get developer => 'Developer';

  @override
  String get version => 'Version';

  @override
  String get size => 'Size';

  @override
  String get rating => 'Rating';

  @override
  String download(Object size) {
    return 'Download $size';
  }

  @override
  String addedToDownloads(Object name) {
    return '$name added to downloads';
  }

  @override
  String get refreshHome => 'Refresh home';

  @override
  String get noDownloads => 'No downloads yet';

  @override
  String get addFromLibrary => 'Add games from Library';

  @override
  String get pending => 'Pending';

  @override
  String get downloading => 'Downloading…';

  @override
  String get completed => 'Completed';

  @override
  String get failed => 'Failed';

  @override
  String get clearAll => 'Clear All';

  @override
  String tasksCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks',
      one: '$count task',
      zero: 'No tasks',
    );
    return '$_temp0';
  }

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get themeMode => 'Color mode';

  @override
  String get themeModeHint => 'Auto follows your system theme';

  @override
  String get themeModeHintLight => 'Say goodbye to your retinas';

  @override
  String get themeModeHintDark => 'Batman approves';

  @override
  String get auto => 'Auto';

  @override
  String get dark => 'Dark';

  @override
  String get light => 'Light';

  @override
  String get advanced => 'Advanced';

  @override
  String get pairWithCode => 'Pair with Code';

  @override
  String get pair => 'Pair';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get accentColor => 'Accent color';

  @override
  String get apply => 'Apply';

  @override
  String get adbConfig => 'ADB Configuration';

  @override
  String get adbPath => 'ADB Path';

  @override
  String adbFound(Object path) {
    return 'ADB found at $path';
  }

  @override
  String get adbNotFound => 'ADB not found';

  @override
  String get adbMissingHint =>
      'ADB comes with QuestLoad — if it\'s missing here, your install may be broken. Reinstall QuestLoad and try again.';

  @override
  String get pairedSuccessfully => 'Paired successfully!';

  @override
  String get invalidPairAddress => 'Enter IP:Port as shown on your Quest';

  @override
  String get pairingFailed => 'Pairing failed';

  @override
  String get connectionFailed => 'Connection failed';

  @override
  String get connectQuestToStart => 'Connect a Quest to get started.';

  @override
  String get emptyLibrarySubtitle => 'Games you install will appear here.';

  @override
  String get downloadManagerComingSoon => 'Download manager coming soon.';

  @override
  String get logs => 'Logs';

  @override
  String get logsCopied => 'Logs copied to clipboard';

  @override
  String get copy => 'Copy';

  @override
  String get noLogsYet => 'No logs yet';

  @override
  String get searchingForQuest => 'Searching for your Quest right now.';

  @override
  String get connectManuallyInstructions =>
      'To connect manually: Connect your device with a USB cable, or go to Settings → Advanced → Connect Device.';

  @override
  String get pairWithCodeInstructions =>
      'On your Quest: Settings → System → Developer → Wireless Debugging → Pair using pairing code';

  @override
  String get windowControls => 'Window controls';

  @override
  String get copied => 'Copied';

  @override
  String get about => 'About';

  @override
  String get framework => 'Framework';

  @override
  String get platform => 'Platform';

  @override
  String get database => 'Database';

  @override
  String get supportedPlatforms => 'Desktop / Android / VR';

  @override
  String get selectTheme => 'Select Theme';

  @override
  String get searchThemes => 'Search themes';

  @override
  String get noThemesFound => 'No themes found';

  @override
  String get themeSubtitle => 'Give QuestLoad a whole new look.';

  @override
  String get change => 'Change';

  @override
  String get fullscreen => 'Fullscreen';

  @override
  String get hideSystemBars => 'Hide system bars';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String errorDetails(Object details) {
    return '$details';
  }

  @override
  String get logoAlt => 'QuestLoad';

  @override
  String get scanNetwork => 'Scan Network';

  @override
  String get scanning => 'Scanning…';

  @override
  String get unknownDevice => 'Unknown Device';

  @override
  String get updateTitle => 'Update available';

  @override
  String updateSubtitle(Object current, Object version) {
    return 'QuestLoad $version is here — you\'re on $current.';
  }

  @override
  String get updateSkip => 'Skip this version';

  @override
  String get updateDownload => 'Download & install';

  @override
  String updateDownloading(Object percent) {
    return 'Downloading… $percent%';
  }

  @override
  String get updateInstalling => 'Installing update…';

  @override
  String get updateFailed => 'Update failed. Please try again.';

  @override
  String get updates => 'Update';

  @override
  String get updateCheck => 'Check for updates';

  @override
  String get updateChecking => 'Checking for updates...';

  @override
  String get updateNoUpdates => 'You\'re up to date';

  @override
  String get updateUnreachable => 'Couldn\'t reach the update server.';

  @override
  String get updateAutoCheck => 'Check for updates on launch';

  @override
  String get updateRemindNever => 'Don\'t remind me about this update';

  @override
  String get updateLater => 'Later';

  @override
  String get updateContinue => 'Continue';

  @override
  String get updateApplyTitle => 'Update ready';

  @override
  String get updateApplyText => 'Restart now to apply the update';

  @override
  String get updateRestartNow => 'Restart now';

  @override
  String get updateWhatNew => 'What\'s new';

  @override
  String get updateNoChangelog => 'No changelog for this version.';

  @override
  String aboutFlutterDart(String dartVersion) {
    return 'Flutter • Dart $dartVersion';
  }

  @override
  String get aboutVrAndroid => 'VR (Android)';

  @override
  String get aboutAndroid => 'Android';

  @override
  String get aboutMobileIos => 'Mobile (iOS)';

  @override
  String get aboutLinuxDesktop => 'Linux (Desktop)';

  @override
  String get aboutWindowsDesktop => 'Windows (Desktop)';

  @override
  String get aboutMacOsDesktop => 'macOS (Desktop)';

  @override
  String get aboutUnknown => 'Unknown';

  @override
  String get pairIpHint => 'IP:Port (e.g. 192.168.1.100:42831)';

  @override
  String get pairCodeHint => 'Code';

  @override
  String get connectIpHint => '192.168.1.100';

  @override
  String get adbMissingShort => 'Bundled ADB not found.';

  @override
  String get adbCorrupted =>
      'Bundled ADB not found. The app installation may be corrupted.';

  @override
  String get pairWrongCode =>
      'Wrong pairing code. Check the code on your Quest.';

  @override
  String get pairRefused =>
      'Pairing refused. Make sure the Quest is showing the pairing code screen (Settings → Developer → Wireless Debugging → Pair using pairing code).';

  @override
  String pairTimeout(String ip) {
    return 'Pairing timed out. Is $ip reachable?';
  }

  @override
  String get pairError => 'Pairing error.';

  @override
  String get connectRefused =>
      'Connection refused. Make sure wireless debugging is enabled on the Quest (Developer Options → Wireless Debugging).';

  @override
  String connectTimeout(String ip) {
    return 'Connection timed out. Is $ip reachable on the network?';
  }

  @override
  String get connectNetworkError => 'Network error while connecting.';

  @override
  String get connectError => 'Failed to connect.';
}
