package Warn::RPM;

use strict;
use warnings;
use diagnostics;
use Cmd;
use PrintText;


sub check_for_rpm_overrides {
    my $rpm_override_dir = '/var/cpanel/rpm.versions.d/';
    my $local_versions   = '/var/cpanel/rpm.versions.d/local.versions';
    my $easy_versions    = '/var/cpanel/rpm.versions.d/easy.versions';
    my $md5_local;
    my $md5_easy;
    my $local_is_default = 0;
    my $easy_is_default = 0;

    return if !-d $rpm_override_dir;

    if ( -f $local_versions ) {
        $md5_local = run( 'md5sum', $local_versions );
    }

    if ( -f $easy_versions ) {
        $md5_easy = run( 'md5sum', $easy_versions );
    }

    ## these are checksums for default files. we ignore them to prevent needless output from SSP
    if ( $md5_local && $md5_local =~ m{ \A (
                                 fab8a718f7e3a1ff9c9d04fb4e8c94c4
                               | fd3f270edda79575343e910369b75ab7
                               | 57baebe121bcd5ab9752dd63f60ecd81
                               | 1d9f5d246ef2c9ab29f33cf00a3af9a5
                                ) \s }xms ) {
        $local_is_default = 1;
    }

    if ( $md5_easy && $md5_easy =~ m{ \A (
                                  d56abe76c47853eceb706f0855e642a7
                                | 89d631ef7c1d43475c20d7be7b7290ff
                                ) \s }xms ) {
        $easy_is_default = 1;
    }

    opendir( my $dir_fh, $rpm_override_dir );
    my @dir_contents = grep { !/^\.(\.?)$/ } readdir $dir_fh;
    closedir $dir_fh;

    if ( $local_is_default == 1 ) {
        @dir_contents = grep { $_ ne 'local.versions' } @dir_contents;
    }

    if ( $easy_is_default == 1 ) {
        @dir_contents = grep { $_ ne 'easy.versions' } @dir_contents;
    }

    ## if the only items in rpm.versions.d/ were defaults that we can ignore, return
    if ( !@dir_contents ) {
        return;
    }

    if (@dir_contents) {
        print_warn('RPM override: ');
        print_warning("$rpm_override_dir contains entries, manually review. More info: http://go.cpanel.net/rpmversions");

        if ( -r $local_versions ) {
            eval { local $SIG{__DIE__}; local $SIG{__WARN__}; require YAML::Syck; };
            if ( !$@ ) {
                my $ref = YAML::Syck::LoadFile($local_versions);
                if ( $ref && $ref->{'target_settings'} ) {
                    foreach my $package ( keys %{ $ref->{'target_settings'} } ) {
                        if ( $ref->{'target_settings'}{$package} =~ m{uninstalled} ) {
                            unless ( $package eq 'easy-tomcat7' ) { # cPanel lists easy-tomcat7 as uninstalled by default
                                print_warn("$package is listed as uninstalled in $local_versions");
                                print_warning('');
                            }
                        }
                    }
                }
            }
        }
    }
}

1;
