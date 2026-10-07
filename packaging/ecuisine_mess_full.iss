; Full Mess PC installer: Flutter exe, frozen API service, bundled MariaDB service.
; Compile with Inno Setup 6 after packaging\build-bundle.ps1.
; Do not install on a PC that already listens on TCP 3306.

#define MyAppName "eCuisine Mess"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "eCuisine"
#define MyAppURL "https://ecuisine.ae"
#define MyAppExeName "ecuisine_mess.exe"
#define MyDataDir "{commonappdata}\eCuisine Mess"

[Setup]
AppId={{9F58C8D2-4731-4FE9-9A08-C1B0367E7AA1}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DisableProgramGroupPage=yes
PrivilegesRequired=admin
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
CloseApplications=yes
CloseApplicationsFilter=ecuisine_mess.exe,mess-api.exe
RestartApplications=no
OutputDir=dist
OutputBaseFilename=ecuisine_mess_full_{#MyAppVersion}
SetupIconFile=..\ecuisine_mess\windows\runner\resources\app_icon.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "..\ecuisine_mess\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "dist\mess-api\*"; DestDir: "{app}\server"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\mariadb\mariadb-11.4.5-winx64\bin\*"; DestDir: "{app}\mariadb\bin"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\mariadb\mariadb-11.4.5-winx64\lib\*"; DestDir: "{app}\mariadb\lib"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\mariadb\mariadb-11.4.5-winx64\share\*"; DestDir: "{app}\mariadb\share"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "third_party\WinSW-x64.exe"; DestDir: "{app}\server"; DestName: "EcuisineMessApi.exe"; Flags: ignoreversion
Source: "third_party\WinSW-x64.exe"; DestDir: "{app}\mariadb"; DestName: "EcuisineMessDb.exe"; Flags: ignoreversion
Source: "tools\mess-service.ps1"; DestDir: "{app}\tools"; Flags: ignoreversion
Source: "tools\install-services.ps1"; DestDir: "{app}\tools"; Flags: ignoreversion
Source: "tools\uninstall-services.ps1"; DestDir: "{app}\tools"; Flags: ignoreversion
Source: "..\database\schema.sql"; DestDir: "{#MyDataDir}\sql"; Flags: ignoreversion
Source: "..\database\seed.sql"; DestDir: "{#MyDataDir}\sql"; Flags: ignoreversion
Source: "redist\vc_redist.x64.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
var
  RemoveData: Boolean;

procedure StopBundleServices;
var
  ResultCode: Integer;
begin
  Exec('sc.exe', 'stop EcuisineMessApi', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Exec('sc.exe', 'stop EcuisineMessDb', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Sleep(2000);
end;

procedure InstallBundleServices;
var
  ResultCode: Integer;
  Redist: String;
  Script: String;
  AppDir: String;
  DataDir: String;
  Args: String;
begin
  Redist := ExpandConstant('{tmp}\vc_redist.x64.exe');
  if FileExists(Redist) then
    Exec(Redist, '/install /quiet /norestart', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);

  AppDir := ExpandConstant('{app}');
  DataDir := ExpandConstant('{#MyDataDir}');
  Script := ExpandConstant('{app}\tools\install-services.ps1');
  Args := '-NoProfile -ExecutionPolicy Bypass -File "' + Script + '" -AppDir "' + AppDir + '" -DataDir "' + DataDir + '"';
  if (not Exec('powershell.exe', Args, '', SW_HIDE, ewWaitUntilTerminated, ResultCode)) or (ResultCode <> 0) then
    MsgBox('The mess services did not start.' + #13#10 + 'See ' + DataDir + '\logs\install.log', mbError, MB_OK);
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssInstall then
    StopBundleServices;
  if CurStep = ssPostInstall then
    InstallBundleServices;
end;

function InitializeUninstall: Boolean;
var
  Answer: Integer;
begin
  Result := True;
  RemoveData := False;
  Answer := MsgBox('Also delete the mess database, member photos, and settings?', mbConfirmation, MB_YESNO or MB_DEFBUTTON2);
  if Answer = IDYES then
    RemoveData := True;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  ResultCode: Integer;
  Script: String;
  Args: String;
begin
  if CurUninstallStep <> usUninstall then
    Exit;
  Script := ExpandConstant('{app}\tools\uninstall-services.ps1');
  Args := '-NoProfile -ExecutionPolicy Bypass -File "' + Script + '" -AppDir "' + ExpandConstant('{app}') + '" -DataDir "' + ExpandConstant('{#MyDataDir}') + '"';
  if RemoveData then
    Args := Args + ' -RemoveData';
  Exec('powershell.exe', Args, '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
end;
