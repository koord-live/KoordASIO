; Note: this Inno Setup installer script is meant to run as part of
; installer.cmake. It will not work on its own.
;
; Inno Setup 6 or later is required for this script to work.

[Setup]
AppID=KoordASIO
AppName=KoordASIO
AppVerName=KoordASIO @FLEXASIO_VERSION@
AppVersion=@FLEXASIO_VERSION@
AppPublisher=Koord.Live
AppPublisherURL=https://github.com/koord-live/KoordASIO
AppSupportURL=https://github.com/koord-live/KoordASIO/issues
AppUpdatesURL=https://github.com/koord-live/KoordASIO/releases
; AppReadmeFile=https://github.com/koord-live/KoordASIO/blob/@DECHAMPS_CMAKEUTILS_GIT_DESCRIPTION@/README.md
AppContact=contact@koord.live
WizardStyle=modern

DefaultDirName={autopf}\KoordASIO
AppendDefaultDirName=no
ArchitecturesInstallIn64BitMode=x64

[Files]
Source:"x64\install\bin\FlexASIO.dll"; DestDir: "{app}\x64"; Flags: ignoreversion regserver 64bit; Check: Is64BitInstallMode
Source:"x64\install\bin\*"; DestDir: "{app}\x64"; Flags: ignoreversion 64bit; Check: Is64BitInstallMode
; Source:"x86\install\bin\FlexASIO.dll"; DestDir: "{app}\x86"; Flags: ignoreversion regserver
; Source:"x86\install\bin\*"; DestDir: "{app}\x86"; Flags: ignoreversion
Source:"*.txt"; DestDir:"{app}"; Flags: ignoreversion
; Source:"*.md"; DestDir:"{app}"; Flags: ignoreversion

[Run]
; Filename:"https://github.com/dechamps/FlexASIO/blob/@DECHAMPS_CMAKEUTILS_GIT_DESCRIPTION@/README.md"; Description:"Open README"; Flags: postinstall shellexec nowait
