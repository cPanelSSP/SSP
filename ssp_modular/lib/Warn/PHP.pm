package Warn::PHP;

use strict;
use warnings;
use diagnostics;
use Cmd;
use PrintText;


sub check_for_sql_safe_mode {
    my @phpinis = qw(
        /usr/local/lib/php.ini
        /usr/local/php4/lib/php.ini
    );

    for my $phpini (@phpinis) {
        if ( open my $file_fh, '<', $phpini ) {
            while (<$file_fh>) {
                chomp( my $line = $_ );
                if ( $line =~ m{ \A sql\.safe_mode \s* = \s* on }ixms ) {
                    print_warn("$phpini: ");
                    print_warning('sql.safe_mode is enabled!');
                }
            }
            close $file_fh;
        }
    }
}

sub check_for_missing_timezone_from_phpini {
    my $phpini = '/usr/local/lib/php.ini';

    return if !-f $phpini;

    my $timezone;

    if ( open my $phpini_fh, '<', $phpini ) {
        while (<$phpini_fh>) {
            my $line = $_;
            chomp $line;
            if ( $line =~ m{ \A date\.timezone (?:\s+)? = (?:\s+)? (?:["'])? ([^/"']+) / ([^/"']+) (?:["'])? (?:\s+)? \z }xms ) {
                $timezone = $1 . '/' . $2;
                last;
            }
        }
        close $phpini_fh;
    }

    if ($timezone) {
        my ( $tz1, $tz2 ) = split /\//, $timezone;
        my $path = '/usr/share/zoneinfo/' . $tz1 . '/' . $tz2;

        if ( !-f $path ) {
            print_warn("date.timezone from $phpini: ");
            print_warning("$path not found!");
        }
    }
}

sub check_pecl_phpini_location {
    my $pecl_phpini = run( 'pecl', 'config-get', 'php_ini' );
    chomp $pecl_phpini;
    if ( $pecl_phpini and $pecl_phpini =~ /cpanel/ ) {
        print_warn('pecl php.ini: ');
        print_warning("'pecl config-get php_ini' shows php.ini path of $pecl_phpini . See FB 59764 for more info");
    }
}

sub check_for_homeloader_php_extension {
    my $php_ini        = '/usr/local/lib/php.ini';
    my $has_homeloader = 0;

    if ( open my $file_fh, '<', $php_ini ) {
        while (<$file_fh>) {
            if (m{ \A ([\s\t]+)? extension ([\s\t]+)? = ([\s\t]+)? ["']? homeloader\.so ['"]? }xms) {
                print_warn('php module: ');
                print_warning("homeloader.so found in ${php_ini}. This can cause errors. See FB 4471 and 63838");
                last;
            }
        }
        close $php_ini;
    }
}

sub check_for_phphandler_and_opcode_caching_incompatibility {
    my $php_conf_yaml = '/usr/local/apache/conf/php.conf.yaml';
    return if !-e $php_conf_yaml;

    my $using_suphp = 0;

    if ( open my $file_fh, '<', $php_conf_yaml ) {
        while ( <$file_fh> ) {
            if ( /^php5:[ \t]+['"]?suphp/ ) {
                $using_suphp = 1;
            }
        }
        close $file_fh;
    }
    else {
        return;
    }

    my $has_eaccelerator    = 0;
    my $has_xcache          = 0;
    my $has_apc             = 0;

    if ( $using_suphp == 1 ) {
        if ( open my $phpconf_fh, '<', '/usr/local/lib/php.ini' ) {
            while ( <$phpconf_fh> ) {
                if ( m{ \A ([\s\t]+)? extension ([\s\t]+)? = ([\s\t]+)? ["']? eaccelerator\.so ['"]? }xms) {
                    $has_eaccelerator = 1;
                }
                elsif ( m{ \A ([\s\t]+)? extension ([\s\t]+)? = ([\s\t]+)? ["']? xcache\.so ['"]? }xms) {
                    $has_xcache = 1;
                }
                elsif ( m{ \A ([\s\t]+)? extension ([\s\t]+)? = ([\s\t]+)? ["']? apc\.so ['"]? }xms) {
                    $has_apc = 1;
                }
            }
            close $phpconf_fh;
        }
        else {
            return;
        }
    }
    else {
        return;
    }

    my $message;
    if ( $has_eaccelerator == 1 ) {
        $message = '[eAccelerator] ';
    }
    if ( $has_xcache == 1 ) {
        $message .= '[XCache] ';
    }
    if ( $has_apc == 1 ) {
        $message .= '[APC] ';
    }

    if ($message) {
        print_warn('PHP: ');
        print_warning("suPHP enabled, but the following installed opcode cachers are not suPHP compatible: $message");
    }
}

1;
