@echo off
cd /d %~dp0
setlocal EnableDelayedExpansion

:: ==========================
:: CONFIGURACAO
:: ==========================
set RUBY_HOME=C:\Ruby33-x64\bin
set PATH=%RUBY_HOME%;%PATH%
set RAILS_ENV=production
set PORT=3000
set BIND=0.0.0.0
set NGINX_DIR=C:\nginx-1.28.0
set NGINX_CONF=C:\nginx-1.28.0\conf\nginx.conf

if not exist log mkdir log

:: AUTO START
if "%1"=="auto" (
    call :iniciar oculto
    exit /b
)

:menu
cls
echo ==========================
echo     MENU SOFTEX RESERVAS
echo ==========================
echo [1] Iniciar com atualizacao
echo [2] Iniciar sem atualizacao (oculto)
echo [3] Iniciar sem atualizacao (visivel)
echo [4] Ver Rails no terminal
echo [5] Ver Delayed Job no terminal
echo [6] Encerrar tudo
echo [7] Sair
echo ==========================

set /p choice="Escolha: "

if "%choice%"=="1" (
    call :atualizar
    call :iniciar oculto
    pause
    goto menu
)

if "%choice%"=="2" (
    call :iniciar oculto
    pause
    goto menu
)

if "%choice%"=="3" (
    call :iniciar visivel
    pause
    goto menu
)

if "%choice%"=="4" (
    bundle exec rails s -b %BIND% -p %PORT% -e production
    goto menu
)

if "%choice%"=="5" (
    bundle exec bin\delayed_job run
    goto menu
)

if "%choice%"=="6" (
    call :encerrar
    pause
    goto menu
)

if "%choice%"=="7" exit /b

goto menu

:: ==========================
:: ATUALIZACAO
:: ==========================
:atualizar
echo Atualizando codigo...
git pull

echo Instalando dependencias...
bundle install
yarn install

echo Rodando migrate...
bundle exec rails db:migrate

echo Precompilando assets...
bundle exec rails assets:precompile

goto :eof

:: ==========================
:: INICIAR
:: ==========================
:iniciar
set modo=%1

echo ==========================
echo Encerrando processos antigos...

taskkill /IM nginx.exe /F >nul 2>&1
taskkill /IM ruby.exe /F >nul 2>&1
taskkill /IM rails.exe /F >nul 2>&1

if exist tmp\pids\server.pid del /f /q tmp\pids\server.pid

timeout /t 2 >nul

echo ==========================
echo Iniciando nginx...

if exist "%NGINX_DIR%\nginx.exe" (
    start "" /D "%NGINX_DIR%" nginx.exe -c "%NGINX_CONF%"
)

echo ==========================
echo Iniciando Delayed Job...

if "%modo%"=="oculto" (
    start /b "" cmd /c "bundle exec bin\delayed_job run > log\delayed_job.log 2>&1"
) else (
    start "Delayed Job" cmd /k "bundle exec bin\delayed_job run"
)

echo ==========================
echo Iniciando Rails...

if "%modo%"=="oculto" (
    start /b "" cmd /c "bundle exec rails s -b %BIND% -p %PORT% -e production > log\rails.log 2>&1"
) else (
    start "Rails Server" cmd /k "bundle exec rails s -b %BIND% -p %PORT% -e production"
)

echo ==========================
echo Aguardando Rails subir...

set /a tentativas=0

:wait
netstat -ano | find ":%PORT%" | find "LISTENING" >nul
if %errorlevel%==0 (
    echo Rails rodando na porta %PORT%
    goto ok
)

set /a tentativas+=1
if %tentativas% LEQ 15 (
    timeout /t 2 >nul
    goto wait
)

echo ERRO: Rails nao subiu
goto :eof

:ok
echo ==========================
echo SISTEMA ONLINE
goto :eof

:: ==========================
:: ENCERRAR
:: ==========================
:encerrar
echo Encerrando tudo...

taskkill /IM nginx.exe /F >nul 2>&1
taskkill /IM ruby.exe /F >nul 2>&1
taskkill /IM rails.exe /F >nul 2>&1

if exist tmp\pids\server.pid del /f /q tmp\pids\server.pid

echo OK
goto :eof