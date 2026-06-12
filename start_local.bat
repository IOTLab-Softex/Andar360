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
set DEFAULT_DOMAIN=andar360.ddns.net
set WIN_ACME_DIR=C:\win-acme
set CERTS_DIR=%~dp0certs

if not exist log mkdir log
if not exist certs mkdir certs

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
echo [7] Gerar/renovar certificado HTTPS
echo [8] Sair
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

if "%choice%"=="7" (
    call :certificado
    pause
    goto menu
)

if "%choice%"=="8" exit /b

goto menu

:: ==========================
:: CERTIFICADO HTTPS
:: ==========================
:certificado
cls
echo ==========================
echo   SETUP CERTIFICADO HTTPS
echo ==========================
echo Este assistente usa win-acme/Let's Encrypt para gerar certificado.
echo Dominio padrao: %DEFAULT_DOMAIN%
echo.
echo IMPORTANTE:
echo - O dominio precisa apontar para o IP publico deste servidor.
echo - As portas 80 e 443 precisam estar liberadas no roteador/firewall.
echo - O Nginx sera parado temporariamente para o win-acme validar na porta 80.
echo.

set DOMAIN=%DEFAULT_DOMAIN%
set /p DOMAIN_INPUT="Dominio [%DEFAULT_DOMAIN%]: "
if not "%DOMAIN_INPUT%"=="" set DOMAIN=%DOMAIN_INPUT%

set EMAIL=
set /p EMAIL="E-mail para avisos da Let's Encrypt: "
if "%EMAIL%"=="" (
    echo ERRO: informe um e-mail valido.
    goto :eof
)

set DOMAIN_CERT_DIR=%CERTS_DIR%\%DOMAIN%
if not exist "%DOMAIN_CERT_DIR%" mkdir "%DOMAIN_CERT_DIR%"

echo.
echo Verificando permissao de administrador...
net session >nul 2>&1
if not "%errorlevel%"=="0" (
    echo AVISO: execute este .bat como Administrador para liberar firewall e usar porta 80.
    echo Clique com botao direito no arquivo e escolha "Executar como administrador".
    goto :eof
)

echo Liberando portas 80 e 443 no Firewall do Windows...
netsh advfirewall firewall add rule name="Andar360 HTTP 80" dir=in action=allow protocol=TCP localport=80 >nul 2>&1
netsh advfirewall firewall add rule name="Andar360 HTTPS 443" dir=in action=allow protocol=TCP localport=443 >nul 2>&1

echo.
echo Baixando/preparando win-acme...
if not exist "%WIN_ACME_DIR%\wacs.exe" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
      "$ErrorActionPreference='Stop';" ^
      "$api='https://api.github.com/repos/win-acme/win-acme/releases/latest';" ^
      "$release=Invoke-RestMethod -Uri $api;" ^
      "$asset=$release.assets | Where-Object { $_.name -match 'x64.*trimmed.*\.zip$' } | Select-Object -First 1;" ^
      "if(-not $asset){ throw 'Nao encontrei o ZIP x64 trimmed do win-acme.' }" ^
      "New-Item -ItemType Directory -Force -Path '%WIN_ACME_DIR%' | Out-Null;" ^
      "$zip=Join-Path $env:TEMP 'win-acme.zip';" ^
      "Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zip;" ^
      "Expand-Archive $zip -DestinationPath '%WIN_ACME_DIR%' -Force;"
    if errorlevel 1 (
        echo ERRO: nao foi possivel baixar/preparar o win-acme.
        goto :eof
    )
)

echo.
echo Parando Nginx temporariamente para validar o dominio...
taskkill /IM nginx.exe /F >nul 2>&1
timeout /t 2 >nul

echo.
echo Gerando certificado para %DOMAIN%...
echo Os arquivos serao salvos em:
echo %DOMAIN_CERT_DIR%
echo.

"%WIN_ACME_DIR%\wacs.exe" --target manual --host "%DOMAIN%" --validation selfhosting --store pemfiles --pemfilespath "%DOMAIN_CERT_DIR%" --installation none --accepttos --emailaddress "%EMAIL%"
if errorlevel 1 (
    echo.
    echo ERRO: o win-acme nao conseguiu gerar o certificado.
    echo Confira se %DOMAIN% aponta para este servidor e se a porta 80 esta aberta.
    goto :eof
)

echo.
echo Certificado gerado/renovado com sucesso.
echo.
echo Configure seu Nginx com estes caminhos:
echo ssl_certificate     %DOMAIN_CERT_DIR%\%DOMAIN%-chain.pem;
echo ssl_certificate_key %DOMAIN_CERT_DIR%\%DOMAIN%-key.pem;
echo.
echo Exemplo de bloco HTTPS foi salvo em:
set NGINX_SAMPLE=%~dp0config\nginx\andar360_ssl.conf
if not exist "%~dp0config\nginx" mkdir "%~dp0config\nginx"
(
echo server {
echo     listen 80;
echo     server_name %DOMAIN%;
echo     return 301 https://$host$request_uri;
echo }
echo.
echo server {
echo     listen 443 ssl;
echo     server_name %DOMAIN%;
echo.
echo     ssl_certificate     %DOMAIN_CERT_DIR:\=/%/%DOMAIN%-chain.pem;
echo     ssl_certificate_key %DOMAIN_CERT_DIR:\=/%/%DOMAIN%-key.pem;
echo.
echo     location / {
echo         proxy_pass http://127.0.0.1:%PORT%;
echo         proxy_set_header Host $host;
echo         proxy_set_header X-Forwarded-Proto https;
echo         proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
echo         proxy_set_header X-Real-IP $remote_addr;
echo     }
echo }
) > "%NGINX_SAMPLE%"
echo %NGINX_SAMPLE%
echo.

if exist "%NGINX_DIR%\nginx.exe" (
    echo Reiniciando Nginx...
    start "" /D "%NGINX_DIR%" nginx.exe -c "%NGINX_CONF%"
)

goto :eof

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
