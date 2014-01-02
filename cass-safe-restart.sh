#!/bin/bash
echo "Attempting safe restart on $(hostname)"
nodetool disableautocompaction
if [ $? -ne 0 ]; then
	echo "Disable compaction failed on $(hostname)"
	exit $?
fi

nodetool stop COMPACTION
if [ $? -ne 0 ]; then
	echo "Stop compaction failed on $(hostname)"
	exit $?
fi

nodetool disablegossip
if [ $? -ne 0 ]; then
	echo "Disable Gossip failed on $(hostname)"
	exit $?
fi
nodetool disablebinary
if [ $? -ne 0 ]; then
	echo "Disable Binary failed on $(hostname)"
	exit $?
fi
nodetool disablethrift
if [ $? -ne 0 ]; then
	echo "Disable Thrift failed on $(hostname)"
	exit $?
fi
nodetool drain
if [ $? -ne 0 ]; then
	echo "Nodetool drain failed on $(hostname)"
	exit $?
fi

sudo service cassandra stop
sleep 4
sudo service cassandra start
exit $?
