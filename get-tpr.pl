#!/usr/bin/perl/

use strict;
use warnings;

### RUN ON THE WCG SERVER.
### Gets mdsol tpr files created in the path molec/T/F and renames them to WCG convention.

##############
my $id = "kt";
my $ID = "KT";
my $i;
my $t;
my $k;
##############

my $bigfile; #write tpr filenames

#disable backups otherwise gromacs fails after creating 99x copies
  if(!defined $ENV{GMX_MAXBACKUP}) {
      $ENV{GMX_MAXBACKUP}=-1
  }        

my $grompp = "/home/SOFT/mygromacs/local_4.6.7/bin/grompp";

for ($i=6; $i<=6; $i++) {
  my $j = sprintf ("%04d", $i);
  for ($t=400; $t<=400; $t += 25) {
    for ($k=1; $k<=100; $k++) {
      my $l = sprintf ("%05d", $k);
      my $path = "/home/wcg/RESULTS/$ID${j}/T${t}/F${l}";
      my $nptgro = "/home/wcg/RESULTS/$ID${j}";
      
     `$grompp -f $path\/MDsolT${t}.mdp -c $nptgro\/${k}$id${i}.npt.gro -p $path\/topol.top -o $path\/$ID${j}_T${t}_F${l}_S00001.tpr`;

        my $checktpr;
        my $failedtpr;

        if (-s "$path\/$ID${j}_T${t}_F${l}_S00001.tpr") {
        open $checktpr, '>>', "/home/wcg/scripts/KT_new.txt";
        print $checktpr "$ID${j}_T${t}_F${l}_S00001.tpr \n";
        close $checktpr;
        }

        else {
        open $failedtpr, '>>', "/home/wcg/scripts/KT_failed.txt";
        print $failedtpr "$ID${j}_T${t}_F${l}_S00001.tpr missing \n";
        close $failedtpr;
        print "$ID${j}_T${t}_F${l}_S00001.tpr failed \n";
        } 
     
    } ### for k loop
  } ### for t loop
      # `rm /home/wcg/RESULTS/$ID${j}\/*npt.gro`;
} ### for i loop



