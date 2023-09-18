#!/bin/bash

source "/data/AutoOzone/variables.sh"

i=0
counter=0
max=10

# infinite loop
while [[ $i < $max ]]
do
	om1_res=$(ansible -i "$INV_FILE" $OM1_HOSTNAME -u root --become-user ozone -m shell -a "/hadoop/app/ozone/bin/ozone sh volume list")
	if [[ $om1_res == *"FAILED"* ]]
	then	
		echo "$om1_res"
  else
    echo -e "\t om1 resp: OK"
	fi

	om2_res=$(ansible -i "$INV_FILE" $OM2_HOSTNAME -u root --become-user ozone -m shell -a "/hadoop/app/ozone/bin/ozone sh volume list")
  if [[ $om2_res == *"FAILED"* ]]	
  then	
    echo "$om2_res"
  else
    echo -e "\t om2 resp: OK"
  fi

	om3_res=$(ansible -i "$INV_FILE" $OM3_HOSTNAME -u root --become-user ozone -m shell -a "/hadoop/app/ozone/bin/ozone sh volume list")
  if [[ $om3_res == *"FAILED"* ]]	
  then	
    echo "$om3_res"
  else
    echo -e "\t om3 resp: OK"
  fi

  dn1_res=$(ansible -i "$INV_FILE" $DN1_HOSTNAME -u root --become-user ozone -m shell -a "/hadoop/app/ozone/bin/ozone sh volume list")
	if [[ $dn1_res == *"FAILED"* ]]
	then	
		echo "$dn1_res"
  else
    echo -e "\t datanode1 resp: OK"
	fi

	dn2_res=$(ansible -i "$INV_FILE" $DN2_HOSTNAME -u root --become-user ozone -m shell -a "/hadoop/app/ozone/bin/ozone sh volume list")
  if [[ $dn2_res == *"FAILED"* ]]	
  then	
    echo "$dn2_res"
  else
    echo -e "\t datanode2 resp: OK"
  fi

	dn3_res=$(ansible -i "$INV_FILE" $DN3_HOSTNAME -u root --become-user ozone -m shell -a "/hadoop/app/ozone/bin/ozone sh volume list")
  if [[ $dn3_res == *"FAILED"* ]]	
  then	
    echo "$dn3_res"
  else
    echo -e "\t datanode3 resp: OK"
  fi
  
  counter=$(($counter+1))
  echo "Finished iteration $counter"
done