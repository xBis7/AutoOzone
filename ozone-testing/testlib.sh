#!/bin/bash

source "/data/AutoOzone/variables.sh"

getHostnameFromNodeName() {
  name=$1

  if [[ $name == "om1" ]]; then
    echo "$OM1_HOSTNAME"
  elif [[ $name == "om2" ]]; then
    echo "$OM2_HOSTNAME"
  elif [[ $name == "om3" ]]; then
    echo "$OM3_HOSTNAME"
  elif [[ $name == "scm1" ]]; then
    echo "$SCM1_HOSTNAME"
  elif [[ $name == "scm2" ]]; then
    echo "$SCM2_HOSTNAME"
  elif [[ $name == "scm3" ]]; then
    echo "$SCM3_HOSTNAME"
  elif [[ $name == "dn1" ]]; then
    echo "$DN1_HOSTNAME"
  elif [[ $name == "dn2" ]]; then
    echo "$DN2_HOSTNAME"
  elif [[ $name == "dn3" ]]; then
    echo "$DN3_HOSTNAME"
  elif [[ $name == "recon" ]]; then
    echo "$RECON_HOSTNAME"
  elif [[ $name == "s3g1" ]]; then
    echo "$S3G1_HOSTNAME"
  elif [[ $name == "s3g2" ]]; then
    echo "$S3G2_HOSTNAME"
  elif [[ $name == "s3g3" ]]; then
    echo "$S3G3_HOSTNAME"
  else
    echo "Unknown node name."
  fi
}

getNodeNameFromHostname() {
  hostname=$1
  service=$2

  # If a hostname isn't provided, use the current.
  if [[ $hostname == "" ]]; then
    hostname=$(hostname)
  fi

  if [[ $hostname == "$OM1_HOSTNAME" ]]; then
    if [[ $service == "om" ]]; then
      echo "om1"
    elif [[ $service == "scm" ]]; then
      echo "scm1"
    elif [[ $service == "recon" ]]; then
      echo "recon"
    else
      echo "invalid service..."
    fi
  elif [[ $hostname == "$OM2_HOSTNAME" ]]; then
    if [[ $service == "om" ]]; then
      echo "om2"
    elif [[ $service == "scm" ]]; then
      echo "scm2"
    else
      echo "invalid service..."
    fi
  elif [[ $hostname == "$OM3_HOSTNAME" ]]; then
    if [[ $service == "om" ]]; then
      echo "om3"
    elif [[ $service == "scm" ]]; then
      echo "scm3"
    else
      echo "invalid service..."
    fi
  elif [[ $hostname == "$DN1_HOSTNAME" ]]; then
    if [[ $service == "dn" ]]; then
      echo "dn1"
    elif [[ $service == "s3g" ]]; then
      echo "s3g1"
    else
      echo "invalid service..."
    fi
  elif [[ $hostname == "$DN2_HOSTNAME" ]]; then
    if [[ $service == "dn" ]]; then
      echo "dn2"
    elif [[ $service == "s3g" ]]; then
      echo "s3g2"
    else
      echo "invalid service..."
    fi
  elif [[ $hostname == "$DN3_HOSTNAME" ]]; then
    if [[ $service == "dn" ]]; then
      echo "dn3"
    elif [[ $service == "s3g" ]]; then
      echo "s3g3"
    else
      echo "invalid service..."
    fi
  else
    echo "Unknown hostname."
  fi
}

sshToNodeBasedOnName() {
  username=$1
  node_name=$2

  # We can use 'whoami' for the username,
  # but the current user might be a root user.
  hostname=$(getHostnameFromNodeName $node_name)

  if [[ $hostname != "Unknown"* ]]; then
    ssh $username@$hostname
  else
    echo "$hostname Exiting..."
    exit 1
  fi
}

doAnsible() {
  # The first parameter can be multiple hosts or all like so
  # "host1,host2,host3" or "all"
  ansible -i "$INV_FILE" $1 -u root --become-user ozone -m $2 -a "$3"
}

doAnsibleAsRoot() {
  ansible -i "$INV_FILE" $1 -u root -m $2 -a "$3"
}

doAnsibleAsOzUser() {
  ansible -i "$INV_FILE" $1 -u root --become-user $2 -m $3 -a "$4"
}

doAnsibleWithNodeName() {
  node=$1
  mod=$2
  cmd=$3

  hostname=$(getHostnameFromNodeName $node)

  if [[ $hostname != "Unknown"* ]]; then
    doAnsible $hostname $mod "$cmd"
  else
    echo "$hostname Exiting..."
    exit 1
  fi
}

doAnsibleWithNodeNameAsRoot() {
  node=$1
  mod=$2
  cmd=$3

  hostname=$(getHostnameFromNodeName $node)

  if [[ $hostname != "Unknown"* ]]; then
    doAnsibleAsRoot $hostname $mod "$cmd"
  else
    echo "$hostname Exiting..."
    exit 1
  fi
}

doAnsibleWithNodeNameAsOzUser() {
  node=$1
  user=$2
  mod=$3
  cmd=$4

  hostname=$(getHostnameFromNodeName $node)

  if [[ $hostname != "Unknown"* ]]; then
    doAnsibleAsOzUser $hostname $user $mod "$cmd"
  else
    echo "$hostname Exiting..."
    exit 1
  fi
}

