package ThirdParty::CSF;

use strict;
use warnings;
use diagnostics;
use PrintText;
use Cmd;
use ProcessList;

use Exporter;
our @ISA = qw( Exporter );
our @EXPORT = qw( check_for_csf );

sub check_for_csf {
    my $lfd = 0;
    my $csf = run( 'whereis', 'csf' );

    if ( $csf and $csf =~ /\// ) {
        print_3rdp('CSF: ');
    }
    else {
        return;
    }

    for my $line (@process_list) {
        if ( $line =~ m{ \A root (?:.*) lfd }xms ) {
            $lfd = 1;
            last;
        }
    }

    if ($lfd == 1) {
        print_3rdp2('installed, LFD is running');
    }
    else {
         print_3rdp2('installed, LFD is not running');
    }
}

1;
