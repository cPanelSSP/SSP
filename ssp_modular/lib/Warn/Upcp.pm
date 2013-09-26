package Warn::Upcp;

use strict;
use warnings;
use diagnostics;
use Cmd;
use PrintText;
use ProcessList;

use Exporter;
our @ISA = qw( Exporter );
our @EXPORT = qw(
    check_if_upcp_is_running
    check_for_stale_upgrade_in_progress_txt
);

sub check_if_upcp_is_running {
    my $upcp_running = 0;

    for my $line (@process_list) {
        if ( $line =~ m{ \A root (?:.*) upcp }xms ) {
            $upcp_running = 1;
            last;
        }
    }

    if ( $upcp_running == 1 ) {
        print_warn('upcp check: ');
        print_warning('upcp is currently running');
    }
}

sub check_for_stale_upgrade_in_progress_txt {
    my $upgradefile = '/usr/local/cpanel/upgrade_in_progress.txt';

    my $upcp_running = 0;
    for my $line (@process_list) {
        if ( $line =~ m{ \A root (?:.*) upcp }xms ) {
            $upcp_running = 1;
            last;
        }
    }

    if ( -e $upgradefile && $upcp_running == 0 ) {
        print_warn("${upgradefile}: ");
        print_warning('exists, but upcp is not running. If Tweak Settings is not loading, this may be why');
    }
}

1;
