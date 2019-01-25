BEGIN{
# in this section we set up some variables before awk 
# starts going through the file line by line
sum_kin = 0
sum_tot = 0
sum_temp = 0
sum_press = 0
i = 0
}
{
# in these brackets awk looks at each line one by one
# add up all the numbers in the 4 columns
sum_kin+=$1
sum_tot+=$2
sum_temp+=$3
sum_press+=$4

# add up number of rows
i+=1
}
END{
# calculate average values
ave_kin = sum_kin/i
ave_tot = sum_tot/i
ave_temp = sum_temp/i
ave_press = sum_press/i

# print average values
print ave_kin/i
print ave_tot/i
print ave_temp/i
print ave_press/i
}
