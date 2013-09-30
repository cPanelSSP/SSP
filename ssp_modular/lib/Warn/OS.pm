package Warn::OS;

use strict;
use warnings;
use diagnostics;
use Vars;
use Time::Local;
use Cmd;
use PrintText;


sub check_runlevel {
    my $runlevel;
    my $who_r = run( 'who', '-r' );

    if ( $who_r =~ m{ \A \s+ run-level \s (\d) }xms ) {
        $runlevel = $1;

        if ( $runlevel != 3 ) {
            print_warn('Runlevel: ');
            print_warning("runlevel is not 3 (current runlevel: $runlevel)");
        }
    }
}

sub check_selinux_status {
    my @selinux_status = split /\n/, run('sestatus');

    return if !@selinux_status;

    for my $line (@selinux_status) {
        if ( $line =~ m{ \A Current \s mode: \s+ enforcing }xms ) {
            print_warn('SELinux: ');
            print_warning('enabled and enforcing!');
        }
    }
}

sub check_for_gdm {
    my $gdm = 0;

    for my $line (@process_list) {
        if ( $line =~ m{ \A root (?:.*) gdm }xms ) {
            $gdm = 1;
            last;
        }
    }

    if ( $gdm == 1 ) {
        print_warn('gdm Process: ');
        print_warning('is running');
    }
}

