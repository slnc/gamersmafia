#!/bin/bash
# Vuelve a crear gamersmafia_test desde cero y carga las fixtures.
# Cargamos las fixtures porque por alguna razón desconocida no se cargan
# bien todas si no lo hacemos así.
# TODO rails 2.3.1: probar a quitar el segundo db:fixtures:load2 a ver si
# ya funciona bien.
 
rake db:test:clone_structure && \
rake RAILS_ENV=test db:fixtures:load2 && \
rake RAILS_ENV=test db:fixtures:load2
