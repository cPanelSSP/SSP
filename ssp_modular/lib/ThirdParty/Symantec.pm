package ThirdParty::Symantec;

use strict;
use warnings;
use diagnostics;
use Vars;
use PrintText;
use Cmd;


sub symantec{
    my $symantec = 0;

    for my $process (@process_list) {
        if ( $process =~ m{ \A root (?:.*) /opt/Symantec/symantec_antivirus }xms ) {
            $symantec = 1;
            last;
        }
    }

    if ( $symantec == 1 ) {
        print_3rdp('Symantec: ');
        print_3rdp2('found /opt/Symantec/symantec_antivirus in process list');
    }
}

1;
