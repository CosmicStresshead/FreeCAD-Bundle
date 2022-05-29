set conda_env="fc_env"
set copy_dir="FreeCAD_Conda_Build"

mkdir %copy_dir%

call conda create ^
 -p %conda_env% ^
 freecad=0.20beta1 python=3.8 occt=7.5 vtk=9 libredwg calculix gitpython gmsh ^
 numpy matplotlib-base scipy sympy pandas six ^
 pyyaml opencamlib ifcopenshell openglider ^
 freecad.asm3 libredwg pycollada  pythonocc-core ^
 lxml xlutils olefile requests ^
 blinker opencv qt.py nine docutils ^
 --copy ^
 -c freecad/label/dev ^
 -c conda-forge ^
 -y
 


REM Copy Conda's Python and (U)CRT to FreeCAD/bin
robocopy %conda_env%\DLLs %copy_dir%\bin\DLLs /S /MT:%NUMBER_OF_PROCESSORS% > nul
robocopy %conda_env%\Lib %copy_dir%\bin\Lib /XD __pycache__ /S /MT:%NUMBER_OF_PROCESSORS% > nul
robocopy %conda_env%\Scripts %copy_dir%\bin\Scripts /S /MT:%NUMBER_OF_PROCESSORS% > nul
robocopy %conda_env%\ python*.* %copy_dir%\bin\ /XF *.pdb /MT:%NUMBER_OF_PROCESSORS% > nul
robocopy %conda_env%\ msvc*.* %copy_dir%\bin\ /XF *.pdb /MT:%NUMBER_OF_PROCESSORS% > nul
robocopy %conda_env%\ ucrt*.* %copy_dir%\bin\ /XF *.pdb /MT:%NUMBER_OF_PROCESSORS% > nul
REM Copy gmsh and calculix
robocopy %conda_env%\Library\bin %copy_dir%\bin\ assistant.exe /MT:%NUMBER_OF_PROCESSORS% > nul
robocopy %conda_env%\Library\bin %copy_dir%\bin\ ccx.exe /MT:%NUMBER_OF_PROCESSORS% > nul
robocopy %conda_env%\Library\bin %copy_dir%\bin\ gmsh.exe /MT:%NUMBER_OF_PROCESSORS% > nul
robocopy %conda_env%\Library\mingw-w64\bin * %copy_dir%\bin\ /MT:%NUMBER_OF_PROCESSORS% > nul
REM Copy Conda's QT5/plugins to FreeCAD/bin
robocopy %conda_env%\Library\plugins %copy_dir%\bin\ /S /MT:%NUMBER_OF_PROCESSORS% > nul
robocopy %conda_env%\Library\bin\ QtWebEngineProces* %copy_dir%\bin\ /MT:%NUMBER_OF_PROCESSORS% > nul
robocopy %conda_env%\Library\resources %copy_dir%\resources /MT:%NUMBER_OF_PROCESSORS% > nul
robocopy %conda_env%\Library\translations %copy_dir%\translations /MT:%NUMBER_OF_PROCESSORS% > nul
echo [Paths] > %copy_dir%\bin\qt.conf
echo Prefix =.. >> "%copy_dir%\bin\qt.conf"
REM get all the dependency .dlls
robocopy %conda_env%\Library\bin *.dll %copy_dir%\bin /XF *.pdb /XF api*.* /MT:%NUMBER_OF_PROCESSORS% > nul
REM Copy FreeCAD build
robocopy %conda_env%\Library\bin FreeCAD* %copy_dir%\bin /XF *.pdb /MT:%NUMBER_OF_PROCESSORS% > nul
robocopy %conda_env%\Library\data %copy_dir%\data /XF *.txt /S /MT:%NUMBER_OF_PROCESSORS% > nul
REM robocopy %conda_env%\Library\doc\ *.html %copy_dir%\doc MT:%NUMBER_OF_PROCESSORS% > nul

if %ADD_DOCS% == 1 (
mkdir -p %copy_dir%\doc
robocopy ..\..\doc %copy_dir%\doc /S /XD __pycache__ /MT:%NUMBER_OF_PROCESSORS% > nul )

robocopy %conda_env%\Library\Ext %copy_dir%\Ext /S /XD __pycache__ /MT:%NUMBER_OF_PROCESSORS% > nul
robocopy %conda_env%\Library\lib %copy_dir%\lib /XF *.lib /XF *.prl /XF *.sh /MT:%NUMBER_OF_PROCESSORS% > nul
robocopy %conda_env%\Library\Mod %copy_dir%\Mod /S /XD __pycache__ /MT:%NUMBER_OF_PROCESSORS% > nul
REM Apply Patches
rename %copy_dir%\bin\Lib\ssl.py ssl-orig.py
copy ssl-patch.py %copy_dir%\bin\Lib\ssl.py
rename %copy_dir%\bin\Lib\site-packages\mpmath\ctx_mp_python.py ctx_mp_python-orig.py
copy C:\Users\travis\build\FreeCAD\FreeCAD-AppImage\conda\modifications\ctx_mp_python.py %copy_dir%\bin\Lib\site-packages\mpmath\ctx_mp_python.py

if "%DEPLOY_RELEASE%"=="weekly-builds" (
%copy_dir%\bin\python.exe -c "import FreeCAD;print('weekly-builds-' + FreeCAD.Version()[2].split(' ')[0])" > tempver.txt
) else (
%copy_dir%\bin\python.exe -c "import FreeCAD;print((FreeCAD.Version()[0]) +'.' + (FreeCAD.Version()[1]) +'.' + (FreeCAD.Version()[2].split(' ')[0]))" > tempver.txt
)
set /p fcver=<tempver.txt

set freecad_version_name=FreeCAD_%fcver%-Win-Conda-x86_64

echo **********************
echo %freecad_version_name%
echo **********************

cd %copy_dir%\..
ren %copy_dir% %freecad_version_name%
dir

REM if errorlevel1 exit 1

"%ProgramFiles%\7-Zip\7z.exe" a -t7z -mmt=%NUMBER_OF_PROCESSORS% %freecad_version_name%.7z %freecad_version_name%\ -bb
certutil -hashfile "%freecad_version_name%.7z" SHA256 > "%freecad_version_name%.7z"-SHA256.txt
echo  %date%-%time% >>"%freecad_version_name%.7z"-SHA256.txt
