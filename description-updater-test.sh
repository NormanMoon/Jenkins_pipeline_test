#!/bin/bash


prefix="COMP-"
#Parent ticket
parent_ticket_num=$(awk -F'"' '/"key":/ {print $8}' create-parent-ticket-test.out | sed 's/COMP-//')
parent_ticket="COMP-${parent_ticket_num}"
last_child_ticket_num=$(awk -F'"' '/"key":/ {print $8}' create-child-ticket-test-subtask.out | sed 's/COMP-//')


token=$1
env=$2
app=$3
app_version=$4
release_type=$5
services=("${@:8}")



#This will remove the ',' from the release_type and
cleaned_release_type="${release_type//[\,]/}"
# This will overwrite the original release_type with the cleaned_release_type
release_type=$cleaned_release_type
# This removes the {} from app version
cleaned_app_version="${app_version//[\{\}]/}"
# This will overwrite the original app_version with the cleaned_app_version
app_version=$cleaned_app_version

cleaned_services=()
# This loop will remove all the un wanted characters from the services array
for service in "${services[@]}"; do
  cleaned_service="${service//[\[\],]/}"
  cleaned_services+=("$cleaned_service")
done
# Overwrites the original service array with the cleaned version of service array
services=("${cleaned_services[@]}")

# Initialize an empty array for tickets
tickets=()

# Loop through all arguments starting from the 7th
for arg in "${@:7}"; do
  # Check if the argument matches the pattern for tticket IDs (e.g., starts with NGD-)
  if [[ $arg =~ ^NGD- ]]; then
    tickets+=("$arg")
  fi
done

# Print the tickets
for i in "${tickets[@]}"; do
  echo "tickets: $i"
done


echo "services: ${services[1]}"

# Federator has always one subticket , mirth one subticket, and smartfhir 3, gmt is 2 (front end or/and backend)
# Whats your current environment?
ticket_description=()

child_tickets=("Deploy: ${app} $app_version \n \n Sequence of Steps:")

for ((i=parent_ticket_num+1; i<=last_child_ticket_num; i++)) do
     child_tickets+=("${prefix}${i}")
done

for ((i=0; i<=${#services[@]}; i++)) do

     if [ "${services[i],,}" = "deployment" ]; then
          ticket_description+=("${env} Deploy Deployment for ${app} $app_version")
     else
          ticket_description+=("${env} Deploy ${services[i]} for ${app} $app_version")
     fi

done

echo "child_tickets ${child_tickets[*]}"

###################################################################################################################

next_step="${bold} <---- current step ★${normal}"

description=("${child_tickets[0]}")


for ((j=1; j<${#child_tickets[@]}; j++)) ; do
     description+=("\n${child_tickets[j]}")
done


#Updates Parent Ticket Description
string_description=${description[*]}
parent_summary="${env} ${release_type} Release of ${app} $app_version - Parent Ticket"
template='{
    "fields" : {
     "summary" : "%s",
      "description" : "%s"
    }
  }'


json_final=$(printf "$template" \
     "$parent_summary" \
     "$string_description")

curl -v -i -X PUT \
  -u norman.moon@aboutobjects.com:$token \
  -H "Content-Type:application/json" \
  -H "Accept: application/json" \
  -H "X-Atlassian-Token:no-check" \
  "https://normanmoon.atlassian.net/rest/api/2/issue/${parent_ticket}" \
  -d \
  "$json_final" \
  -o update-task-test.out


for ((i=1; i<${#child_tickets[@]}; i++))
 do
  if ((i > 0)) &&  [[ ${description[i-1]} == *"${next_step}"* ]]
  then
     description[i-1]=$(echo "${description[i-1]}" | sed "s/${next_step}//g")
  fi
  description[i]+=${next_step}


  string_description=${description[*]}
  summary_temp=${ticket_description[i-1]}
  #string_summary=${tickets[i]}
  template='{
      "fields" : {
        "summary" : "%s",
        "description" : "%s"
      }
    }'

  json_final=$(printf "$template" \
    "$summary_temp" \
    "$string_description")


     curl -v -i -X PUT \
          -u norman.moon@aboutobjects.com:$token \
          -H "Content-Type:application/json" \
          -H "Accept: application/json" \
          -H "X-Atlassian-Token:no-check" \
          "https://normanmoon.atlassian.net/rest/api/2/issue/${child_tickets[i]}" \
          -d \
          "$json_final" \
          -o update-task-test.out

done











