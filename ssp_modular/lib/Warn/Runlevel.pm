package Warn::Runlevel;

use strict;
use warnings;
use diagnostics;
use Cmd;
use PrintText;

use Exporter;
our @ISA = qw( Exporter );
our @EXPORT = qw( check_runlevel );

sub check_runlevel {
    my $runlevel;
    my $who_r = run( 'who', '-r' );

    if ( $who_r =~ m{ \A \s+ run-level \s (\d) }xms ) {
        $runlevel = $1;

        if ( $runlevel != 3 ) {
            print_warn('Runlevel: ');
            print_warning("runlevel is not 3 (current runlevel: $runlevel)");
        }
    }
}

1;
