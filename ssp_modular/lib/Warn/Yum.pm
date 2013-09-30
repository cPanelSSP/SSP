package Warn::Yum;

use strict;
use warnings;
use diagnostics;
use PrintText;

my $yumconf = '/etc/yum.conf';

sub check_for_missing_yumconf {
    if ( !-e $yumconf ) {
        print_warn('YUM: ');
        print_warning("$yumconf is missing!");
    }
}

sub check_for_empty_yumconf {
    if ( -e $yumconf and -z $yumconf ) {
        print_warn('Yum: ');
        print_warning("$yumconf is empty!");
    }
}

sub check_for_wget_exclude {
    return if ( !-e $yumconf );

    if ( open( my $yum_conf_fh, '<', '/etc/yum.conf' ) ) {
        local $/ = undef;
        my $yum_conf_text = readline($yum_conf_fh);
        if ( $yum_conf_text =~ m/exclude=.*?wget/ ) {
            print_warn('YUM: ');
            print_warning("$yumconf has wget excluded!");
        }
    }
}

sub check_for_odd_yumconf {
    return if ( !-e $yumconf );

    my $exclude_line_count = 0;
    my $exclude_kernel     = 0;

    if ( open my $file_fh, '<', $yumconf ) {
        while (<$file_fh>) {
            if (/^exclude/i) {
                $exclude_line_count += 1;
            }
            if (/exclude(.*)kernel/) {
                $exclude_kernel = 1;
            }
        }
        close $file_fh;
    }

    if ( $exclude_line_count > 1 ) {
        print_warn('yum.conf: ');
        print_warning('contains multiple "exclude" lines! See FB 63311');
    }

    if ( $exclude_kernel == 1 ) {
        print_warn('yum.conf: ');
        print_warning('may be excluding kernel updates! See FB 63311');
    }
}

1;
