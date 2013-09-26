#!/usr/bin/perl

package SSP;

use strict;
use warnings;
use diagnostics;
use lib '../lib';
use Term::ANSIColor qw( :constants );
use Cmd;
use PrintText;
use Tips;
use ProcessList;

use Info::Cpanel;
use Info::HostName;

use Warn::SELinux;
use Warn::Runlevel;
use Warn::Cron;
use Warn::Upcp;
use Warn::Loopback;
use Warn::Cpanel;
use Warn::EasyApache;
use Warn::Apache;
use Warn::Tomcat;
use Warn::Permissions;
use Warn::DiskUsage;
use Warn::PureFTPd;

use ThirdParty::ASSP;
use ThirdParty::Varnish;
use ThirdParty::LiteSpeed;
use ThirdParty::Nginx;
use ThirdParty::MailScanner;
use ThirdParty::APF;
use ThirdParty::CSF;
use ThirdParty::PRM;
use ThirdParty::LES;
use ThirdParty::Webmin;
use ThirdParty::Symantec;
use ThirdParty::HAProxy;

chomp( my $os = lc run( 'uname' ));
if ( $os =~ /freebsd/i ) {
    print "FreeBSD is not supported\n";
    exit;
}

if ( $< != 0 ) {
    die "SSP must be run as root\n";
}

if ( !-d '/usr/local/cpanel' ) {
    die '/usr/local/cpanel not found';
}

{
    local @INC = ( @INC, "/usr/local/cpanel" );
    eval { local $SIG{__DIE__}; local $SIG{__WARN__}; require Cpanel::CachedCommand; };
}

$ENV{'PATH'} = '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin';

my $version = '5.0';

$|                          = 1;
$Term::ANSIColor::AUTORESET = 1;

my %cpconf;
{
    open my $cpconf_fh, '<', '/var/cpanel/cpanel.config';
    local $/ = undef;
    %cpconf  = map { ( split( /=/, $_, 2 ) )[ 0, 1 ] } split( /\n/, readline($cpconf_fh) );
    close $cpconf_fh;
}

my %pureftpdconf;
{
    open my $pureftpdconf_fh, '<', '/etc/pure-ftpd.conf';
    local $/ = undef;
    %pureftpdconf = map { ( split( /\s+/, $_, 2 ) )[ 0, 1 ] } split( /\n/, readline($pureftpdconf_fh) );
    close $pureftpdconf_fh;
}

my $cpanel_version = get_cpanel_version();
my ( $cpanel_version_major, $cpanel_version_minor ) = split /\./, $cpanel_version;

my @apache_version_output;     # httpd -v
my @apache_modules_output;     # httpd -M

if ( -x '/usr/local/apache/bin/httpd' ) {
    @apache_version_output = split /\n/, timed_run( '/usr/local/apache/bin/httpd', '-v' );
    @apache_modules_output = split /\n/, timed_run( '/usr/local/apache/bin/httpd', '-M' );
}

my @local_ipaddrs_list    = get_local_ipaddrs();


sub get_local_ipaddrs {
    my @ifconfig = split /\n/, run( 'ifconfig', '-a' );
    for my $line (@ifconfig) {
        if ( $line =~ m{ (\d+\.\d+\.\d+\.\d+) }xms ) {
            my $ipaddr = $1;
            unless ( $ipaddr =~ m{ \A 127\. }xms ) {
                push @local_ipaddrs_list, $ipaddr;
            }
        }
    }

    return @local_ipaddrs_list;
}


# SSP output can skew ticket system search results
print "\n\n";
for (1..3) {
    print BOLD GREEN ON_RED "\tPlease DO NOT paste output from SSP into tickets unless it is relevant to an issue" . RESET . "\n";
}
print "\n";

# print a useful informational message about cPanel
print_tip();

print BOLD YELLOW ON_BLACK "\tSSP $version\n\n";

## [ INFO ]
print_hostname();

## [ WARN ]
check_selinux_status();
check_runlevel();
check_for_missing_root_cron();
check_roots_cron_for_certain_commands();
check_cron_process();
check_for_harmful_php_mode_600_cron();
check_if_upcp_is_running();
check_for_stale_upgrade_in_progress_txt();
check_cpanelconfig_filetype();
check_cpanelsync_exclude();
check_for_rawopts();
check_for_rawenv();
check_for_custom_opt_mods();
check_for_local_makecpphp_template( $cpanel_version );
check_easy_skip_cpanelsync();
check_for_apache_update_no_restart();
check_for_stale_easyapache_build_file();
check_if_easyapache_is_running();
check_for_easyapache_hooks();
check_for_empty_easyapache_profiles();
check_for_local_apache_templates();
check_for_custom_apache_includes();
check_for_huge_apache_logs();
check_for_empty_apache_templates();
check_for_missing_or_commented_customlog( @apache_version_output );
check_if_httpdconf_ipaddrs_exist( @local_ipaddrs_list );
check_distcache_and_libapr();
check_for_apache_rlimits();
check_for_apache_listen_host_is_localhost();
check_for_var_cpanel_conf_apache_local();
check_for_maxclients_or_maxrequestworkers_reached( @apache_version_output );
check_for_bw_module_and_more_than_1024_vhosts( @apache_modules_output );
check_for_sneaky_htaccess();
check_for_tomcatoptions();
check_for_non_default_permissions( $cpanel_version_major, $cpanel_version_minor );
check_awstats_permissions();
check_disk_space();
check_disk_inodes();
check_var_cpanel_users_files_ownership();
check_root_suspended();
check_for_domain_forwarding();
check_usr_local_cpanel_path_for_symlinks();
check_for_cpanel_files();
check_wwwacctconf_for_incorrect_minuid();
check_for_cpsources_conf();
check_for_extra_uid0_pwcache_file( $cpanel_version_major, $cpanel_version_minor );
check_for_11_30_scripts_not_a_symlink( $cpanel_version );
check_var_cpanel_immutable_files();
check_for_cpanel_CN_newline();
check_cpanel_config_for_low_maxmem( %cpconf );
check_for_empty_or_missing_files();
check_for_C_compiler_optimization();
check_for_fork_bomb_protection();
check_for_cPanel_lower_than_11_30_7_3( $cpanel_version );
check_for_mainip_newline();
check_for_skiphttpauth_disabled();
check_for_use_compiled_dnsadmin();
check_for_jailshell_additional_mounts_trailing_slash();
check_for_invalid_HOMEDIR();
check_pure_ftpd_conf_for_upload_script_and_dead( \%cpconf, \%pureftpdconf );

## [ 3RDP ]
check_for_assp();
check_for_varnish();
check_for_litespeed();
check_for_nginx();
check_for_mailscanner();
check_for_apf();
check_for_csf();
check_for_prm();
check_for_les();
check_for_webmin();
check_for_symantec();
check_for_haproxy();
check_if_loopback_is_up();
check_loopback_connectivity();

1;
