@echo off
rem Exporta as versoes Windows (.exe + .zip) e Android (.apk) do NEON//VERTEX.
rem Uso: de dois cliques neste arquivo, ou rode  tools\export.cmd  na pasta do projeto.
rem       tools\export.cmd windows   (so a versao Windows)
setlocal
chcp 65001 >nul
cd /d "%~dp0.."
set "PROJECT=%CD%"

for /r "%LOCALAPPDATA%\Microsoft\WinGet\Packages" %%F in (Godot_v4*_win64_console.exe) do set "GODOT=%%F"
if not defined GODOT (
  echo Godot nao encontrado. Instale com: winget install GodotEngine.GodotEngine
  exit /b 1
)

rem Chave de assinatura do Android (guarde estes arquivos!)
set "INFO=%USERPROFILE%\.android\neonvertex-release-INFO.txt"
for /f "tokens=1,* delims==" %%A in ('findstr /b "senha=" "%INFO%"') do set "GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=%%B"
set "GODOT_ANDROID_KEYSTORE_RELEASE_PATH=%USERPROFILE%\.android\neonvertex-release.keystore"
set "GODOT_ANDROID_KEYSTORE_RELEASE_USER=neonvertex"
for /d %%J in ("C:\Program Files\Eclipse Adoptium\jdk-17*") do set "JAVA_HOME=%%J"
set "ANDROID_HOME=%LOCALAPPDATA%\Android\Sdk"

if not exist "build\windows" mkdir "build\windows"
if not exist "build\android" mkdir "build\android"

echo == Exportando Windows ==
"%GODOT%" --headless --path "%PROJECT%" --export-release "Windows Desktop" "%PROJECT%\build\windows\NEON-VERTEX.exe"
if /i "%~1"=="windows" goto :zip
echo == Exportando Android ==
"%GODOT%" --headless --path "%PROJECT%" --export-release "Android" "%PROJECT%\build\android\NEON-VERTEX.apk"

echo == Exportando Web ==
if exist "build\web" rmdir /s /q "build\web"
mkdir "build\web"
"%GODOT%" --headless --path "%PROJECT%" --export-release "Web" "%PROJECT%\build\web\index.html"

:zip
echo == Compactando ==
if exist "build\NEON-VERTEX-demo-windows.zip" del "build\NEON-VERTEX-demo-windows.zip"
tar -a -c -f "build\NEON-VERTEX-demo-windows.zip" -C "build\windows" NEON-VERTEX.exe LEIA-ME.txt
rem a versao Web vai para o itch.io como zip com o index.html na raiz
if not exist "build\web\index.html" goto :done
if exist "build\NEON-VERTEX-web.zip" del "build\NEON-VERTEX-web.zip"
tar -a -c -f "build\NEON-VERTEX-web.zip" -C "build\web" *

:done
echo.
echo == Resultado ==
dir /-c "build\windows\NEON-VERTEX.exe" "build\android\NEON-VERTEX.apk" "build\NEON-VERTEX-demo-windows.zip" "build\NEON-VERTEX-web.zip" | findstr /i "NEON"
endlocal
