#!/usr/bin/perl

use strict;
use warnings;

my $state;
my $frames;
my $i;

my $dashfile = "bout1150"; #dash output used here as input file
my $dashtrjin = "seed-dashs-transitions-bout1150.txt"; #script output

open FILE, '>'.$dashtrjin;
open (INFILE, "<$dashfile") or die print "can't open states file $dashfile\n";

print FILE "# dashstate per frame on column\n";

my $dashstates = 0;
my $dashtrj = 0;

while (<INFILE>) {
  chomp $_;
  if (/<DashStateTrajectory>/) {
    $dashtrj = 1;
  }
  if (/\/<DashStateTrajectory>/) {
    $dashtrj = 0;
  }
  if ($dashtrj eq 1 && /^\d/) {
    #print "$_\n";
    $state = 0;
    $frames=0; 
    ($state, $frames) = split (/\s+/);  
    for ($i=1; $i<=$frames; $i++) {
      print FILE "$state\n";
    }
  }
}
close(INFILE);
close(FILE);

