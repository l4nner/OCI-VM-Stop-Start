#!/bin/bash
# Quick and easy way to start/stop your OCI VM instances
# set -x

# Enter your compartment ID here:
compartment='ocid1.compartment.oc1..aaaaaaaa32o4bzgvqgjb5xvz4brhf4gxutq7yyl2epw6jwd5ty2s2izbyqva'

# Checking requirements
command -v jq >/dev/null 2>&1 || { echo >&2 "jq is not available. Please install. "; exit 1; }

#### Variables

# Just to document. Not needed.
declare jsonfile="./listinstances.json";  #temp json store
:> $jsonfile
declare -i index                  #loops index
declare -i totalInsts             #total number of running or stopped instances
declare -i arrayMembers           #number of array members
declare -i numberOfParameters     #number of passed parameters
declare action                    #stores "stop" or "start"
declare option="N"                #user input
declare runningInstances="false"  #flag for there is running VMs
declare auxState                  #temp store for the state value
declare compartmentName
declare -a vmNumber               #array for VM numbers
declare -a id                     #array for instances' ids
declare -a name                   #array for instances' names
declare -a state                  #array for instances' states
declare -a parameters             #array for command line parameters

#### Functions

# good distraction
function _spinningthing() {
  declare -i counter=0
  declare interval=$1
  while true
  do
    (( counter = counter + 1 ))
    case $counter in
      1) printf "%s\b" "-";  sleep $interval ;;
      2) printf "%s\b" "/";  sleep $interval ;;
      3) printf "%s\b" "-";  sleep $interval ;;
      4) printf "%s\b" "\\"; sleep $interval ;;
      5) counter=0 ;;
    esac
  done
}

# Data gathering
function _datagathering() {
  # Send query to OCI
  printf "> Capturing VM instances information "
  _spinningthing 0.25 &
  bgpid=$!
  oci compute instance list --sort-by TIMECREATED --compartment-id $compartment --all --sort-order ASC > $jsonfile
  compartmentName=`oci iam compartment get --compartment-id $compartment | jq -r '.data.name'`

  # Populate array with VMs in states "of interest". Running or Stopped
  totalInsts=`cat -s $jsonfile | jq '[.data[].id]' | grep instance | wc -l`
  for index in `seq 1 $totalInsts`
  do
      auxState=$(cat -s $jsonfile | jq '[.data['$index']."lifecycle-state"]' | grep \" | sed 's/[\ ,\,,\"]//g')
      if [ "$auxState" == "STOPPED" ] || [ "$auxState" == "RUNNING" ];
  		then
        state[$index]=$auxState
        vmNumber[$index]=$index
        id[$index]=`cat -s $jsonfile | jq '[.data['$index'].id]' | grep "ocid1.instance.oc1" | sed 's/[\ ,\,,\"]//g'`
        name[$index]=`cat -s $jsonfile | jq '[.data['$index']."display-name"]' | grep \" | sed 's/[\ ,\,,\"]//g'`
  			[ "$auxState" == "RUNNING" ] && [ $runningInstances == "false" ] && runningInstances="true"
      fi
  done
  arrayMembers=${#state[*]}
  kill $bgpid
  wait $bgpid > /dev/null 2>&1
}

# Change instance status
function _changeVmStatus() {
  if [ "${state[$1]}" == "STOPPED" ]
  then
    action="start"
    printf "\n> STARTING "${name[$1]}""
  else
    action="stop"
    printf "\n> STOPPING "${name[$1]}""
  fi
  #OK, this is poetry: action --action $action
  oci compute instance action --action $action --instance-id "${id[$1]}" >/dev/null
}

# search array
_searchArray () {
  searchArray="false"
  local e match=$1
  shift
  for e; do [[ "$e" == "$match" ]] && searchArray="true" ; done;
}

# line on the screen
function _line() {
  echo "------------------------------------------";
}

#### Main

if [ "$#" != "0" ]; then
  # If parameters were provided, just execute gainst the VMs
  # Create parameters array
  # If the parameter is not even an integer, abandon before capturing VMs
  index=0
  while (( "$#" ));
  do
    if ! [[ "$1" =~ ^[0-9]+$ ]]
    then
       printf "\n Parameter os invalid\n"
       exit
    fi
	  parameters[$index]=$1
    shift
    ((index++))
  done
  # compare parameters and VM numbers
  _datagathering
  numberOfParameters=${#parameters[*]}
  topIndex=`expr $numberOfParameters - 1`
  for paramIndex in `seq 0 $topIndex`
  do
    _searchArray "${parameters[$paramIndex]}" "${vmNumber[@]}"
    if [ $searchArray == "true" ]
    then
      _changeVmStatus ${parameters[$paramIndex]}
    else
      printf "\nThere is no VM instance "${parameters[$paramIndex]}""
    fi
  done
else
#### Interactive mode menu
  _datagathering
  clear
  _line
  printf "Compartment $compartmentName\n"
  _line
  for index in `seq 1 $arrayMembers`
  do
    printf "$index\t"${state[$index]}"\t"${name[$index]}"\n"
  done
  _line
  printf '** S to stop all instances\n'
  printf '** anything else to abandon (or Q to quit)\n'
  _line
  printf "Instance number: "
  read -n 1 option
fi

#### Actual execution
case $option in
  [1-$arrayMembers])
		# one of the listed VMs was picked
		# if it is running, stop it. If it's stopped, start it.
    _changeVmStatus $option;;
  [Ss])
		# Stopping all running VMs (if there is any to stop)
		if [ $runningInstances == "true" ]
		then
    		printf "\nStop all running instances?(y/n) "
    		read -n 1 option
        printf "\n"
        if [ "$option" == "Y" ] || [ "$option" == "y" ]
        then
      		index=0
      		while [ $index -le $totalInsts ]
      		do
        		if [ "${state[$index]}" == "RUNNING" ]
        		then
          		_changeVmStatus $index
        		fi
        		((index++))
      		done
        else
          printf "  > Nothing done\n"
    		fi
		else
				printf "  > You have no running instances to stop. That was easy.\n"
		fi;;
  [Qq])
  	# calling it quits
    # No different from entering an invalid option.
    printf "\n> Quitting.";;
  *)
		# just abandon
esac
printf "\n"
rm -f $jsonfile
