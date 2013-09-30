package Warn::Perl;

use strict;
use warnings;
use diagnostics;
use Cmd;
use PrintText;


sub check_for_PERL5LIB_env_var {
    my $PERL5LIB = $ENV{'PERL5LIB'};

    if ($PERL5LIB) {
        print_warn('PERL5LIB env var: ');
        print_warning('exists! This can break cPanel\'s perl. See FB 64265');
    }
}

sub check_for_broken_list_util {
    if ( -e '/usr/bin/perl' and -x '/usr/bin/perl' ) {
        system('/usr/bin/perl', '-MList::Util', '-e', '1');
        if ($?) {
            print_warn('List::Util: ');
            print_warning('seems broken. To fix, run this: /scripts/autorepair scalarutil');
        }
    }
}

sub check_perl_version_less_than_5_8 {
    my ( $perl_version_major, $perl_version_minor, $perl_version_patch );
    my @perl_v = split /\n/, cached_run( 'perl', '-v' );

    my $perl_version;
    for my $line (@perl_v) {
        if ( $line =~ m{ \A This \s is \s perl, \s v((\d+)\.(\d+)\.(?:\d+)) \s }xms ) {
            $perl_version = $1;
            ( $perl_version_major, $perl_version_minor ) = ( $2, $3 );
            last;
        }
    }

    return if !$perl_version;

    if (( $perl_version_major < 5 ) or ( $perl_version_major == 5 and $perl_version_minor < 8 )) {
        print_warn('Perl Version: ');
        print_warning("less than 5.8: $perl_version");
    }
}

sub check_perl_sanity {
    my $usr_bin_perl       = '/usr/bin/perl';
    my $usr_local_bin_perl = '/usr/local/bin/perl';

    if ( !-e $usr_bin_perl ) {
        print_warn('perl: ');
        print_warning("$usr_bin_perl does not exist!");
    }

    if ( -l $usr_bin_perl and -l $usr_local_bin_perl ) {
        my $usr_bin_perl_link       = readlink $usr_bin_perl;
        my $usr_local_bin_perl_link = readlink $usr_local_bin_perl;
        if ( -l $usr_bin_perl_link and -l $usr_local_bin_perl_link ) {
            print_warn('perl: ');
            print_warning("$usr_bin_perl and $usr_local_bin_perl are both symlinks!");
        }
    }

    ## a symlink will test true for both -x AND -l
    if ( -x $usr_bin_perl and !-l $usr_bin_perl ) {
        if ( -x $usr_local_bin_perl and !-l $usr_local_bin_perl ) {
            print_warn('perl: ');
            print_warning("$usr_bin_perl and $usr_local_bin_perl are both binaries!");
        }
    }

    if ( -x $usr_bin_perl and !-l $usr_bin_perl ) {
        my $mode = ( stat($usr_bin_perl) )[2] & 07777;
        $mode = sprintf "%lo", $mode;
        if ( $mode != 755 ) {
            print_warn('Perl Permissions: ');
            print_warning("$usr_bin_perl is $mode");
        }
    }

    if ( -x $usr_local_bin_perl and !-l $usr_local_bin_perl ) {
        my $mode = ( stat($usr_local_bin_perl) )[2] & 07777;
        $mode = sprintf "%lo", $mode;
        if ( $mode != 755 ) {
            print_warn('Perl Permissions: ');
            print_warning("$usr_local_bin_perl is $mode");
        }
    }
}

sub check_for_missing_perl_modules {
    for my $module ( 'Digest::SHA1', 'Crypt::PasswdMD5' ) {
        my $output = run_trap_stderr( '/usr/bin/perl', '-M' . $module, '-e', "print q{ok};" );
        if ( $output ne 'ok' ) {
            print_warn("Missing perl module (see FB 64015): ");
            print_warning("$module: $output");
        }
    }
}

1;
