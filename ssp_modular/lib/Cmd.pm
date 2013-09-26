package Cmd;

use strict;
use warnings;

use Exporter;
our @ISA = qw( Exporter );
our @EXPORT = qw(
    run
    timed_run
);


sub run {
    my $cmdline = \@_;
    my $output;

    local ($/);
    my ( $pid, $prog_fh );

    open STDERR, '>', '/dev/null';
    if ( $pid = open( $prog_fh, '-|' ) ) {

    }
    else {
        ( $ENV{'PATH'} ) = $ENV{'PATH'} =~ m/(.*)/;    # untaint, FB 6622
        exec(@$cmdline);
        exit(127);
    }
    close STDERR;

    if ( !$prog_fh || !$pid ) {
        $? = -1;

        return \$output;
    }
    $output = readline($prog_fh);
    close($prog_fh);

    return $output;
}

sub timed_run {
    eval { local $SIG{__DIE__}; local $SIG{__WARN__}; require Cpanel::SafeRun::Timed; };

    if ( !$@ && $INC{'Cpanel/SafeRun/Timed.pm'} ) {
        open( my $save_stderr_fh, '>&STDERR' );
        open( STDERR, '>', '/dev/null' );
        my $result = Cpanel::SafeRun::Timed::timedsaferun( 10, @_ );
        open( STDERR, '>&=' . fileno($save_stderr_fh) );
        return $result;
    }
    goto \&run;
}

1;
