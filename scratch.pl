#!/usr/bin/perl

use warnings;
use strict;

## Variables ##
our $x = 20e2;
print("\$x = $x\n");
our $y = -40e2;
print("\$y = $y\n");

{
    my $x = 10;
    print("within this block, \$x = $x\n");
    my $y = 30;
    print("and \$y = $y\n");
    my $z = $x + $y;
    print("so, in this block only, the sum of \$x: $x and \$y: $y is \$z: $z\n");
}

our $z = $x + $y;
print("but outside that block, the sum of \$x: $x and \$y: $y is \$z: $z!\n");


## Operators ##
print("10 + 20 = ", 10 + 20, "\n");
print "10 - 20 = ", 10 - 20, "\n";
print "10 * 20 = ", 10 * 20, "\n";
print "10 / 20 = ", 10 / 20, "\n";
print "10 ^ 20 = ", 10 ** 20, "\n";
print "10 % 20 = ", 10 % 20, "\n";

my $a = 0b0101;
print "\$a = 0b0101 or $a\n";
my $b = 0b0011;
print "\$b = 0b0011 or $b\n";

printf("\$a & \$b = $a & $b\n");
print "\$a | \$b = ", $a | $b, "\n";


## Arrays ##
my @team_members = qw(Charles Micheal Jeffrey Chao Isaac);
print "@team_members\n";
print "Newer members: @team_members[-3..-1]", "\n";

my $num_team_members = @team_members;
print "$num_team_members\n";

$team_members[-2] = "Chao-Ruey";
print "@team_members\n";

my @stack = ();
push(@stack, 1);
push(@stack, 2);
push(@stack, 3);

print "Pushing 1, 2, 3:\n\@stack = @stack\n";

my @queue = ();
unshift(@queue, 1);
unshift(@queue, 2);
unshift(@queue, 3);

print "Unshifting 1, 2, 3:\n\@queue = @queue\n";

my $popped = pop(@stack);
print "Popped $popped from \@stack,\nnow \@stack = @stack\n";
$popped = pop(@queue);
print "Popped $popped from \@queue,\nnow \@queue = @queue\n";


## Hashes ##
my %roles = (
    Isaac => 'Engineer',
    Charles => 'Manager',
    Seon => 'Director',
    Wenbin => 'Senior Director',
    Shantanu => 'VP'
);

for (keys %roles) {
    print "$_ has the role of $roles{$_}\n";
}