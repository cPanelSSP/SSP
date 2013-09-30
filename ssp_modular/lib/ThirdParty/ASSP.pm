package ThirdParty::ASSP;

use strict;
use warnings;
use diagnostics;
use PrintText;
use Cmd;


sub assp {
    my @port_25_processes;

    my @lsof_25 = split /\n/, run( 'lsof', '-n', '-i', 'tcp:25' );
    if (@lsof_25) {
        for my $line (@lsof_25) {
            if ( $line =~ m{ (\S+) \s+ (?:.*) \s TCP (?:.*):smtp \s \(LISTEN\) }xms ) {
                push( @port_25_processes, $1 );
            }
        }

        if ( grep { m{ \A assp\.pl }xms } @port_25_processes ) {
            print_3rdp('ASSP: ');
            print_warning('assp.pl is listening on port 25');
        }

        if ( grep { m{ \A perl \z }xms } @port_25_processes ) {
            print_3rdp('Exim: ');
            print_3rdp2('something other than Exim found listening on port 25');
        }
    }
}

1;
