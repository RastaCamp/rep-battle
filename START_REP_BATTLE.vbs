' Double-click this file to launch Rep Battle (works when .bat closes instantly)
Set fso = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")
projectDir = fso.GetParentFolderName(WScript.ScriptFullName)

flutterBat = "C:\flutter\bin\flutter.bat"
If Not fso.FileExists(flutterBat) Then
  flutterBat = shell.ExpandEnvironmentStrings("%LOCALAPPDATA%") & "\flutter\bin\flutter.bat"
End If
If Not fso.FileExists(flutterBat) Then
  flutterBat = "flutter.bat"
End If

cmdLine = "cmd.exe /k ""cd /d """ & projectDir & """ && title Rep Battle && """ & flutterBat & """ pub get && """ & flutterBat & """ run -d chrome"""

shell.Run cmdLine, 1, False
