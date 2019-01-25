BEGIN{
# in this section we set up some variables before awk 
# starts going throught he file line by line

#sum_kin = 0
sum_tot = 0
#sum_temp = 0
#sum_press =0
i = 0
}
{
# awk goes through the file line by line here

# sum up the values in each column 
#sum_kin+=$1
sum_tot+=$2
#sum_temp+=$3
#sum_press+=$4
#print sum_tot

# store each number in an array
tot[i] = $2

# keep track of the numnber of rows
i+=1
}
END{
# awk has finished going through the file. Now  we need to do our calculations
#print sum_kin/i
#print sum_tot/i
#print sum_temp/i
#print sum_press/i

# calculate average kinetic eneergy
ave_tot = sum_tot/i

# calculate standard deviation for the final 26 out of 51 data points
for(j=0; j<i; j++)

{
stddev += (tot[j]-ave_tot)*(tot[j]-ave_tot) 
}
stddev = sqrt(stddev/i)
#print stddev
#print ave_tot

stddev /= ave_tot
stddev *= 100.0 

# print standard deviation
print stddev
}
