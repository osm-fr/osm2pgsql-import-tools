#! /bin/sh

for i in $(grep "^\[" /etc/renderd.conf | egrep -v "(renderd|mapnik|note|fixme|my_own|noname|nooneway|noref)" | cut -d"[" -f2 | cut -d"]" -f1); do
  echo $(date "+%Y-%m-%d %H:%M:%S") $i
  sudo -u www-data ../mod_tile/render_list -m $i -a -f -z 1 -Z 11 -n 8 -l 12 -s /var/run/renderd/renderd.sock
  echo $(date "+%Y-%m-%d %H:%M:%S") done $i
done
