package ThirdParty::HAProxy;

use strict;
use warnings;
use diagnostics;
use Vars;
use PrintText;
use Cmd;


sub haproxy {
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
