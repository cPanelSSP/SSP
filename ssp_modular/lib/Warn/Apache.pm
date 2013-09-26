package Warn::Apache;

use strict;
use warnings;
use diagnostics;
use Cmd;
use PrintText;
use ProcessList;

use Exporter;
our @ISA = qw( Exporter );
our @EXPORT = qw(
    check_for_local_apache_templates
    check_for_custom_apache_includes
    check_for_huge_apache_logs
    check_for_empty_apache_templates
    check_for_missing_or_commented_customlog
    check_if_httpdconf_ipaddrs_exist
    check_distcache_and_libapr
    check_for_apache_rlimits
    check_for_apache_listen_host_is_localhost
    check_for_var_cpanel_conf_apache_local
    check_for_maxclients_or_maxrequestworkers_reached
    check_for_bw_module_and_more_than_1024_vhosts
    check_for_sneaky_htaccess
);

sub check_for_local_apache_templates {
    my $apache2_template_dir = '/var/cpanel/templates/apache2';
    my @dir_contents;

    if ( -d $apache2_template_dir ) {
        opendir( my $dir_fh, $apache2_template_dir );
        @dir_contents = readdir $dir_fh;
        closedir $dir_fh;
    }

    my $templates;
    for my $template (@dir_contents) {
        if ( $template =~ m{ \.local \z }xms ) {
            $templates .= " $template";
        }
    }

    if ($templates) {
        print_warn('Custom apache2 templates: ');
        print_warning($templates);
    }
}

sub check_for_custom_apache_includes {
    my $include_dir = '/usr/local/apache/conf/includes';

    return if !$include_dir;

    my @includes = qw(
      post_virtualhost_1.conf
      post_virtualhost_2.conf
      post_virtualhost_global.conf
      pre_main_1.conf
      pre_main_2.conf
      pre_main_global.conf
      pre_virtualhost_1.conf
      pre_virtualhost_2.conf
      pre_virtualhost_global.conf
    );

    my $custom_includes;
    for my $include (@includes) {
        if ( !-z "${include_dir}/${include}" ) {
            if ( $include eq 'pre_virtualhost_global.conf' ) {
                my $md5 = run( 'md5sum', '/usr/local/apache/conf/includes/pre_virtualhost_global.conf' );
                next if ( $md5 && $md5 =~ m{ \A 1693b9075fa54ede224bfeb8ad42a182 \s }xms );
                $custom_includes .= " [$include]";
            }
            else {
                $custom_includes .= " [$include]";
            }
        }
    }

    if ($custom_includes) {
        print_warn('Apache Includes: ');
        print_warning($custom_includes);
    }
}

sub check_for_huge_apache_logs {
    my @logs = qw( access_log error_log suphp_log suexec_log mod_jk.log modsec_audit.log modsec_debug.log );
    for my $log (@logs) {
        $log = '/usr/local/apache/logs/' . $log;
        if ( -e $log ) {
            my $size = ( stat($log) )[7];
            if ( $size > 2_100_000_000 ) {
                $size = sprintf( "%0.2fGB", $size / 1073741824 );
                print_warn('M-M-M-MONSTER LOG!: ');
                print_warning("$log ($size)");
            }
        }
    }
}

sub check_for_empty_apache_templates {
    my $apache2_template_dir = '/var/cpanel/templates/apache2';
    my @dir_contents;
    my $empty_templates;

    if ( -d $apache2_template_dir ) {
        opendir( my $dir_fh, $apache2_template_dir );
        @dir_contents = grep { !/^\.\.?$/ } readdir $dir_fh;
        closedir $dir_fh;
    }

    if ( !@dir_contents ) {
        print_warn('Apache templates: ');
        print_warning("none found in $apache2_template_dir !");
    }
    else {
        for my $template (@dir_contents) {
            if ( -z "$apache2_template_dir/$template" ) {
                $empty_templates .= "$template ";
            }
        }
    }

    if ($empty_templates) {
        print_warn("Empty Apache templates in $apache2_template_dir (this can affect the ability to remove domains): ");
        print_warning("$empty_templates");
    }
}

