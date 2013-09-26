package Warn::Cpanel;

use strict;
use warnings;
use diagnostics;
use Cmd;
use PrintText;

use Exporter;
our @ISA = qw( Exporter );
our @EXPORT = qw(
    check_cpanelconfig_filetype
    check_cpanelsync_exclude
    check_var_cpanel_users_files_ownership
    check_root_suspended
    check_for_domain_forwarding
    check_usr_local_cpanel_path_for_symlinks
    check_for_cpanel_files
    check_wwwacctconf_for_incorrect_minuid
    check_for_cpsources_conf
    check_for_extra_uid0_pwcache_file
    check_for_11_30_scripts_not_a_symlink
    check_var_cpanel_immutable_files
    check_for_cpanel_CN_newline
    check_cpanel_config_for_low_maxmem
    check_for_empty_or_missing_files
    check_for_C_compiler_optimization
    check_for_fork_bomb_protection
    check_for_cPanel_lower_than_11_30_7_3
    check_for_mainip_newline
    check_for_skiphttpauth_disabled
    check_for_use_compiled_dnsadmin
    check_for_jailshell_additional_mounts_trailing_slash
    check_for_invalid_HOMEDIR
    check_pkgacct_override
);

sub check_cpanelconfig_filetype {
    if ( !-e '/var/cpanel/cpanel.config' ) {
        print_warn('/var/cpanel/cpanel.config: ');
        print_warning('missing!');
    }
    else {
        chomp( my $file = run( 'file', '/var/cpanel/cpanel.config' ) );
        if ( $file !~ m{ \A /var/cpanel/cpanel.config: \s ASCII \s text \z }xms ) {
            print_warn('/var/cpanel/cpanel.config: ');
            print_warning("filetype is something other than 'ASCII text'! ($file)");
        }
    }
}

sub check_cpanelsync_exclude {
    my $cpanelsync_exclude    = '/etc/cpanelsync.exclude';
    my $rpmversions_file      = '/usr/local/cpanel/etc/rpm.versions';
    my $excluding_rpmversions = 0;

    return if ( -f $cpanelsync_exclude and -z $cpanelsync_exclude );

    if ( open my $file_fh, '<', $cpanelsync_exclude ) {
        while (<$file_fh>) {
            chomp;
            if (m{ \A \s* $rpmversions_file \s* \z }xms) {
                $excluding_rpmversions = 1;
                last;
            }
        }
        close $file_fh;
    }

    if ( $excluding_rpmversions == 1 ) {
        print_warn('cpanelsync exclude: ');
        print_warning("$rpmversions_file found! This should NEVER be done!");
    }
    else {
        print_warn('cpanelsync exclude: ');
        print_warning("$cpanelsync_exclude is not empty!");
    }
}

sub check_var_cpanel_users_files_ownership {
    my $var_cpanel_users = '/var/cpanel/users';

    my @files;
    if ( -d $var_cpanel_users ) {
        opendir( my $dir_fh, $var_cpanel_users );
        @files = grep { !m/^(?:\.(\.?)|root|system|nobody)$/ } readdir $dir_fh;
        closedir $dir_fh;
    }

    my $group_root_files;
    for my $file (@files) {
        next if ( $file !~ /^[a-z0-9]+$/ );
        my $gid = ( stat( '/var/cpanel/users/' . $file ) )[5];
        if ( $gid == 0 ) {
            $group_root_files .= " $file";
        }
    }

    if ($group_root_files) {
        print_warn('/v/c/users file(s) owned by group "root": ');
        print_warning($group_root_files);
    }
}

sub check_root_suspended {
    if ( -e '/var/cpanel/suspended/root' ) {
        print_warn('root suspended: ');
        print_warning('the root account is suspended! Unsuspend it to avoid problems.');
    }
}

sub check_for_domain_forwarding {
    my $domainfwdip = '/var/cpanel/domainfwdip';

    if ( -f $domainfwdip and !-z $domainfwdip ) {
        print_warn('Domain Forwarding: ');
        print_warning("cat $domainfwdip to see what is being forwarded!");
    }
}

