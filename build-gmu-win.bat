@echo off
REM ================================================================
REM GMU OS 0.1 - Windows convenience build
REM Base OS build remains the upstream MikeOS NASM build process.
REM The first C sample is supplied prebuilt because the historical
REM MikeOS Windows build environment does not include a C compiler.
REM Students who edit C sources should rebuild them using a validated
REM gcc -m16 environment (Linux/WSL is one option) and replace the
REM file in c_src\prebuilt before running this script.
REM ================================================================

call buildwin.bat
if errorlevel 1 goto :error

copy /Y c_src\prebuilt\*.BIN programs\ >nul
copy /Y gmu_docs\GMU_OS.TXT programs\gmu_os.txt >nul

echo Mounting image again to add GMU C program and identity file...
imdisk -a -f disk_images\mikeos.flp -s 1440K -m B:
copy /Y c_src\prebuilt\*.BIN B:\
copy /Y gmu_docs\GMU_OS.TXT B:\GMU_OS.TXT
imdisk -D -m B:
copy /Y disk_images\mikeos.flp disk_images\gmuos.flp >nul

echo GMU OS build completed.
goto :eof

:error
echo GMU OS build failed in the upstream build step.
exit /b 1
