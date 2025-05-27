@echo off
cd %~dp0
setlocal EnableDelayedExpansion
set RAILS_ENV=production

:menu
cls
echo ==========================
echo     MENU SOFTEX RESERVAS
echo ==========================
echo [1] Iniciar o SRS (com atualização, oculto)
echo [2] Iniciar o SRS (sem atualização, oculto)
echo [3] Exibir Rails server no terminal
echo [4] Exibir Delayed Job no terminal
echo [5] Encerrar o SRS
echo [6] Sair
echo ==========================
set /p choice="Digite a opcao desejada (1-6): "

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
    call :encerrar
    echo Iniciando Rails server no terminal...
    ruby bin\rails server -e production
    pause
    goto menu
)

if "%choice%"=="4" (
    call :encerrar
    echo Iniciando Delayed Job no terminal...
    ruby bin\delayed_job run
    pause
    goto menu
)

if "%choice%"=="5" (
    call :encerrar
    pause
    goto menu
)

if "%choice%"=="6" (
    echo Saindo...
    exit /b
)

goto menu

:atualizar
echo ==========================
echo Atualizando código...
git pull > git_output.txt
findstr /C:"Already up to date" git_output.txt >nul
if !errorlevel! equ 0 (
    echo Código já está atualizado. Pulando etapas de build.
) else (
    echo Código atualizado! Executando dependências e migrações...
    bundle install
    yarn install
    rails db:migrate
    rails assets:precompile
)
del git_output.txt
goto :eof

:iniciar
:: Parametro %1 pode ser "oculto"
set modo=%1

echo ==========================
echo Verificando nginx...
tasklist /FI "IMAGENAME eq nginx.exe" | find /I "nginx.exe" >nul
if !errorlevel! equ 0 (
    echo nginx.exe ja esta rodando. Reiniciando...
    taskkill /IM nginx.exe /F
)
pushd C:\nginx-1.28.0
start nginx.exe
popd

echo ==========================
echo Verificando delayed_job...
tasklist /FI "WINDOWTITLE eq Delayed Job Worker*" | find /I "Delayed Job Worker" >nul
if !errorlevel! equ 0 (
    echo delayed_job ja esta rodando. Encerrando...
    ruby bin\delayed_job stop
)
echo Iniciando delayed_job...
if "%modo%"=="oculto" (
   start /b "" cmd /c "ruby bin\delayed_job run > nul 2>&1"

) else (
    ruby bin\delayed_job run
)

echo ==========================
echo Verificando Rails server...

set rails_running=false

:: Checar pelo PID file
if exist tmp\pids\server.pid (
    set pid=
    for /f %%p in (tmp\pids\server.pid) do set pid=%%p
    if defined pid (
        echo Rails server detectado pelo PID %%p.
        set rails_running=true
    )
)

:: Checar pelo processo ruby.exe ouvindo na porta 3000
if "!rails_running!"=="false" (
    netstat -an | find ":3000" | find "LISTENING" >nul
    if !errorlevel! equ 0 (
        echo Rails server detectado ouvindo na porta 3000.
        set rails_running=true
    )
)

:: Se estiver rodando, parar
if "!rails_running!"=="true" (
    echo Encerrando Rails server atual...
    if defined pid (
        taskkill /PID %pid% /F
    ) else (
        echo Nenhum PID file, matando todos ruby.exe ouvindo.
        for /f "tokens=2 delims=," %%p in ('netstat -ano ^| find ":3000" ^| find "LISTENING"') do (
            taskkill /PID %%p /F
        )
    )
) else (
    echo Rails server nao estava rodando.
)

:: Iniciar Rails server
echo Iniciando Rails server...
if "%modo%"=="oculto" (
    start /b "" cmd /c "ruby bin\rails server -e production > nul 2>&1"
) else (
    ruby bin\rails server -e production
)

echo ==========================
echo Verificando status final...

:: Checar nginx
tasklist /FI "IMAGENAME eq nginx.exe" | find /I "nginx.exe" >nul
if !errorlevel! equ 0 (
    echo ✔ nginx rodando.
) else (
    echo ⚠ nginx nao detectado.
)

:: Checar delayed_job (olhamos por ruby.exe + janela)
tasklist /FI "WINDOWTITLE eq Delayed Job Worker*" | find /I "Delayed Job Worker" >nul
if !errorlevel! equ 0 (
    echo ✔ delayed_job rodando.
) else (
    echo ⚠ delayed_job nao detectado.
)

echo ==========================
echo Aguardando Rails server abrir a porta 3000...

set /a retries=0
set rails_ready=false

:wait_for_rails_port
netstat -an | find ":3000" | find "LISTENING" >nul
if !errorlevel! equ 0 (
    set rails_ready=true
    echo ✔ Rails server agora esta ouvindo na porta 3000.
) else (
    set /a retries+=1
    if !retries! leq 10 (
        echo Tentativa !retries!/10: Aguardando porta 3000...
        timeout /t 2 >nul
        goto wait_for_rails_port
    ) else (
        echo ⚠ Rails server nao abriu a porta 3000 apos 10 tentativas.
    )
)

echo ==========================

echo ==========================

pause
goto :eof

:encerrar
echo ==========================
echo Encerrando nginx...
taskkill /IM nginx.exe /F

echo Encerrando delayed_job...
ruby bin\delayed_job stop

echo Encerrando Rails server...
taskkill /IM ruby.exe /F

echo Todos os serviços foram encerrados.
goto :eof
