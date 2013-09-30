package ThirdParty::Nginx;

use strict;
use warnings;
use diagnostics;
use Vars;
use PrintText;
use Cmd;


sub nginx {
    my $nginx = 0;

    for my $line (@process_list) {
        if ( $line =~ m{ \A root (?:.*) nginx: }xms ) {
            $nginx = 1;
            last;
        }
    }

    if ( $nginx == 1 ) {
        print_3rdp('nginx: ');
        print_3rdp2('is running');
    }
}

1;