sub check_for_missing_or_commented_customlog {
    my @apache_version_output = shift @_;
    my $apache_version;
    my $templates_dir = '/var/cpanel/templates/apache';
    my $commented_templates;
    my $missing_customlog_templates;
    my $httpdconf = '/usr/local/apache/conf/httpd.conf';
    my $httpdconf_commented_customlog;
    my $httpdconf_customlog_exists;

    if (@apache_version_output) {
        for my $line (@apache_version_output) {
            if ( $line =~ m{ \A Server \s version: \s Apache/(\d) (?:.*) \z }xms ) {
                $apache_version = $1;
            }
        }
    }

    return if !$apache_version;
    $apache_version == 1 ? $templates_dir .= 1 : $templates_dir .= 2;

    my %templates = (
        'main.default'      => 0,
        'main.local'        => 0,
        'vhost.default'     => 0,
        'vhost.local'       => 0,
        'ssl_vhost.default' => 0,
        'ssl_vhost.local'   => 0,
    );

    for my $template ( keys %templates ) {
        my $template_full_path = $templates_dir . '/' . $template;
        if ( -f $template_full_path ) {
            if ( open my $template_fh, '<', $template_full_path ) {
                while (<$template_fh>) {
                    if (/#(?:\s+)?CustomLog\s/i) {
                        $commented_templates .= "$template_full_path ";
                        $templates{$template} = 1;
                        last;
                    }
                    elsif (/CustomLog\s/i) {
                        $templates{$template} = 1;
                    }
                }
                close $template_fh;
            }
        }
    }

    while ( my ( $template, $value ) = each(%templates) ) {
        if ( $value == 0 and -f "$templates_dir/$template" ) {
            $missing_customlog_templates .= "$templates_dir/$template ";
        }
    }

    if ( open my $httpdconf_fh, '<', $httpdconf ) {
        local $/ = undef;
        my $httpdconf_txt = readline($httpdconf_fh);
        close $httpdconf_fh;
        if ( $httpdconf_txt =~ m/\n[\t ]*#[\t ]*CustomLog\s/si ) {
            $httpdconf_commented_customlog = 1;
        }
        if ( $httpdconf_txt =~ m/\n[\t ]*CustomLog\s/si ) {
            $httpdconf_customlog_exists = 1;
        }
    }

    if ($httpdconf_commented_customlog) {
        $commented_templates .= ' httpd.conf';
    }
    elsif ( !$httpdconf_customlog_exists ) {
        $missing_customlog_templates .= ' httpd.conf';
    }

    if ($commented_templates) {
        print_warn('CustomLog commented out: ');
        print_warning($commented_templates);
    }

    if ($missing_customlog_templates) {
        print_warn('CustomLog entries missing: ');
        print_warning($missing_customlog_templates);
    }
}

sub check_if_httpdconf_ipaddrs_exist {
    my @local_ipaddrs_list = shift @_;
    my $httpdconf = '/usr/local/apache/conf/httpd.conf';
    my @vhost_ipaddrs;
    my @unbound_ipaddrs;

    return if !$httpdconf;

    if ( open my $httpdconf_fh, '<', $httpdconf ) {
        local $/ = undef;
        my $httpdconf_txt = readline($httpdconf_fh);
        close $httpdconf_fh;
        while ( $httpdconf_txt =~ m/<VirtualHost\s+(\d+\.\d+\.\d+\.\d+):(?:\d+)>/sig ) {
            push @vhost_ipaddrs, $1;
        }
    }

    # uniq IP addrs only
    @vhost_ipaddrs = do {
        my %seen;
        grep { !$seen{$_}++ } @vhost_ipaddrs;
    };

    for my $vhost_ipaddr (@vhost_ipaddrs) {
        my $is_bound = 0;
        for my $local_ipaddr (@local_ipaddrs_list) {
            if ( $vhost_ipaddr eq $local_ipaddr ) {
                $is_bound = 1;
                last;
            }
        }
        if ( $is_bound == 0 ) {
            push @unbound_ipaddrs, $vhost_ipaddr;
        }
    }

    if (@unbound_ipaddrs) {
        print_warn('Apache: ');
        print_warning('httpd.conf has VirtualHosts for these IP addrs, which aren\'t bound to the server:');

        for my $unbound_ipaddr (@unbound_ipaddrs) {
            print_magenta("\t \\_ $unbound_ipaddr");
        }
    }
}

