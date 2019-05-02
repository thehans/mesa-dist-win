@REM Try locating all Python versions via Python Launcher.
@SET pythonloc=python.exe

@rem Check if Python launcher is installed.
@set ERRORLEVEL=0
@where /q py.exe
@IF ERRORLEVEL 1 GOTO nopylauncher

:pylist
@set pythontotal=0
@set pythoncount=0
@set goodpython=0
@cls

@rem Count supported python installations
@setlocal ENABLEDELAYEDEXPANSION
@FOR /F "USEBACKQ tokens=1 skip=1" %%a IN (`py -0 2^>nul`) do @(
@set pythoninstance=%%a
@IF !pythoninstance^:^~1^,1! EQU 2 IF !pythoninstance^:~^3^,-3! EQU 7 set goodpython=1
@IF !pythoninstance^:^~1^,1! GEQ 3 IF !pythoninstance^:~^3^,-3! GEQ 5 set goodpython=1
@IF !goodpython!==1 set /a pythontotal+=1
)
@endlocal&set pythontotal=%pythontotal%
@IF %pythontotal%==0 GOTO nopylauncher

@rem Select Python installation to use
@IF %enablemeson%==0 echo Select python installation. Note that experimental /enablemeson command-line argument is not set. We won't attempt to build Mesa3D if you pick any Python 3.x installation: & echo.
@IF %enablemeson%==1 echo Select python installation. Note that experimental /enablemeson command-line argument is set. We will attempt to build Mesa3D regardless of Python installation selected: & echo.
@setlocal ENABLEDELAYEDEXPANSION
@FOR /F "USEBACKQ tokens=1 skip=1" %%a IN (`py -0 2^>nul`) do @(
@set pythoninstance=%%a
@IF !pythoninstance^:^~1^,1! EQU 2 IF !pythoninstance^:~^3^,-3! EQU 7 set goodpython=1
@IF !pythoninstance^:^~1^,1! GEQ 3 IF !pythoninstance^:~^3^,-3! GEQ 5 set goodpython=1
@IF !goodpython!==1 set /a pythoncount+=1
@IF !goodpython!==1 echo !pythoncount!. Python !pythoninstance:~1,1!.!pythoninstance:~3,-3! !pythoninstance:~-2! bit
)
@endlocal
@echo.
@set /p pyselect=Select Python version by entering its index from the table above:
@echo.
@IF %pyselect% LEQ 0 echo Invalid entry.
@IF %pyselect% LEQ 0 pause
@IF %pyselect% LEQ 0 GOTO pylist
@IF %pyselect% GTR %pythontotal% echo Invalid entry.
@IF %pyselect% GTR %pythontotal% pause
@IF %pyselect% GTR %pythontotal% GOTO pylist

@rem Locate selected Python installation
@setlocal ENABLEDELAYEDEXPANSION
@FOR /F "USEBACKQ tokens=1 skip=1" %%a IN (`py -0 2^>nul`) do @(
@set pythoninstance=%%a
@IF !pythoninstance^:^~1^,1! EQU 2 IF !pythoninstance^:~^3^,-3! EQU 7 set goodpython=1
@IF !pythoninstance^:^~1^,1! GEQ 3 IF !pythoninstance^:~^3^,-3! GEQ 5 set goodpython=1
@IF !goodpython!==1 set /a pythoncount+=1
@IF !pythoncount!==%pyselect% set selectedpython=%%a
)
@endlocal&set selectedpython=%selectedpython%
@FOR /F "tokens=* USEBACKQ" %%a IN (`py %selectedpython%  -c "import sys; print(sys.executable)"`) DO @set pythonloc=%%~sa
@GOTO loadpypath

:nopylauncher
@rem Missing Python launcher fallback code path.
@rem First remove Python UWP installer from PATH (see https://github.com/pal1000/mesa-dist-win/issues/23)

@setlocal ENABLEDELAYEDEXPANSION
@SET PATH=!PATH:;%LOCALAPPDATA%\Microsoft\WindowsApps=!
@endlocal&set PATH=%PATH%

@SET ERRORLEVEL=0
@IF %pythonloc%==python.exe where /q python.exe
@IF ERRORLEVEL 1 set pythonloc=%mesa%\python\python.exe
@IF %pythonloc%==%mesa%\python\python.exe IF NOT EXIST %pythonloc% (
@echo Python is unreachable. Cannot continue.
@echo.
@pause
@exit
)
@IF %pythonloc%==python.exe FOR /F "tokens=* USEBACKQ" %%a IN (`where /f python.exe`) DO @SET pythonloc=%%~sa & GOTO loadpypath

:loadpypath
@REM Load Python in PATH to convince CMake to use the selected version.
@SET ERRORLEVEL=0
@set pypath=1
@where /q python.exe
@IF ERRORLEVEL 1 set pypath=0
@IF %pypath%==1 FOR /F "tokens=* USEBACKQ" %%a IN (`where /f python.exe`) DO @SET pypath=%%~sa & GOTO doloadpy

:doloadpy
@IF NOT %pypath%==%pythonloc% set PATH=%pythonloc:~0,-10%;%PATH%

:pyver
@rem Identify Python version.
@FOR /F "USEBACKQ delims= " %%a IN (`%pythonloc% -c "import sys; print(sys.version)"`) DO @SET pythonver=%%a

@rem Check if Python version is not too old.
@IF NOT %pythonver:~0,3%==2.7 IF NOT %pythonver:~0,3%==3.5 IF NOT %pythonver:~0,3%==3.6 IF NOT %pythonver:~0,3%==3.7 (
@echo Your Python version is too old. Only Python 2.7 or 3.5 through 3.7 are supported.
@echo.
@pause
@exit
)

@echo Using Python %pythonver% from %pythonloc%.
@echo.
@set pythonver=%pythonver:~0,1%
@if %pythonver% GEQ 3 IF %enablemeson%==1 echo WARNING: Python 3.x support is experimental.
@if %pythonver% GEQ 3 IF %enablemeson%==0 echo WARNING: Selected a Python 3.x version. We will only build LLVM. We can only build Mesa3D with Python 2.7 for the time being.
@if %pythonver% GEQ 3 echo.