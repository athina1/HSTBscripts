#/bin/perl/

use strict;
use Math::Trig;

my $rad2deg = 57.296;

my @files;
@files = `ls *mol2`;

my $filenr = 0;

foreach (@files) {
 
  chomp;
  my $file = $_;
  $_= $file;
  s/\.mol2$// or die print "only .mol2 files as structure input allowed\n";
  my $filename = $_;
  my $g09inp = "$filename.g09inp";
 
#  print "opening file $file\n";

  my @file = ();
  push (@file, $file);

  #filehandling
  my $secMolec = 0;
  my $secAtoms = 0;
  my $secBonds = 0;

  my $molname;
  my $atomcount;
  my $bondcount;

  $filenr += 1;

  open MOL2, $file or die "Cannot open $file for read :$!";

  while (<MOL2>) 
  {
    chomp $_;
    push (@file, $_);
    #print "Line $. is : $_\n";
    if ($_=~/<TRIPOS>MOLECULE/) 
    {
      #print "found pattern in line $.\n";
      $secMolec = $.;
    }
    if ($_=~/\@<TRIPOS>ATOM/)
    {
      #print "found pattern in line $.\n";
      $secAtoms = $.;
    }

    if ($_=~/\@<TRIPOS>BOND/)
    {
      #print "found pattern in line $.\n";
      $secBonds = $.;
    }
  }
  close (MOL2);

  chomp @file[$secMolec+1];
  $molname = @file[$secMolec+1];

  $_ = @file[$secMolec+2];
  chomp $_;
  s/^\s+//;
  s/\s+/ /;
  ($atomcount, $bondcount) = split(/\s+/);

  my (@element, @atom, @x, @y, @z, @atomtypes, @charge, @groups);
  my $groupcount = 0;
  $element[0]=$atomcount;
  $atom[0]=$atomcount;
  $x[0]=$atomcount;
  $y[0]=$atomcount;
  $z[0]=$atomcount;
  $atomtypes[0]=$atomcount;
  $charge[0]=$atomcount;

  my $i;
  for ($i=1; $i<=$atomcount; $i++) {
    $_ = @file[$secAtoms+$i];
    chomp $_;
    s/^\s+//;
    s/\s+/ /;
    my ($atnr, $atom, $x, $y, $z);  
    ($atnr, $atom, $x, $y, $z) = split(/\s+/);
    push (@atom, $atom);
    if ($atom =~ /^[a-zA-Z]+/) {
    $atom =~ /(^[a-zA-Z])+/;
      push (@element, $1);
    }
    else {
      print "could not assign element to atomtype\n";
      exit;
    }
    push (@x, $x);  
    push (@y, $y);
    push (@z, $z); 
  }
  # now looking up bonds
  # creating array (nr bonds,atom1,2,3,4)*$atomcount
  my @bonds ;
  my ($a,$b);
  for ($a=0; $a<=$atomcount; $a++) {
    for ($b=0; $b<=4; $b++) {
      $bonds[$a][$b] = 0;
    };
  };
  my $a;
  for ($a=1; $a<=$bondcount; $a++) {
    my ($bondnr, $atom1, $atom2);
    $_ = @file[$secBonds+$a];
    chomp $_;
    s/^\s+//;
    s/\s+/ /;
   ($bondnr, $atom1, $atom2) = split(/\s+/);
    # index 1 bound to 2
    $bonds[$atom1][0] = $bonds[$atom1][0] + 1 ;
    $bonds[$atom1][$bonds[$atom1][0]] = $atom2;
    # and 2 bound to one
    $bonds[$atom2][0] = $bonds[$atom2][0] + 1 ;
    $bonds[$atom2][$bonds[$atom2][0]] = $atom1;
  }
  # test for atom 5
  #print "$bonds[5][0]\n";
  #print "$bonds[5][1], $element[$bonds[5][1]]\n";
  #print "$bonds[5][2], $element[$bonds[5][2]]\n";
  #print "$bonds[5][3], $element[$bonds[5][3]]\n";
  #print "$bonds[5][4], $element[$bonds[5][4]]\n";

#  open G09, ">$g09inp";
  # print gaussian header
#  print G09 "\%chk=$g09inp.chk\n";
#  print G09 "\%nproc=4\n";
#  print G09 "%mem=200MW\n";
#  print G09 "\#P AM1 Opt \n";
#  print G09 "\n";
#  print G09 "$filename AM1 Opt\n";
#  print G09 "\n";
#  print G09 "0,1\n";
#  my $j;
#  for ($j=1; $j<=$atomcount; $j++) { 
#    printf G09 ("%-4s%10.4f%12.4f%12.4f",@element[$j],@x[$j],@y[$j],@z[$j]);
#    printf G09 "\n";
#  }
#  print G09 "\n";
#  print G09 "\n";
#  close (G09);

  #print "running gaussian on $file  \n...\n";
  #`g09 <$g09inp >$filename.gout`;
  #print "g09 run completed\n";

  # for topology:
  # first find atomtypes:
  # start with oxygens, loop through file
  my $n;
  for ($n=1; $n<=$atomcount; $n++) {
    if ($element[$n] =~/^O$/) {
      if ($bonds[$n][0] == 1) {   #  C=O atomtype but which
      # how many carbons bound to C of number: $bonds[$n][1]
        my $Ccount = 0;
        my $m = 0;
        for ($m=1; $m<=3; $m++) { #check the neighbour's connected atoms m
          if ($element[$bonds[$bonds[$n][1]][$m]] =~ /^C$/) {
            $Ccount++;
          }
        }
        print "ccount is $Ccount\n";
        if ($Ccount == 1) {
          print "$element[$n] is C=O in COOH (or aldehyde)\n";
          $atomtypes[$n] = 269;
          $charge[$n] = -0.44;
        }
        elsif ($Ccount == 2) {
          print "$element[$n] is pure C=O \n";
          $atomtypes[$n] = 281;
          $charge[$n] = -0.47;
        }
        else {
          print "can't assign atom type for atom $n $element[$n]. Exit\n";
          exit;
        }
      }
      elsif ($bonds[$n][0] == 2) {  # OH, COOH or ether O
        if ($element[$bonds[$n][1]] =~ /^C$/ && $element[$bonds[$n][2]] =~ /^C$/ ) { #ether O 
           print "$element[$n] is ether\n";
           $atomtypes[$n] = 180;
           $charge[$n] = -0.4;
        }
        elsif ($element[$bonds[$n][1]] =~ /^C$/ && $element[$bonds[$n][2]] =~ /^H$/ ) { # OH 
           print "$element[$n] is OH\n";
           # discriminate between COOH C3-OH
           print "number of neighbours of C $bonds[$n][1] conected to O: \n";           
           print "$bonds[$bonds[$n][1]][0]\n";
           if ($bonds[$bonds[$n][1]][0] == 3) { 
             print "$element[$n] is COOH hydroxyl\n";
             $atomtypes[$n] = 268;
             $charge[$n] = -0.53;
           }
           elsif ($bonds[$bonds[$n][1]][0] == 4) {
             print "$element[$n] is aliphatic hydroxyl\n";
             $atomtypes[$n] = 154;
             $charge[$n] = -0.683;
           }
        }
        elsif ($element[$bonds[$n][1]] =~ /^H$/ && $element[$bonds[$n][2]] =~ /^C$/ ) { # OH 
           print "$element[$n] is OH\n";
           # discriminate between COOH C3-OH
           print "number of neighbours of C $bonds[$n][1] conected to O: \n";
           print "$bonds[$bonds[$n][1]][0]\n";
           if ($bonds[$bonds[$n][1]][0] == 3) {
             print "$element[$n] is COOH hydroxyl\n";
             $atomtypes[$n] = 268;
             $charge[$n] = -0.53;
           }
           elsif ($bonds[$bonds[$n][1]][0] == 4) {
             print "$element[$n] is aliphatic hydroxyl\n";
             $atomtypes[$n] = 154;
             $charge[$n] = -0.683;
           }
           else {
             print "can't assign atom type for atom $n $element[$n]. Exit\n";
             exit;
           }
        }
        elsif ($element[$bonds[$n][1]] =~ /^H$/ && $element[$bonds[$n][2]] =~ /^C$/ ) { # OH 
           print "$element[$n] is OH\n";
           # discriminate between COOH C3-OH
           print "number of neighbours of C $bonds[$n][2] conected to O: \n";
           print "$bonds[$bonds[$n][2]][0]\n";
           if ($bonds[$bonds[$n][2]][0] == 3) {
             print "$element[$n] is COOH hydroxyl\n";
             $atomtypes[$n] = 268;
             $charge[$n] = -0.53;
           }
           elsif ($bonds[$bonds[$n][2]][0] == 4) {
             print "$element[$n] is aliphatic hydroxyl\n";
             $atomtypes[$n] = 154;
             $charge[$n] = -0.683;
           }
           else {
             print "can't assign atom type for atom $n $element[$n]. Exit\n";
             exit;
           }
        }
        else {
          print "can't assign atom type for atom $n $element[$n]. Exit\n";
          exit;
        }
      }
      else {
        print "can't assign atom type for atom $n $element[$n]. Exit\n";
        exit;   
      }
    } # if element=O close
  } # loop through $elements
  # loop through elements again
  my $n;
  for ($n=1; $n<=$atomcount; $n++) {
    if ($element[$n] =~/^H$/) {
      if ($bonds[$n][0] != 1) {
        print "Hydrogen with too many bonded atoms element[$n]. Exit\n";
        exit;
      }
      # what is the neighbouring atom?
      if ($element[$bonds[$n][1]] =~ /^O$/) {
        # check connected O type
        if ($atomtypes[$bonds[$n][1]] == 154) {
          print "$element[$n] mono-alcohol\n";
          $atomtypes[$n] = 155;
          $charge[$n] = 0.418;
        }
        elsif ($atomtypes[$bonds[$n][1]] == 268) {
          print "$element[$n] HO in COOH\n";
          $atomtypes[$n] = 270;
          $charge[$n] = 0.45;
        }
        else {
        print "can't assign hydroxy atom type for atom $n $element[$n].Exit.\n"; 
        exit;
        }
      }     
      elsif ($element[$bonds[$n][1]] =~ /^C$/) {
        print "$element[$n] connected to C\n";
        # check if connected C bears any oxygens
        my $conectC = $bonds[$n][1]; # index of conected C
        my $m=0;
        my $checkether = 0;
        for ($m=1; $m<=$bonds[$conectC][0]; $m++) {
          if ($element[$bonds[$conectC][$m]] =~ /^O$/) {
            if ($atomtypes[$bonds[$conectC][$m]] == 180) {
              $checkether = 1;
            }
          }
        }
        if ($checkether == 1) {
          print "is H alpha to ether\n";
          $atomtypes[$n] = 185;
          $charge[$n] = 0.03;
        }
        elsif ($checkether == 0) {
          print "is H aliphatic\n";
          $atomtypes[$n] = 140;
          $charge[$n] = 0.06;
        }
      }
      else {
        print "can't assign atom type for atom $n $element[$n]\n"; 
        print "$element[$n] connected to $element[$bonds[$n][1]] not implemented yet. Exit\n";
        exit;
      }     
    } # if element=H close
  } # loop through $elements
  # loop through elements again
  # counter for chargegroups
  my $cg = -1;
  my $n;
  for ($n=1; $n<=$atomcount; $n++) {
    if ($element[$n] =~/^C$/) {
      print "$element[$n]\n";
      # how many neighbours?
      if ($bonds[$n][0] == 3) {   
        my $m=0;
        my $Ocount = 0;
        # how many O neighbours?
        for ($m=1; $m<=3; $m++) {
          if ($element[$bonds[$n][$m]] =~ /^O$/) {
            $Ocount++;
          }
        }
        if ($Ocount == 1) {
          print "is keto C\n";
          $atomtypes[$n] = 280;
          $charge[$n] = 0.47;
          # assign charge group
          $cg++;
          $groups[$cg][0] = 2;                         # nr of atoms in charge group
          $groups[$cg][1] = $n;                        # the carbon
          for ($m=1; $m<=3; $m++) {
            if ($element[$bonds[$n][$m]] =~ /^O$/) {
              $groups[$cg][2] = $bonds[$n][$m];        # the oxygen
            }
          }
          print "charge group: $groups[$cg][1] $groups[$cg][2]\n";
        }
        elsif ($Ocount == 2) {
          print "is carcoxylic C\n";
          $atomtypes[$n] = 267;
          $charge[$n] = 0.52;
          # assign charge group
          $cg++;
          $groups[$cg][0] = 4;                         # nr of atoms in charge group
          $groups[$cg][1] = $n;                        # the carbon
          my $m =0;
          for ($m=1; $m<=3; $m++) {
            if ($element[$bonds[$n][$m]] =~ /^O$/) {
              if ($atomtypes[$bonds[$n][$m]] == 269) {
                $groups[$cg][2] = $bonds[$n][$m];        # 1st oxygen 
              }
              if ($atomtypes[$bonds[$n][$m]] == 268) {
                my $OHO = $bonds[$n][$m];
                $groups[$cg][3] = $OHO;                # OH oxygen 
                my $mm =0;
                for ($mm=1; $mm<=2; $mm++) {
                  if ($element[$bonds[$OHO][$mm]] =~ /^H$/) {
                    $groups[$cg][4] = $bonds[$OHO][$mm];  # HO hydrogen
                  }
                }
              }
            }
          }
        print "charge group: $groups[$cg][1] $groups[$cg][2] $groups[$cg][3] $groups[$cg][4] \n";
        }
        else {
          print "can't assign atom type for atom $n $element[$n].Exit.\n";
          exit;
        }  
      }
      elsif ($bonds[$n][0] == 4) {
        my $m=0;
        my @Ocount = 0;
        # how many O neighbours?
        for ($m=1; $m<=4; $m++) {
          if ($element[$bonds[$n][$m]] =~ /^O$/) {
            $Ocount[0] = $Ocount[0] + 1;           # number of oxygens
            $Ocount[$Ocount[0]] = $bonds[$n][$m];  # atom ID of oxygen found
          }
        }
        if ($Ocount[0] == 1) {
          # print "It is either an ether C or an alcohol C\n";
       #  print "Found stomtype $atomtypes[$Ocount[1]]\n"; 
          if ($atomtypes[$Ocount[1]] == 154) {
             print "Found alcoholic C \n";
             $atomtypes[$n] = 158;
             $charge[$n] = 0.205;
             # assign charge group
             $cg++;
             $groups[$cg][0] = 4;                         # nr of atoms in charge group
             $groups[$cg][1] = $n;                        # the carbon
             my $mn = 0 ;
             for ($mn=1; $mn<=4; $mn++) {
               if ($element[$bonds[$n][$mn]] =~ /^H$/) {
                 $groups[$cg][2] = $bonds[$n][$mn];       # CH hydrogen
               }
             }             
             $groups[$cg][3] = $Ocount[1];                # the OH oxygen
             my $mm = 0 ;
             for ($mm=1; $mm<=2; $mm++) {
               if ($element[$bonds[$Ocount[1]][$mm]] =~ /^H$/) {
                 $groups[$cg][4] = $bonds[$Ocount[1]][$mm];  # HO hydrogen
               }
             }
             print "charge group: $groups[$cg][1] $groups[$cg][2]  $groups[$cg][3] $groups[$cg][4] \n";
          }
            elsif ($atomtypes[$Ocount[1]] == 180) {
           #  print "Found etheric C \n";
              my @Hcount = 0;
              # how many H neighbours?
              for ($m=1; $m<=4; $m++) {
                if ($element[$bonds[$n][$m]] =~ /^H$/) {
                  $Hcount[0] = $Hcount[0] + 1;           # number of hydrogens
                  $Hcount[$Hcount[0]] = $bonds[$n][$m];  # atom ID of hydrogen found
                }
              }
              if ($Hcount[0] == 1) {
                print "Found C in CHOR \n";
                $atomtypes[$n] = 183;
                $charge[$n] = 0.17;
                # assign charge group metoxy ether
                $cg++;
                $groups[$cg][0] = 7;                         # nr of atoms in charge group
                $groups[$cg][1] = $n;                        # the CHO carbon
                $groups[$cg][2] = $Hcount[1];                # ether CHO hydrogen
                $groups[$cg][3] = $Ocount[1];                # ether O
                my $mx = 0;
                for ($mx=1; $mx<=2; $mx++) {
                  if ($element[$bonds[$Ocount[1]][$mx]] =~ /^C$/ && $atomtypes[$bonds[$Ocount[1]][$mx]] != 183 ) {
                    my $C2 = $bonds[$Ocount[1]][$mx];
                    $groups[$cg][4] = $C2;                   # CH3OR carbon
                    my $my = 0 ;
                    my $count3 = 4;
                    for ($my=1; $my<=4; $my++) {
                      if ($element[$bonds[$C2][$my]] =~ /^H$/) {
                        $count3++;
                        $groups[$cg][$count3] = $bonds[$C2][$my];       # CH3OR hydrogen
                      }
                    }
                  }
                }
                print "charge group: $groups[$cg][1] $groups[$cg][2]  $groups[$cg][3] $groups[$cg][4] $groups[$cg][5] $groups[$cg][6] $groups[$cg][7]\n";
 
              }
              if ($Hcount[0] == 3) {
                 print "Found C in CH3-OR \n";
                 $atomtypes[$n] = 181;
                 $charge[$n] = 0.11;
              }
            }       
        } 
       elsif ($Ocount[0] == 0) {
          # either alkane or cyclopropane C         
          my @Hcount = 0; # how many H neighbours?
         for ($m=1; $m<=4; $m++) {
           if ($element[$bonds[$n][$m]] =~ /^H$/) {
           $Hcount[0] = $Hcount[0] + 1;           # number of hydrogens
           $Hcount[$Hcount[0]] = $bonds[$n][$m];  # atom ID of hydrogen found
           }
         }
           if ($Hcount[0] == 3) {
             print "Found C in CH3 \n";
             $atomtypes[$n] = 135;
             $charge[$n] = -0.18;
             # assign charge group for aliphatic CH3
             $cg++;
             $groups[$cg][0] = 4;                         # nr of atoms in charge group
             $groups[$cg][1] = $n;                        # the CH3 carbon
             $groups[$cg][2] = $Hcount[1];                # CH3 hydrogen
             $groups[$cg][3] = $Hcount[2];                # CH3 hydrogen
             $groups[$cg][4] = $Hcount[3] ;               # CH3 hydrogen
             print "charge group: $groups[$cg][1] $groups[$cg][2]  $groups[$cg][3] $groups[$cg][4] \n";
           }
           if ($Hcount[0] == 2) {
             # print "Found CH2 in cyclopropane or regular alkane \n";
             # we have to calculate the CCC angle
             # get coordinates of carbons
             my @Cx = ();
             my @Cy = ();
             my @Cz = ();
             # first the central atom
             print "$n $x[$n]\n";
             push (@Cx, $x[$n]);
             push (@Cy, $y[$n]);
             push (@Cz, $z[$n]);
             # now the conecting Carbons
             for ($m=1; $m<=4; $m++) {
               if ($element[$bonds[$n][$m]] =~ /^C$/) {
                 #print "$bonds[$n][$m] $x[$bonds[$n][$m]] is a conected Carbon\n";
                 push (@Cx, $x[$bonds[$n][$m]]);
                 push (@Cy, $y[$bonds[$n][$m]]);
                 push (@Cz, $z[$bonds[$n][$m]]);
               }
             }
             # now calculate the angle
             # vectors @Avec = (length,x,y,z), a = C0->C1, b = C0->C2
             my @Avec = ();
             my @Bvec = ();
             my $cosalpha = 0;
             # 
             $Avec[1] = $Cx[1] - $Cx[0];
             $Avec[2] = $Cy[1] - $Cy[0];
             $Avec[3] = $Cz[1] - $Cz[0];
             $Bvec[1] = $Cx[2] - $Cx[0];
             $Bvec[2] = $Cy[2] - $Cy[0];
             $Bvec[3] = $Cz[2] - $Cz[0];
             $Avec[0] = sqrt ($Avec[1] * $Avec[1] + $Avec[2] * $Avec[2] + $Avec[3] * $Avec[3]);
             $Bvec[0] = sqrt ($Bvec[1] * $Bvec[1] + $Bvec[2] * $Bvec[2] + $Bvec[3] * $Bvec[3]);
             #
             $cosalpha = $Avec[1] * $Bvec[1] + $Avec[2] * $Bvec[2] + $Avec[3] * $Bvec[3];
             $cosalpha = $cosalpha / ($Avec[0] * $Bvec[0]);
             $cosalpha = acos($cosalpha) * $rad2deg;
             #print "alength $Avec[0] and Blength $Bvec[0] angle is $cosalpha\n";
             # now assign atomtypes
             if ($cosalpha < 70) { 
               print "CH2 cyclopropane carbon\n"; 
               $atomtypes[$n] = 711;
               $charge[$n] = -0.12;
               # assign charge group for cyclopropane CH2
               $cg++;
               $groups[$cg][0] = 3;                         # nr of atoms in charge group
               $groups[$cg][1] = $n;                        # the CH2 carbon of the cyclopropane
               $groups[$cg][2] = $Hcount[1];                # CH2 hydrogen
               $groups[$cg][3] = $Hcount[2];                # CH2 hydrogen
               print "charge group: $groups[$cg][1] $groups[$cg][2]  $groups[$cg][3]\n";
             }
             else {
               print "aliphatic CH2\n";
               $atomtypes[$n] = 136;
               $charge[$n] = -0.12;
               # assign charge group for aliphatic CH2
               $cg++;
               $groups[$cg][0] = 3;                         # nr of atoms in charge group
               $groups[$cg][1] = $n;                        # the aliphatic CH2 carbon
               $groups[$cg][2] = $Hcount[1];                # CH2 hydrogen
               $groups[$cg][3] = $Hcount[2];                # CH2 hydrogen
               print "charge group: $groups[$cg][1] $groups[$cg][2]  $groups[$cg][3]\n";
             }
           }
           if ($Hcount[0] == 1) {
             print "Found CH in cyclopropane or regular alkane \n";
             # we have to calculate the CCC angle
             # get coordinates of carbons
             my @Cx = ();
             my @Cy = ();
             my @Cz = ();
             # first the central atom
             print "$n $x[$n]\n";
             push (@Cx, $x[$n]);
             push (@Cy, $y[$n]);
             push (@Cz, $z[$n]);
             # now the conecting Carbons
             for ($i=1; $i<=4; $i++) {
               if ($element[$bonds[$n][$i]] =~ /^C$/) {
                 #print "$bonds[$n][$i] $x[$bonds[$n][$i]] is a conected Carbon\n";
                 push (@Cx, $x[$bonds[$n][$i]]);
                 push (@Cy, $y[$bonds[$n][$i]]);
                 push (@Cz, $z[$bonds[$n][$i]]);
               }
             }
             # now calculate all 3 possible angles
             my $smallangle = 0;
             my $o = 0,
             my @p =(0,3,1,2);
             for ($o=1; $o<=3; $o++) {
               #print "numbers: $o $p[$o]\n";
               # now calculate the angle
               # vectors @Avec = (length,x,y,z), a = C0->C$o, b = C0->C$p[$o]
               my @Avec = ();
               my @Bvec = ();
               my $cosalpha = 0;
               # 
               $Avec[1] = $Cx[$o] - $Cx[0];
               $Avec[2] = $Cy[$o] - $Cy[0];
               $Avec[3] = $Cz[$o] - $Cz[0];
               $Bvec[1] = $Cx[$p[$o]] - $Cx[0];
               $Bvec[2] = $Cy[$p[$o]] - $Cy[0];
               $Bvec[3] = $Cz[$p[$o]] - $Cz[0];
               $Avec[0] = sqrt ($Avec[1] * $Avec[1] + $Avec[2] * $Avec[2] + $Avec[3] * $Avec[3]);
               $Bvec[0] = sqrt ($Bvec[1] * $Bvec[1] + $Bvec[2] * $Bvec[2] + $Bvec[3] * $Bvec[3]);
               #
               $cosalpha = $Avec[1] * $Bvec[1] + $Avec[2] * $Bvec[2] + $Avec[3] * $Bvec[3];
               $cosalpha = $cosalpha / ($Avec[0] * $Bvec[0]);
               $cosalpha = acos($cosalpha) * $rad2deg;
               #print "angle between $o , C0, $p[$o] is $cosalpha\n";
               if ($cosalpha < 70) {
                 $smallangle = 1;
               }
             }
             if ($smallangle == 1) {
               print "CH cyclopropane carbon\n";
               $atomtypes[$n] = 712;
               $charge[$n] = -0.06;
               # assign charge group for CH in cyclopropane
               $cg++;
               $groups[$cg][0] = 2;                         # nr of atoms in charge group
               $groups[$cg][1] = $n;                        # the CH carbon in the cyclopropane
               $groups[$cg][2] = $Hcount[1];                # CH hydrogen
               print "charge group: $groups[$cg][1] $groups[$cg][2]\n";
             }
             else {
               print "aliphatic CH\n";
               $atomtypes[$n] = 137;
               $charge[$n] = -0.06;
               # assign charge group for aliphatic CH
               $cg++;
               $groups[$cg][0] = 2;                         # nr of atoms in charge group
               $groups[$cg][1] = $n;                        # the aliphatic CH carbon
               $groups[$cg][2] = $Hcount[1];                # CH hydrogen
               print "charge group: $groups[$cg][1] $groups[$cg][2]\n";
             }             
           }
       }  
        else {
          print "can't assign atom type for atom $n $element[$n].Exit.\n";
          exit;
        }
      }
      else {
        print "can't assign atom type for atom $n $element[$n].Exit.\n";
        exit;
      }     
     

    } # if C loop
  } # loop through $elements
  #

  # create rtp file for Gromacs
  my $rtp;
  open (my $rtp, '>', "$filename.rtp");
  $groupcount = $cg;
  # now create rtp entry (first on sceeen)
  my $mycolic = "AT$filenr";
  print $rtp "[ $mycolic ]\n";
  print $rtp " [ atoms ]\n";
  ## for printing the atoms we have to reorder them ???
  my ($i,$j);
  for ($i=0; $i<=$groupcount; $i++) {
    for ($j=1; $j<=$groups[$i][0]; $j++) {
      # print "$groups[$i][$j] group $i+1\n";
      my $opls ="opls_";
      my $lch = $i + 1;
      my $at  = $groups[$i][$j];
      #printf ("     %-9sopls_$atomtypes[$at]     % s$charge[$at]", $atom[$at]);
      printf $rtp ("     %-7s%10s%3d%12.2f    %-4d",$atom[$at],$opls,$atomtypes[$at],$charge[$at],$lch);
      print $rtp "\n";
    }
  }
  my $bondcount = 0;
  print $rtp " [ bonds ]\n";
  for ($n=1; $n<=$atomcount; $n++) {
#    printf ("     %-10s$bonds[$n][0]", $atom[$n]); 
#    print "\n";
    my $u = 0;
    for ($u=1; $u<=$bonds[$n][0]; $u++ ) {
      if ($bonds[$n][$u] > $n) {
        $bondcount ++;
        printf $rtp ("       %-10s%-s",$atom[$n],$atom[$bonds[$n][$u]]); 
        print $rtp "\n";
      }
    }
  }
  close $rtp; 

## 
# Update 13/04/2015: xyz files not needed anymore, as the new coordinates were extracted from gout with xyzextract 
# and then the molecules were renumbered and saved as mol2 with Aten.
# Old mol2 files (pre- optimisation and renumbering) need to be replaced with the new ones.
# Keeping the following xyz section for future reference.

#my $xyz = "p1-07-14-19.xyz";

#open XYZ, $xyz or die print "can't open $xyz\n";

#@file = <XYZ>;

#my (@newelement, @newx, @newy, @newz);

#my $z;
#for ($z=2; $z<=$atomcount; $z++) {
#   $_=@file[$z];
#   chomp $_;
#   s/^\s+//;
#   s/\s+/ /;
#   my ($newelement, $newx, $newy, $newz);
#  ($newelement, $newx, $newy, $newz) = split (/\s+/);
#   push (@newx, $newx);
#   push (@newy, $newy);
#   push (@newz, $newz);
#   print $newx, $newy, $newz;
#   print "\n";
#   }

#close (XYZ);
##

# create gro file for Gromacs run
 
 my $gro;
 open (my $gro, '>', "$filename.gro");
 my $l;
 my $title = "$filename";
 my $boxx = 10.00000;
 my $boxy = 10.00000;
 my $boxz = 10.00000;
 printf $gro "%s$title";
 printf $gro "\n";
 printf $gro ("%5d",$atomcount);
 printf $gro "\n";
  for ($l=1; $l<=$atomcount; $l++) {
    my $mycolic = "AT$filenr";
    printf $gro("%5d%-5s%5s%5d%8.3f%8.3f%8.3f",1,$mycolic,@atom[$l],$l,@x[$l]/10,@y[$l]/10,@z[$l]/10);
    printf $gro "\n";
  }
 printf $gro("%10.5f%10.5f%10.5f",$boxx,$boxy,$boxz);
 printf $gro "\n";
 close $gro;

#print "number of bonds: $bondcount\n";

} # loop through files
