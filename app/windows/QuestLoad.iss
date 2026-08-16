; QuestLoad installer — per-user, no admin, modern wizard.
; Version comes from CI: ISCC.exe QuestLoad.iss /DMyAppVersion=26.8.16
#ifndef MyAppVersion
  #define MyAppVersion "0.0.0"
#endif

#define MyAppName "QuestLoad"

[Setup]
AppId={{8E2F1C3A-5B74-4D9A-9C2E-6F8B1A0D4E77}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
DefaultDirName={localappdata}\Programs\QuestLoad
PrivilegesRequired=lowest
DisableProgramGroupPage=yes
OutputBaseFilename=questload-setup-{#MyAppVersion}
OutputDir=..\..\build
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayName={#MyAppName}

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\questload.exe"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\questload.exe"

[Run]
Filename: "{app}\questload.exe"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}"