sub check_usr_local_cpanel_path_for_symlinks {
    my @dirs = qw(  /usr
      /usr/local
      /usr/local/cpanel
    );

    for my $dir (@dirs) {
        if ( -l $dir ) {
            print_warn('Directory is a symlink: ');
            print_warning("$dir (this can cause Internal Server Errors for redirects like /cpanel, etc)");
        }
    }
}

sub check_for_cpanel_files {
    my @files = qw(
      /usr/local/cpanel/cpanel
      /usr/local/cpanel/cpsrvd
      /usr/local/cpanel/cpsrvd-ssl
    );

    for my $file (@files) {
        if ( !-e $file ) {
            print_warn('Critical file missing: ');
            print_warning("$file");
        }
    }
}

sub check_wwwacctconf_for_incorrect_minuid {
    my $wwwacctconf = '/etc/wwwacct.conf';
    my $minuid;

    if ( open my $wwwacctconf_fh, '<', $wwwacctconf ) {
        while (<$wwwacctconf_fh>) {
            if (/^MINUID\s(\d+)$/) {
                $minuid = $1;
            }
        }
        close $wwwacctconf_fh;
    }

    if ( $minuid and $minuid =~ /\d+/ ) {
        if ( $minuid < 500 or $minuid > 60000 ) {
            print_warn('MINUID: ');
            print_warning("$wwwacctconf has a MINUID value of $minuid (should be between 500 and 60000)");
        }
    }
}

sub check_for_cpsources_conf {
    my $cpsources_conf = '/etc/cpsources.conf';

    if ( -f $cpsources_conf and !-z $cpsources_conf ) {
        print_warn('/etc/cpsources.conf: ');
        print_warning('exists!');
    }
}

# Fixed in 11.36.1.3, case 62467
sub check_for_extra_uid0_pwcache_file {
    my ( $cpanel_version_major, $cpanel_version_minor ) = @_;
    return if ($cpanel_version_major <= 11 and $cpanel_version_minor > 36);
    if ( -f '/var/cpanel/pw.cache/2:0' ) {
        print_warn('MySQL: ');
        print_warning('/var/cpanel/pw.cache/2:0 exists. If MySQL shows as offline in cPanel, please update FB 59670');
    }
}

sub check_for_11_30_scripts_not_a_symlink {
    my $cpanel_version = shift;
    my ( $v1, $v2 ) = split /\./, $cpanel_version;

    if ( ( $v1 > 11 ) || ( ( $v1 == 11 ) and ( $v2 >= 30 ) ) ) {
        if ( !-l '/scripts' ) {
            print_warn('/scripts: ');
            print_warning("cPanel is >= 11.30 [$cpanel_version] and /scripts is not a symlink");
        }
    }
}

sub check_var_cpanel_immutable_files {
    my $immutable_files = '/var/cpanel/immutable_files';

    if ( -e $immutable_files and !-z $immutable_files ) {
        print_warn('immutable files: ');
        print_warning("$immutable_files is not empty!");
    }
}

sub check_for_cpanel_CN_newline {
    my $cpanel_CN   = '/var/cpanel/ssl/cpanel-CN';
    my $has_newline = 0;

    if ( !-e $cpanel_CN ) {
        print_warn("$cpanel_CN: ");
        print_warning('missing!');
    }
    else {
        if ( open my $cpanel_CN_fh, '<', $cpanel_CN ) {
            while (<$cpanel_CN_fh>) {
                if (/\n/) {
                    $has_newline = 1;
                    last;
                }
            }
            close $cpanel_CN_fh;
        }
    }

    if ( $has_newline == 1 ) {
        print_warn("$cpanel_CN: ");
        print_warning('contains a newline. This can cause "Access Web Disk" menus to not work. See FB 63425');
    }
}

sub check_cpanel_config_for_low_maxmem {
    my (%cpconf) = @_;

    if ( $cpconf{'maxmem'} && $cpconf{'maxmem'} < 512 ) {
        print_warn("/var/cpanel/cpanel.config: ");
        print_warning("maxmem < 512M, value=$cpconf{'maxmem'} phpmyadmin may fail");
    }

    if ( $cpconf{'use_safe_quotas'} ) {
        print_warn("/var/cpanel/cpanel.config: ");
        print_warning("use_safe_quotas=1 suspend and unsuspend will be slow");
    }
}