tailNodeLogs() {
  node_name=$1
  tail=$2

  hostname=$(getHostnameFromNodeName $node_name)

  type="om"

  if [[ $hostname != "Unknown"* ]]; then
    # Check the type 'om, scm, dn'
    if [[ $node_name == *"om"* ]]; then
      type="om"
    elif [[ $node_name == *"scm"* ]]; then
      type="scm"
    elif [[ $node_name == *"dn"* ]]; then
      type="datanode"
    elif [[ $node_name == *"s3g"* ]]; then
      type="s3g"
    elif [[ $node_name == *"recon"* ]]; then
      type="recon"
    fi

    doAnsible $hostname shell "cat /hadoop/app/ozone/logs/ozone-ozone-$type-$hostname.log | tail -$tail"
  else
    echo "$hostname Exiting..."
    exit 1
  fi
}

freonKeyCreation() {
  hostname=$1
  freon_cmd=$2
  volume=$3
  bucket=$4
  prefix=$5
  threads=$6
  num=$7
  key_size=$8
  buffer_size=$9

  if [[ $freon_cmd == "omkg" ]]; then
    doAnsible $hostname shell "/hadoop/app/ozone/bin/ozone freon omkg -t $threads -n $num -v $volume -b $bucket -p $prefix"
  else
    # Default values
    if [[ $key_size == "" ]]; then
      key_size=10240
    fi

    if [[ $buffer_size == "" ]]; then
      buffer_size=4096
    fi

    doAnsible $hostname shell "/hadoop/app/ozone/bin/ozone freon ockg -t $threads -n $num -v $volume -b $bucket -p $prefix -s $key_size --buffer $buffer_size"
  fi
}

# Return num of the newest available backup dir or return 0 if there isn't one.
getLatestBackupDirNum() {
  # This can be either
  # "/hadoop/testBackup"
  #   or
  # "/hadoop/testBackup/backup_<num>/om_bootstrap_backup"
  backup_root_dir=$1

  # Backup counter will be the same for all.
  # Get all backup_ dirs, get the last one and split the name to get the number.
  res_num=$(doAnsibleWithNodeName "om1" shell "ls -lah $backup_root_dir | grep 'backup_'" | tail -1 | awk -F '[_]' '{ print $2 }')

  dir_counter=0

  # If the response is empty, there are no directories yet.
  if [[ $res_num != "" ]]; then
    echo "$res_num"
  else
    echo "$dir_counter"
  fi
}

dataBackup() {
  src_dir_parent="/hadoop/ozone"
  backup_root_dir="/hadoop/testBackup"

  doAnsibleWithNodeName "om1" shell "mkdir -p $backup_root_dir"
  doAnsibleWithNodeName "om2" shell "mkdir -p $backup_root_dir"
  doAnsibleWithNodeName "om3" shell "mkdir -p $backup_root_dir"
  doAnsibleWithNodeName "dn1" shell "mkdir -p $backup_root_dir"
  doAnsibleWithNodeName "dn2" shell "mkdir -p $backup_root_dir"
  doAnsibleWithNodeName "dn3" shell "mkdir -p $backup_root_dir"

  # Latest dir num will return 0 if there isn't one available.
  # In any case, just incr the num by 1.
  latest_dir_num=$(getLatestBackupDirNum $backup_root_dir)

  num=$(($latest_dir_num + 1))
  dest_dir="$backup_root_dir/backup_$num"

  # Backup all

  doAnsibleWithNodeName "om1" shell "mkdir -p $dest_dir"
  doAnsibleWithNodeName "om2" shell "mkdir -p $dest_dir"
  doAnsibleWithNodeName "om3" shell "mkdir -p $dest_dir"
  doAnsibleWithNodeName "dn1" shell "mkdir -p $dest_dir"
  doAnsibleWithNodeName "dn2" shell "mkdir -p $dest_dir"
  doAnsibleWithNodeName "dn3" shell "mkdir -p $dest_dir"

  #	doAnsibleWithNodeName "om1" copy "src=$src_dir dest=$dest_dir remote_src=yes"

  # When the copied dir is pretty large, millions of keys and thousands of snapshots,
  # tar takes under 1 minute to finish, while builtin copy takes more than 20 minutes.

  # The '-p' option preserves the permissions of the dir.
  doAnsibleWithNodeName "om1" shell "cd $src_dir_parent; tar cf - . -p | (cd $dest_dir; tar xvf -)"
  doAnsibleWithNodeName "om2" shell "cd $src_dir_parent; tar cf - . -p | (cd $dest_dir; tar xvf -)"
  doAnsibleWithNodeName "om3" shell "cd $src_dir_parent; tar cf - . -p | (cd $dest_dir; tar xvf -)"
  doAnsibleWithNodeName "dn1" shell "cd $src_dir_parent; tar cf - . -p | (cd $dest_dir; tar xvf -)"
  doAnsibleWithNodeName "dn2" shell "cd $src_dir_parent; tar cf - . -p | (cd $dest_dir; tar xvf -)"
  doAnsibleWithNodeName "dn3" shell "cd $src_dir_parent; tar cf - . -p | (cd $dest_dir; tar xvf -)"

  echo "om1, ls -lah"
  doAnsibleWithNodeName "om1" shell "ls -lah $backup_root_dir"
}

