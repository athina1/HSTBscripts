#!/usr/bin/perl

use warnings;
use strict;

my $id = "ac";
my $ID = "AC";
my $g_angle = "/usr/local/gromacs/bin/g_angle";
my $i;
my $k;
my $userathost = "athina\@pezxeonws.nottingham.ac.uk:";
my $input;
my $output;

#disable Gromacs backups because otherwise it fails after writing 99x copies
  if(!defined $ENV{GMX_MAXBACKUP}) {
    $ENV{GMX_MAXBACKUP}=-1
  }

for ($i=2; $i<=2; $i++) {
  my $j = sprintf ("%05d", $i);
    for ($k=15; $k<=15; $k++) {
      my $l = sprintf ("%04d", $k);
      my $path = "/Users/athina/check-ma/$ID${l}/F${j}";
      my $dashFolder = "/media/data/athina/dash-test/$ID${l}"; 

`$g_angle -f $path\/${i}${id}${k}.mdsol.centered.xtc -n /Users/athina/check-ma/$ID${l}/F00001/dihedrals-1${id}${k}.ndx -type dihedral -all -ov $path\/gangle-dihedrals-${i}${id}${k}.xvg -od $path\/out.xvg`;

open $input, '<', '/Users/athina/check-ma/$ID${l}/F${j}\/gangle-dihedrals-${i}${id}${k}.xvg' or die $!;
open $output, '>', '/Users/athina/check-ma/$ID${l}/F${j}\/in-dihedrals-${i}${id}${k}.txt' or die $!;

while (my $line = <$input>) {

  chomp $line;            # remove end-of-line character
  $line =~ s/^\s+//;       # strip leading whitespace
  next unless $line;      # skip blank lines
  
  # skip first 12 lines 
  next unless $. > 12;     # $. contains current line number
  
  my @columns = split(/\s+/, $line);    # split columns on whitespace
  
  my $col1 = shift @columns;  # column 1 (throw away)
  my $col2 = shift @columns;  # column 2 (throw away)
  
  my $col3 = shift @columns;  # column 3 (special - keep this one) 
  my $result = sprintf("%8.3f", $col3); # special format for col 3

  # loop over remaining columns, appending to result string
  for my $c (@columns) {
    my $data = sprintf("%9.3f", $c);
    $result .= " $data";                
  }  

  print $output "$result\n";                    
}

 `scp $path\/gangle-dihedrals-${i}${id}${k}.xvg ${userathost}$dashFolder`;
       
    } ### for k loop
} ### for i loop

