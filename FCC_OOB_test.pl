#!/usr/bin/perl
use warnings;
use strict;
use diagnostics;

my $filename = 'C:\Users\irvinelabuser\Documents\Playground\test.csv';
my $str = <<END;
Hello

I am testing out this perl script
I need to learn how to use perl to create a regulatory OOB script
END

my @table1 = (
    [1, 2, 3],
    [4, 5, 6],
);
print "@table1\n";
my @subtable = $table1[0];
print "$subtable[1]\n";
my $unit = $subtable[1];
print "$unit\n";
=comment
for my $i (@table1) {
    for my $n (@table1[$i]) {
        print "$table1[$i][$n],";
    }
    print "\n";
}
=comment
open(FH, '>', $filename) or die $!;

print FH $str;
foreach(@table1) {
    print FH $table1[$_];
}

close(FH);

print("File $filename: successfully written!\n");

open(FH2, '<', $filename) or die $!;
print("File $filename: successfully opened!\n");

while(<FH2>) {
    print $_;
}

close(FH2);
=cut