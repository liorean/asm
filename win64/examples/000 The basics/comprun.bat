@echo off
set asm="%1.asm"
set obj="%1.obj"
set lst="%1.lst"
set exe="%1.exe"
if exist %obj% del %obj%

nasm -o %obj% -f win64 -l %lst% %asm%
if errorlevel 1 goto asmerr

golink /console /ni /entry main %obj% kernel32.dll user32.dll gdi32.dll msvcrt.dll comctl32.dll comdlg32.dll oleaut32.dll hhctrl.ocx winspool.drv shell32.dll
if errorlevel 1 goto linkerr

if exist %obj% del %obj%
goto runit

:linkerr
echo ----
echo Error while Linking
echo ----
pause
goto fin

:asmerr
echo ----
echo Assembly Error
echo ----
pause
goto fin

:runit
echo ----
echo Running Program
echo ----
%exe%

:fin
echo ----