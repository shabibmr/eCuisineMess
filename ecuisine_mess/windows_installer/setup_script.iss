; Script generated for Inno Setup 6.x
; Builds a self-contained Windows installer for eCuisine Mess Billing & Management

#define MyAppName "eCuisine Mess"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "eCuisine"
#define MyAppURL "https://ecuisine.ae"
#define MyAppExeName "ecuisine_mess.exe"

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
AppId={{9F58C8D2-4731-4FE9-9A08-C1B0367E7AA1}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DisableProgramGroupPage=yes
; Cleanly handle running application when updating
CloseApplications=yes
CloseApplicationsFilter=ecuisine_mess.exe
RestartApplications=no
PrivilegesRequired=lowest
OutputDir=..\build\installer
OutputBaseFilename=ecuisine_mess_setup_{#MyAppVersion}
SetupIconFile=..\windows\runner\resources\app_icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Copy all build release artifacts (Flutter runner, Flutter engine DLLs, assets, data)
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
; When running interactively, show launch checkbox. When running silently (/VERYSILENT), automatically relaunch.
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
Filename: "{app}\{#MyAppExeName}"; Flags: nowait postinstall; Check: ShouldLaunchSilent

[Code]
// Helper function to relaunch app after a silent auto-update
function ShouldLaunchSilent: Boolean;
begin
  Result := WizardSilent;
end;
