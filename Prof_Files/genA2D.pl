#!/usr/bin/perl

######################################################################
#############USE AT YOUR OWN RISK#####################################
# the revisions to this code are quick, hasty, and relatively untested
######################################################################

################################################################### 
# This is a simple Perl Program in which the user specifies an    #
# values for amplitude, period, and damping factor for the error  #
# term, then an analog.dat file is created containing the values  #
# for the A2D measurements that represent the IR reading of the   #
# line follower.                                                  #
# For use with Spring 2015 project                                #
###################################################################
open(OUTFILE,">analog.dat") || die "ERROR: Can't open analog.dat for write\n";

print "Enter amplitude of error(value from 0 to 2047): ";
$e_amp = <STDIN>;
print "Damping time will be 5 periods\n";
print "Enter the period of the error signal in # of error_calc_num: ";
$period = <STDIN>;
print "Enter any DC offset if desired (0 to 2047):";
$DC = <STDIN>;

$inner_weight = 384;
$mid_weight = 768;
$outer_weight = 1536;

print "\nCreating analog.dat...\n";
$angle = 0;
for ($error_calc_num = 0; $error_calc_num < $period*5; $error_calc_num++) {
  $angle = $error_calc_num/$period * 6.28;
  $damping = exp(-$error_calc_num/$period);
  $amplitude = $e_amp*$damping;
  $error = int($amplitude*sin($angle) + $DC);
  printf OUTFILE "// Error = %x hex %d decimal\n",$error,$error;
  if ($error>0) {		## Error is positive so all on right side.
    if ($error>($mid_weight+$inner_weight)) {		## signal will be in outer and mid sensors
	  if ($error>=$outer_weight) {
	    $A3 = ($outer_weight>>2);
		$A4 = (($error - $outer_weight)>>1);
		$A1 = 0;
	  }
	  else {
	    $A3 = ($error>>2);
		$A4 = 0;
		$A1 = 0;
	  }
	}
	elsif ($error>$inner_weight) {				## signal will be in mid and inner sensors
	  if ($error>=$mid_weight) {
	    $A4 = ($mid_weight>>1);
		$A1 = ($error - $mid_weight);
		$A3 = 0;
	  }
	  else {
	    $A4 = ($error>>1);
		$A3 = 0;
		$A1 = 0;
	  }
	}
	else {										## signal is purely in inner sensor
	  $A1 = $error;
	  $A4 = 0;
	  $A3 = 0;
	}
	$A0 = 0;
	$A2 = 0;
	$A7 = 0;
  }
  else {				## Error is negative so all on left side.
    $error = -$error;
    if ($error>($mid_weight+$inner_weight)) {		## signal will be in outer and mid sensors
	  if ($error>=$outer_weight) {
	    $A7 = ($outer_weight>>2);
		$A2 = (($error - $outer_weight)>>1);
		$A0 = 0;
	  }
	  else {
	    $A7 = ($error>>2);
		$A0 = 0;
		$A2 = 0;
	  }
	}
	elsif ($error>$inner_weight) {				## signal will be in mid and inner sensors
	  if ($error>=$mid_weight) {
	    $A2 = ($mid_weight>>1);
		$A0 = ($error - $mid_weight);
		$A7 = 0;
	  }
	  else {
	    $A2 = ($error>>1);
		$A0 = 0;
		$A7 = 0;
	  }
	}
	else {										## signal is purely in inner sensor
	  $A0 = $error;
	  $A2 = 0;
	  $A7 = 0;
	}
	$A1 = 0;
	$A3 = 0;
	$A4 = 0;
  }
  $A5 = 0;		## this channel not used and always reads zero
  $A6 = 0;		## this channel not used and always reads zero
  
  $A0 = 4095 - $A0;
  $A1 = 4095 - $A1;
  $A2 = 4095 - $A2;
  $A3 = 4095 - $A3;
  $A4 = 4095 - $A4;
  $A5 = 4095 - $A5;
  $A6 = 4095 - $A6;
  $A7 = 4095 - $A7;  
  for ($conversions=0; $conversions<6; $conversions++) {	## There are 6 A2D error_calc_num per Error calculation
    printf OUTFILE "// conversion %d for error number %d\n",$conversions+1,$error_calc_num;
    printf OUTFILE "\@%x %3x\n",$error_calc_num*48+$conversions*8,$A0;
    printf OUTFILE "\@%x %3x\n",$error_calc_num*48+$conversions*8+1,$A1;
    printf OUTFILE "\@%x %3x\n",$error_calc_num*48+$conversions*8+2,$A2;
    printf OUTFILE "\@%x %3x\n",$error_calc_num*48+$conversions*8+3,$A3;
    printf OUTFILE "\@%x %3x\n",$error_calc_num*48+$conversions*8+4,$A4;
    printf OUTFILE "\@%x %3x\n",$error_calc_num*48+$conversions*8+5,$A5;
    printf OUTFILE "\@%x %3x\n",$error_calc_num*48+$conversions*8+6,$A6;
    printf OUTFILE "\@%x %3x\n",$error_calc_num*48+$conversions*8+7,$A7;
  }
}


close(OUTFILE);
