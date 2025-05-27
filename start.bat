@echo off
cd %~dp0
set RAILS_ENV=production

echo ==========================
echo Verificando atualizações de código...

git pull > git_output.txt

findstr /C:"Already up to date" git_output.txt >nul
if %errorlevel%==0 (
    echo Código já está atualizado. Pulando etapas de build.
) else (
    echo Código atualizado! Executando dependências e migrações...
    bundle install
    yarn install
    rails db:migrate
    rails assets:precompile
)

del git_output.txt

echo ==========================
:: Iniciar nginx se necessário
tasklist /FI "IMAGENAME eq nginx.exe" | find /I "nginx.exe" >nul
if %errorlevel%==0 (
    echo nginx.exe já está rodando.
) else (
    echo nginx.exe não está rodando. Iniciando...
    pushd C:\nginx-1.28.0
    start nginx.exe
    popd
)

:: Iniciar delayed_job em segundo plano
echo Iniciando delayed_job...
start /b cmd /c "ruby bin\delayed_job run"

:: Iniciar Rails server (Puma) em segundo plano
echo Iniciando Rails server...
start /b cmd /c "bundle exec puma -C config/puma.rb -e production"

echo ==========================
echo Todos os serviços foram iniciados.
pause
