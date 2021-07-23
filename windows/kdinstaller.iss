; Inno Setup 6 or later is required for this script to work.

[Setup]
AppID=KoordASIO
AppName=KoordASIO
AppVerName=KoordASIO_0.9.0
AppVersion=0.9.0
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
Source:"deploy\x86_84\KoordASIO.dll"; DestDir: "{app}"; Flags: ignoreversion regserver 64bit; Check: Is64BitInstallMode
; install everything else in deploy dir, including portaudio.dll, kdasioconfig.exe and all Qt dll deps
Source:"deploy\x86_84\*"; DestDir: "{app}"; Flags: ignoreversion 64bit; Check: Is64BitInstallMode
; Source:"x86\install\bin\FlexASIO.dll"; DestDir: "{app}\x86"; Flags: ignoreversion regserver
; Source:"x86\install\bin\*"; DestDir: "{app}\x86"; Flags: ignoreversion
; Source:"*.txt"; DestDir:"{app}"; Flags: ignoreversion
; Source:"*.md"; DestDir:"{app}"; Flags: ignoreversion

[Run]
; Filename:"https://github.com/dechamps/FlexASIO/blob/@DECHAMPS_CMAKEUTILS_GIT_DESCRIPTION@/README.md"; Description:"Open README"; Flags: postinstall shellexec nowait
