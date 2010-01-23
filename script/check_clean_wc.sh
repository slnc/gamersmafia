#!/bin/bash
# Chequea que la wc esté limpia antes de hacer un commit. 
# Devuelve 0 si está limpia y != 0 caso contrario.

if echo `pwd` | grep -q script; then
	echo "Este script debe ejecutarse desde RAILS_ROOT"
fi

EXIT_STATUS=`git reset | grep -c ^M`
exit $EXIT_STATUS
