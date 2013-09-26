package ThirdParty::LiteSpeed;

use strict;
use warnings;
use diagnostics;
use PrintText;
use Cmd;
use ProcessList;

use Exporter;
our @ISA = qw( Exporter );
our @EXPORT = qw( check_for_litespeed );

sub check_for_litespeed {
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
