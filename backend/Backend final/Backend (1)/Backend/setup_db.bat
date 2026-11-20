@echo off
REM Crea la BD leondejuda y carga schema.sql + seed.sql
REM Busca psql.exe automaticamente (versiones 18 a 14)
set PSQL=
for %%V in (18 17 16 15 14) do (
  if exist "C:\Program Files\PostgreSQL\%%V\bin\psql.exe" if not defined PSQL set PSQL="C:\Program Files\PostgreSQL\%%V\bin\psql.exe"
)
if not defined PSQL (
  echo No se encontro psql.exe en C:\Program Files\PostgreSQL\
  echo Edita este archivo y escribe la ruta correcta en la variable PSQL.
  pause & exit /b 1
)
echo Usando %PSQL%
echo Se te pedira la clave del usuario postgres varias veces.
%PSQL% -U postgres -tc "SELECT 1 FROM pg_database WHERE datname='leondejuda'" | findstr 1 >nul || %PSQL% -U postgres -c "CREATE DATABASE leondejuda;"
%PSQL% -U postgres -d leondejuda -v ON_ERROR_STOP=1 -f "%~dp0db\schema.sql"
%PSQL% -U postgres -d leondejuda -v ON_ERROR_STOP=1 -f "%~dp0db\seed.sql"
echo.
echo Listo. Revisa que no haya errores arriba.
pause
