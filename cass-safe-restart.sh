#!/bin/bash

nodetool disableautocompaction
nodetool stop COMPACTION
nodetool disablegossip
nodetool disablebinary
nodetool disablethrift
nodetool drain
sudo service cassandra stop
sleep 4
sudo service cassandra start
