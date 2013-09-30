package ThirdParty::Varnish;

use strict;
use warnings;
use diagnostics;
use PrintText;
use Cmd;


sub varnish {
    my @port_80_processes;

    my @lsof_80 = split /\n/, run( 'lsof', '-n', '-i', 'tcp:80' );
    for my $line (@lsof_80) {
        if ( $line =~ m{ (\S+) \s+ (?:.*) \s TCP (?:.*):http \s \(LISTEN\) }xms ) {
            push( @port_80_processes, $1 );
        }
    }

    if ( grep { m{ \A varnish }xms } @port_80_processes ) {
        print_3rdp('Varnish: ');
        print_3rdp2('varnish is listening on port 80');
    }
}

1;