sub check_distcache_and_libapr {
    my $last_success_profile           = '/var/cpanel/easy/apache/profile/_last_success.yaml';
    my $has_distcache                  = 0;
    my $httpd_not_linked_to_system_apr = 0;

    if ( open my $profile_fh, '<', $last_success_profile ) {
        while (<$profile_fh>) {
            if (/Distcache:/) {
                $has_distcache = 1;
                last;
            }
        }
        close $profile_fh;
    }

    if ( $has_distcache == 1 ) {
        my @ldd = split /\n/, run( 'ldd', '/usr/local/apache/bin/httpd' );
        for my $line (@ldd) {
            if ( $line =~ m{ libapr(?:.*) \s+ => \s+ (\S+) }xms ) {
                if ( $1 !~ m{ \A /usr/local/apache/lib/libapr }xms ) {
                    $httpd_not_linked_to_system_apr = 1;
                    last;
                }
            }
        }
    }

    if ( $httpd_not_linked_to_system_apr == 1 ) {
        print_warn('Apache: ');
        print_warning('httpd linked to system APR, not APR in /usr/local/apache/lib/ (see 62676)');
    }
}

sub check_for_apache_rlimits {
    my $httpdconf = '/usr/local/apache/conf/httpd.conf';
    my ( $rlimitmem, $rlimitcpu );
    my $output;

    if ( open my $httpdconf_fh, '<', $httpdconf ) {
        local $/ = undef;
        my $httpdconf_txt = readline($httpdconf_fh);
        close $httpdconf_fh;
        if ( $httpdconf_txt =~ m/\n[\t ]+RLimitMEM (\d+)/s ) {
            $rlimitmem = $1;
        }
        if ( $httpdconf_txt =~ m/\n[\t ]+RLimitCPU (\d+)/s ) {
            $rlimitcpu = $1;
        }
    }

    if ($rlimitmem) {
        my $rlimitmem_converted = sprintf( '%.0f MB', $rlimitmem / 1024 / 1024 );
        $output = "RLimitMEM $rlimitmem [$rlimitmem_converted]";
    }

    if ($rlimitcpu) {
        $output .= " RLimitCPU $rlimitcpu";
    }

    if ($output) {
        print_warn('Apache RLimits: ');
        print_warning($output);
    }
}

sub check_for_apache_listen_host_is_localhost {
    my $cpanel_config = '/var/cpanel/cpanel.config';
    my $localhost_80;

    return if !$cpanel_config;

    if ( open my $cpanel_config_fh, '<', $cpanel_config ) {
        while (<$cpanel_config_fh>) {
            if (/^apache_port=(\d+\.\d+\.\d+\.\d+):(?:\d+)/) {
                if ( $1 eq '127.0.0.1' ) {
                    $localhost_80 = 1;
                }
            }
        }
        close $cpanel_config_fh;
    }

    if ($localhost_80) {
        print_warn('Apache listen host: ');
        print_warning('Apache may only be listening on 127.0.0.1');
    }
}

sub check_for_var_cpanel_conf_apache_local {
    my $local = '/var/cpanel/conf/apache/local';

    if ( -f $local ) {
        print_warn('Apache: ');
        print_warning("file $local exists. This can potentially cause various issues. See ticket 3915299 for an example");
    }
}

