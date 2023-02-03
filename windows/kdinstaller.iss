; Inno Setup 6 or later is required for this script to work.

[Setup]
AppID=KoordASIO
AppName=KoordASIO
AppVersion=2.0
AppPublisher=Koord.Live
AppPublisherURL=https://github.com/koord-live/KoordASIO
AppSupportURL=https://github.com/koord-live/KoordASIO/issues
AppUpdatesURL=https://github.com/koord-live/KoordASIO/releases
AppContact=contact@koord.live
WizardStyle=modern

DefaultDirName={autopf}\KoordASIO
AppendDefaultDirName=no
ArchitecturesInstallIn64BitMode=x64

; for 100% dpi setting should be 164x314 - https://jrsoftware.org/ishelp/
WizardImageFile=windows\koordasio.bmp
; for 100% dpi setting should be 55x55 
WizardSmallImageFile=windows\koordasio-small.bmp

[Files]
Source:"deploy\x86_64\KoordASIO.dll"; DestDir: "{app}"; Flags: ignoreversion regserver 64bit; Check: Is64BitInstallMode
; install everything else in deploy dir, including portaudio.dll, KoordASIOControl_builtin.exe and all Qt dll deps
Source:"deploy\x86_64\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs 64bit; Check: Is64BitInstallMode

[Icons]
Name: "{group}\KoordASIO (Built-in) Control"; Filename: "{app}\KoordASIOControl_builtin.exe"; WorkingDir: "{app}"

[Run]
; make sure we have SOME working default configuration after installation
Filename: "{app}\KoordASIOControl.exe"; Parameters: "-defaults"; Description: "Set KoordASIO defaults"; Flags: nowait
; also allow user to configure immediately after installation
Filename: "{app}\KoordASIOControl.exe"; Description: "Run KoordASIO Control"; Flags: postinstall nowait skipifsilent

; install reg key to locate KoordASIOControl_builtin at runtime
[Registry]
Root: HKLM64; Subkey: "Software\Koord"; Flags: uninsdeletekeyifempty
Root: HKLM64; Subkey: "Software\Koord\KoordASIO"; Flags: uninsdeletekey
Root: HKLM64; Subkey: "Software\Koord\KoordASIO\Install"; ValueType: string; ValueName: "InstallPath"; ValueData: "{app}"
