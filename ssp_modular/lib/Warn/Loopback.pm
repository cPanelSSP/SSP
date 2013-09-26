package Warn::Loopback;

use strict;
use warnings;
use diagnostics;
use Cmd;
use PrintText;
use IO::Socket::INET;

use Exporter;
our @ISA = qw( Exporter );
our @EXPORT = qw(
    check_if_loopback_is_up
    check_loopback_connectivity
);


my $is_up = 0;

sub check_if_loopback_is_up {
    my $ifconfig_lo = run( 'ifconfig', 'lo' );

    if ( $ifconfig_lo =~ /UP LOOPBACK/ ) {
        $is_up = 1;
    }

    if ( $is_up == 0 ) {
        print_warn('Loopback Interface: ');
        print_warning('loopback interface is not up!');
    }
}

sub check_loopback_connectivity {
    return if ( $is_up == 0 );

    my @ports     = qw( 25 80 143 );
    my $connected = 0;

    for my $port (@ports) {
        my $sock = IO::Socket::INET->new(
            PeerAddr => '127.0.0.1',
            PeerPort => $port,
            Proto    => 'tcp',
            Timeout  => '1',
        );

        if ($sock) {
            $connected = 1;
            close $sock;
        }

        last if $connected == 1;
    }

    if ( !$connected ) {
        print_warn('Loopback connectivity: ');
        print_warning('could not connect to 127.0.0.1 on ports 25, 80, or 143');
    }
}

1;
