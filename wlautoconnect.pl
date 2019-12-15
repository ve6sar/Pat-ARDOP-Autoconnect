#!/usr/bin/perl 


# This script works in conjunction with KM4ACK's getardop script 
# to make a list of ardop stations based on their distance from 
# the users station andT work outwards trying to connect to RMS
# stations using the PA CLI until it is able to make a connection 
# and pass any traffic.
#
# Written by Sean Smith VE6SAR October 2019 
#
# October 15, 2019 Update fixed distance calculation bug when muliple bands to be used
#


use strict;
use warnings;
use Astro::Sunrise;
use DateTime;
use Data::Dumper;

# Define our paths and file locations
my $dataPath = $ENV{"HOME"} . '/Documents/ardop-list/';
my $patPath = '/usr/bin/pat';
my $getardopPath = '/usr/local/bin/getardoplist';
my $logFile = $ENV{"HOME"}.'/Documents/autoconnect.log';

#Define other needed variables and arrays
my @bands = (20,30,40,80); #Define all the bands we want data files for
my @day = (20,30,40); #Define our day bands
my @night = (40,80); #Define our night bands
my @stations;
my %location = ("lat" => "56", "long" => "-117");
my $dist = 250; #Starting distance in miles
my $distLast = 0;
my $max = 2000;

open(my $log, ">>", $logFile)
	or die "Can't open > $logFile: $!";

print $log localtime()." Script Started\r\n";  

print "Pat Winlink ARDOP auto connection script starting....\r\n";
print "Checking if ARDOP station lists have been downloaded....\r\n";

check_files ($dataPath, $getardopPath, \@bands, $log);
my $sunrise = sun_rise( { lon => $location{long}, lat => $location{lat} } ); #Get the sunrise
my $sunset = sun_set( { lon => $location{long}, lat => $location{lat} } ); #Get the sunset
my $dt = DateTime->now->set_time_zone( 'America/Edmonton' ); #Set the time zone

my $hm = $dt->hour.$dt->minute;

# Remove the colon from the sunrise and sunset variables
$sunrise =~ tr/://d;
$sunset =~ tr/://d;

if ($hm >= $sunrise && $hm <= $sunset) { #Check if it's day or night
  print "It's day time\r\n"; 
  print $log localtime()."It's day time\r\n"; 

     while ($dist <= $max){
       foreach my $band (@day){
         print "Band = $band \r\n";
         getStations ($dataPath, $band, $dist, $distLast, $patPath, $log); 
       }
         $distLast = $dist;
         $dist = $dist + 250;
     }
} else {
  print "It's night time\r\n"; 
  print $log localtime()."It's night time\r\n"; 
   while ($dist <= $max){
    foreach my $band (@night){
      print "Band = $band \r\n";
      #my @stations = 
      getStations ($dataPath, $band, $dist, $distLast, $patPath, $log); 
    }
      $distLast = $dist;
      $dist = $dist + 250;
  }

}

##############################
#Subroutines for various tasks

sub logmsg {
  print (scalar localtime() . " @_\n");
}

# This sub checks that we have all the data files. If files are missing it attempts to download them via the getardop script
sub check_files {
  my $path = $_[0]; #The path of the data files 
  my $getardop = $_[1];
  my @bands = @{$_[2]};
  my $log = $_[3];
  my $n = 0; #Error counter

  print "Our data path is ".$path." \r\n";
  foreach (@bands)
  {
    print "Checking for ";
    print $_;
    print "m band data file.... ";
    my $file = $path.$_.'mardoplist.txt';
    if ( -e $file) { print "Data file found\r\n"; } else { print "Data File not found\r\n"; $n++;}
    
  }  
  
  #Lets check if we encoutered any missing files
  if ($n != 0) { 
    print "We are missing one or more data files\r\n";
    print "Running the getardop script.... \r\n";
    print $log localtime()." Missing Datafiles, running getardop script\r\n";  

    system ("$getardop") == 0 
          or die "system $getardop failed: $?"; #Get ARDOP lists or die if we can't
    print $log localtime()." Files Downloaded\r\n";  

  } else { 
    print "All files located!\r\n";
    print $log localtime()." All data files accounted for\r\n";  

  }
}

# Get the stations list
sub getStations {
  #PopulatUse of uninitialized value variables for clearity 
  my $distance = $_[2];
  my $path = $_[0];
  my $band = $_[1];
  my $last = $_[3];
  my $pat = $_[4];
  my $log = $_[5];
  my $file = $path.$band.'mardoplist.txt';

print $log localtime()." *************************\r\n";
print $log localtime()." Band =     $band\r\n";
print $log localtime()." Min Dist = $last\r\n";
print $log localtime()." Max Dist = $distance\r\n";
#print "Path = $path\r\n";
#print "File = $file\r\n";
print $log localtime()." *************************\r\n";

  #Open a read only file handle
  open (FH, '<', $file) or die $!;

  #Read our file and extract the stations if we want
  while (<FH>){
#    print $_;
     if ($_ =~ /\w+/) {  
       my @line = split /\s+/, $_;
#     print Dumper @line;    	
       if ($line[2] =~ /\d+/){  
         if ($line[2] > $last && $line[2] < $distance) {
           print "Station = $line[0] Distance = $line[2] miles\r\n";
           print "Connection parameters: $line[10]\r\n";
	   my $command = $pat." connect ".$line[10];
           system ($command);
           my $exit_code = ($? >> 8);
#           print "Exit code = $exit_code \r\n";
           if ($exit_code == 1) {
             print "No connection moving to next station....\r\n";
#             print $log localtime()." No connection to $line[0]\r\n";
           } elsif ($exit_code == 0){
             print "\r\n\r\nConnection made....Exiting....\r\n\r\n";
             print $log localtime()." Connection made with $line[0]\r\n";
             exit;
           }
         }
       } 
     }
   }
}
