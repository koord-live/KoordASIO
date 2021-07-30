; Inno Setup 6 or later is required for this script to work.

[Setup]
AppID=KoordASIO
AppName=KoordASIO
AppVerName=KoordASIO_1.7a-k01
AppVersion=1.7a-k01
AppPublisher=Koord.Live
AppPublisherURL=https://github.com/koord-live/KoordASIO
AppSupportURL=https://github.com/koord-live/KoordASIO/issues
AppUpdatesURL=https://github.com/koord-live/KoordASIO/releases
AppContact=contact@koord.live
WizardStyle=modern

DefaultDirName={autopf}\KoordASIO
AppendDefaultDirName=no
ArchitecturesInstallIn64BitMode=x64

[Files]
Source:"deploy\x86_64\KoordASIO.dll"; DestDir: "{app}"; Flags: ignoreversion regserver 64bit; Check: Is64BitInstallMode
; install everything else in deploy dir, including portaudio.dll, kdasioconfig.exe and all Qt dll deps
Source:"deploy\x86_64\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs 64bit; Check: Is64BitInstallMode
; Source:"x86\install\bin\FlexASIO.dll"; DestDir: "{app}\x86"; Flags: ignoreversion regserver
; Source:"x86\install\bin\*"; DestDir: "{app}\x86"; Flags: ignoreversion
; Source:"*.txt"; DestDir:"{app}"; Flags: ignoreversion
; Source:"*.md"; DestDir:"{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\KoordASIO Config"; Filename: "{app}\kdasioconfig.exe"; WorkingDir: "{app}"

[Run]
Filename: "{app}\kdasioconfig.exe"; Description: "Run KoordASIO Config"; Flags: postinstall nowait skipifsilent

; install reg key to locate kdasioconfig at runtime
[Registry]
Root: HKLM64; Subkey: "Software\Koord"; Flags: uninsdeletekeyifempty
Root: HKLM64; Subkey: "Software\Koord\KoordASIO"; Flags: uninsdeletekey
Root: HKLM64; Subkey: "Software\Koord\KoordASIO\Install"; ValueType: string; ValueName: "InstallPath"; ValueData: "{app}"