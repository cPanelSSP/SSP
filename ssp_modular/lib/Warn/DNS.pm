package Warn::DNS;

use strict;
use warnings;
use diagnostics;
use PrintText;


## This is already fixed: http://rhn.redhat.com/errata/RHBA-2012-1158.html
sub check_for_options_rotate_redhat_centos_63 {
    my $sysinfo_config = '/var/cpanel/sysinfo.config';
    my $os_release;
    my $resolv_conf    = '/etc/resolv.conf';
    my $options_rotate = 0;

    if ( open my $sysinfo_config_fh, '<', $sysinfo_config ) {
        while ( my $line = <$sysinfo_config_fh> ) {
            if ( $line =~ m{ \A release=(\d\.\d) }xms ) {
                $os_release = $1;
                last;
            }
        }
        close $sysinfo_config_fh;
    }

    if ( $os_release and $os_release eq '6.3' ) {
        if ( open my $resolv_conf_fh, '<', $resolv_conf ) {
            while ( my $line = <$resolv_conf_fh> ) {
                if ( $line =~ m{ options \s+ rotate }xms ) {
                    $options_rotate = 1;
                    last;
                }
            }
            close $resolv_conf_fh;
        }
    }

    if ( $options_rotate == 1 ) {
        print_warn('RH/CentOS 6.3 resolv.conf: ');
        print_warning('contains "options rotate", can break lookups. See FB 60347. Already fixed upstream.');
    }
}

sub check_for_allow_query_localhost {
    my $named_conf = '/etc/named.conf';
    return if !-f $named_conf;

    my $allow_query_localhost = 0;

    my $namedconf_contents;
    if ( open my $named_conf_fh, '<', $named_conf ) {
        local $/;
        $namedconf_contents = <$named_conf_fh>;
        close $named_conf_fh;
    }
    else {
        return;
    }

    if ( $namedconf_contents =~ m#allow-query ([\s\t\r\n]+)? { ([\s\t]+)? ( localhost | 127\. )#xms ) {
        $allow_query_localhost = 1;
    }

    if ( $allow_query_localhost == 1 ) {
        print_warn('named.conf: ');
        print_warning('allow-query is restricted to localhost. Remote DNS queries may not work');
    }
}

sub check_for_bad_permissions_on_named_ca {
    my $namedca = '/var/named/named.ca';
    if ( !-e $namedca ) {
        print_warn("${namedca}: ");
        print_warning('missing. named may not start without it');
        return;
    }

    my ( $mode, $uid, $gid ) = (stat('/var/named/named.ca'))[2,4,5];
    my $world_readable_bit = $mode & 007;
    my $user = getpwuid($uid);
    my $group = getgrgid($gid);

    if (($user ne 'named' and $group ne 'named') and ($world_readable_bit == 0)) {
        print_warn("${namedca}: ");
        print_warning('may not be readable to the \'named\' user, causing named to not restart');
    }
}

1;
