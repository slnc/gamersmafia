#!/bin/bash
git submodule update
if rake gm:fiveminutely | grep -q assertions; then
    exit 1
fi
