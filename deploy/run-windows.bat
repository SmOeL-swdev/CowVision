@echo off
rem CowVision - native Windows launcher with auto-restart.
rem Put the downloaded engine exe in this folder and set ENGINE_EXE to its name.
rem Keep config.json (filled from config.template.json) in this same folder.

title CowVision AI Detector (CalvingCatcher)
set "ENGINE_EXE=aidetector-winml-onnx.exe"

:loop
echo --------------------------------------------------
echo [INFO] AI Detector started on %date% at %time%
echo --------------------------------------------------
"%ENGINE_EXE%"
echo [WARN] AI Detector exited. Restarting in 20 seconds... (Ctrl+C to stop)
timeout /t 20 /nobreak
goto loop
