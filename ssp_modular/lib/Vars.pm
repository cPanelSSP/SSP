package Vars;

use strict;
use warnings;
use diagnostics;
use Sys::Hostname;
use Term::ANSIColor qw( :constants );
use Cmd;

use Exporter;
our @ISA = qw( Exporter );
our @EXPORT = qw(
    $|
    $version
    $hostname
    %cpconf
    %pureftpdconf
    @local_ipaddrs_list
    $mysql_datadir
    $mysql_error_log
    $cpanel_version
    $cpanel_version_major
    $cpanel_version_minor
    @apache_version_output
    @apache_modules_output
    @process_list
);

our $|                  = 1;
our $version            = '5.0';
our $hostname           = hostname();
our @local_ipaddrs_list = get_local_ipaddrs();
our $mysql_datadir      = get_mysql_datadir();
our $mysql_error_log    = get_mysql_error_log();
our $cpanel_version     = get_cpanel_version();
our ( $cpanel_version_major, $cpanel_version_minor ) = split /\./, $cpanel_version;
our %cpconf;
our %pureftpdconf;
our @apache_version_output;
our @apache_modules_output;
our @process_list       = split /\n/, run( 'ps', 'axwwwf', '-o', 'user,cmd' );


if ( -x '/usr/local/apache/bin/httpd' ) {
    @apache_version_output = split /\n/, timed_run( '/usr/local/apache/bin/httpd', '-v' );
    @apache_modules_output = split /\n/, timed_run( '/usr/local/apache/bin/httpd', '-M' );
}

{
    open my $cpconf_fh, '<', '/var/cpanel/cpanel.config';
    local $/ = undef;
    %cpconf  = map { ( split( /=/, $_, 2 ) )[ 0, 1 ] } split( /\n/, readline($cpconf_fh) );
    close $cpconf_fh;
}

{
    open my $pureftpdconf_fh, '<', '/etc/pure-ftpd.conf';
    local $/ = undef;
    %pureftpdconf = map { ( split( /\s+/, $_, 2 ) )[ 0, 1 ] } split( /\n/, readline($pureftpdconf_fh) );
    close $pureftpdconf_fh;
}

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

sub get_mysql_datadir {
    my $my_cnf  = '/etc/my.cnf';
    my $datadir = '/var/lib/mysql/';

    if ( open my $my_cnf_fh, '<', $my_cnf ) {
        while (<$my_cnf_fh>) {
            chomp( my $line = $_ );
            if ( $line =~ m{ \A datadir \s* = \s* (?:["']?) ([^"']+) }xms ) {
                $datadir = $1;
                $datadir =~ s/[\s\t]+$//g;
                last;
            }
        }
        close $my_cnf_fh;
    }

    if ( $datadir !~ m{ / \z }xms ) {
        $datadir .= '/';
    }

    return $datadir;
}

sub get_mysql_error_log {
    my $mysql_error_log;
    if ( open my $file_fh, '<', '/etc/my.cnf' ) {
        while (<$file_fh>) {
            if (m{ \A log-error \s? = \s? (.*) \z }xms) {
                $mysql_error_log = $1;
                $mysql_error_log =~ s/\"//g;
                $mysql_error_log =~ s/\'//g;
                chomp $mysql_error_log;
                last;
            }
        }
        close $file_fh;
    }

    if ($mysql_error_log) {
        return $mysql_error_log;
    }
    else {
        return '/var/lib/mysql/' . $hostname . '.err';
    }
}

sub get_cpanel_version {
    my $cpanel_version;
    my $cpanel_version_file = '/usr/local/cpanel/version';

    if ( open my $file_fh, '<', $cpanel_version_file ) {
        while (<$file_fh>) {
            chomp( $cpanel_version = $_ );
        }
        close $file_fh;
    }

    if ( $cpanel_version =~ /(\d+\.\d+\.\d+\.\d+)/ ) {
        return $cpanel_version;
    }
    else {
        return 'unknown';
    }
}

1;
