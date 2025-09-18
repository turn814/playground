#!/usr/local/bin/perl
#
# command line fmtune (modified by NT)

use strict;
use warnings;
use BTSP;

#######################################################################

my $transport = "$ARGV[0]";
my %command; 
my %event;

sub BTReset
{
	%command = ('opcode' => 'Reset');
	eval {
		%event = BTSP::SendHCICmdW4SuccessEvent($transport, \%command, 'timeout=1000 ms');
		BTSP::Log( $transport, 'Reset Successful');
	}
	or do {
		print('Reset Failed');
	};
}

sub SetEventFilter
{
	%command = ('opcode' => "Set_Event_Filter",
            	'Filter_Type' => "Connection Setup",
	    	    'Connection_Setup_Filter_Condition_Type' => "Allow Connections from all devices",
	    	    'Auto_Accept_Flag' => "Do Auto accept the connection with role switch disabled");
	BTSP::SendHCICmdW4SuccessEvent($transport, \%command, 'timeout=100 ms');
}

sub WriteScanEnable
{
	%command = ('opcode' => 'Write_Scan_Enable',
	    		'Scan_Enable'  => "Inquiry and Page Scan enabled");
	
	BTSP::SendHCICmdW4SuccessEvent($transport, \%command, 'timeout=100 ms');
}

sub DUTtestmode
{
	%command = ("opcode" => "Enable_Device_Under_Test_Mode");
	BTSP::SendHCICmdW4SuccessEvent($transport, \%command, 'timeout=1000 ms');
}

sub Read_BD
{
	%command = ('opcode' => 'Read_BD_ADDR');
	BTSP::SendHCICmdW4SuccessEvent($tranport, \%command, 'timeout=1000 ms');
}

BTSP::Open($transport);
BTSP::SetProtocol($transport, 'HCI');
BTSP::Wait_ms(200);
BTReset($transport);
BTSP::Wait_ms(200); 
SetEventFilter($transport);
BTSP::Wait_ms(200);
WriteScanEnable($transport);
BTSP::Wait_ms(200);
DUTtestmode($transport);
BTSP::Wait_ms(200);
Read_BD($tranaport);