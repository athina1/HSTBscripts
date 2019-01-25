#!/usr/bin/perl/

use strict;
use warnings;

#####Date and time####
#use POSIX qw(strftime);
my $time = gmtime();
#####################

###To be changed
#$batchout name (now is "beta tar")
#$batchcount, $totalinfiles, $totaloutfiles, $batchsize
#$filesbatchin, $filesbatchout, $tarcount, $tarfilecount 

###Sleep script###
my $run = 1;
my $timeout = "3600";
##################

# keeping track of submitting files
my $batchcount = 300000; # serial number of batchjob (submitted) ##changed received to submitted
my $totalinfiles = 0; # serial number of WUs/jobs received
my $totaloutfiles = 0; # serial number of WUs/jobs submitted

# number of files for outgoing batches
my $batchsize = 100;

my $grompp = "/home/SOFT/mygromacs/local_4.6.7/bin/grompp";

my $id;

my $incoming = "/home/wcg/INCOMING"; # where WCG will put tar files.
my $unpacked = "/home/wcg/INCOMING/unpacked"; # where packed data will get unpacked.
my $results = "/home/wcg/RESULTS"; # packed data coming from the wcg.
my $outgoing = "/home/wcg/OUTGOING"; # tars we provide to the wcg.
my $notpacked = "/home/wcg/OUTGOING/files"; # inputs we provide to the wcg before compression.
my $logfiles = "/home/wcg/LOGS"; # log files etc.
my $scripts = "/home/wcg/scripts"; #scripts and new input files

my $output;
my $logfile;

my $gro = "gro";
my $edr = "edr";
my $log = "log";
my $xtc = "xtc";
my $tpr = "tpr";

my $filepath;
my $batch;
my $number;
my $molec;
my $temper;
my $frame;
my $mdstep;

#disable Gromacs backups because otherwise it fails after writing 99x copies
  if(!defined $ENV{GMX_MAXBACKUP}) {
    $ENV{GMX_MAXBACKUP}=-1
  }

