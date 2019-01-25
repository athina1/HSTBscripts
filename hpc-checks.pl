#/bin/perl/

use strict;

my $i;
for ($i=1; $i<=1; $i++) {

my $file = $i;
my $id = "ac2";
my $faillog;

if (-e "$file$id.em3.gro") {
  #editconf -> define box size and place molecule in the centre of the box
  `editconf -f "$file""$id".em3.gro -o "$file""$id".box.gro -c -d 1.0 -bt cubic -box 10`;
}
   else {
    open $faillog, '>>', "error.$file$id.log";
    printf $faillog ("%-50s%5s","WARNING file $file$id.em3.gro missing","- step: editconf");
    printf $faillog "\n";
    close $faillog;
   }

 if (-e "$file$id.box.gro") {
  #genbox -> solvate
  #first use genbox to find out how many SOL molecules are added
  `genbox -cp "$file""$id".box.gro -cs tip4p.gro -p topol.top -o "$file""$id".sol.gro`;
  #for p5-19-18-17 -> 32961 added - 25 = 32936

  #subtract 25 molecules, getting x number of SOL molecules
  #use maxsol flag to add exactly x number of SOL molecules
 `genbox -cp "$file""$id".box.gro -cs tip4p.gro -maxsol 32933 -p topol.top -o "$file""$id".sol.gro`;
}
   else {
    open $faillog, '>>', "error.ac2.log";
    printf $faillog ("%-50s%10s", "WARNING file $file$id.box.gro missing","- step: genbox");
    printf $faillog "\n";
    close $faillog;
   }

 if ((-e "$file$id.sol.gro") and (-e "em_sol.mdp")) {
  #grompp -> generate run input file for the EM solvent run
 `grompp -f em_sol.mdp -c "$file""$id".sol.gro -p topol.top -o "$file""$id".em_sol.tpr`;
 }
   else {
    open $faillog, '>>', "error.$file$id.log";
    printf $faillog ("%-50s%10s","WARNING file $file$id.sol.gro or em_sol.mdp missing","- step: grompp for em_sol.tpr");
    printf $faillog "\n";
    close $faillog;
   }
 
 if (-e "$file$id.em_sol.tpr") {
  #mdrun -> begin the EM solvent run using the created tpr file
 `mdrun $nt -v -deffnm "$file""$id".em_sol`;
 }
  else {
    open $faillog, '>>', "error.$file$id.log";
    printf $faillog ("%-50s%10s","WARNING file $file$id.em_sol.tpr missing","- step: mdrun for em sol");
    printf $faillog "\n";
    close $faillog;
   }
   
 if ((-e "$file$id.em_sol.gro") and (-e "NVT.mdp")) {
  #grompp -> generate run input file for the NVT run
 `grompp -f NVT.mdp -c "$file""$id".em_sol.gro -p topol.top -o "$file""$id".nvt.tpr`;
  }
   else {
    open $faillog, '>>', "error.$file$id.log";
    printf $faillog ("%-50s%10s","WARNING file $file$id.em_sol.gro or NVT.mdp missing","- step: grompp for nvt.tpr");
    printf $faillog "\n";
    close $faillog;
   }

 if (-e "$file$id.nvt.tpr") {
 #mdrun -> begin the NVT run using the created tpr file
 `mdrun $nt -v -deffnm "$file""$id".nvt`;
 }
   else {
    open $faillog, '>>', "error.$file$id.log";
    printf $faillog ("%-50s%10s","WARNING file $file$id.nvt.tpr missing","- step: mdrun for nvt");
    printf $faillog "\n";
    close $faillog;
   }

 if ((-e "$file$id.nvt.gro") and (-e "NPT.mdp")) {
  #grompp -> generate run input file for the NPT run
 `grompp -maxwarn 1 -f NPT.mdp -c "$file""$id".nvt.gro -p topol.top -o "$file""$id".npt.tpr`;
 }
   else {
    open $faillog, '>>', "error.$file$id.log";
    printf $faillog ("%-50s%10s","WARNING file $file$id.nvt.gro or NPT.mdp missing","- step: grompp for npt.tpr");
    printf $faillog "\n";
    close $faillog;
   }
 
 if (-e "$file$id.npt.tpr") {
#  mdrun -> begin the NPT run using the created tpr file
 `mdrun -deffnm "$file""$id".npt`;
 }
   else {
    open $faillog, '>>', "error.$file$id.log";
    printf $faillog ("%-50s%10s","WARNING file $file$id.npt.tpr missing","- step: mdrun for npt");
    printf $faillog "\n";
    close $faillog;
   }


 #Using awk command to import energy values from npt log file and store them in txt file
 if (-e "$file$id.npt.log") {
 `awk '/Kinetic En./ { getline; print \$0 }' $file$id.npt.log | head -n -1 | tail -n -26 > $file$id.nptdata.txt`;
 }
   else {
    open $faillog, '>>', "error.$file$id.log";
    printf $faillog ("%-50s%10s","WARNING file $file$id.npt.log missing","- step: awk command to get energies from npt log file");
    printf $faillog "\n";
    close $faillog;
   } 

 #Ignore 1st (kinetic energy) and 4th (pressure) column 
 #Check if STDEV values exceed our thresholds (0,5% for total energy and 1 degree for temperature)
my $stddevtemp = `awk -f temp-dev.awk $file$id.nptdata.txt`;
my $stddevenergy = `awk -f tot-dev.awk $file$id.nptdata.txt`;
my $absenergy = abs($stddevenergy);

print $stddevtemp;
print $stddevenergy;
print abs($stddevenergy);
print "\n";


if (($absenergy < 0.5) and ($stddevtemp < 1)) {   # "and" or "or" here?
 print "more equilibration is needed \n";
   
   if (-e "$file$id.npt.gro") {
   print "doing more eq, then preparing the input file for the production run \n"; 

   #grompp -> generate run input file for additional npt equilibration run
   `$grompp -maxwarn 1 -f NPTxxx.mdp -c "$file""$id".npt.gro -p topol.top -o "$file""$id".nptxxx.tpr`;

   #mdrun -> begin the extra NPT run using the tpr file created above
   `$taskset $mdrun $nt -v -deffnm "$file""$id".nptxxx`;

   #then we need more grompp to generate the tpr file for the production run
   #grompp -> generate tpr file for production run, using as inputs the files from the additional npt run above
   `$grompp -maxwarn 1 -f MDsol.mdp -c "$file""$id".nptxxxx.gro -p topol.top -o "$file""$id".mdsol.tpr`;
   }  

     else {
     open $faillog, '>>', "error.$file$id.log";
     printf $faillog ("%-50s%10s","WARNING file $file$id.npt.gro missing","- step: grompp for additional npt.tpr");
     printf $faillog "\n";
     close $faillog;
     } 
 }
    else {
    print "we have equilibrated enough - proceeding directly to production run \n";
    #proceed to production run with the initial npt.gro created
    #grompp -> generate run input file for production run
    `$grompp -maxwarn 1 -f MDsol.mdp -c "$file""$id".npt.gro -p topol.top -o "$file""$id".mdsol.tpr`;
    }    


} #big "for" loop in the beginning
