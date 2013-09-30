package Warn::EasyApache;

use strict;
use warnings;
use diagnostics;
use Vars;
use File::Find;
use Cmd;
use PrintText;


my @custom_opt_mods;
my @easyapache_templates;

sub check_for_rawopts {
    my $rawopts_dir = '/var/cpanel/easy/apache/rawopts';
    my @dir_contents;

    if ( -d $rawopts_dir ) {
        opendir( my $dir_fh, $rawopts_dir );
        @dir_contents = grep { !/^\.\.?$/ } readdir $dir_fh;
        closedir $dir_fh;
    }

    if (@dir_contents) {
        print_warn('Rawopts Detected: ');
        print_warning("check $rawopts_dir !");
    }
}

sub check_for_rawenv {
    my $rawenv_dir = '/var/cpanel/easy/apache/rawenv';
    my @dir_contents;

    if ( -d $rawenv_dir ) {
        opendir( my $dir_fh, $rawenv_dir );
        @dir_contents = grep { !/^\.\.?$/ } readdir $dir_fh;
        closedir $dir_fh;
    }

    if (@dir_contents) {
        print_warn('Rawenv detected: ');
        print_warning("check $rawenv_dir !");
    }
}

sub check_for_custom_opt_mods {
    my $custom_opt_mods;
    my $dir = '/var/cpanel/easy/apache/custom_opt_mods';

    return if !-e $dir;

    find( \&find_custom_opt_mods, $dir );
    if ( scalar @custom_opt_mods > 10 ) {
        print_warn("$dir: ");
        print_warning('many custom opt mods exist, check manually');
    }
    elsif (@custom_opt_mods) {
        for my $custom_opt_mod (@custom_opt_mods) {
            $custom_opt_mods .= "$custom_opt_mod ";
        }

        print_warn("$dir: ");
        print_warning($custom_opt_mods);
    }
}

sub find_custom_opt_mods {
    # Ignore these, Attracta:
    #  /var/cpanel/easy/apache/custom_opt_mods/Cpanel/Easy/ModFastInclude.pm
    #  /var/cpanel/easy/apache/custom_opt_mods/Cpanel/Easy/ModFastInclude.pm.tar.gz

    my $file = $File::Find::name;
    if ( -f $file and $file !~ m{ /ModFastInclude\.pm(.*) }xms ) {
        $file =~ s#/var/cpanel/easy/apache/custom_opt_mods/##;
        push @custom_opt_mods, $file;
    }
}

sub check_for_local_makecpphp_template {
    my $cpanel_version = shift or return;
    my ( $v1, $v2 ) = split /\./, $cpanel_version;

    # makecpphp has been removed from 11.36+
    if ( ( $v1 > 11 ) || ( $v1 == 11 ) and ( $v2 >= 36 ) ) {
        return;
    }    

    my $makecpphp_local_profile = '/var/cpanel/easy/apache/profile/makecpphp.profile.yaml.local';

    if ( -e $makecpphp_local_profile ) {
        print_warn('makecpphp Local Profile: ');
        print_warning("exists at $makecpphp_local_profile !");
    }    
}

sub check_easy_skip_cpanelsync {
    if ( -e '/var/cpanel/easy_skip_cpanelsync' ) {
        print_warn('Touchfile: ');
        print_warning('/var/cpanel/easy_skip_cpanelsync exists! ');
    }
}

sub check_for_apache_update_no_restart {
    my $apache_update_no_restart = '/var/cpanel/mgmt_queue/apache_update_no_restart';
    my $ea_in_process_list       = 0;

    for my $process (@process_list) {
        if ( $process =~ m{ \A root (?:.*) easyapache }xms ) {
            $ea_in_process_list = 1;
            last;
        }
    }

    if ( -e $apache_update_no_restart and $ea_in_process_list == 0 ) {
        print_warn('EasyApache: ');
        print_warning("$apache_update_no_restart exists! This will prevent EA from completing successfully.");
    }
}

sub check_for_stale_easyapache_build_file {
    my $ea_is_running_file       = '/usr/local/apache/AN_EASYAPACHE_BUILD_IS_CURRENTLY_RUNNING';
    my $ea_in_process_list       = 0;
    my $ea_is_running            = 0;

    if ( -e $ea_is_running_file ) { 
        for my $process (@process_list) {
            if ( $process =~ m{ \A root (?:.*) easyapache }xms ) { 
                $ea_in_process_list = 1;
                last;
            }   
            else {
                $ea_in_process_list = 0;
            }   
        }   
        if ( $ea_in_process_list == 0 ) { 
            print_warn('EasyApache: ');
            print_warning("$ea_is_running_file exists, but 'easyapache' not found in process list");
        }   
    }   
}

sub check_if_easyapache_is_running {
    my $ea_is_running = 0;

    for my $process (@process_list) {
        if ( $process =~ m{ \A root (?:.*) easyapache }xms ) {
            $ea_is_running = 1;
            last;
        }
    }
    if ( $ea_is_running == 1 ) {
        print_warn('EasyApache: ');
        print_warning("is running");
    }
}

sub check_for_easyapache_hooks {
    my $hooks;

    my @hooks = qw(
        /scripts/before_apache_make
        /scripts/after_apache_make_install
        /scripts/before_httpd_restart_tests
        /scripts/after_httpd_restart_tests
    );

    # default CloudLinux hooks that can be ignored
    my %hooks_ignore = qw(
      41ec2d3f35d8cd7cb01b60485fb3bdbb    /scripts/before_apache_make
      407df66f28c8822cd4f51fe56160f74e    /scripts/before_apache_make
    );

    for my $hook (@hooks) {
        if ( -f $hook and !-z $hook ) {
            chomp( my $checksum = run( 'md5sum', $hook ) );
            $checksum =~ s/\s.*//g;
            next if exists $hooks_ignore{$checksum};
            $hooks .= " $hook";
        }
    }

    if ($hooks) {
        print_warn('EA hooks: ');
        print_warning($hooks);
    }
}

sub check_for_empty_easyapache_profiles {
    my $templates;
    my $dir = '/var/cpanel/easy/apache/profile';
    find( \&find_easyapache_templates, $dir );

    if (@easyapache_templates) {
        for my $template (@easyapache_templates) {
            $templates .= "$template ";
        }

        print_warn("Empty template(s) in $dir: ");
        print_warning($templates);
    }
}

sub find_easyapache_templates {
    my $file = $File::Find::name;
    if ( -f $file and -z $file ) {
        $file =~ s#/var/cpanel/easy/apache/profile/##g;
        push @easyapache_templates, $file;
    }
}

1;