############## DO THIS LOOP every 1h ################
while ($run == 1) {

my ($mday, $mon, $year) = (localtime(time))[3, 4, 5];

$mon  += 1;
$year += 1900;

my $logfilename = sprintf "%s%02d%02d", $year % 100, $mon, $mday;

###############################################

my $tarcount = 0;
my $tarfilecount = 0;

my @tar; # incoming tar files from the wcg.
@tar = `ls $incoming\/\*\.tar`;
print @tar;
print "\n";

print "Script start \n";
print "\n";

############ Start of foreach tar and (next) foreach gro loops ############

  foreach (@tar) {
  print "Foreach tar loop start \n";
  print "\n";
 
  my $tarname = $_;
  /(HST1_\d{6})/;
  my $done = $1;
  my $donefile = $done . ".done_wcg";
  # for testing only
  #my $donefile = "test.done_wcg";
  print "done file present? $donefile\n";
  $tarcount++;

  if (-e "$incoming\/$donefile") {

  print "yes existing\n";
  `mkdir $unpacked\/$done`; 
  `tar -C $unpacked\/$done -xvf $tarname`;
#  print "chmod 666 $unpacked/*gz"; CAN CREATE too long argument list
# `chmod 666 $unpacked/*gz`;
#  print "find $unpacked -maxdepth 1 -name *.gz -print0 | xargs -0 chmod 666\n";
# `find $unpacked -maxdepth 1 -name "*.gz" -print0 | xargs -0 chmod 666`;
# print "find $unpacked -maxdepth 1 -name \"*.gz\" -print0 | xargs -0 gunzip -d\n";
# `find $unpacked -maxdepth 1 -name "*.gz" -print0 | xargs -0 gunzip -d `;
 # write that the tar file has been unpacked
 #`touch $tarname/.unpacked`;
 `rm -f $tarname`;
 
  my $filesbatchin = 0;  # number of files in individual batch received 
  my $filesbatchout = 0; # number of files in individual batch sent out

  my @files; 
  @files = `ls $unpacked\/$done\/*$gro.gz`;
  print "@files \n";

    foreach (@files) { # start of foreach gro file loop.

    $tarfilecount++;

    $filesbatchin++;
    $totalinfiles++;
  
    /HST1_(\d{6})_(\d{6})_(\w{2})(\d{4})_T(\d{3})_F(\d{5})_S(\d{5})/;

    $batch = $1;
    $number = $2;
    $id = $3;
    $molec = $4;
    $temper = $5;
    $frame = $6;
    $mdstep = $7;

    $filepath = "/${id}${molec}/T${temper}/F${frame}/";

    print "batch: $batch \n";
    print "sequential batch number: $number \n";
    print "\n";
    print "molecule: ${id}${molec} \n";
    print "temperature: $temper \n";
    print "frame: $frame \n";
    print "mdstep: $mdstep \n";
    print "\n";
   
    ##### check for edr, log and xtc files and move to results.
    ### move chmod and gunzip command to here to prevent long input commands
    `chmod 666 $unpacked\/$done\/\*${id}$molec\_T$temper\_F${frame}\_S${mdstep}*.gz`;
    print "chmod 666 $unpacked\/$done\/\*${id}$molec\_T$temper\_F${frame}\_S${mdstep}*.gz\n";
    `gunzip -d $unpacked\/$done\/\*${id}$molec\_T$temper\_F${frame}\_S${mdstep}*.gz`;
    my $check = 0;
       
    $check = `ls $unpacked\/$done\/\*${id}$molec\_T$temper\_F${frame}\_S${mdstep}.${edr} | grep -c \.$edr`;
    print "$unpacked\/$done\/${id}${molec}\_T$temper\_F$frame\_S$mdstep\.$edr: $check \n";
    print "\n";

        if ($check == 0) {
        `touch ${results}$filepath\/STOP`;
        open $logfile, '>>', "$logfiles\/history$logfilename.log";
        print $logfile "WARNING: ${id}$molec\_T$temper\_F$frame\_S$mdstep\.$edr is MISSING, simulation stopped \n";
        close $logfile; 
        }

          else {
          #print "INFO: $unpacked\/$id$molec\_F$frame\_S$mdstep\.$edr is FOUND \n";
          }
   
    $check = 0;
    print "$check \n"; 
    print "\n";

    $check = `ls $unpacked\/$done\/\*${id}$molec\_T$temper\_F${frame}\_S${mdstep}.${log} | grep -c \.$log`;
    print "$unpacked\/$done\/${id}$molec\_T$temper\_F$frame\_S$mdstep\.$log: $check \n";
    print "\n";

        if ($check == 0) {
        `touch ${results}$filepath\/STOP`;
        open $logfile, '>>', "$logfiles\/history$logfilename.log";
        print $logfile "WARNING: ${id}$molec\_T$temper\_F$frame\_S$mdstep\.$log is MISSING, simulation stopped \n";
        close $logfile;
        }
        
          else {
          #print "INFO: $unpacked\/$id$molec\_F$frame\_S$mdstep\.$log is FOUND \n";
          }
       
    $check = 0;
    print "$check \n"; 
    print "\n";

    $check = `ls $unpacked\/$done\/\*${id}$molec\_T$temper\_F$frame\_S$mdstep.$xtc | grep -c \.$xtc`; 
    print "$unpacked\/$done\/${id}$molec\_T$temper\_F$frame\_S$mdstep\.$xtc: $check \n";
    print "\n";
 
        if ($check == 0) { 
        `touch ${results}$filepath\/STOP`;
        open $logfile, '>>', "$logfiles\/history$logfilename.log";
        print $logfile "WARNING: $id$molec\_T$temper\_F$frame\_S$mdstep\.$xtc is MISSING, simulation stopped \n";
        close $logfile;
        }

          else {
          #print "INFO: $unpacked\/$id$molec\_F$frame\_S$mdstep\.$xtc is FOUND \n";
          }

    $check = 0;
    print "$check \n"; 
    print "\n";

   `mv -f $unpacked\/$done\/*${id}${molec}\_T${temper}\_F${frame}\_S${mdstep}\.${gro} ${results}${filepath}${id}${molec}\_T${temper}\_F${frame}\_S${mdstep}\.${gro}`;
   `mv -f $unpacked\/$done\/*${id}${molec}\_T${temper}\_F${frame}\_S${mdstep}\.${edr} ${results}${filepath}${id}${molec}\_T${temper}\_F${frame}\_S${mdstep}\.${edr}`;
   `mv -f $unpacked\/$done\/*${id}${molec}\_T${temper}\_F${frame}\_S${mdstep}\.${log} ${results}${filepath}${id}${molec}\_T${temper}\_F${frame}\_S${mdstep}\.${log}`;
   `mv -f $unpacked\/$done\/*${id}${molec}\_T${temper}\_F${frame}\_S${mdstep}\.${xtc} ${results}${filepath}${id}${molec}\_T${temper}\_F${frame}\_S${mdstep}\.${xtc}`;
   # and remove .info file
   `rm -f $unpacked\/$done\/*${id}${molec}\_T${temper}\_F${frame}\_S${mdstep}.info`;  

   # added 21/07/16
   # checking for invalid incoming gro file increase of box size
   my $tail = `tail -1 ${results}${filepath}${id}${molec}\_T${temper}\_F${frame}\_S${mdstep}\.${gro}`;
   chomp $tail;
   my @split = split /\s+/, $tail;
   my $sum = $split[1] + $split[2] + $split[3]; 
   if ($sum <= 28 or $sum >= 34) {
     `touch ${results}$filepath\/STOP`;
     open $logfile, '>>', "$logfiles\/history$logfilename.log";
     print $logfile "WARNING: $id$molec\_T$temper\_F$frame\_S$mdstep\.$gro box invalid, md stopped \n";
     close $logfile;
  }


   # for the next step tpr file.
   my $nextstep = $mdstep + 1;
   my $nextformat = sprintf ("%s%05d", "S", $nextstep);
   #for the empty step file.
   my $previousstep = $mdstep - 1;
   my $previousformat = sprintf ("%s%05d", "S", $previousstep);
   #for the old gro file that we will remove.
   my $removegro = $mdstep - 2;
   my $removeformat = sprintf ("%s%05d", "S", $removegro);

   if (-e "${results}$filepath\/STOP") {
   open $logfile, '>>', "$logfiles\/history$logfilename.log";
   print $logfile "INFO: MD stopped due to STOP file found in ${results}${filepath} \n";
   close $logfile;
   }

     elsif ((! -e "${results}${filepath}MDsolT${temper}.mdp") and (! -e "${results}${filepath}topol.top")) {   
     open $logfile, '>>', "$logfiles\/history$logfilename.log";
     print $logfile "ERROR: input files MISSING, simulation stopped in ${results}${filepath} \n";
     close $logfile;
     `touch ${results}$filepath\/STOP`;
     }

       else {
       `touch ${results}${filepath}S${mdstep}`;
       print "Grompp step: getting new input \n";
      `$grompp -f ${results}${filepath}MDsolT${temper}.mdp -c ${results}${filepath}${id}${molec}\_T$temper\_F$frame\_S$mdstep\.$gro \\
      -p ${results}${filepath}topol.top -o ${results}${filepath}${id}${molec}\_T$temper\_F$frame\_$nextformat\.$tpr`; 
       if (-e "${results}${filepath}${id}${molec}\_T$temper\_F$frame\_$nextformat\.$tpr") {
        $filesbatchout++;
         ###$totaloutfiles++; ##commented out as we shouldn't count twice
        `mv -f ${results}${filepath}${id}${molec}\_T$temper\_F$frame\_$nextformat\.$tpr $notpacked`; 
       }
       else {
         open $logfile, '>>', "$logfiles\/history$logfilename.log";
         print $logfile "ERROR: GROMPP failure, ${results}${filepath}${id}${molec}\_T$temper\_F$frame\_$nextformat\.$tpr \n";
         print $logfile "could not be created, simulation stopped\n";
         close $logfile;
       } 
      }
   if ((-e "${results}${filepath}${id}${molec}\_T$temper\_F$frame\_$removeformat\.$gro") and (-e "${results}${filepath}${previousformat}")) {
   print "Delete step: deleting ${results}${filepath}${id}${molec}\_T$temper\_F$frame\_$removeformat\.$gro and ${results}${filepath}${previousformat} \n";
   `rm -f ${results}${filepath}${id}${molec}\_T$temper\_F$frame\_$removeformat\.$gro`;
   `rm -f ${results}${filepath}${previousformat}`;
   #`touch ${results}${filepath}S${mdstep}`; 
   }

     else {
	 open $logfile, '>>', "$logfiles\/history$logfilename.log";
     print $logfile "INFO: ${results}${filepath}${id}${molec}\_T$temper\_F$frame\_$removeformat\.$gro or $previousformat MISSING \n";
     close $logfile;
      }
     
    $batch = 0;
    $number = 0;
    $molec = 0;
    $frame = 0;
    $mdstep = 0;

    } # end of foreach gro file loop
    # and remove empty directory
    `rmdir $unpacked\/$done`;

  $time = gmtime();
  open $logfile, '>>', "$logfiles\/history$logfilename.log";
  print $logfile "$time: $tarname: $filesbatchin received and $filesbatchout submitted \n";
  close $logfile;

  } # end of loop through tar files

} # end of if tar_done_wcg exists
 
  $time = gmtime(); 
  open $logfile, '>>', "$logfiles\/history$logfilename.log";
  print $logfile "$time: a total of $totalinfiles jobs received; $tarfilecount new jobs from $tarcount tar files \n";
  close $logfile;

##################### end of tar and foreach gro loops.



##################### loop for new input files.

print "Now loop for new input files \n";
print "\n";

my $addfiles = 0;

if (-e "$scripts\/new.txt") {
  open (my $newinputs, '<', "$scripts\/new.txt") or print "Can't open file: $! \n";
  print "opening file \n";
 
  `cp $scripts\/new.txt $scripts\/new_copy.txt`;
 
  while ( <$newinputs> ) {
    chomp $_;
    if ($_=~/(\w{2})(\d{4})_T(\d{3})_F(\d{5})_S(\d{5})/) {
    
      $id = $1;
      $molec = $2;
      $temper = $3;
      $frame = $4;
      $mdstep = $5;
  
      $filepath = "/$id$molec/T$temper/F$frame/";

      print "molecule: $id$molec \n";
      print "frame: $frame \n";
      print "mdstep: $mdstep \n";
      print "\n";
      print "the new tpr file is : $id$molec\_T$temper\_F$frame\_S$mdstep.$tpr \n";
      print "\n";

      if (-e "${results}${filepath}${id}${molec}\_T$temper\_F$frame\_S$mdstep.$tpr") {
        print " additional $addfiles jobs added from input files\n";
        #########!!!!!!!!!!!# changed mv to cp!!! ############!!!!!!!!!!!!!!!!!!!!!!!###################
		`cp -f  ${results}${filepath}${id}${molec}\_T$temper\_F$frame\_S$mdstep.$tpr $notpacked`;
        $addfiles++;
      }
      else {
        open $logfile, '>>', "$logfiles\/history$logfilename.log";
        print $logfile "WARNING: could not find $id$molec\_T$temper\_F$frame\_S$mdstep.$tpr mentioned in new.txt\n";
        close $logfile;
      }
    } ### if match pattern loop.
  } ### while "new input" txt file is open for read.
  
  close ($newinputs);
  `rm $scripts\/new.txt`;  
   
  $time = gmtime();       
  open $logfile, '>>', "$logfiles\/history$logfilename.log";
  print $logfile "$time: $addfiles jobs added from new.txt\n";
  close $logfile;

} ### if "new inputs" txt file exists.

else {
  print "No new inputs for now \n";
}
 

##################### end of loop for new input files.



##################### now loop for packing and submission.

print "Now comes the packing \n";
print "\n";

my $newbatch = 1; ### do create new batch tar.gz

while ($newbatch == 1) {
  my $wcgoutcount = `ls -l $notpacked\/\*\.$tpr | wc -l`;
 
  print "WCGOUTCOUNT: $wcgoutcount \n";    
  print "\n";
  
  if ($wcgoutcount >= $batchsize) {
  
  chdir "$notpacked" or print "cannot chdir to $notpacked $! \n";
  print `pwd`;
  print "\n";
  
  $newbatch = 1;
  $batchcount++;
  my $batchcountform = sprintf ("%06d", $batchcount);
  my @wcgfiles;
  my $i;
  @wcgfiles = `ls \*\.$tpr`;    

  print "WCGFILES: \n";
  print "@wcgfiles \n";
  print "\n";        
  
      for ($i=0; $i<$batchsize; $i++) { 
      my $index = ($i+1);
      my $indexform = sprintf ("%06d", $index); 
      $totaloutfiles++;
      my $totaloutfilesform = sprintf ("%06d", $totaloutfiles);
      chomp $wcgfiles[$i];
      rename("$wcgfiles[$i]", "HST1_$batchcountform\_$indexform\_$wcgfiles[$i]") or print ( "Error in renaming $! ");
      
      my $hex = "0";
      my $hexform = sprintf ("%03d", $hex);
      my $wat = "1";
      my $watform = sprintf ("%03d", $wat);

      my $wcgbase = substr $wcgfiles[$i], 0, -4;

      my $TEMPER = substr $wcgfiles[$i], 8, 3 ;
    
      if ($TEMPER == $hexform) {
      print "$TEMPER = $hexform hexane! \n";
      `echo "-s HST1_$batchcountform\_$indexform\_$wcgfiles[$i] -cpt 5 -pd -nt 1 -reprod -cpi state.cpt " > HST1_$batchcountform\_$indexform\_$wcgbase`;
      }
        elsif ($TEMPER == $watform) {
        print "$TEMPER = $watform water !\n";
        `echo "-s HST1_$batchcountform\_$indexform\_$wcgfiles[$i] -cpt 5 -pd -nt 1 -reprod -cpi state.cpt " > HST1_$batchcountform\_$indexform\_$wcgbase`;
        }
          else {
          print "we have the standard simulation \n";
          `echo "-s HST1_$batchcountform\_$indexform\_$wcgfiles[$i] -cpt 5 -nt 1 -reprod -cpi state.cpt " > HST1_$batchcountform\_$indexform\_$wcgbase`;
          }

     
      }
    
       `tar -czvf $outgoing\/HST1_${batchcountform}.tar.gz HST* --remove-files`;
   
       `md5sum $outgoing\/HST1_${batchcountform}.tar.gz > $outgoing\/HST1_${batchcountform}.md5`;    
     
     #`tar -czvf $outgoing\/test.tar.gz HST* --remove-files`;`md5sum $outgoing\/test.tar.gz > $outgoing\/test`;
     #`md5sum $outgoing\/test.tar.gz > $outgoing\/test`;

      $time = gmtime();
      open $logfile, '>>', "$logfiles\/history$logfilename.log";
      print $logfile "$time: submitted batch job number $batchcount; total of $totaloutfiles jobs submitted\n";
      close $logfile;
  }

  else {
    print "Not enough files to zip yet \n";
    $newbatch = 0;
  }
} #### while newbatch
  
  chdir "$incoming" or print "cannot chdir to $incoming $! \n";
  print `pwd`;
  print "\n";
  
##################### end of loop for packing and submission.

 if (-e "$scripts/RUN_WCGdatatransfer") {
    $run = 1;
  }
  else {
    $run = 0;
    print "stopping\n";
    exit;
  }
  sleep $timeout;
}
