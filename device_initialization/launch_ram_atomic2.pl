use Hci;
use BTSP;
use strict;
use Data::Dumper;

# usage: perl FW_download_atomic2.pl <COMxxx> <baudrate> <C:\path\to\fw\file.hcd>

my $comport = lc($ARGV[0]);
my $baudrate = $ARGV[1];
my $central = "$comport" . '@' . "$baudrate";
my $config_central = $ARGV[2];

BTSP::Open($central);
BTSP::SetProtocol($central, 'HCI');

Reset($central);

LaunchRam($central);

ReadBdAddr($central);

BTSP::Close($central);

sub Reset {
	my ($transport) = @_;
	print "Reset $transport...\n";
	my %params = ( 'opcode' => 'Reset' );
	my %event = BTSP::SendHCICmdW4SuccessEvent($transport, \%params, "timeout=3000 ms");
	if ($event{'Status'} ne 'Success') {
		die "Reset for $transport failed";
	}
}

sub ReadBdAddr {
	my ($transport) = @_;	
	my %params = ('opcode' => 'Read_BD_ADDR');
	my %event = BTSP::SendHCICmdW4SuccessEvent($transport, \%params, "timeout=3000 ms");
	
	if ($event{'Status'} ne 'Success') {
		die "Read_BD_ADDR for $transport failed";
	}
	
	my $addr = undef;
	if (defined($event{'BD_ADDR'})) {
		$addr = $event{'BD_ADDR'};
		print "BD_ADDR of $transport is $addr\n";
	}
	else {
		die "BD_ADDR of $transport not found\n"
	}
	
	return $addr;
}

sub LaunchRam {
    my ($transport) = @_;
    my %params = ('opcode' => 'Launch_RAM',
    'Address' => 4294967295);
    my %event = BTSP::SendHCICmdW4SuccessEvent($transport, \%params, "timeout=3000 ms");

    if ($event{'Status'} ne 'Success') {
        die "Launch_RAM for $transport failed";
    }
}