sub check_for_empty_or_missing_files {
    opendir( my $dir_fh, '/var/cpanel/users' );
    my @dir_contents = grep { !/^\.\.?$/ } readdir $dir_fh;
    closedir $dir_fh;

    # if there are no users on the box, don't warn about userdatadomains
    return if scalar @dir_contents == 0;

    my $userdatadomains = '/etc/userdatadomains';

    if ( !-e $userdatadomains ) {
        print_warn('Missing file: ');
        print_warning("$userdatadomains (new server with no accounts, perhaps)");
    }
    elsif ( -f $userdatadomains and -z $userdatadomains ) {
        print_warn('Empty file: ');
        print_warning("$userdatadomains (generate it with /scripts/updateuserdatacache --force)");
    }
}

sub check_for_C_compiler_optimization {
    my $enablecompileroptimizations = 0;

    if ( open my $file_fh, '<', '/var/cpanel/cpanel.config' ) {
        while (<$file_fh>) {
            if (m{ \A enablecompileroptimizations=(\d) }xms) {
                $enablecompileroptimizations = $1;
                last;
            }
        }
        close $file_fh;
    }

    if ( $enablecompileroptimizations == 1 ) {
        print_warn('Tweak Setting: ');
        print_warning('"Enable optimizations for the C compiler" enabled. If Sandy Bridge CPU, problems MAY occur (see ticket 3355885)');
    }
}

sub check_for_fork_bomb_protection {
    if ( -f '/etc/profile.d/limits.sh' or -f '/etc/profile.d/limits.csh' ) {
        print_warn('Fork Bomb Protection: ');
        print_warning('enabled!');
    }
}

# cPanel < 11.30.7.3 will get YAML::Syck from CPAN. If this causes any issues with
# Cpanel::TaskQueue, cPanel's position is to upgrade cPanel.
sub check_for_cPanel_lower_than_11_30_7_3 {
    my $cpanel_version = shift;
    my $could_be_affected = 0;

    if ( $cpanel_version =~ m{ \A (\d+)\.(\d+)\.(\d+)\.(\d+) \z }xms ) {
        if ( $1 < 11 ) {
            $could_be_affected = 1;
        }
        elsif ( $1 == 11 ) {
            if ( $2 < 30 ) {
                $could_be_affected = 1;
            }
            elsif ( $2 == 30 and $3 < 7 ) {
                $could_be_affected = 1;
            }
            elsif ( $2 == 30 and $3 == 7 and $4 < 3 ) {
                $could_be_affected = 1;
            }
        }
    }

    if ( $could_be_affected == 1 ) {
        print_warn('cPanel: ');
        print_warning('versions < 11.30.7.3 use YAML::Syck from CPAN. If problems with Cpanel::TaskQueue, cPanel needs to be updated');
    }
}

sub check_for_mainip_newline {
    my $mainip      = '/var/cpanel/mainip';
    my $has_newline = 0;

    if ( !-e $mainip ) {
        print_warn("$mainip: ");
        print_warning('missing!');
    }
    else {
        if ( open my $mainip_fh, '<', $mainip ) {
            while (<$mainip_fh>) {
                if (/\n/) {
                    $has_newline = 1;
                    last;
                }
            }
            close $mainip_fh;
        }
    }

    if ( $has_newline == 1 ) {
        print_warn("$mainip: ");
        print_warning('contains a newline. /scripts/ipcheck may send incorrect "hostname [..] should resolve to" emails. See FB 54844');
    }
}

sub check_for_skiphttpauth_disabled {
    my $cpanel_config = '/var/cpanel/cpanel.config';
    my $skiphttpauth_setting; # should be 0 or 1 in cpanel.config

    if ( open my $config_fh, '<', $cpanel_config ) {
        while ( <$config_fh> ) {
            if ( /^skiphttpauth=(\d)$/ ) {
                $skiphttpauth_setting = $1;
                last;
            }
        }
        close $config_fh;
    }
    else {
        return;
    }

    if ( defined $skiphttpauth_setting && $skiphttpauth_setting == 0 ) {
        print_warn('skiphttpauth: ');
        print_warning('not set to \'1\' in cpanel.config. Compatibility problems with security tokens possible. Can be toggled at Tweak Settings >> Enable HTTP Authentication');
    }
}

