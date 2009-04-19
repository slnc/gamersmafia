#!/bin/bash
# Guarda la definición de la BBDD en el archivo .sql de creación
# No usamos el mecanismo de Rails de schema.rb porque no guarda índices,
# foreign keys y otras constraints que nosotros usamos
pg_dump -xsOR gamersmafia > db/create.sql
