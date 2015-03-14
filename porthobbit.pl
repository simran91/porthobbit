#!/usr/bin/perl

##################################################################################################################
# 
# File         : porthobbit.pl
# Description  : scans remote hosts for open ports
# Original Date: 1998
# Author       : simran@dn.gs
#
##################################################################################################################

require 5.002;
use Socket;
use Carp;
use FileHandle;
use POSIX;

$|=1;
$version="1.0 24/Feb/1998";


$SIG{'ALRM'} = 'alarmcall';

################ assign default values #################################################################################
#
#
#

$timeout = 7;

#
#
#
########################################################################################################################


################ read in args etc... ###################################################################################
#
#
#

($cmd = $0) =~ s:(.*/)::g;
($startdir = $0) =~ s/$cmd$//g;

while (@ARGV) { 
  $arg = "$ARGV[0]";
  $nextarg = "$ARGV[1]";
  if ($arg =~ /^-o$/i) {
    $outfile = "$nextarg";
    shift(@ARGV);
    shift(@ARGV);
    next;
  }
  elsif ($arg =~ /^-s$/i) {
    $startport = $nextarg;
    die "A valid numeric port number must be given with the -s argument : $!" if ($startport !~ /^\d+$/);
    shift(@ARGV);
    shift(@ARGV);
  }
  elsif ($arg =~ /^-e$/i) {
    $endport = $nextarg;
    die "A valid numeric port number must be given with the -e argument : $!" if ($endport !~ /^\d+$/);
    shift(@ARGV);
    shift(@ARGV);
  }
  elsif ($arg =~ /^-t$/i) {
    $timeout = $nextarg;
    die "A valid numeric number must be given with the -t argument : $!" if ($timeout !~ /^\d+$/);
    shift(@ARGV);
    shift(@ARGV);
  }
  elsif ($arg =~ /^-h$/i) {
    $host = $nextarg;
    shift(@ARGV);
    shift(@ARGV);
  }
  elsif ($arg =~ /^-about$/i) {
    shift(@ARGV);
    &about();
  }
  else { 
    print "\n\nArgument $arg not understood.\n";
    &usage();
  }
}

#
#
#
########################################################################################################################


############### forward declarations for subroutines ... ###############################################################
#
#
#

# forward declarations for subroutines

sub spawn;    # subroutine that spawns code... 
sub logmsg;   # subroutine that logs stuff on STDOUT 
sub REAPER;   # reaps zombie process... 
sub alarmcall; # Gets called when it takes more than "$timeout" seconds to answer a request... 

#
#
#
########################################################################################################################

################# main program #########################################################################################
#
#
#

if (! ($host && $startport && $endport && $outfile)) {
  &usage();
  exit(0);
}
if ($endport < $startport) {
  die "endport _must_ be greater than or equal to startport\n";
}

open(OUT, "> $outfile") || die "Could not open $outfile for writing : $!";
OUT->autoflush(1);

$proto = getprotobyname('tcp');

$remotehost = "$host";
$remote_iaddr = inet_aton($remotehost);
  

for ($remoteport = $startport; $remoteport <= $endport; $remoteport++) {
  alarm($timeout);
  socket(RemoteHost, PF_INET, SOCK_STREAM, $proto) or die "socket: $!";
  $remote_paddr = sockaddr_in($remoteport,$remote_iaddr);
  print STDERR "\rChecking port: $remoteport";
  if (! connect(RemoteHost, $remote_paddr)) {
    print OUT "$remotehost port $remoteport - Closed\n" if (! $timedout);
    $timedout = 0;
    close(RemoteHost);
  }
  else {
    close(RemoteHost);
    print OUT "$remotehost port $remoteport - Open\n";
  }
  alarm(0);
}
print STDERR "\n";

#
#
#
########################################################################################################################


########################################################################################################################
# usage: prints usage... 
#
#
sub usage {
  print "\n\n@_\n";
  print << "EOUSAGE"; 

Usage: $cmd [options]
       
   -h hostname  # connects to remote host 'hostname'
   -s num   	# starts checking from port 'num'
   -e num    	# last port checked is 'num'
   -o outfile   # Output filename... 
   -t num       # the request will time out after 'num' seconds if there was no response ... default 7
   -about	# About the program 

   eg. $cmd -h www.nowhere.com.au -o out.nowhere -s 10 -e 100


EOUSAGE
  exit(0);
}
#
#
#
########################################################################################################################

########################################################################################################################
# sub alarmcall: # the subroutine that is called when requests take too long to get a response for or respond to... 
#
#
sub alarmcall {
  my $signame = shift;
  $timedout = 1;
#  print STDERR <<"EO_ALRM_MSG";
#
#connection timed out ... or remote host not contactable... 
#
#EO_ALRM_MSG
  print OUT "$remotehost port $remoteport - Timeout\n";
  close(RemoteHost);
  # exit(1);
}
#
#
#
########################################################################################################################

########################################################################################################################
#
#
#
sub about {
  print <<"EOABOUT";
  
  PortHobbit version $version
  ----------------------------------

  Written to see which ports are open, being listened on
  a particular host, or which ports can get through a 
  firewall.

  Please mail comments/suggestions to simran\@dn.gs

EOABOUT
  exit(0);
}
#
#
#
########################################################################################################################


