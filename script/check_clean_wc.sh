#!/bin/bash
# Chequea que la wc esté limpia antes de hacer un commit. Devuelve 0 si está
# limpia y != 0 caso contrario.
# Debe ejecutarse desde directorio RAILS_ROOT
echo `pwd`
cd ..
EXIT_STATUS=`git reset | grep -c locally`
exit $EXIT_STATUS