sub check_for_use_compiled_dnsadmin {
    my $cpanel_config = '/var/cpanel/cpanel.config';
    my $has_custom_dnsadmin_modules;
    my ( @setup_modules, @remote_modules );
    my $setup_modules_dir = '/usr/local/cpanel/Cpanel/NameServer/Remote';
    my $remote_modules_dir = '/usr/local/cpanel/Cpanel/NameServer/Setup/Remote';

    my $disable_compiled_dnsadmin_setting; # should be 0 or 1

    # http://docs.cpanel.net/twiki/bin/view/SoftwareDevelopmentKit/WritingSetupModules
    if ( -d $setup_modules_dir ) {
        opendir( my $dir_fh, $setup_modules_dir );
        @setup_modules = grep { !/^\.\.?$/ } readdir $dir_fh;
        closedir $dir_fh;
    }

    # http://docs.cpanel.net/twiki/bin/view/SoftwareDevelopmentKit/WritingRemoteModules
    if ( -d $remote_modules_dir ) {
        opendir( my $dir_fh, $remote_modules_dir );
        @remote_modules = grep { !/^\.\.?$/ } readdir $dir_fh;
        closedir $dir_fh;
    }

    @setup_modules = grep { !/^(cPanel\.pm|SoftLayer\.pm|VPSNET\.pm)/ } @setup_modules;
    @remote_modules = grep { !/^(cPanel\.pm|SoftLayer\.pm|VPSNET\.pm)/ } @remote_modules;

    # return if there are no custom dnsadmin modules being used
    return if ( scalar @setup_modules == 0 and scalar @remote_modules == 0 );

    if ( open my $config_fh, '<', $cpanel_config ) {
        while ( <$config_fh> ) {
            if ( /^disable_compiled_dnsadmin=(\d)$/ ) {
                $disable_compiled_dnsadmin_setting = $1;
                last;
            }
        }
        close $config_fh;
    }
    else {
        return;
    }

    if ( defined $disable_compiled_dnsadmin_setting && $disable_compiled_dnsadmin_setting == 0 ) {
        print_warn('dnsadmin: ');
        print_warning('Tweak Settings >> Use compiled dnsadmin: On. If problems with custom dnsadmin modules, see if disabling helps (see ticket 4279965)');
    }
}

sub check_for_jailshell_additional_mounts_trailing_slash {
    my $mounts_file = '/var/cpanel/jailshell-additional-mounts';
    return if ( !-f $mounts_file );

    my $has_slash = 0;

    if ( open my $file_fh, '<', $mounts_file ) {
        while ( <$file_fh> ) {
            chomp;
            if ( m#/(?:[\s\t]+)?\z# ) {
                $has_slash = 1;
                last;
            }
        }
        close $file_fh;
    }
    else {
        return;
    }

    if ( $has_slash == 1 ) {
        print_warn("$mounts_file: ");
        print_warning( 'contains trailing slashes! Server may become unstable. See FB 71613');
    }
}

sub check_for_invalid_HOMEDIR {
    my $wwwacctconf = '/etc/wwwacct.conf';

    return if !-f $wwwacctconf;

    my $homedir;

    if ( open my $file_fh, '<', $wwwacctconf ) {
        while ( <$file_fh> ) {
            if ( /\AHOMEDIR[\s\t]+([^\s]+)/ ) {
                $homedir = $1;
                last;
            }
        }
        close $file_fh;
    }

    if (!$homedir) {
        print_warn("$wwwacctconf: ");
        print_warning('HOMEDIR value not found!');
    }
    else {
        if (!-d $homedir) {
            print_warn("$wwwacctconf: ");
            print_warning("the directory that is specified as the HOMEDIR does not exist! ($homedir)");
        }
    }
}

sub check_pkgacct_override {
    if ( -d '/var/cpanel/lib/Whostmgr' ) {
        print_warn('pkgacct override: ');
        print_warning(' /var/cpanel/lib/Whostmgr exists, override may exist');
    }
}

1;
