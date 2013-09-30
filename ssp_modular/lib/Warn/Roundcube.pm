package Warn::Roundcube;

use strict;
use warnings;
use diagnostics;
use PrintText;


sub check_for_var_cpanel_roundcube_install {
    my $install = '/var/cpanel/roundcube/install';

    if ( -f $install and -x $install ) {
        print_warn('RoundCube: ');
        print_warning("$install exists. /u/l/c/b/update-roundcube won't fully run (by design - see the docs)");
    }
}

sub check_roundcube_mysql_pass_mismatch {
    my $roundcube_mysql = 0;
    my $roundcubepass;
    my $rc_mysql_pass;

    if ( open my $cpanelconf_fh, '<', '/var/cpanel/cpanel.config' ) {
        while (<$cpanelconf_fh>) {
            if (/roundcube_db=mysql/) {
                $roundcube_mysql = 1;
                last;
            }
        }
        close $cpanelconf_fh;
    }

    return if ( $roundcube_mysql == 0 );

    if ( open my $rc_pass_fh, '<', '/var/cpanel/roundcubepass' ) {
        while (<$rc_pass_fh>) {
            chomp( $roundcubepass = $_ );
        }
        close $rc_pass_fh;
    }
    else {
        return;
    }

    if ( open my $db_inc_fh, '<', '/usr/local/cpanel/base/3rdparty/roundcube/config/db.inc.php' ) {
        while (<$db_inc_fh>) {
            if (m{ \A \$rcmail_config\['db_dsnw'\] \s = \s 'mysql://roundcube:(.*)\@(?:.*)/roundcube';  }xms) {
                $rc_mysql_pass = $1;
            }
        }
        close $db_inc_fh;
    }
    else {
        return;
    }

    if ( !$roundcubepass or !$rc_mysql_pass ) {
        return;
    }

    if ( $roundcubepass ne $rc_mysql_pass ) {
        print_warn('RoundCube: ');
        print_warning('password mismatch [/var/cpanel/roundcubepass] [/usr/local/cpanel/base/3rdparty/roundcube/config/db.inc.php]');
    }
}

1;
