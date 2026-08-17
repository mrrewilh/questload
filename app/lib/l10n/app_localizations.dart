import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'QuestLoad'**
  String get appTitle;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @device.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get device;

  /// No description provided for @downloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloads;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @compactMode.
  ///
  /// In en, this message translates to:
  /// **'Compact Mode'**
  String get compactMode;

  /// No description provided for @sidebar.
  ///
  /// In en, this message translates to:
  /// **'Sidebar'**
  String get sidebar;

  /// No description provided for @toggleLayout.
  ///
  /// In en, this message translates to:
  /// **'Toggle Layout'**
  String get toggleLayout;

  /// No description provided for @smoothScroll.
  ///
  /// In en, this message translates to:
  /// **'Smooth Scroll'**
  String get smoothScroll;

  /// No description provided for @smoothScrollOn.
  ///
  /// In en, this message translates to:
  /// **'Silky'**
  String get smoothScrollOn;

  /// No description provided for @smoothScrollOff.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get smoothScrollOff;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'QuestLoad is ready'**
  String get ready;

  /// No description provided for @noDevice.
  ///
  /// In en, this message translates to:
  /// **'No device connected'**
  String get noDevice;

  /// No description provided for @connectQuest.
  ///
  /// In en, this message translates to:
  /// **'Connect your Quest via Device page'**
  String get connectQuest;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @battery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get battery;

  /// No description provided for @totalGames.
  ///
  /// In en, this message translates to:
  /// **'Total Games'**
  String get totalGames;

  /// No description provided for @recentGames.
  ///
  /// In en, this message translates to:
  /// **'Recent Games'**
  String get recentGames;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @noGamesDb.
  ///
  /// In en, this message translates to:
  /// **'No games in database yet'**
  String get noGamesDb;

  /// No description provided for @searchGames.
  ///
  /// In en, this message translates to:
  /// **'Search games...'**
  String get searchGames;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @gamesInCat.
  ///
  /// In en, this message translates to:
  /// **'{count} games in {category}'**
  String gamesInCat(Object category, Object count);

  /// No description provided for @noGamesFound.
  ///
  /// In en, this message translates to:
  /// **'No games found'**
  String get noGamesFound;

  /// No description provided for @connectDevice.
  ///
  /// In en, this message translates to:
  /// **'Connect Device'**
  String get connectDevice;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get connecting;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @connectFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect to {ip}'**
  String connectFailed(Object ip);

  /// No description provided for @adbStatus.
  ///
  /// In en, this message translates to:
  /// **'ADB'**
  String get adbStatus;

  /// No description provided for @connectedDevice.
  ///
  /// In en, this message translates to:
  /// **'Connected Device'**
  String get connectedDevice;

  /// No description provided for @noDevices.
  ///
  /// In en, this message translates to:
  /// **'No devices found. Connect your Quest via ADB.'**
  String get noDevices;

  /// No description provided for @model.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get model;

  /// No description provided for @android.
  ///
  /// In en, this message translates to:
  /// **'Android'**
  String get android;

  /// No description provided for @ip.
  ///
  /// In en, this message translates to:
  /// **'IP'**
  String get ip;

  /// No description provided for @serial.
  ///
  /// In en, this message translates to:
  /// **'Serial'**
  String get serial;

  /// No description provided for @usb.
  ///
  /// In en, this message translates to:
  /// **'USB'**
  String get usb;

  /// No description provided for @package.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get package;

  /// No description provided for @developer.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get developer;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get size;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download {size}'**
  String download(Object size);

  /// No description provided for @addedToDownloads.
  ///
  /// In en, this message translates to:
  /// **'{name} added to downloads'**
  String addedToDownloads(Object name);

  /// No description provided for @refreshHome.
  ///
  /// In en, this message translates to:
  /// **'Refresh home'**
  String get refreshHome;

  /// No description provided for @noDownloads.
  ///
  /// In en, this message translates to:
  /// **'No downloads yet'**
  String get noDownloads;

  /// No description provided for @addFromLibrary.
  ///
  /// In en, this message translates to:
  /// **'Add games from Library'**
  String get addFromLibrary;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading…'**
  String get downloading;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @tasksCount.
  ///
  /// In en, this message translates to:
  /// **'{count,plural, =0{No tasks} =1{{count} task} other{{count} tasks}}'**
  String tasksCount(num count);

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeMode.
  ///
  /// In en, this message translates to:
  /// **'Color mode'**
  String get themeMode;

  /// No description provided for @themeModeHint.
  ///
  /// In en, this message translates to:
  /// **'Auto follows your system theme'**
  String get themeModeHint;

  /// No description provided for @themeModeHintLight.
  ///
  /// In en, this message translates to:
  /// **'Say goodbye to your retinas'**
  String get themeModeHintLight;

  /// No description provided for @themeModeHintDark.
  ///
  /// In en, this message translates to:
  /// **'Batman approves'**
  String get themeModeHintDark;

  /// No description provided for @auto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get auto;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced;

  /// No description provided for @pairWithCode.
  ///
  /// In en, this message translates to:
  /// **'Pair with Code'**
  String get pairWithCode;

  /// No description provided for @pair.
  ///
  /// In en, this message translates to:
  /// **'Pair'**
  String get pair;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @accentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent color'**
  String get accentColor;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @adbConfig.
  ///
  /// In en, this message translates to:
  /// **'ADB Configuration'**
  String get adbConfig;

  /// No description provided for @adbPath.
  ///
  /// In en, this message translates to:
  /// **'ADB Path'**
  String get adbPath;

  /// No description provided for @adbFound.
  ///
  /// In en, this message translates to:
  /// **'ADB found at {path}'**
  String adbFound(Object path);

  /// No description provided for @adbNotFound.
  ///
  /// In en, this message translates to:
  /// **'ADB not found'**
  String get adbNotFound;

  /// No description provided for @adbMissingHint.
  ///
  /// In en, this message translates to:
  /// **'ADB comes with QuestLoad — if it\'s missing here, your install may be broken. Reinstall QuestLoad and try again.'**
  String get adbMissingHint;

  /// No description provided for @pairedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Paired successfully!'**
  String get pairedSuccessfully;

  /// No description provided for @invalidPairAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter IP:Port as shown on your Quest'**
  String get invalidPairAddress;

  /// No description provided for @pairingFailed.
  ///
  /// In en, this message translates to:
  /// **'Pairing failed'**
  String get pairingFailed;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get connectionFailed;

  /// No description provided for @connectQuestToStart.
  ///
  /// In en, this message translates to:
  /// **'Connect a Quest to get started.'**
  String get connectQuestToStart;

  /// No description provided for @emptyLibrarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Games you install will appear here.'**
  String get emptyLibrarySubtitle;

  /// No description provided for @downloadManagerComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Download manager coming soon.'**
  String get downloadManagerComingSoon;

  /// No description provided for @logs.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get logs;

  /// No description provided for @logsCopied.
  ///
  /// In en, this message translates to:
  /// **'Logs copied to clipboard'**
  String get logsCopied;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @noLogsYet.
  ///
  /// In en, this message translates to:
  /// **'No logs yet'**
  String get noLogsYet;

  /// No description provided for @searchingForQuest.
  ///
  /// In en, this message translates to:
  /// **'Searching for your Quest right now.'**
  String get searchingForQuest;

  /// No description provided for @connectManuallyInstructions.
  ///
  /// In en, this message translates to:
  /// **'To connect manually: Connect your device with a USB cable, or go to Settings → Advanced → Connect Device.'**
  String get connectManuallyInstructions;

  /// No description provided for @pairWithCodeInstructions.
  ///
  /// In en, this message translates to:
  /// **'On your Quest: Settings → System → Developer → Wireless Debugging → Pair using pairing code'**
  String get pairWithCodeInstructions;

  /// No description provided for @windowControls.
  ///
  /// In en, this message translates to:
  /// **'Window controls'**
  String get windowControls;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @framework.
  ///
  /// In en, this message translates to:
  /// **'Framework'**
  String get framework;

  /// No description provided for @platform.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get platform;

  /// No description provided for @database.
  ///
  /// In en, this message translates to:
  /// **'Database'**
  String get database;

  /// No description provided for @supportedPlatforms.
  ///
  /// In en, this message translates to:
  /// **'Desktop / Android / VR'**
  String get supportedPlatforms;

  /// No description provided for @selectTheme.
  ///
  /// In en, this message translates to:
  /// **'Select Theme'**
  String get selectTheme;

  /// No description provided for @searchThemes.
  ///
  /// In en, this message translates to:
  /// **'Search themes'**
  String get searchThemes;

  /// No description provided for @noThemesFound.
  ///
  /// In en, this message translates to:
  /// **'No themes found'**
  String get noThemesFound;

  /// No description provided for @themeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Give QuestLoad a whole new look.'**
  String get themeSubtitle;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @fullscreen.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen'**
  String get fullscreen;

  /// No description provided for @hideSystemBars.
  ///
  /// In en, this message translates to:
  /// **'Hide system bars'**
  String get hideSystemBars;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @errorDetails.
  ///
  /// In en, this message translates to:
  /// **'{details}'**
  String errorDetails(Object details);

  /// No description provided for @logoAlt.
  ///
  /// In en, this message translates to:
  /// **'QuestLoad'**
  String get logoAlt;

  /// No description provided for @scanNetwork.
  ///
  /// In en, this message translates to:
  /// **'Scan Network'**
  String get scanNetwork;

  /// No description provided for @scanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning…'**
  String get scanning;

  /// No description provided for @unknownDevice.
  ///
  /// In en, this message translates to:
  /// **'Unknown Device'**
  String get unknownDevice;

  /// No description provided for @updateTitle.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updateTitle;

  /// No description provided for @updateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'QuestLoad {version} is here — you\'re on {current}.'**
  String updateSubtitle(Object current, Object version);

  /// No description provided for @updateSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip this version'**
  String get updateSkip;

  /// No description provided for @updateDownload.
  ///
  /// In en, this message translates to:
  /// **'Download & install'**
  String get updateDownload;

  /// No description provided for @updateDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading… {percent}%'**
  String updateDownloading(Object percent);

  /// No description provided for @updateInstalling.
  ///
  /// In en, this message translates to:
  /// **'Installing update…'**
  String get updateInstalling;

  /// No description provided for @updateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed. Please try again.'**
  String get updateFailed;

  /// No description provided for @updates.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updates;

  /// No description provided for @updateCheck.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get updateCheck;

  /// No description provided for @updateChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates...'**
  String get updateChecking;

  /// No description provided for @updateNoUpdates.
  ///
  /// In en, this message translates to:
  /// **'You\'re up to date'**
  String get updateNoUpdates;

  /// No description provided for @updateUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach the update server.'**
  String get updateUnreachable;

  /// No description provided for @updateAutoCheck.
  ///
  /// In en, this message translates to:
  /// **'Check for updates on launch'**
  String get updateAutoCheck;

  /// No description provided for @updateRemindNever.
  ///
  /// In en, this message translates to:
  /// **'Don\'t remind me about this update'**
  String get updateRemindNever;

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get updateLater;

  /// No description provided for @updateContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get updateContinue;

  /// No description provided for @updateApplyTitle.
  ///
  /// In en, this message translates to:
  /// **'Update ready'**
  String get updateApplyTitle;

  /// No description provided for @updateApplyText.
  ///
  /// In en, this message translates to:
  /// **'Restart now to apply the update'**
  String get updateApplyText;

  /// No description provided for @updateRestartNow.
  ///
  /// In en, this message translates to:
  /// **'Restart now'**
  String get updateRestartNow;

  /// No description provided for @updateWhatNew.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get updateWhatNew;

  /// No description provided for @updateNoChangelog.
  ///
  /// In en, this message translates to:
  /// **'No changelog for this version.'**
  String get updateNoChangelog;

  /// No description provided for @aboutFlutterDart.
  ///
  /// In en, this message translates to:
  /// **'Flutter • Dart {dartVersion}'**
  String aboutFlutterDart(String dartVersion);

  /// No description provided for @aboutVrAndroid.
  ///
  /// In en, this message translates to:
  /// **'VR (Android)'**
  String get aboutVrAndroid;

  /// No description provided for @aboutAndroid.
  ///
  /// In en, this message translates to:
  /// **'Android'**
  String get aboutAndroid;

  /// No description provided for @aboutMobileIos.
  ///
  /// In en, this message translates to:
  /// **'Mobile (iOS)'**
  String get aboutMobileIos;

  /// No description provided for @aboutLinuxDesktop.
  ///
  /// In en, this message translates to:
  /// **'Linux (Desktop)'**
  String get aboutLinuxDesktop;

  /// No description provided for @aboutWindowsDesktop.
  ///
  /// In en, this message translates to:
  /// **'Windows (Desktop)'**
  String get aboutWindowsDesktop;

  /// No description provided for @aboutMacOsDesktop.
  ///
  /// In en, this message translates to:
  /// **'macOS (Desktop)'**
  String get aboutMacOsDesktop;

  /// No description provided for @aboutUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get aboutUnknown;

  /// No description provided for @pairIpHint.
  ///
  /// In en, this message translates to:
  /// **'IP:Port (e.g. 192.168.1.100:42831)'**
  String get pairIpHint;

  /// No description provided for @pairCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get pairCodeHint;

  /// No description provided for @connectIpHint.
  ///
  /// In en, this message translates to:
  /// **'192.168.1.100'**
  String get connectIpHint;

  /// No description provided for @adbMissingShort.
  ///
  /// In en, this message translates to:
  /// **'Bundled ADB not found.'**
  String get adbMissingShort;

  /// No description provided for @adbCorrupted.
  ///
  /// In en, this message translates to:
  /// **'Bundled ADB not found. The app installation may be corrupted.'**
  String get adbCorrupted;

  /// No description provided for @pairWrongCode.
  ///
  /// In en, this message translates to:
  /// **'Wrong pairing code. Check the code on your Quest.'**
  String get pairWrongCode;

  /// No description provided for @pairRefused.
  ///
  /// In en, this message translates to:
  /// **'Pairing refused. Make sure the Quest is showing the pairing code screen (Settings → Developer → Wireless Debugging → Pair using pairing code).'**
  String get pairRefused;

  /// No description provided for @pairTimeout.
  ///
  /// In en, this message translates to:
  /// **'Pairing timed out. Is {ip} reachable?'**
  String pairTimeout(String ip);

  /// No description provided for @pairError.
  ///
  /// In en, this message translates to:
  /// **'Pairing error.'**
  String get pairError;

  /// No description provided for @connectRefused.
  ///
  /// In en, this message translates to:
  /// **'Connection refused. Make sure wireless debugging is enabled on the Quest (Developer Options → Wireless Debugging).'**
  String get connectRefused;

  /// No description provided for @connectTimeout.
  ///
  /// In en, this message translates to:
  /// **'Connection timed out. Is {ip} reachable on the network?'**
  String connectTimeout(String ip);

  /// No description provided for @connectNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Network error while connecting.'**
  String get connectNetworkError;

  /// No description provided for @connectError.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect.'**
  String get connectError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
