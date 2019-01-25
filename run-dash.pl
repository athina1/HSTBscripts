#!/usr/bin/perl

use warnings;
use strict;

my $id = "kc";
my $ID = "KC";
my $T = "85";
my $N = "100001";
my $i;
my $k;
my $bout;

for ($i=1; $i<=1; $i++) {
my $j = sprintf ("%05d", $i);
  
  for ($k=12; $k<=12; $k++) {
  my $l = sprintf ("%04d", $k);
  my $path = "/media/data/athina/dash-test/$ID${l}";
 
    for ($bout=2600; $bout<=2600; $bout += 100) {
    
    `dash -N $N -T $T -l $bout -R -H < in-dihedrals-${i}${id}${k}.txt  > ${i}${id}${k}-dash-out-b${bout}.txt`;

    }
  } ### for k loop
} ### for i loop


