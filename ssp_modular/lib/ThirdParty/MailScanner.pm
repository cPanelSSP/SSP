package ThirdParty::MailScanner;

use strict;
use warnings;
use diagnostics;
use Vars;
use PrintText;
use Cmd;


sub mailscanner {
    my $mailscanner = 0;

    for my $line (@process_list) {
        if ( $line =~ m{ \A mailnull (?:.*) MailScanner }xms ) {
            $mailscanner = 1;
            last;
        }
    }

    if ( $mailscanner == 1 ) {
        print_3rdp('MailScanner: ');
        print_3rdp2('is running');
    }
}

1;
