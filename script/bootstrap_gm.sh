# Script que instala Gamersmafia en un sistema Ubuntu.
#
# El script es bastante agresivo a la hora de instalar paquetes por lo que es
# aconsejable usarlo en una máquina virtual o en una instalación que no tenga
# nada más.
#
# Es seguro ejecutar este script más de una vez  ya que no se borran base de
# datos o repositorios existentes.
#
# Para más información:
#
#   https://github.com/slnc/gamersmafia

set -u
set -e

APACHE2_MODULES="expires headers rewrite"
GM_CURRENT="/srv/www/gamersmafia/current"
GM_APACHE_CONFIG="${GM_CURRENT}/config/apache.morpheus.conf"
GIT_REPOSITORY="git://github.com/slnc/gamersmafia.git"
PACKAGES_TO_INSTALL="
apache2
apache2-mpm-prefork
apache2-threaded-dev
apache2.2-bin
apache2.2-common
build-essential
git
libapr1-dev
libaprutil1-dev
libgraphicsmagick++1-dev
libgraphicsmagick1-dev
libmagick++-dev
libopenssl-ruby
libpq-dev
libtidy-0.99-0
libxml2-dev libxml2 libxslt1-dev
nodejs
openssh-server
postgresql
postgresql-client
rpl
ruby1.8
ruby1.8-dev
rubygems
vim
zip
"
PASSENGER_APACHE2_CONF=<<-__HERE

# Passenger
LoadModule passenger_module
/usr/lib/ruby/gems/1.8/gems/passenger-3.0.9/ext/apache2/mod_passenger.so
PassengerRoot /usr/lib/ruby/gems/1.8/gems/passenger-3.0.9
PassengerRuby /usr/bin/ruby1.8"
__HERE

Bootstrap() {
  InstallSystemPackages
  CloneRepo
  SetupPostgreSql
  SetupApache2
  SetupGamersmafiaApp
  PrintFinalNotes
}

CloneRepo() {
  if [ ! -d ${GM_CURRENT} ]; then
    sudo mkdir -p ${GM_CURRENT}
    sudo chown -R ${USER} ${GM_CURRENT}
    git clone ${GIT_REPOSITORY} ${GM_CURRENT}
  fi
}

InstallSystemPackages() {
  sudo apt-get install -qq -y `echo ${PACKAGES_TO_INSTALL} | tr '\n' ' '`
  sudo gem update rubygems-update=1.3.5
  sudo gem install passenger --no-rdoc --no-ri
  sudo gem install bundler --no-rdoc --no-ri
  echo -e "\nSnippet that should be present now in apache2.conf"
  sudo passenger-install-apache2-module -a --snippet
  echo -e "\n"
}

SetupPostgreSql() {
  sudo rpl " peer" " trust" /etc/postgresql/9.1/main/pg_hba.conf
  export PGUSER=postgres
  if ! grep -q PGUSER ~/.bashrc
  then
    echo "export PGUSER=postgres" >> ~/.bashrc
  fi
  sudo /etc/init.d/postgresql restart

  if ! `psql --list | grep -q gamersmafia`
  then
    for db in gamersmafia gamersmafia_test
    do
      createdb ${db}
    done
  fi
}

SetupGamersmafiaApp() {
  old_pwd=`pwd`
  cd ${GM_CURRENT} && bundle install && cd ${old_pwd}

  sudo apache2ctl restart
}

SetupApache2() {
  for module in ${APACHE2_MODULES}
  do
    module_dst="/etc/apache2/mods-enabled/${module}"
    if [ ! -f ${module_dst} ]; then
      sudo ln -s /etc/apache2/mods-available/${module}.load ${module_dst}
    fi
  done

  apache2_config_dst="/etc/apache2/sites-enabled/gamersmafia.conf"
  if [ ! -f ${apache2_config_dst} ]; then
    sudo ln -s ${GM_APACHE_CONFIG} ${apache2_config_dst}
  fi

  if ! grep -q passenger /etc/apache2/apache2.conf
  then
    sudo sh -c "echo ${PASSENGER_APACHE2_CONF} >> /etc/apache2/apache2.conf"
  fi
}

GetEth0Ip() {
  /sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'
}


PrintFinalNotes() {
  ip=`GetEth0Ip`
  msg=`cat <<END

INSTALACIÓN COMPLETADA
GM debería estar ejecutándose en el puerto 80. Para acceder a ella edita el
archivo hosts de tu sistema principal y añade la siguiente línea:

  ${ip} gamersmafia.dev


He intenta acceder desde tu navegador escribiendo:

  http://gamersmafia.dev/
END`
echo -e "$msg\n"
}

Bootstrap