# This method will run for saving data after an OM bootstrap.
# It will be executed on top of data from a previous backup.
# User will provide the backup_dir_num.
#
# With this backup, we can revisit the state after a ratis snapshot installation.
bootstrappedOmDataBackup() {
  backup_dir_num=$1

  backup_root_dir="/hadoop/testBackup"

  # If backup_dir_num is empty, then use the latest.
  if [[ $backup_dir_num == "" ]]; then
    backup_dir_num=$(getLatestBackupDirNum $backup_root_dir)
  fi

  bootstrap_backup_dir="$backup_root_dir/backup_$backup_dir_num/om_bootstrap_backup"

  doAnsibleWithNodeName "om1" shell "mkdir -p $bootstrap_backup_dir"
  doAnsibleWithNodeName "om2" shell "mkdir -p $bootstrap_backup_dir"
  doAnsibleWithNodeName "om3" shell "mkdir -p $bootstrap_backup_dir"
  doAnsibleWithNodeName "dn1" shell "mkdir -p $bootstrap_backup_dir"
  doAnsibleWithNodeName "dn2" shell "mkdir -p $bootstrap_backup_dir"
  doAnsibleWithNodeName "dn3" shell "mkdir -p $bootstrap_backup_dir"

  src_dir_parent="/hadoop/ozone"

  latest_om_backup_num=$(getLatestBackupDirNum $bootstrap_backup_dir)

  num=$(($latest_om_backup_num + 1))
  om_boot_backup_dir="$bootstrap_backup_dir/backup_$num"

  doAnsibleWithNodeName "om1" shell "mkdir -p $om_boot_backup_dir"
  doAnsibleWithNodeName "om2" shell "mkdir -p $om_boot_backup_dir"
  doAnsibleWithNodeName "om3" shell "mkdir -p $om_boot_backup_dir"
  doAnsibleWithNodeName "dn1" shell "mkdir -p $om_boot_backup_dir"
  doAnsibleWithNodeName "dn2" shell "mkdir -p $om_boot_backup_dir"
  doAnsibleWithNodeName "dn3" shell "mkdir -p $om_boot_backup_dir"

  doAnsibleWithNodeName "om1" shell "cd $src_dir_parent; tar cf - . -p | (cd $om_boot_backup_dir; tar xvf -)"
  doAnsibleWithNodeName "om2" shell "cd $src_dir_parent; tar cf - . -p | (cd $om_boot_backup_dir; tar xvf -)"
  doAnsibleWithNodeName "om3" shell "cd $src_dir_parent; tar cf - . -p | (cd $om_boot_backup_dir; tar xvf -)"
  doAnsibleWithNodeName "dn1" shell "cd $src_dir_parent; tar cf - . -p | (cd $om_boot_backup_dir; tar xvf -)"
  doAnsibleWithNodeName "dn2" shell "cd $src_dir_parent; tar cf - . -p | (cd $om_boot_backup_dir; tar xvf -)"
  doAnsibleWithNodeName "dn3" shell "cd $src_dir_parent; tar cf - . -p | (cd $om_boot_backup_dir; tar xvf -)"

}

