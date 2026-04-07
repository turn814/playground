$| = 1; # Force immediate output
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
DownloadMinidriver($central);

BTSP::SetProtocol($central, 'Download');
BTSP::Wait_ms(200);
DownloadFW($central, $config_central);

BTSP::SetProtocol($central, 'HCI');
my $central_addr = ReadBdAddr($central);

print('Closing transport...');
BTSP::Close($central);

$central = undef;

exit;

sub Reset {
	my ($transport) = @_;
	print "Reset $transport...\n";
	my %params = ( 'opcode' => 'Reset' );
	my %event = BTSP::SendHCICmdW4SuccessEvent($transport, \%params, "timeout=3000 ms");
	if ($event{'Status'} ne 'Success') {
		die "Reset for $transport failed";
	}
}

sub DownloadFW {
	my ($transport, $config) = @_;
	print "Download FW...\n";
	my %event;
	my %params = (
		'Read_Write_Mode' => 'Cortex M3 HCI',
		'Write_Verify_Mode' => 'Write and verify',
		'Max_Write_Size' => 240,
		'Sector_Erase_Mode' => 'Written sectors only',
		'Config_Image' => $config,
		'Config_Location' => 'RAM runtime',
		'SS_Location' => 536899584,
		'Include_Fixed_Header' => 1,
		'Include_Fixed_Header_From_Burn_Image' => 0,
		'Crystal_Frequency' => '24 MHz',
		'Crystal_Error' => '0',
		'BD_ADDR' => '20829B1ABBCC',
		'Include_BTW_Security_Key' => 0,
		'Output_Power_Adjust' => 40,
		'Impedance_Match_Tuning' => 31
		);

	BTSP::InitiateDownload($transport, \%params);
	do
	{
		eval{ %event = BTSP::WaitForEvent($transport, 'timeout=1000 ms'); };
				
		if(defined $event{'event'} && $event{'event'} eq 'download_status')
			{
				my $state = $event{'State'} || '';
				my $percent = $event{'Percent_Complete'} || 0;
				
				if($state eq 'Config')
					{
						if($percent <= 5 ||
						($percent % 30) == 0 ||
						$percent >= 95)
							{
								my $num_hash = int($percent / 5);
								my $num_min = 20 - $num_hash;
								my $s = ('#' x $num_hash) . ('-' x $num_min);
								printf("\rState: %-12s [%-20s] %3d%% completed", $state, $s, $percent);
							}
					}
					elsif($state eq 'Config verify')
					{
						if($percent <= 5 ||
						($percent % 30) == 0 ||
						$percent >= 95)
							{
								my $num_hash = int($percent / 5);
								my $num_min = 20 - $num_hash;
								my $s = ('#' x $num_hash) . ('-' x $num_min);
								printf("\rState: %-12s [%-20s] %3d%% completed", $state, $s, $percent);
							}

					}
					else
					{
						print "\n$state";
					}
			}
	} until(defined $event{'State'} && $event{'State'} eq "Completed");
	print "\n"
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
		return $addr;
	}
	else {
		die "BD_ADDR of $transport not found\n"
	}
	
	return 1;
}

sub DownloadMinidriver {
	my ($transport) = @_;
	my %params = ('opcode' => 'Download_Minidriver');
	my %event = BTSP::SendHCICmdW4SuccessEvent($transport, \%params, "timeout=3000 ms");
}

END {
    if (defined $central) {
        print "\nCleaning up connection to $central...\n";
        
        eval {
            BTSP::Close($central);
        };
        
        if ($@) {
            # This catches the E0010050 error silently
            print "Connection was already closed or invalid.\n";
        } else {
            print "Connection closed successfully.\n";
        }
    }
}
