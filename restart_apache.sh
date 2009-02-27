wget -O /dev/null --header="HOST: gamersmafia.com" http://127.0.0.1:8000/site/sync_portals_hits &> /dev/null
wget -O /dev/null --header="HOST: gamersmafia.com" http://127.0.0.1:8001/site/sync_portals_hits &> /dev/null
wget -O /dev/null --header="HOST: gamersmafia.com" http://127.0.0.1:8002/site/sync_portals_hits &> /dev/null
mongrel_rails cluster::stop 
rm tmp/pids/*.pid 
mongrel_rails cluster::start 
# dummy