replaceFilesWithBackup() {
  backup_dir_num=$1
  node_name=$2

  # backup dir has a txt with the terminal output.
  # To avoid copying that as well, copy just the disk1 dir.
  oz_root_dir="/hadoop/ozone/data"
  backup_dir="/hadoop/testBackup/backup_$backup_dir_num/data"

  if [[ $node_name == "" ]]; then
    # Delete data for all nodes
    doAnsibleWithNodeNameAsRoot "om1" shell "rm -rf $oz_root_dir/*"
    echo "Deleted data for om1/scm1/s3g1/recon"
    doAnsibleWithNodeNameAsRoot "om1" shell "ls -lah $oz_root_dir"
    doAnsibleWithNodeNameAsRoot "om1" shell "cd $backup_dir; tar cf - . -p | (cd $oz_root_dir; tar xvf -)"

    doAnsibleWithNodeNameAsRoot "om2" shell "rm -rf $oz_root_dir/*"
    echo "Deleted data for om2/scm2/s3g2"
    doAnsibleWithNodeNameAsRoot "om2" shell "ls -lah $oz_root_dir"
    doAnsibleWithNodeNameAsRoot "om2" shell "cd $backup_dir; tar cf - . -p | (cd $oz_root_dir; tar xvf -)"

    doAnsibleWithNodeNameAsRoot "om3" shell "rm -rf $oz_root_dir/*"
    echo "Deleted data for om3/scm3/s3g3"
    doAnsibleWithNodeNameAsRoot "om3" shell "ls -lah $oz_root_dir"
    doAnsibleWithNodeNameAsRoot "om3" shell "cd $backup_dir; tar cf - . -p | (cd $oz_root_dir; tar xvf -)"

    doAnsibleWithNodeNameAsRoot "dn1" shell "rm -rf $oz_root_dir/*"
    echo "Deleted data for dn1"
    doAnsibleWithNodeNameAsRoot "dn1" shell "ls -lah $oz_root_dir"
    doAnsibleWithNodeNameAsRoot "dn1" shell "cd $backup_dir; tar cf - . -p | (cd $oz_root_dir; tar xvf -)"

    doAnsibleWithNodeNameAsRoot "dn2" shell "rm -rf $oz_root_dir/*"
    echo "Deleted data for dn2"
    doAnsibleWithNodeNameAsRoot "dn2" shell "ls -lah $oz_root_dir"
    doAnsibleWithNodeNameAsRoot "dn2" shell "cd $backup_dir; tar cf - . -p | (cd $oz_root_dir; tar xvf -)"

    doAnsibleWithNodeNameAsRoot "dn3" shell "rm -rf $oz_root_dir/*"
    echo "Deleted data for dn3"
    doAnsibleWithNodeNameAsRoot "dn3" shell "ls -lah $oz_root_dir"
    doAnsibleWithNodeNameAsRoot "dn3" shell "cd $backup_dir; tar cf - . -p | (cd $oz_root_dir; tar xvf -)"
  else
    doAnsibleWithNodeNameAsRoot "$node_name" shell "rm -rf $oz_root_dir/*"
    echo "Deleted data for $node_name"
    doAnsibleWithNodeNameAsRoot "$node_name" shell "ls -lah $oz_root_dir"
    doAnsibleWithNodeNameAsRoot "$node_name" shell "cd $backup_dir; tar cf - . -p | (cd $oz_root_dir; tar xvf -)"
  fi

  # Move backup data
  # doAnsibleWithNodeName "om1" copy "src=$backup_dir dest=$oz_root_dir remote_src=yes"
  # doAnsibleWithNodeName "om2" copy "src=$backup_dir dest=$oz_root_dir remote_src=yes"
  # doAnsibleWithNodeName "om3" copy "src=$backup_dir dest=$oz_root_dir remote_src=yes"
  # doAnsibleWithNodeName "dn1" copy "src=$backup_dir dest=$oz_root_dir remote_src=yes"
  # doAnsibleWithNodeName "dn2" copy "src=$backup_dir dest=$oz_root_dir remote_src=yes"
  # doAnsibleWithNodeName "dn3" copy "src=$backup_dir dest=$oz_root_dir remote_src=yes"

  # tar is way more performant than builtin copy. The difference is greatly noticeable with large files.
}

replaceFilesWithBootstrapBackup() {
  backup_dir_num=$1
  boostrap_backup_dir_num=$2
  node_name=$3

  # backup dir has a txt with the terminal output.
  # To avoid copying that as well, copy just the disk1 dir.
  oz_root_dir="/hadoop/ozone/data"
  backup_dir="/hadoop/testBackup/backup_$backup_dir_num/om_bootstrap_backup/backup_$boostrap_backup_dir_num/data"

  if [[ $node_name == "" ]]; then
    # Delete data for all nodes
    doAnsibleWithNodeNameAsRoot "om1" shell "rm -rf $oz_root_dir/*"
    echo "Deleted data for om1/scm1/s3g1/recon"
    doAnsibleWithNodeNameAsRoot "om1" shell "ls -lah $oz_root_dir"
    doAnsibleWithNodeNameAsRoot "om1" shell "cd $backup_dir; tar cf - . -p | (cd $oz_root_dir; tar xvf -)"

    doAnsibleWithNodeNameAsRoot "om2" shell "rm -rf $oz_root_dir/*"
    echo "Deleted data for om2/scm2/s3g2"
    doAnsibleWithNodeNameAsRoot "om2" shell "ls -lah $oz_root_dir"
    doAnsibleWithNodeNameAsRoot "om2" shell "cd $backup_dir; tar cf - . -p | (cd $oz_root_dir; tar xvf -)"

    doAnsibleWithNodeNameAsRoot "om3" shell "rm -rf $oz_root_dir/*"
    echo "Deleted data for om3/scm3/s3g3"
    doAnsibleWithNodeNameAsRoot "om3" shell "ls -lah $oz_root_dir"
    doAnsibleWithNodeNameAsRoot "om3" shell "cd $backup_dir; tar cf - . -p | (cd $oz_root_dir; tar xvf -)"

    doAnsibleWithNodeNameAsRoot "dn1" shell "rm -rf $oz_root_dir/*"
    echo "Deleted data for dn1"
    doAnsibleWithNodeNameAsRoot "dn1" shell "ls -lah $oz_root_dir"
    doAnsibleWithNodeNameAsRoot "dn1" shell "cd $backup_dir; tar cf - . -p | (cd $oz_root_dir; tar xvf -)"

    doAnsibleWithNodeNameAsRoot "dn2" shell "rm -rf $oz_root_dir/*"
    echo "Deleted data for dn2"
    doAnsibleWithNodeNameAsRoot "dn2" shell "ls -lah $oz_root_dir"
    doAnsibleWithNodeNameAsRoot "dn2" shell "cd $backup_dir; tar cf - . -p | (cd $oz_root_dir; tar xvf -)"

    doAnsibleWithNodeNameAsRoot "dn3" shell "rm -rf $oz_root_dir/*"
    echo "Deleted data for dn3"
    doAnsibleWithNodeNameAsRoot "dn3" shell "ls -lah $oz_root_dir"
    doAnsibleWithNodeNameAsRoot "dn3" shell "cd $backup_dir; tar cf - . -p | (cd $oz_root_dir; tar xvf -)"
  else
    doAnsibleWithNodeNameAsRoot "$node_name" shell "rm -rf $oz_root_dir/*"
    echo "Deleted data for $node_name"
    doAnsibleWithNodeNameAsRoot "$node_name" shell "ls -lah $oz_root_dir"
    doAnsibleWithNodeNameAsRoot "$node_name" shell "cd $backup_dir; tar cf - . -p | (cd $oz_root_dir; tar xvf -)"
  fi
}