sub check_limitsconf {
    my @limitsconf;

    if ( open my $limitsconf_fh, '<', '/etc/security/limits.conf' ) {
        while (<$limitsconf_fh>) {
            push @limitsconf, $_;
        }
        close $limitsconf_fh;
    }

    @limitsconf = grep { !/^(\s+|#)/ } @limitsconf;

    if (@limitsconf) {
        print_warn('limits.conf: ');
        print_warning('custom limits defined in /etc/security/limits.conf!');
    }
}

sub check_for_redhat_firewall {
    my $iptables = run( 'iptables', '-L', 'RH-Firewall-1-INPUT' );

    if ($iptables) {
        print_warn('Default Redhat Firewall Check: ');
        print_warning('RH-Firewall-1-INPUT table exists. /scripts/configure_rh_firewall_for_cpanel to open ports.');
    }
}

sub check_for_home_noexec {
    my @mount = split /\n/, run('mount');

    for my $mount (@mount) {
        if ( $mount =~ m{ \s on \s (/home([^\s]?)) \s (:?.*) noexec }xms ) {
            my $noexec_partition = $1;
            print_warn('mounted noexec: ');
            print_warning($noexec_partition);
        }
    }
}

sub check_for_oracle_linux {
    my $centos_5_oracle_release_file = '/etc/enterprise-release';
    my $centos_6_oracle_release_file = '/etc/oracle-release';

    if ( -f $centos_5_oracle_release_file ) {
        print_warn('Oracle Linux: ');
        print_warning("$centos_5_oracle_release_file detected!");
    }
    elsif ( -f $centos_6_oracle_release_file ) {
        print_warn('Oracle Linux: ');
        print_warning("$centos_6_oracle_release_file detected!");
    }
}

sub check_for_proc_mdstat_recovery {
    my $mdstat = '/proc/mdstat';

    my $recovery = 0;

    if ( open my $mdstat_fh, '<', $mdstat ) {
        while (<$mdstat_fh>) {
            if (/recovery/) {
                $recovery = 1;
                last;
            }
        }
        close $mdstat_fh;
    }

    if ( $recovery == 1 ) {
        print_warn('Software RAID recovery: ');
        print_warning("cat $mdstat to check the status");
    }
}

sub check_for_system_mem_below_512M {
    my $meminfo = '/proc/meminfo';
    my $memtotal;

    if ( open my $meminfo_fh, '<', $meminfo ) {
        while (<$meminfo_fh>) {
            if (m{ \A MemTotal: \s+ (\d+) \s+ kB \s+ \z }xms) {
                $memtotal = $1 / 1024;
                $memtotal =~ s/\..*//g;
            }
        }
        close $meminfo_fh;
    }

    if ( $memtotal < 512 ) {
        print_warn('Memory: ');
        print_warning("Server has less than 512M physical memory! [$memtotal MB]");
    }
}

sub check_for_usr_local_lib_libz_so {
    if ( -f '/usr/local/lib/libz.so' ) {
        print_warn('/usr/local/lib/libz.so: ');
        print_warning('exists. This can prevent EA from completing');
    }
}

sub check_etc_hosts_sanity {
    my $hostname          = shift;
    my $hosts             = '/etc/hosts';
    my $localhost         = 0;
    my $httpupdate        = 0;
    my $localhost_not_127 = 0;
    my $hostname_entry    = 0;

    if ( !-f $hosts ) {
        print_warn('/etc/hosts: ');
        print_warning('missing!');
        return;
    }
    else {
        if ( open my $hosts_fh, '<', $hosts ) {
            while ( my $line = <$hosts_fh> ) {
                chomp $line;

                next if ( $line =~ /^(\s+)?#/ );

                if ( $line =~ m{  127\.0\.0\.1 (.*) localhost }xms ) {
                    $localhost = 1;
                }
                if ( ( $line =~ m{ \s localhost (\s|\z) }xmsi ) and ( $line !~ m{ 127\.0\.0\.1 | ::1 }xms ) ) {
                    $localhost_not_127 = 1;
                }
                if ( $line =~ m{ httpupdate\.cpanel\.net }xmsi ) {
                    $httpupdate = 1;
                }
                if ( $line =~ m{ $hostname }xmsi ) {
                    $hostname_entry = 1;
                }
            }
            close $hosts_fh;
        }
    }

    if ( $localhost == 0 ) {
        print_warn('/etc/hosts: ');
        print_warning('no entry for localhost, or commented out');
    }

    if ( $httpupdate == 1 ) {
        print_warn('/etc/hosts: ');
        print_warning('contains an entry for httpupdate.cpanel.net');
    }

    if ( $localhost_not_127 == 1 ) {
        print_warn('/etc/hosts: ');
        print_warning('contains an entry for "localhost" that isn\'t 127.0.0.1 ! This can break EA');
    }

    if ( $hostname_entry == 0 ) {
        print_warn('/etc/hosts: ');
        print_warning("no entry found for the server's hostname! [$hostname]");
    }
}

sub check_for_kernel_headers_rpm {
    if ( !-f '/usr/include/linux/limits.h' ) {
        print_warn('Missing file: ');
        print_warning('/usr/include/linux/limits.h not found. This can cause problems with EA. kernel-headers RPM missing/broken?');
    }
    else {
        my $rpm_check = run( 'rpm', '-q', 'kernel-headers' );

        if ( $rpm_check =~ /not installed/ ) {
            print_warn('kernel-headers RPM: ');
            print_warning('not found. This can cause problems with EA');
        }
    }
}

sub check_for_low_ulimit_for_root {
    my $ulimit_m = run('echo `ulimit -m`');
    my $ulimit_v = run('echo `ulimit -v`');

    chomp( $ulimit_m, $ulimit_v );

    if ( $ulimit_m =~ /\d+/ ) {
        $ulimit_m = sprintf( '%.0f', $ulimit_m / 1024 );
    }
    if ( $ulimit_v =~ /\d+/ ) {
        $ulimit_v = sprintf( '%.0f', $ulimit_v / 1024 );
    }

    if ( $ulimit_m =~ /\d+/ and $ulimit_m <= 256 or $ulimit_v =~ /\d+/ and $ulimit_v <= 256 ) {
        if ( $ulimit_m =~ /\d+/ ) {
            $ulimit_m .= 'MB';
        }
        if ( $ulimit_v =~ /\d+/ ) {
            $ulimit_v .= 'MB';
        }

        print_warn('ulimit: ');
        print_warning("-m [ $ulimit_m ] -v [ $ulimit_v ] Low ulimits can cause EA to fail when run via the shell");
    }
}

sub check_for_clock_skew {
    my $localtime = time();
    my $rdate_time;
    my $clock_skew;
    my $has_dovecot = 0;

    my %months = qw(
      Jan 0   Feb 1   Mar 2   Apr 3   May 4   Jun 5
      Jul 6   Aug 7   Sep 8   Oct 9   Nov 10  Dec 11
    );

    $rdate_time = run( 'rdate', '-p', '-t', '1', 'rdate.cpanel.net' );

    # fall back to UDP if necessary
    if ( !$rdate_time ) {
        $rdate_time = run( 'rdate', '-p', '-t', '1', '-u', 'rdate.cpanel.net' );
    }

    return if !$rdate_time;

    $rdate_time =~ s/\A rdate: \s \[rdate\.cpanel\.net\] \s+//gxms;

    if ( $rdate_time =~ m{ \A \S+ \s (\S+) \s (\d+) \s (\d+):(\d+):(\d+) \s (\d+) }xms ) {
        my ( $mon, $mday, $hour, $min, $sec, $year ) = ( $1, $2, $3, $4, $5, $6 );
        $mon = $months{$mon};
        $rdate_time = timelocal( $sec, $min, $hour, $mday, $mon, $year );
    }

    return if ( $rdate_time !~ /\d{10}/ );

    $clock_skew = ( $rdate_time - $localtime );
    $clock_skew = abs $clock_skew;                # convert negative numbers to positive

    return if ( $clock_skew < 60 );

    if ( $clock_skew >= 31536000 ) {
        $clock_skew = sprintf '%.1f', ( $clock_skew / 31536000 );
        $clock_skew .= ' years';
    }
    elsif ( $clock_skew >= 86400 ) {
        $clock_skew = sprintf '%.1f', ( $clock_skew / 86400 );
        $clock_skew .= ' days';
    }
    elsif ( $clock_skew >= 3600 ) {
        $clock_skew = sprintf '%.1f', ( $clock_skew / 3600 );
        $clock_skew .= ' hours';
    }
    elsif ( $clock_skew >= 60 ) {
        $clock_skew = sprintf '%.1f', ( $clock_skew / 60 );
        $clock_skew .= ' minutes';
    }

    for my $process (@process_list) {
        if ( $process =~ m{ \A root (.*) dovecot }xms ) {
            $has_dovecot = 1;
            last;
        }
    }

    if ( $has_dovecot == 0 and $clock_skew !~ /minutes/ ) {
        print_warn('Clock skew: ');
        print_warning("servers time may be off by $clock_skew");
    }
    elsif ( $has_dovecot == 1 ) {
        print_warn('Clock skew: ');
        print_warning("server time may be off by ${clock_skew}. This can cause Dovecot to die during upcp");
    }
}

sub check_for_zlib_h {
    if ( -f '/usr/local/include/zlib.h' ) {
        print_warn('/usr/local/include/zlib.h: ');
        print_warning('This file can cause EA to fail with libxml issues. You may need to mv it, run EA again');
    }
}

sub check_for_noxsave_in_grub_conf {
    my $grub_conf   = '/boot/grub/grub.conf';
    my $has_noxsave = 0;

    return if !$grub_conf;

    if ( open my $grub_fh, '<', $grub_conf ) {
        while (<$grub_fh>) {
            if (/noxsave/) {
                $has_noxsave = 1;
                last;
            }
        }
        close $grub_fh;
    }

    if ( $has_noxsave == 1 ) {
        print_warn('noxsave: ');
        print_warning("found in ${grub_conf}. kernel panics? segfaults? see ticket 3689211");
    }
}

sub check_for_networkmanager {
    my $networkmanager_running;

    for my $line (@process_list) {
        if ( $line =~ m{ \A root (?:.*) NetworkManager }xms ) {
            $networkmanager_running = 1;
            last;
        }
    }

    if ( $networkmanager_running && $networkmanager_running == 1 ) {
        print_warn('NetworkManager: ');
        print_warning('found in the process list');
    }
}

sub check_for_dhclient {
    my $dhclient_running;

    for my $line (@process_list) {
        if ( $line =~ m{ \A root (?:.*) dhclient }xms ) {
            $dhclient_running = 1;
            last;
        }
    }

    if ( $dhclient_running && $dhclient_running == 1 ) {
        print_warn('dhclient: ');
        print_warning('found in the process list');
    }
}

sub check_for_missing_etc_localtime {
    if ( !-f '/etc/localtime' ) {
        print_warn('/etc/locatime: ');
        print_warning('Missing! upcp may fail with "Error testing if the RPMs will install" (see ticket 3811269)');
    }
}

sub check_for_immutable_files {
    return if !-x '/usr/bin/lsattr';

    my @path_dirs = split( m{:}, $ENV{'PATH'} );

    foreach my $file ( grep ( m/^-[-]*(?:a|i)/, split( /\n/, run( 'lsattr', @path_dirs ) ) ) ) {
        print_warn('Immutable file: ');
        print_warning("$file");
    }
}

sub check_for_uppercase_chars_in_hostname {
    my $hostname = shift;
    if ( $hostname =~ /[A-Z]/ ) {
        print_warn('Hostname: ');
        print_warning('contains UPPERCASE characters. Seeing incorrect info at cPanel >> Configure Email Client? See ticket 4231465');
    }
}

sub check_for_usr_local_include_jpeglib_h {
    my $jpeglib = '/usr/local/include/jpeglib.h';
    if ( -f $jpeglib ) {
        print_warn( "$jpeglib: " );
        print_warning( 'Seeing "Wrong JPEG library version"? This file may be the cause. See ticket 4159697' );
    }
}

sub check_for_non_default_umask {
    my $umask = run('echo `umask`');

    return if !$umask;

    chomp $umask;

    if ( $umask !~ /2$/ ) {
        print_warn('umask: ');
        print_warning("Non-default value [$umask] (check FB 62683 if permissions error when running convert_roundcube_mysql2sqlite)");
    }
}

sub check_for_extra_uid_0_user {
    my $uid_0_users = 0;

    open my $file_fh, '<', '/etc/passwd' or die $!;
    while (<$file_fh>) {
        if (m{ \A ([^:]+) :x:0: }xms) {
            next if $1 =~ m{ \A root | toor \z }xms;
            $uid_0_users = 1;
            last;
        }
    }
    close $file_fh;

    if ( $uid_0_users == 1 ) {
        print_warn('non-root uid 0 user(s): ');
        print_warning('EasyApache failing with "can\'t create [...] all_iplist.db"? See FB 62467. Do *not* escalate as security issue.');
    }
}

sub check_bash_history_for_certain_commands {
    my $bash_history     = '/root/.bash_history';
    my %history_commands = ();
    my $commands;

    if ( -l $bash_history ) {
        my $link = readlink $bash_history;
        print_warn("$bash_history: ");
        print_warning("is a symlink! Linked to $link");
    }
    elsif ( -f $bash_history ) {
        if ( open my $history_fh, '<', $bash_history ) {
            while (<$history_fh>) {
                if (/chattr/) {
                    $history_commands{'chattr'} = 1;
                }
                if (/chmod/) {
                    $history_commands{'chmod'} = 1;
                }
                if (/openssl(?:.*)\.tar/) {
                    $history_commands{'openssl*.tar'} = 1;
                }
            }
            close $history_fh;
        }
    }

    if (%history_commands) {
        while ( my ( $key, $value ) = each(%history_commands) ) {
            $commands .= "[$key] ";
        }

        print_warn("$bash_history commands found: ");
        print_warning($commands);
    }
}

1;
