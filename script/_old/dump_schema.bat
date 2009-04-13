cd "C:\Documents and Settings\slnc\workspace\gamersmafia"
"C:\Archivos de Programa\Postgresql\8.2\bin\pg_dump" -U postgres -xsOR gamersmafia > db/create.sql
del /Q "C:\Documents and Settings\slnc\workspace\gamersmafia\tmp\sessions\*"
rake log:clear
