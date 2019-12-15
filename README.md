# Pat-ARDOP-Autoconnect
This script works in conjunction with KM4ACK's getardop script 
to make a list of ardop stations based on their distance from 
the users station and work outwards trying to connect to RMS
stations using the PAT CLI until it is able to make a connection 
and pass any traffic.

Please edit the following sections to suit your installation:
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
my %location = ("lat" => "56", "long" => "-117");  #Your stations Latitude and Longitude
my $dist = 250; #Starting distance in miles
my $distLast = 0;
my $max = 2000; #Max distance
