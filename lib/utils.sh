

# Writing a map function, that takes a function, and applies it to every element of an array
map() {
     local func_to_apply=$1 # Passed in function argument
     shift #Shift is used because we no longer need the $1 argument
     local elements=("$@") # An array of the passed in arguments after shift
     local return_result=() # The array to hold the changed elements
     # for loop that goes through all the elements in the array elements
     for element in "${elements[@]}"; do
          # Calls the function func_to_apply on the current element and saves the result in the array return_result

          # The outside ("$ ...") is used to capture the result of ($func_to_apply "$element")
          return_result+=("$($func_to_apply "$element")")
     done

     # returns the array with the transformed elements, seperated by spaces
     echo "${return_result[@]}"
}

# This cleans one service
clean_one_service() {
     local service=$1
     echo "${service//[\[\],]/}"
}

# Uses the map function and the clean_one_service function to clean all services
clean_all_services() {
     local services=("$@")
     map clean_one_service "${services[@]}"
}