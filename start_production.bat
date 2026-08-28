@echo off
cd /d %~dp0
set RUBY_ROOT=C:\Ruby33-x64
set RI_FORCE_PATH_FOR_DLL=1
set RUBYLIB=%CD%\ruby_overrides
set PATH=%RUBY_ROOT%\bin;%RUBY_ROOT%\lib\ruby\3.3.0\x64-mingw-ucrt;%RUBY_ROOT%\msys64\ucrt64\bin;%RUBY_ROOT%\msys64\usr\bin;%PATH%
set RAILS_ENV=production
set RACK_ENV=production

:: Defina VISIVEL=1 para iniciar o delayed_job com janela visível
:: Defina VISIVEL=0 para iniciar em segundo plano (janela oculta)
set VISIVEL=0

echo Iniciando delayed_job...

if "%VISIVEL%"=="1" (
    start "Delayed Job Worker" cmd /k "bundle exec bin\delayed_job run"
) else (
    start /b bundle exec bin\delayed_job run
)

echo Aguardando 2 segundos...
timeout /t 2 >nul

echo Iniciando servidor Rails...
bundle exec rackup config.ru -s webrick -E production -o 127.0.0.1 -p 3000

echo Encerrando delayed_job...
bundle exec bin\delayed_job stop

echo Tudo finalizado.
pause
