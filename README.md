This is a very quick stab at doing a PowerDNS-external implementation of BIND9 catalog zones, using just the API.

To test:
```
$ sudo ./ips.sh  # bring up 3 IPs for testing
$ sqlite3 pdns-slave/powerdns.sqlite3 < ~/projects/powerdns/pdns/modules/gsqlite3backend/schema.sqlite3.sql
$ pdnsutil --config-dir=pdns-slave create-slave-zone catalog.example.com 10.33.55.1
$ sudo named -g -c bind-master/named.conf   # tty1
$ sudo named -g -c bind-slave/named.conf    # tty2
$ sudo pdns_server --config-dir=pdns-slave  # tty3
```

You should see all three daemons starting up. `bind-slave` should sync the catalog zone and add the two zones listed in it. `pdns-slave` should sync the catalog zone.

Then, run `./lolcatz.lua` (the arguments, in order, are `<catalog zone name> <domains.account value for cataloged zones> <default master>`), it should add two zones to pdns:
```
./lolcatz.lua catalog.example.com catalog1 10.33.55.1
Processing PTR da6275bc1e0221b29ff95c97da659e213086e6f8.zones.catalog.example.com.
Record count is 1
Zone name is example.net.
Processing PTR 2fcd737781dfde2e53ae10a5411e85adf20b6ae6.zones.catalog.example.com.
Record count is 1
Zone name is example.org.
Done reading catalog zone, desired zone list:
- example.org.
- example.net.
Done reading current database, current zone list:
Looking for zones to add
Adding zone example.org.
{"account": "catalog1", "dnssec": false, "id": "example.org.", "kind": "Slave", "last_check": 0, "masters": ["10.33.55.1"], "name": "example.org.", "notified_serial": 0, "rrsets": [], "serial": 0, "soa_edit": "", "soa_edit_api": "DEFAULT", "url": "api/v1/servers/localhost/zones/example.org."}
Adding zone example.net.
{"account": "catalog1", "dnssec": false, "id": "example.net.", "kind": "Slave", "last_check": 0, "masters": ["10.33.55.1"], "name": "example.net.", "notified_serial": 0, "rrsets": [], "serial": 0, "soa_edit": "", "soa_edit_api": "DEFAULT", "url": "api/v1/servers/localhost/zones/example.net."}
Looking for zones to delete
```

Shortly after this you should see `pdns-slave` AXFRing the two zones in.

After this, if you update the master config (http://jpmens.net/2016/05/24/catalog-zones-are-coming-to-bind-9-11/ is a good guide although I did not configure rndc), and rerun `./lolcatz.lua`, you should see zones being added and removed as specified.

NOTE: I only did the `PTR` part of the draft, this is just a proof of concept. There are lots of edge cases. It should probably be a daemon, not a one-shot script. Once daemonized, it should probably monitor the SOA of the slaved zone and not fetch the whole zone every second. The configs in this repo do not all correctly source NOTIFY/AXFR from the right IPs, etc.