@echo off

if defined SVNCMD_PROJECT_ROOT_INIT0_DIR exit /b 0

call "%%~dp0..\..\__init__\__init__.bat"
