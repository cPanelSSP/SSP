package Warn::Cron;

use strict;
use warnings;
use diagnostics;
use Cmd;
use PrintText;
use ProcessList;

use Exporter;
our @ISA = qw( Exporter );

our @EXPORT = qw(
    check_for_missing_root_cron
    check_roots_cron_for_certain_commands
    check_cron_process
    check_for_harmful_php_mode_600_cron
);


sub check_for_missing_root_cron {
    my $cron = '/var/spool/cron/root';

    if ( !-f $cron ) {
        print_warn('Missing cron: ');
        print_warning("root's cron file $cron is missing!");
    }
}

sub check_roots_cron_for_certain_commands {
    my $cron = '/var/spool/cron/root';

    return if !-e $cron;

    my %commands = ();
    my $commands;

    if ( open my $cron_fh, '<', $cron ) {
        while (<$cron_fh>) {
            if (m{ \A [^#]+ (\s|\/)rm\s }xms) {
                $commands{'rm'} = 1;
            }
            if (m{ \A [^#]+ (\s|\/)unlink\s }xms) {
                $commands{'unlink'} = 1;
            }
            if (m{ \A [^#]+ (\s|\/)chmod\s }xms) {
                $commands{'chmod'} = 1;
            }
            if (m{ \A [^#]+ (\s|\/)chown\s }xms) {
                $commands{'chown'} = 1;
            }
            if (m{ \A [^#]+ (\s|\/)chattr\s }xms) {
                $commands{'chattr'} = 1;
            }
            if (m{ \A [^#]+ (\s|\/)kill\s }xms) {
                $commands{'kill'} = 1;
            }
            if (m{ \A [^#]+ (\s|\/)pkill\s }xms) {
                $commands{'pkill'} = 1;
            }
            if (m{ \A [^#]+ (\s|\/)skill\s }xms) {
                $commands{'skill'} = 1;
            }
            if (m{ \A [^#]+ (\s|\/)tmpwatch\s }xms) {
                $commands{'tmpwatch'} = 1;
            }
        }
        close $cron_fh;
    }

    if (%commands) {
        while ( my ( $key, $value ) = each(%commands) ) {
            $commands .= "[$key] ";
        }

        print_warn("$cron commands found: ");
        print_warning($commands);
    }
}

sub check_cron_process {
    my $crond_is_running = 0;

    for my $process (@process_list) {
        if ( $process =~ m{ \A root (?:.*) crond }xms ) {
            $crond_is_running = 1;
        }
    }

    if ( $crond_is_running == 0 ) {
        print_warn('crond: ');
        print_warning('not found in the process list!');
    }
}

sub check_for_harmful_php_mode_600_cron {
    return if !-d '/etc/cron.daily';

    my @dir_contents;
    my $has_harmful_cron = 0;
    my $cron_file;

    opendir( my $dir_fh, '/etc/cron.daily' ) or return;
    @dir_contents = grep { !/^\.\.?$/ } readdir $dir_fh;
    closedir $dir_fh;

    for my $file ( @dir_contents ) {
        $file = '/etc/cron.daily/' . $file;
        open my $file_fh, '<', $file or next;
        while ( <$file_fh> ) {
            if ( /^mytmpfile=\/tmp\/php-mode-/ ) {
                $has_harmful_cron = 1;
                $cron_file = $file;
                last;
            }
        }
    }

    if ( $has_harmful_cron == 1 ) {
        print_warn('harmful cron: ');
        print_warning( "${cron_file}! Breaks webmail, phpMyAdmin, and more! See tickets 4225765, 4237465, 4099807, 4231469, 4231473. Vendor: http://whmscripts.net/misc/2013/apache-symlink-security-issue-fixpatch/" );
    }
}

1;
