@echo off
cd %~dp0
set RAILS_ENV=production

:: Defina VISIVEL=1 para iniciar o delayed_job com janela visível
:: Defina VISIVEL=0 para iniciar em segundo plano (janela oculta)
set VISIVEL=0

echo Iniciando delayed_job...

if "%VISIVEL%"=="1" (
    start "Delayed Job Worker" cmd /k "ruby bin\delayed_job run"
) else (
    start /b ruby bin\delayed_job run
)

echo Aguardando 2 segundos...
timeout /t 2 >nul

echo Iniciando servidor Rails...
ruby bin\rails server -e production

echo Encerrando delayed_job...
ruby bin\delayed_job stop

echo Tudo finalizado.
pause
