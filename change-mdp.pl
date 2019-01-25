#!/usr/bin/perl/

use strict;
use warnings;

my $i; ### ATi - molecule
my $k; ### Fk - frame
my $t; ### Temperature subdirectory
my $path; ### path
my $input = "MDsolT300.mdp";

my $id = "AT";

for ($i=1; $i<=2; $i++) {
my $j = sprintf ("%04d", $i);
  for ($t=300; $t<=325; $t += 25) {
    for ($k=1; $k<=2; $k++) {
    my $l = sprintf ("%05d", $k);
    $path = "/home/wcg/RESULTS/$id$j/T$t/F${l}";

    open (IN, "<", "/home/wcg/RESULTS/$id$j/$input") or die print "can't open IN file $! \n";
    my @lines = <IN>;
    close (IN);

    open (OUT, ">>$path\/temp") or die print "can't open OUT file $! \n";

    foreach (@lines) {
 
    chomp $_;
      if ($_=~/^title/) {
      print OUT "title                    = $id$i in water\n";
      }
      elsif ($_=~/^nsteps/) {
      print OUT "nsteps                   = 100000  ;100ps run\n";
      }
      elsif ($_=~/^xtc_grps/) {
      print OUT "xtc_grps                 = $id$i\n";
      }
      elsif ($_=~/^energygrps/) {
      print OUT "energygrps               = $id$i   SOL\n";
      }
      elsif ($_=~/^tc_grps/) {
      print OUT "tc_grps                  = $id$i   SOL\n";
      }
      elsif ($_=~/^ref_t/) {
      print OUT "ref_t                    = $t    $t\n";
      }
      else {
      print OUT "$_\n";
      }
    } #foreach lines end

    close (OUT);
    `mv $path\/temp $path\/MDsolT${t}.mdp`;

   } ## for t end
 } ## for k end
} ## for i end