sub check_for_maxclients_or_maxrequestworkers_reached {
    my @apache_version_output = shift @_;
    my ( $version_major, $version_minor );
    my $apache_version;

    for my $line (@apache_version_output) {
        if ( $line =~ m{ \A Server \s version: \s Apache/(\d\.\d) }xms ) {
            ( $version_major, $version_minor ) = split /\./, $1;
            last;
        }
    }

    if (( $version_major == 2 ) and ( $version_minor == 2 )) {
        $apache_version = '2.2';
    }
    elsif (( $version_major == 2 ) and ( $version_minor == 4 )) {
        $apache_version = '2.4';
    }

    return if !$apache_version;

    my $log            = '/usr/local/apache/logs/error_log';
    my $size           = ( stat($log) )[7];
    my $bytes_to_check = 20_971_520 / 2;                       # 10M limit of logs to check, may need adjusting, depending how much time it adds to SSP
    my $seek_position  = 0;
    my $log_data;
    my @logs;
    my $limit_last_hit_date;

    return if !$size;

    if ( $size > $bytes_to_check ) {
        $seek_position = ( $size - $bytes_to_check );
    }

    if ( open my $file_fh, '<', $log ) {
        seek $file_fh, $seek_position, 0;
        read $file_fh, $log_data, $bytes_to_check;
        close $file_fh;
    }
    if ( $log_data =~ m/(?:MaxClients|MaxRequestWorkers)/s ) {
        @logs = split /\n/, $log_data;
        undef $log_data;
        @logs = reverse @logs;
        for my $log_line (@logs) {
            if ( $apache_version eq '2.2' ) {

                # [Wed Nov 14 05:55:04 2012] [error] server reached MaxClients setting, consider raising the MaxClients setting
                if ( $log_line =~ m{ \A \[ (\S+ \s+ \S+ \s+ \S+ \s+ \S+ \s+ \S+ ) \] \s+ \[error\] \s+ server \s+ reached \s+ MaxClients }xms ) {
                    $limit_last_hit_date = $1;
                    last;
                }
            }
            elsif ( $apache_version eq '2.4' ) {

                # [Fri Feb 08 09:58:45.875187 2013] [mpm_prefork:error] [pid 23220] AH00161: server reached MaxRequestWorkers
                if ( $log_line =~ m{ \A \[ (\S+ \s+ \S+ \s+ \S+ \s+ \S+ \s+ \S+ ) \] \s (.*) server \s reached \s MaxRequestWorkers }xms ) {
                    $limit_last_hit_date = $1;
                    last;
                }
            }
        }
    }

    if ($limit_last_hit_date) {
        if ( $apache_version eq '2.2' ) {
            print_warn('MaxClients: ');
        }
        elsif ( $apache_version eq '2.4' ) {
            print_warn('MaxRequestWorkers: ');
        }

        print_warning("limit last reached at $limit_last_hit_date");
    }
}

sub check_for_bw_module_and_more_than_1024_vhosts {
    my @apache_modules_output = shift @_;
    my $httpdconf = '/usr/local/apache/conf/httpd.conf';
    return if !-f $httpdconf;

    return if ( !grep { /^\sbw_module\s/ } @apache_modules_output );

    my $num_vhosts = 0;

    open my $httpdconf_fh, '<', $httpdconf or return;
    while ( <$httpdconf_fh> ) {
        if ( m{ \A (?:\s+)? <VirtualHost \s }xms ) {
            $num_vhosts++;
        }
    }
    close $httpdconf_fh;

    if ( $num_vhosts and $num_vhosts > 1024 ) {
        print_warn('bw_module: ');
        print_warning("loaded, and httpd.conf has >1024 VirtualHosts ($num_vhosts). Apache failing to start? See FB 69121");
    }
}

sub check_for_sneaky_htaccess {
    ## this is lazy checking. ideally we'd check HOMEMATCH from wwwacct.conf and go from there.
    ## but then, nothing guarantees the current HOMEMATCH has always been the same, either.
    my @dirs = qw( / /home/ /home2/ /home3/ /home4/ /home5/ /home6/ /home7/ /home8/ /home9/ );
    my $htaccess;

    for my $dir (@dirs) {
        if ( -f $dir . '.htaccess' and !-z $dir . '.htaccess' ) {
            $htaccess .= $dir . '.htaccess ';
        }
    }

    if ($htaccess) {
        print_warn('Sneaky .htaccess file(s) found: ');
        print_warning($htaccess);
    }
}

1;
