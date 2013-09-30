package Warn::Horde;

use strict;
use warnings;
use diagnostics;
use PrintText;


sub check_for_hordepass_newline {
    my $hordepass   = '/var/cpanel/hordepass';
    my $has_newline = 0;

    if ( !-e $hordepass ) {
        print_warn("$hordepass: ");
        print_warning('missing!');
    }
    else {
        if ( open my $hordepass_fh, '<', $hordepass ) {
            while (<$hordepass_fh>) {
                if (/\n/) {
                    $has_newline = 1;
                    last;
                }
            }
            close $hordepass_fh;
        }
    }

    if ( $has_newline == 1 ) {
        print_warn("$hordepass: ");
        print_warning('contains a newline. This can cause leftover cptmpdb_* MySQL dbs. See FB 63364');
    }
}

1;
