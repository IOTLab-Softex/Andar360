@echo off
cd /d C:\srs-softex-reserva-de-salas
C:\Ruby32-x64\bin\bundle.bat exec puma -C config/puma.rb -e production