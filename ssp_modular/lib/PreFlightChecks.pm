package PreFlightChecks;

use strict;
use warnings;
use Cmd;
use Vars;
use Term::ANSIColor qw( :constants );


sub print_nopaste {
    # SSP output can skew ticket system search results
    print "\n\n";
    for (1..3) {
        print BOLD GREEN ON_RED "\tPlease DO NOT paste output from SSP into tickets unless it is relevant to an issue" . RESET . "\n";
    }
    print "\n";
}

sub print_ssp_version {
    print BOLD YELLOW ON_BLACK "\tSSP $version\n\n";
}

sub check_for_freebsd {
    chomp( my $os = lc run( 'uname' )); 
    if ( $os =~ /freebsd/i ) { 
        print "FreeBSD is not supported\n";
        exit;
    }
}

sub check_if_root {
    if ( $< != 0 ) { 
        print "SSP must be run as root\n";
        exit;
    }
}

sub check_for_cpanel {
    if ( !-d '/usr/local/cpanel' ) { 
        print "/usr/local/cpanel not found\n";
        exit;
    }
}

1;
