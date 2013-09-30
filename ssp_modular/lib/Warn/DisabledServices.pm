package Warn::DisabledServices;

use strict;
use warnings;
use diagnostics;
use PrintText;


sub check_for_disabled_services {
    my ( @disabled_services );
    my $disabled;

    my %touchfiles = (
        '/etc/ftpddisable'          => 'ftpd',
        '/etc/ftpserverdisable'     => 'ftpd',
        '/etc/sshddisable'          => 'sshd',
        '/etc/eximdisable'          => 'exim',
        '/etc/httpddisable'         => 'httpd',
        '/etc/imapdisable'          => 'imapd',
        '/etc/imapddisable'         => 'imapd',
        '/etc/nameddisable'         => 'named',
        '/etc/binddisable'          => 'named',
        '/etc/dnsdisable'           => 'named',
        '/etc/nsddisable'           => 'nsd',
        '/etc/mydnsdisable'         => 'mydns',
        '/etc/mysqldisable'         => 'mysql',
        '/etc/postgresdisable'      => 'postgresql',
        '/etc/postgresqldisable'    => 'postgresql',
        '/etc/postmasterdisable'    => 'postgresql',
        '/etc/clamddisable'         => 'clamd',
        '/etc/antirelayddisable'    => 'antirelayd',
        '/etc/tailwatchddisable'    => 'tailwatchd',
        '/var/cpanel/version/securetmp_disabled'    => 'securetmp',
        '/etc/queueprocddisable'    => 'queueprocd',
        '/etc/spamdisable'          => 'spamd',
        '/etc/mailmandisable'       => 'mailman',
        '/etc/ipaliasesdisable'     => 'ipaliases',
        '/etc/cpsrvdddisable'       => 'cpsrvd',
        '/etc/cpdavddisable'        => 'cpdavd',
        '/etc/cpanellogddisable'    => 'cpanellogd',
        '/etc/rsyslogdisable'       => 'rsyslogd',
        '/etc/syslogdisable'        => 'syslogd',
        '/etc/disablehackcheck'     => 'hackcheck',
    );

    while ( my ( $touchfile, $service ) = each ( %touchfiles ) ) {
        if ( -e $touchfile ) {
            if ( ! grep { /^${service}$/ } @disabled_services ) {
                push @disabled_services, $touchfiles{$touchfile};
            }
        }
    }

    return if !@disabled_services;

    for my $service ( @disabled_services ) {
        $disabled .= "[$service] ";
    }

    print_warn('Disabled services: ');
    print_warning($disabled);
}

1;
