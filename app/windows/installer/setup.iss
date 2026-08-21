; QuestLoad Inno Setup — per-user, anonymous, modern wizard + dark background
; Built by CI: iscc /DMyAppVersion=26.8.21 /DBuildDir=... setup.iss
#define MyAppName "QuestLoad"
#define MyAppPublisher "QuestLoad"
#define MyAppURL "https://github.com/mrrewilh/questload"
#define MyAppExeName "questload.exe"

#ifndef MyAppVersion
  #define MyAppVersion "0.0.0"
#endif
#define MyAppVersionInfo StringChange(MyAppVersion, "-", ".")
#ifndef BuildDir
  #define BuildDir "..\\..\\build\\windows\\x64\\runner\\Release"
#endif

[Setup]
AppId={{8B9A3D3A-2E5F-4A9C-B7C1-9F2D6A1E4C3B}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={localappdata}\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableDirPage=no
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
OutputDir=..\..\..\build
OutputBaseFilename=QuestLoad-Setup-{#MyAppVersion}
SetupIconFile=setup.ico
WizardStyle=modern dynamic
Compression=lzma2/ultra64
SolidCompression=yes
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName}
VersionInfoVersion={#MyAppVersionInfo}
VersionInfoCompany={#MyAppPublisher}
VersionInfoProductName={#MyAppName}
VersionInfoProductVersion={#MyAppVersionInfo}
CloseApplications=yes
RestartApplications=no
ArchitecturesInstallIn64BitMode=x64
ArchitecturesAllowed=x64
MinVersion=10.0

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#BuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; CHANGELOG shipped next to exe if present (CI copies repo/CHANGELOG.md into Release/)
Source: "{#BuildDir}\CHANGELOG.md"; DestDir: "{app}"; Flags: ignoreversion; Permissions: everyone-modify

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon
; optional start menu handled by group above

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  ResultCode: Integer;
begin
  if CurUninstallStep = usUninstall then
  begin
    // stop our adbd so uninstall can delete bundled adb.exe/dlls
    Exec(ExpandConstant('{app}\adb.exe'), 'kill-server', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    Exec('taskkill', '/f /im adb.exe', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    Exec('taskkill', '/f /im questload.exe', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  end;
end;

[UninstallDelete]
Type: filesandordirs; Name: "{app}\downloads"
Type: filesandordirs; Name: "{localappdata}\questload"
