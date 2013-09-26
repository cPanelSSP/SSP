package Warn::SELinux;

use strict;
use warnings;
use diagnostics;
use Cmd;
use PrintText;

use Exporter;
our @ISA = qw( Exporter );
our @EXPORT = qw( check_selinux_status );

sub check_selinux_status {
    my @selinux_status = split /\n/, run('sestatus');

    return if !@selinux_status;

    for my $line (@selinux_status) {
        if ( $line =~ m{ \A Current \s mode: \s+ enforcing }xms ) {
            print_warn('SELinux: ');
            print_warning('enabled and enforcing!');
        }
    }
}

1;
