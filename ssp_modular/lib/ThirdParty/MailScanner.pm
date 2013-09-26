package ThirdParty::MailScanner;

use strict;
use warnings;
use diagnostics;
use PrintText;
use Cmd;
use ProcessList;

use Exporter;
our @ISA = qw( Exporter );
our @EXPORT = qw( check_for_mailscanner );

sub check_for_mailscanner {
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
