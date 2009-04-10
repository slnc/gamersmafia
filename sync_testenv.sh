#!/bin/bash

rake db:test:clone_structure && rake RAILS_ENV=test db:fixtures:load2 && rake RAILS_ENV=test db:fixtures:load2
