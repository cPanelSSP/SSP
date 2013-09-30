package Warn::ModSec;

use strict;
use warnings;
use diagnostics;
use PrintText;


sub check_for_non_default_modsec_rules {
    my @apache_modules_output = @_;
    my $modsec_enabled = 0;

    my $modsec2_conf      = '/usr/local/apache/conf/modsec2.conf';
    my $modsec2_user_conf = '/usr/local/apache/conf/modsec2.user.conf';
    my $modsec_rules_dir  = '/usr/local/apache/conf/modsec_rules';

    for my $module (@apache_modules_output) {
        if ( $module =~ /security2_module/ ) {
            $modsec_enabled = 1;
            last;
        }
    }

    return if ( $modsec_enabled == 0 );

    if ( -f $modsec2_conf ) {
        ## On 11.32.5.9 with EA v3.14.13, default modsec2.conf is 650 bytes.
        ## It's always been small in size.
        my $modsec2_conf_size     = ( stat($modsec2_conf) )[7];
        my $modsec2_conf_max_size = 1200;
        if ( $modsec2_conf_size > $modsec2_conf_max_size ) {
            print_warn('modsec: ');
            print_warning("$modsec2_conf is > $modsec2_conf_max_size bytes, may contain custom rules");
        }
    }

    if ( -f $modsec2_user_conf ) {
        my $modsec2_user_conf_size = ( stat($modsec2_user_conf) )[7];
        if ( $modsec2_user_conf_size != 0 ) {
            print_warn('modsec: ');
            print_warning("$modsec2_user_conf is not empty, may contain rules");
        }
    }

    if ( -d $modsec_rules_dir ) {
        print_warn('modsec: ');
        print_warning("$modsec_rules_dir exists, 3rd party rules may be in use");
    }
}

1;
