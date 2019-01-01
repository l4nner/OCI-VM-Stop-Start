#!/bin/bash
# set -x
exec 2>/dev/null
compartmentid="ocid1.compartment.oc1..aaaaaaaa32o4bzgvqgjb5xvz4brhf4gxutq7yyl2epw6jwd5ty2s2izbyqva"
instanceslist=~/listinstances.json
printf 'Refreshing instance list...\n'
oci compute instance list --sort-by TIMECREATED --compartment-id $compartmentid --all --sort-order ASC > $instanceslist
totalinst=`cat -s $instanceslist | jq '[.data[]."display-name"],[.data[].id]' | grep "^  \"ocid1.instance.oc1" | wc -l | sed -e 's/ //g'`
counter=1
flcounter=1

function line { echo "----------------------------------------";}
clear
line

while [ $counter -le $totalinst ]
do
    id[$counter]=`cat -s $instanceslist | jq '[.data['$counter'].id]' | grep "ocid1.instance.oc1" | sed 's/\"//g;s/\  //'`
    name[$counter]=`cat -s $instanceslist | jq '[.data['$counter']."display-name"]' | grep \" | sed 's/\"//g;s/\  //'`
    state[$counter]=`cat -s $instanceslist | jq '[.data['$counter']."lifecycle-state"]' | grep \" | sed 's/\"//g;s/\  //'`
	  if [ "${state[$counter]}" == "STOPPED" ] || [ "${state[$counter]}" == "RUNNING" ];
		then
			flid[$flcounter]=${id[$counter]}
			flname[$flcounter]=${name[$counter]}
			flstate[$flcounter]=${state[$counter]}
			printf "$counter\t"${state[$counter]}"\t"${name[$counter]}"\n"
			((flcounter++))
		fi
    ((counter++))
done
line
printf '** S to stop all instances\n'
printf '** anything else to abandon (or Q to quit)\n'
line
printf "Which one? "
read option
case $option in
  [1-${#flstate[*]}])
    if [ "${state[$option]}" == "STOPPED" ]
    then
      oci compute instance action --action start --instance-id "${flid[$option]}" >/dev/null
      printf "\n> STARTING "${flname[$option]}"\n"
    else
      oci compute instance action --action stop --instance-id "${flid[$option]}" >/dev/null
  		printf "\n> STOPPING "${flname[$option]}"\n"
    fi;;
	[Qq])
		printf '> bye\n\n\n'; exit ;;
  [Ss])
    option=""
    printf "stop all running instances?(Y/n) "
    read option
    [ $option == "y" ] && [ option="Y" ]
    if [ -z $option ] || [ $option == "Y" ]
    then
      counter=0
      while [ $counter -le $totalinst ]
      do
        if [ "${flstate[$counter]}" == "RUNNING" ]
        then
          printf "> Stopping instance "${flname[$counter]}""
          oci compute instance action --action stop --instance-id "${flid[$counter]}" >/dev/null
        fi
        ((counter++))
      done
    fi
		printf 'Stopping request was sent to all of the running instances. \n\n\n';;
  *)
    printf '> invalid option\n\n\n';;
esac