copyTermOutToAllNodesAndClearFile() {
  term_file=$1
  backup_dir_num=$2
  bootstrap_backup_dir_num=$3

  backup_root_dir="/hadoop/testBackup"

  if [[ $backup_dir_num == "" || $bootstrap_backup_dir_num == "" ]]; then
    echo "No backup data dirs specified, exiting..."
    exit 1
  fi

  bootstrap_backup_dir="/hadoop/testBackup/backup_$backup_dir_num/om_bootstrap_backup"
  dest="$bootstrap_backup_dir/backup_$bootstrap_backup_dir_num/$term_file"

  doAnsible "all" copy "src=$term_file dest=$dest"
  # doAnsibleWithNodeName "om1" copy "src=$term_file dest=$dest_dir"
  # doAnsibleWithNodeName "om2" copy "src=$term_file dest=$dest_dir"
  # doAnsibleWithNodeName "om3" copy "src=$term_file dest=$dest_dir"
  # doAnsibleWithNodeName "dn1" copy "src=$term_file dest=$dest_dir"
  # doAnsibleWithNodeName "dn2" copy "src=$term_file dest=$dest_dir"
  # doAnsibleWithNodeName "dn3" copy "src=$term_file dest=$dest_dir"

  echo "ls -lah $bootstrap_backup_dir/backup_$bootstrap_backup_dir_num"
  doAnsibleWithNodeName "om1" shell "ls -lah $bootstrap_backup_dir/backup_$bootstrap_backup_dir_num"

  >$term_file
}

deleteBackupData() {
  backup_dir="/hadoop/testBackup"
  doAnsibleWithNodeNameAsRoot "om1" shell "rm -rf $backup_dir/*"
  echo "Backup data deleted for om1/scm1/s3g1/recon, ls -lah $backup_dir"
  doAnsibleWithNodeNameAsRoot "om1" shell "ls -lah $backup_dir"

  doAnsibleWithNodeNameAsRoot "om2" shell "rm -rf $backup_dir/*"
  echo "Backup data deleted for om2/scm2/s3g2, ls -lah $backup_dir"
  doAnsibleWithNodeNameAsRoot "om2" shell "ls -lah $backup_dir"

  doAnsibleWithNodeNameAsRoot "om3" shell "rm -rf $backup_dir/*"
  echo "Backup data deleted for om3/scm3/s3g3, ls -lah $backup_dir"
  doAnsibleWithNodeNameAsRoot "om3" shell "ls -lah $backup_dir"

  doAnsibleWithNodeNameAsRoot "dn1" shell "rm -rf $backup_dir/*"
  echo "Backup data deleted for dn1, ls -lah $backup_dir"
  doAnsibleWithNodeNameAsRoot "dn1" shell "ls -lah $backup_dir"

  doAnsibleWithNodeNameAsRoot "dn2" shell "rm -rf $backup_dir/*"
  echo "Backup data deleted for dn2, ls -lah $backup_dir"
  doAnsibleWithNodeNameAsRoot "dn2" shell "ls -lah $backup_dir"

  doAnsibleWithNodeNameAsRoot "dn3" shell "rm -rf $backup_dir/*"
  echo "Backup data deleted for dn3, ls -lah $backup_dir"
  doAnsibleWithNodeNameAsRoot "dn3" shell "ls -lah $backup_dir"
}

doAnsibleFreonKeyCreation() {
  dn1=$1
  dn2=$2
  dn3=$3
  freon_cmd=$4
  volume=$5
  bucket=$6
  prefix=$7
  random=$8
  keys_per_client=$9
  threads=${10}
  key_size=${11}
  buffer_size=${12}

  # writes=$(($keys/4))
  # threads=$(($writes/10))
  # threads=1000

  # Run the commands in the background
  freonKeyCreation $dn1 "$freon_cmd" $volume $bucket "$prefix$random" "$threads" "$keys_per_client" "$key_size" "$buffer_size" &
  pid_dn1=$!

  random=$(($random + 1))

  freonKeyCreation $dn2 "$freon_cmd" $volume $bucket "$prefix$random" "$threads" "$keys_per_client" "$key_size" "$buffer_size" &
  pid_dn2=$!

  random=$(($random + 1))

  freonKeyCreation $dn3 "$freon_cmd" $volume $bucket "$prefix$random" "$threads" "$keys_per_client" "$key_size" "$buffer_size" &
  pid_dn3=$!

  # Wait for all commands to finish
  wait $pid_dn1 $pid_dn2 $pid_dn3
}

doAnsibleFreonKeyCreationOneNode() {
  dn1=$1
  freon_cmd=$2
  volume=$3
  bucket=$4
  prefix=$5
  keys_per_client=$6
  threads=$7
  key_size=$8
  buffer_size=$9

  freonKeyCreation $dn1 "$freon_cmd" $volume $bucket "$prefix" "$threads" "$keys_per_client" "$key_size" "$buffer_size"
}

