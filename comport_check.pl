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

# Define BT Reset command 
sub BTReset
{
	%command = ('opcode' => 'Reset');
	BTSP::SendHCICmdW4SuccessEvent( $transport, \%command, 'timeout=100 ms');
	BTSP::Log( $transport, 'Reset was successful');
}

# Define Read_BD_ADDR
sub BTReadBDAddress
{
	%command = ('opcode' => 'Read_BD_ADDR');
	%event = BTSP::SendHCICmdW4SuccessEvent( $transport, \%command, 'timeout=100 ms');
	my $uart_addr = $event{'BD_ADDR'};
	BTSP::Log( $transport, "BD_ADDR is $uart_addr");
}

# Open transport with passed script line argument
BTSP::Open($transport);
BTSP::SetProtocol($transport, 'HCI');
BTSP::Wait_ms(200);

# Reset and read back address
BTReset($transport);
BTReadBDAddress($transport);
BTSP::Close();