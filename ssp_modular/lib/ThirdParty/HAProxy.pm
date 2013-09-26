package ThirdParty::HAProxy;

use strict;
use warnings;
use diagnostics;
use PrintText;
use Cmd;
use ProcessList;

use Exporter;
our @ISA = qw( Exporter );
our @EXPORT = qw( check_for_haproxy );

sub check_for_haproxy {
    my $haproxy = 0;

    for my $process (@process_list) {
        if ( $process =~ m{ \A root (?:.*) haproxy }xms ) {
            $haproxy = 1;
            last;
        }
    }

    if ( $haproxy == 1 ) {
        print_3rdp('HAProxy: ');
        print_3rdp2('found haproxy in process list');
    }
}

1;