createVolBucketKeys() {
  om=$1
  volume=$2
  bucket=$3
  layout=$4
  keys=$5
  freon_cmd=$6

  doAnsible $om shell "/hadoop/app/ozone/bin/ozone sh volume create /$volume"
  doAnsible $om shell "/hadoop/app/ozone/bin/ozone sh bucket create /$volume/$bucket --layout $layout"

  echo "Successful volume - bucket init"

  freonKeyCreation $om "$freon_cmd" $volume $bucket "p" $threads $keys

  echo "Successful key creation"
}

doAnsibleAsyncPoll() {
  ansible -i "$INV_FILE" $1 -u root --become-user ozone -m $2 -a "$3" -B $4 -P $5
}

checkService() {
  # doAnsible, becomes ozone user before executing the command.
  # We need to pass the user as part of 'ps'.
  ansible -i "$INV_FILE" $1 -m shell -a "ps -f -u ozone | grep '$2'"
}

stopOM() {
  om=$1
  doAnsible $om shell "/hadoop/app/ozone/bin/stop_om.sh"

  # verify that the om is stopped.
  om_stop_logs_res=$(checkService $om "OzoneManagerStarter")

  # If the service is not running, then result should be FAILED.
  if [[ $om_stop_logs_res != *"FAILED"* ]]; then
    echo "$om failed to shut down, exiting..."
    exit 1
  fi

  echo "$om successfuly stopped"
}

deleteOMData() {
  om=$1
  parent_path=$2

  doAnsible $om file "dest=$parent_path/om state=absent"
  # ratis dir needs to be reinitialized as well.
  doAnsible $om file "dest=$parent_path/data/ratis state=absent"

  # verify that the parent dir no longer has the data
  empty_data_res=$(doAnsible $om shell "ls $parent_path | grep 'om'")

  if [[ $empty_data_res != *"FAILED"* ]]; then
    echo "Failed to delete data for $om, exiting..."
    exit 1
  fi

  echo "Deleted all data for $om"
}

startOM() {
  om=$1

  doAnsibleAsyncPoll $om shell "/hadoop/app/ozone/bin/start_om.sh" 120 5

  om_logs_res=$(checkService $om "OzoneManagerStarter")

  # If result contains FAILED, then the om hasn't been started.
  if [[ $om_logs_res == *"FAILED"* ]]; then
    echo "$om failed to restart, exiting..."
    exit 1
  fi

  echo "$om successfuly started"
}

createDescriptionFileIfNeeded() {
  dir_num=$1
  node_name=$2

  backup_dir="/hadoop/testBackup/backup_$dir_num"

  file_exists=$(doAnsibleWithNodeName om1 shell "ls -lah $backup_dir | grep 'state_desc.txt'")

  # Check if file already exists.
  if [[ $file_exists == *"FAILED"* ]]; then
    # If it's empty, then create on all nodes.
    if [[ $node_name == "" ]]; then
      doAnsible "all" shell "touch $backup_dir/state_desc.txt"
      doAnsible "all" shell "ls -lah $backup_dir"
    else
      doAnsibleWithNodeName "$node_name" shell "touch $backup_dir/state_desc.txt"
      doAnsibleWithNodeName "$node_name" shell "ls -lah $backup_dir"
    fi
  fi
}

addLineToDescriptionFile() {
  dir_num=$1
  msg=$2
  node_name=$3

  desc_file="$backup_dir/state_desc.txt"

  # If it's empty, then create on all nodes.
  if [[ $node_name == "" ]]; then
    doAnsible "all" shell "echo '$msg' >> $desc_file"
    doAnsible "all" shell "cat $desc_file"
  else
    doAnsibleWithNodeName "$node_name" shell "echo '$msg' >> $desc_file"
    doAnsibleWithNodeName "$node_name" shell "cat $desc_file"
  fi
}

manualKeyWriting() {
  hostname=$1
  volume=$2
  bucket=$3
  prefix=$4
  key_num=$5

  tmp_file="/hadoop/app/ozone/bin/tmp.txt"

  start_time=$(date +%s)

  count=0
  while [ $count -lt $key_num ]; do
    keyname="$prefix/$count"
    # Write the key name to the tmp file
    doAnsible $hostname shell "echo '$keyname' >> $tmp_file"
    # Create a key based on the tmp file
    doAnsible $hostname shell "/hadoop/app/ozone/bin/ozone sh key put /$volume/$bucket/$keyname $tmp_file"
    # pid=$!
    # wait $pid

    # Clear the tmp file
    doAnsible $hostname shell "> $tmp_file"

    count=$(($count + 1))
  done

  end_time=$(date +%s)
  echo "Finished writing '$key_num' keys manually. Elapsed time: $(($end_time - $start_time)) seconds"
}

