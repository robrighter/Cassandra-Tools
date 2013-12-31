#!/bin/bash
CASSANDRA_DATA_DIR="/var/lib/cassandra/data"
#exit 0

#$1 dir to escape
function escapeDir(){
	echo $(echo $1 | sed -e 's/\//\\\//g')
}
CASSANDRA_DATA_DIR_ESCAPED=$(escapeDir $CASSANDRA_DATA_DIR)


#$1 = existing-file, $2 = destination-folder, $3 = backup or snapshot folder
function getDestinationDirectoryName(){
	echo $(echo $(dirname $1) | sed -e "s/\/$(escapeDir $3)$//g" | sed -e "s/$CASSANDRA_DATA_DIR_ESCAPED/$(escapeDir $2)/")
}

#$1 = output directory name (will be placed in the data dir)
function compileIncrementalBackupFiles(){
	echo "Creating Incremental Backup in $1..."
	if [ -d $1 ]; then
		rm -rf $1
	fi
	for f in $(find $CASSANDRA_DATA_DIR | grep "/backups/")
	do
		echo "copying $f into $(getDestinationDirectoryName $f $1 "backups")"
		mkdir -p "$(getDestinationDirectoryName $f $1 "backups")"
		cp $f "$(getDestinationDirectoryName $f $1 "backups")"
	done
}

#$1 = output directory name (will be placed in the data dir), $2 = snapshot name
function compileSnapshotBackupFiles(){
	echo "Creating Snapshot Backup in $1..."
	if [ -d $1 ]; then
		rm -rf $1
	fi
	for f in $(find $CASSANDRA_DATA_DIR | grep "/snapshots/$2/")
	do
		echo "copying $f into $(getDestinationDirectoryName $f $1 "snapshots/$2")"
		mkdir -p "$(getDestinationDirectoryName $f $1 "snapshots/$2")"
		cp $f "$(getDestinationDirectoryName $f $1 "snapshots/$2")"
	done
}

#$1 outfile without the tar.gz at the end
function tarAndRemoveBackupFolder(){
	tar -zcvf "$1.tar.gz" "$1"	
	rm -rf $1
}

function makeCassandraSnapshot(){
	echo $(nodetool snapshot | grep "Snapshot directory" | sed -e "s/Snapshot directory: //g")
}

#$1 outfile without the tar.gz at the end
function createTaredSnapshotBackup(){
	if [ "$1" == "$CASSANDRA_DATA_DIR" ]; then
		echo "Error: Passed in command would overwrite cassandra data directory"
		exit 1
	fi
	#clear out any existing snapshots
	nodetool clearsnapshot
	#compile the new snapshot and copy it out for taring
	compileSnapshotBackupFiles "$1" "$(makeCassandraSnapshot)"
	#TODO: DELETE the incremental files
	#TODO TODO TODO TODO
	#tar and feather the new snapshot
	tarAndRemoveBackupFolder "$1"
}

#$1 outfile without the tar.gz at the end
function createTaredIncrementalBackup(){
	if [ "$1" == "$CASSANDRA_DATA_DIR" ]; then
                echo "Error: Passed in command would overwrite cassandra data directory"
                exit 1
        fi
	compileIncrementalBackupFiles "$1"
	tarAndRemoveBackupFolder "$1"
}

#$1 snapshot or incremental
function makeDatedFileName(){
	echo "$(date -u +%m-%d-%Y)-$(hostname)-$1"
}

function completeSnapshotBackup(){
	createTaredSnapshotBackup "/var/lib/cassandra/data/$(makeDatedFileName "snapshot")"
}

function completeIncrementalBackup(){
	createTaredIncrementalBackup "/var/lib/cassandra/data/$(makeDatedFileName "incremental")"
}

completeSnapshotBackup
completeIncrementalBackup

