#/bin/perl/
use strict;
#
# -- create .xyz files from Gaussian .out files, using xyzextract 1.1.4 (c) 2010 Sebastian Schenker
# -- convert the .xyz files to .mol2 files        

## first, invoke xyzextract to create the .xyz files

my $atomcount;


my @files;
@files = `ls *.out`;

foreach (@files) {
  chomp;
  my $file = $_;
  $_= $file;
  s/\.out$// or die print "I'm only looking for .out files and I can't find them!\n";
  print "opening file $file\n";
 # my @file = ();
 # push (@file, $file);
  system "/media/storage/home/christof/bint/xyzextract -f $file";
}

my @xyzfiles;
@xyzfiles = `ls *.xyz`;

foreach (@xyzfiles) {
  chomp;
  my $coordfile = $_;
  $_= $coordfile;
  s/\.xyz$// or die print "I'm only looking for .xyz files and I can't find them!\n";
  print "opening file $coordfile\n";
  open (my $fh, '<', $coordfile) or die $!;   
} 