getOMBasedOnRole() {
  om=$1
  role=$2

  leader_res=$(doAnsible $om shell "/hadoop/app/ozone/bin/ozone admin om roles -id=omcluster" | grep 'LEADER')

  while [[ $leader_res != *"LEADER"* ]]; do
    echo "waiting for OM leader to be available..."
    leader_res=$(doAnsible $om shell "/hadoop/app/ozone/bin/ozone admin om roles -id=omcluster" | grep 'LEADER')
  done

  if [[ $role == "leader" ]]; then
    doAnsible $om shell "/hadoop/app/ozone/bin/ozone admin om roles -id=omcluster" | grep 'LEADER' | head -1 | awk '{ print $4 }' | awk -F '[()]' '{ print $2 }'
  elif [[ $role == "follower1" ]]; then
    doAnsible $om shell "/hadoop/app/ozone/bin/ozone admin om roles -id=omcluster" | grep 'FOLLOWER' | head -1 | awk '{ print $4 }' | awk -F '[()]' '{ print $2 }'
  elif [[ $role == "follower2" ]]; then
    doAnsible $om shell "/hadoop/app/ozone/bin/ozone admin om roles -id=omcluster" | grep 'FOLLOWER' | tail -1 | awk '{ print $4 }' | awk -F '[()]' '{ print $2 }'
  else # return the first follower
    doAnsible $om shell "/hadoop/app/ozone/bin/ozone admin om roles -id=omcluster" | grep 'FOLLOWER' | head -1 | awk '{ print $4 }' | awk -F '[()]' '{ print $2 }'
  fi
}

kinitHost() {
  host=$1
  doAnsible $host shell "kinit -kt /etc/security/keytabs/ozone.keytab ozone/$host@$HOSTNAME_SUFFIX"
}

kinitHostWithNodeName() {
  name=$1
  hostname=$(getHostnameFromNodeName $name)

  if [[ $hostname != "Unknown"* ]]; then
    doAnsible $hostname shell "kinit -kt /etc/security/keytabs/ozone.keytab ozone/$hostname@$HOSTNAME_SUFFIX"
  else
    echo "$hostname Exiting..."
    exit 1
  fi
}

checkRatisSnapshotIns() {
  om=$1

  snap_start_time=$(date +%s)

  checkpointDir_res=$(doAnsible $om shell "ls -lah /hadoop/ozone/data/disk1/om/db.snapshots/checkpointState | grep 'om.db-'")

  # If it contains FAILED, the tarball hasn't been installed on the follower yet
  while [[ $checkpointDir_res == *"FAILED"* ]]; do
    echo "No snapshots have been installed on the follower yet, retrying..."
    sleep 10
    checkpointDir_res=$(doAnsible $om shell "ls -lah /hadoop/ozone/data/disk1/om/db.snapshots/checkpointState | grep 'om.db-'")
  done

  # This check makes sense only if the existing snapshots on the system,
  # are the ones that the load test created and that we can find on 'snaps.txt' file.
  # Otherwise, the Ratis snapshot will also install previous Ozone snapshots.
  #
  # We may reach the number of snapshots on the file before finishing all snapshot installation.
  # In that case, leadership transfer will timeout and fail.
  snap_num_on_dir_res=$(doAnsible $om shell "ls -lah /hadoop/ozone/data/disk1/om/db.snapshots/checkpointState | grep 'om.db-' | wc -l")
  snap_num_on_file_res=$(cat snaps.txt | wc -l)

  while [[ $snap_num_on_dir_res < $snap_num_on_file_res ]]; do
    echo "Waiting for all snapshots to install"
    snap_num_on_dir_res=$(doAnsible $om shell "ls -lah /hadoop/ozone/data/disk1/om/db.snapshots/checkpointState | grep 'om.db-' | wc -l")
    snap_num_on_file_res=$(cat snaps.txt | wc -l)
  done

  snap_end_time=$(date +%s)
  echo "Ratis snapshot has been installed. Elapsed time: $(($snap_end_time - $snap_start_time)) seconds"

  echo "Tarballs installed in OM: '$om'"
  doAnsible $om shell "ls -lah /hadoop/ozone/data/disk1/data/snapshot"
}

checkOMIsLeader() {
  om=$1

  leader_om=$(getOMBasedOnRole $om "leader")
  echo "Checking om leadership, current om: '$om' | leader: '$leader_om'"

  if [[ $om == $leader_om ]]; then
    echo "current om: '$om' is the leader."
  else
    counter=0

    # Retry 2 times, with some sleep,
    # in case there is some lag during om leadership transfer.
    while [[ $counter < 2 ]]; do
      echo "Retrying, ..."
      leader_om=$(getOMBasedOnRole $om "leader")

      if [[ $om == $leader_om ]]; then
        break
      fi
      sleep 3
      counter=$(($counter + 1))
    done
    echo "'$om' is not the leader, exiting..."
    exit 1
  fi
}

transferOMLeadership() {
  om=$1

  echo "Transferring leadership to OM: $om"

  om_id=$(doAnsible $om shell "/hadoop/app/ozone/bin/ozone admin om roles -id=omcluster | grep '$om'" | tail -1 | awk -F '[:]' '{ print $1 }')

  # Transfer leadership
  leader_change_res=$(doAnsible $om shell "/hadoop/app/ozone/bin/ozone admin om transfer -id=omcluster -n=$om_id")

  retry=0

  while [[ $leader_change_res == *"FAILED"* ]]; do
    # Retry 2 times, then exit.
    if [[ $retry > 2 ]]; then
      echo "Leadership transfer failed 3 times, exiting..."
      exit 1
    fi

    echo "Leader change response contains FAILED, retrying..."
    leader_change_res=$(doAnsible $om shell "/hadoop/app/ozone/bin/ozone admin om transfer -id=omcluster -n=$om_id")
    retry=$(($retry + 1))
  done

  checkOMIsLeader $om
}

