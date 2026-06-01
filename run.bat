@echo off
echo ========================================
echo  PocketMind - Flutter Setup & Run
echo ========================================
echo.
echo [1/2] Installing dependencies...
flutter pub get
echo.
echo [2/2] Running app...
echo  Connect a device or start an emulator first.
echo  Press Ctrl+C to stop.
echo.
flutter run
pause
