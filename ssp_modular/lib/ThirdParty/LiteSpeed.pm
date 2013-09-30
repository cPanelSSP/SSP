package ThirdParty::LiteSpeed;

use strict;
use warnings;
use diagnostics;
use Vars;
use PrintText;
use Cmd;


sub litespeed {
    my $litespeed = 0;

    for my $line (@process_list) {
        if ( $line =~ /litespeed|lshttp/ and $line !~ /\_/ ) {
            $litespeed = 1;
            last;
        }
    }

    if ( $litespeed == 1 ) {
        print_3rdp('litespeed: ');
        print_3rdp2('is running');
    }
}

1;