runSnapDiff() {
  hostname=$1
  host_service=$2
  volume=$3
  bucket=$4
  snap1=$5
  snap2=$6
  filename=$7

  name=$(getNodeNameFromHostname $hostname "$host_service")

  diff_start_time=$(date +%s)

  # Submit a snapshot diff
  echo "Submitting a snap diff job for '/$volume/$bucket $snap1 $snap2'"
  diff_res=$(doAnsible $hostname shell "/hadoop/app/ozone/bin/ozone sh snapshot diff /$volume/$bucket $snap1 $snap2")

  while [[ $diff_res == *"IN_PROGRESS"* ]]; do
    # Wait for the results
    echo "Snap diff is IN_PROGRESS, retrying..."
    diff_res=$(doAnsible $hostname shell "/hadoop/app/ozone/bin/ozone sh snapshot diff /$volume/$bucket $snap1 $snap2")
    sleep 10
  done

  doAnsible $hostname shell "/hadoop/app/ozone/bin/ozone sh snapshot diff /$volume/$bucket $snap1 $snap2" >>"$filename"

  diff_end_time=$(date +%s)

  echo "Finished snap diff job for '/$volume/$bucket $snap1 $snap2'. Elapsed time: $(($diff_end_time - $diff_start_time)) seconds"

  diff_key_num=$(cat "$filename" | grep -E "/sn[0-9]+\/" | wc -l)

  echo "Number of keys: '$diff_key_num' for snap diff '/$volume/$bucket $snap1 $snap2'"
}

checkKeyValuesFromFile() {
  filename=$1
  hostname=$2
  volume=$3
  bucket=$4
  snapshot=$5
  NUM_KEYS_PER_SNAPSHOT=$6

  count=1
  start_time=$(date +%s)

  # Iterating over all keys in the file.
  while (($count <= $NUM_KEYS_PER_SNAPSHOT)); do
    # keys are in format '+	./sn1454/227'
    # split using '/', get the two parts and then concantenate them.
    # 'sn1454'
    prefix=$(cat "$filename" | tail -$count | head -1 | awk -F '[/]' '{ print $2 }')
    # '227'
    keyname=$(cat "$filename" | tail -$count | head -1 | awk -F '[/]' '{ print $3 }')

    key="$prefix/$keyname"

    # Regular key read
    key_info_res=$(doAnsible $om shell "/hadoop/app/ozone/bin/ozone sh key info /$volume/$bucket/.snapshot/$snapshot/$key")

    # Retry?
    if [[ $key_info_res == *"FAILED"* ]]; then
      echo "'/$volume/$bucket/$key' doesn't exist on ΟΜ:'$om', exiting..."
      exit 1
    fi

    key_cont_res=$(doAnsible $hostname shell "/hadoop/app/ozone/bin/ozone sh key cat /$volume/$bucket/.snapshot/$snapshot/$key | grep '$key'")

    if [[ $key_cont_res == *"FAILED"* ]]; then
      echo "Key contents are not what was expected, cont: $key_cont_res, exiting..."
      exit 1
    fi

    echo "'/$volume/$bucket/.snapshot/$snapshot/$key', contents: $key_cont_res"
    count=$(($count + 1))
  done

  end_time=$(date +%s)
  echo "Finished checking keys for snapshot: '$snapshot'. Elapsed time: $(($end_time - $start_time)) seconds"
}

checkSnapsAndKeysOnLeaderOM() {
  om=$1
  volume=$2
  bucket=$3
  NUM_KEYS_PER_SNAPSHOT=$4
  NUM_SNAPSHOTS=$5

  checkOMIsLeader $om

  for i in {0..9}; do
    snap_num1=$(($i * 100))
    snap_num2=$(($snap_num1 + 1))

    if (($snap_num2 <= $NUM_SNAPSHOTS)); then
      diff_dir="diff"

      mkdir -p "$diff_dir"

      filename="diff/diff-$snap_num1-$snap_num2.txt"

      # Clear the file.
      >$filename

      runSnapDiff $om "om" $volume $bucket "snap-$snap_num1" "snap-$snap_num2" $filename

      diff_key_num=$(cat "$filename" | grep -E "/sn[0-9]+\/" | wc -l)

      # number of results should be equal to "NUM_KEYS_PER_SNAPSHOT"
      # This check makes sense if number of keys per snapshot is <=1000,
      # because there is pagination and we can't get the whole number of results.
      if [[ $diff_key_num != $NUM_KEYS_PER_SNAPSHOT ]]; then
        echo "Number of diff keys on the follower is not '$NUM_KEYS_PER_SNAPSHOT'"
        echo "Number of diff keys on the follower is '$diff_key_num'"
        exit 1
      fi

      checkKeyValuesFromFile $filename $om $volume $bucket "snap-$snap_num2" "$NUM_KEYS_PER_SNAPSHOT"
    fi
  done
}
