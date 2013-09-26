package Warn::Permissions;

use strict;
use warnings;
use diagnostics;
use Cmd;
use PrintText;

use Exporter;
our @ISA = qw( Exporter );
our @EXPORT = qw(
    check_for_non_default_permissions
    check_awstats_permissions
);

sub check_for_non_default_permissions {
    my ( $cpanel_version_major, $cpanel_version_minor ) = @_;

    my %resources_and_perms = (
        '/'                            => '755',
        '/bin'                         => '755',
        '/bin/bash'                    => '755',
        '/dev/null'                    => '666',
        '/etc/group'                   => '644',
        '/etc/hosts'                   => '644',
        '/etc/nsswitch.conf'           => '644',
        '/etc/passwd'                  => '644',
        '/etc/stats.conf'              => '644',
        '/opt'                         => '755',
        '/root/cpanel3-skel'           => '755',
        '/sbin'                        => '755',
        '/tmp'                         => '1777',
        '/usr'                         => '755',
        '/usr/bin'                     => '755',
        '/usr/sbin'                    => '755',
        '/usr/local/apache'            => '755',
        '/usr/local/apache/bin/httpd'  => '755',
        '/usr/local/bin'               => '755',
        '/usr/local/sbin'              => '755',
        '/var'                         => '755',
        '/var/cpanel'                  => '755',
        '/var/cpanel/features'         => '755',
        '/var/cpanel/locale'           => '755',
        '/var/cpanel/resellers'        => '644',
        '/var/tmp'                     => '1777',
        '/usr/local/cpanel/php/cpanel.php'  => '644',
        '/usr/local/cpanel/base/3rdparty/roundcube/plugins/cpanellogin/cpanellogin.php' => '644',
        '/usr/local/cpanel/base/3rdparty/phpMyAdmin/index.php'  => '644',
        '/usr/local/cpanel/base/3rdparty/phpPgAdmin/index.php'  => '644',
        '/usr/local/cpanel/base/3rdparty/roundcube/index.php'   => '644',
        '/usr/local/cpanel/base/horde/index.php'                => '644',
        '/usr/local/cpanel/base/3rdparty/squirrelmail/index.php'    => '644',
    );

    for my $resource ( keys %resources_and_perms ) {
        if ( -e $resource ) {
            my $mode = ( stat($resource) )[2] & 07777;
            $mode = sprintf "%lo", $mode;
            if ( $mode != $resources_and_perms{$resource} ) {
                next if ( $resource =~ '^(/(s?)bin|/usr/(s?)bin|/)$' and $mode == 555 );                  # CentOS 6.2+
                next if ( $resource =~ '^/(var|sbin|usr/local/sbin|usr|usr/sbin)?$' and $mode == 711 );
                print_warn('Non-default Permissions: ');
                print_warning("$resource (mode: $mode | default: $resources_and_perms{$resource})");
            }
        }
    }

    ## cPanel changes /etc/shadow from 0400 to 0600 (and possibly 0200?)
    if ( -e '/etc/shadow' ) {
        my $mode = ( stat('/etc/shadow') )[2] & 07777;
        $mode = sprintf "%lo", $mode;
        if ( $mode != 600 and $mode != 400 and $mode != 200 ) {
            print_warn('Non-default Permissions: ');
            print_warning("/etc/shadow (mode: $mode | default: 0400 or 0600)");
        }
    }

    if ( -e '/usr/bin/crontab' ) {
        my $mode = ( stat('/usr/bin/crontab') )[2] & 07777;
        $mode = sprintf "%lo", $mode;
        if ( $mode != 4755 and $mode != 6755 and $mode != 4555 ) {
            print_warn('Non-default Permissions: ');
            print_warning("/usr/bin/crontab (mode: $mode | default: 4755 or 6755 or 4555)");
        }
    }

    if ( -e '/usr/bin/passwd' ) {
        my $mode = ( stat('/usr/bin/passwd') )[2] & 07777;
        $mode = sprintf "%lo", $mode;
        if ( $mode !~ m{ \A ( 4755 | 6755 | 4511 | 4555 ) \z }xms ) {
            print_warn('Non-default Permissions: ');
            print_warning("/usr/bin/passwd (mode: $mode | default: 4755 or 6755 or 4511 or 4555)");
        }
    }

    if ( -e '/sbin/ifconfig' ) {
        my $mode = ( stat('/sbin/ifconfig') )[2] & 07777;
        $mode = sprintf "%lo", $mode;
        if ( $mode != 755 and $mode != 555 ) {
            print_warn('Non-default Permissions: ');
            print_warning("/sbin/ifconfig (mode: $mode | default: 755 or 555)");
        }
    }

    if ( -e '/bin/ln' ) {
        my $mode = ( stat('/bin/ln') )[2] & 07777;
        $mode = sprintf "%lo", $mode;
        if ( $mode != 755 and $mode != 555 ) {
            print_warn('Non-default Permissions: ');
            print_warning("/bin/ln (mode: $mode | default: 755 or 555)");
        }
    }

    if ( -e '/usr/local/cpanel/bin/cpwrap' ) {
        my $mode = ( stat('/usr/local/cpanel/bin/cpwrap') )[2] & 07777;
        $mode = sprintf "%lo", $mode;
        if ( ( $cpanel_version_major <= 11 ) and ( $cpanel_version_minor <= 36 ) ) {
            if ( $mode != 4755 ) {
                print_warn('Non-default Permissions: ');
                print_warning("/usr/local/cpanel/bin/cpwrap (mode: $mode | default: 4755 )");
            }
        }
        else {
            if ( $mode != 755 ) {
                print_warn('Non-default Permissions: ');
                print_warning("/usr/local/cpanel/bin/cpwrap (mode: $mode | default: 0755 )");
            }
        }
    }
}

sub check_awstats_permissions {
    my $cpanel_config = '/var/cpanel/cpanel.config';
    my $awstats       = '/usr/local/cpanel/3rdparty/bin/awstats.pl';
    my $skipawstats   = 0;

    return if !-e $cpanel_config;

    if ( open my $cpanel_config_fh, '<', $cpanel_config ) {
        while (<$cpanel_config_fh>) {
            if (/^skipawstats=(\d)/) {
                $skipawstats = $1;
            }
        }
        close $cpanel_config_fh;
    }

    if ( $skipawstats == 0 ) {
        if ( -e $awstats ) {
            my $mode = ( stat($awstats) )[2] & 07777;
            $mode = sprintf "%lo", $mode;
            if ( $mode != 755 ) {
                print_warn('Awstats: ');
                print_warning(" enabled, but $awstats isn't 755 !");
            }
        }
    }
}

1;
