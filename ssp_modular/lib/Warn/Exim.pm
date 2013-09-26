package Warn::Exim;

use strict;
use warnings;
use diagnostics;
use PrintText;

use Exporter;
our @ISA = qw( Exporter );
our @EXPORT = qw(
    check_for_custom_exim_conf_local
    check_eximstats_size
    check_eximstats_corrupt
);

sub check_for_custom_exim_conf_local {
    my $exim_conf_local = '/etc/exim.conf.local';
    my $is_customized   = 0;

    if ( open my $file_fh, '<', $exim_conf_local ) {
        while ( my $line = <$file_fh> ) {
            chomp $line;
            if ( $line !~ m{ \A ( @ | $ ) }xms ) {
                $is_customized = 1;
                last;
            }
        }
        close $file_fh;
    }

    if ( $is_customized == 1 ) {
        print_warn('Exim: ');
        print_warning("$exim_conf_local contains customizations");
    }
}

sub check_eximstats_size {
    my $mysql_datadir = shift;
    return if !$mysql_datadir;

    my $eximstats_dir = $mysql_datadir . 'eximstats/';
    my @dir_contents;
    my $size;

    if ( -d $eximstats_dir ) {
        opendir( my $dir_fh, $eximstats_dir );
        @dir_contents = grep { /(defers|failures|sends|smtp)\.(frm|MYI|MYD)$/ } readdir $dir_fh;
        closedir $dir_fh;
    }

    for my $file (@dir_contents) {
        $file = $eximstats_dir . $file;
        $size += ( stat($file) )[7];
    }

    if ( $size && $size > 5_000_000_000 ) {
        $size = sprintf( "%0.2fGB", $size / 1073741824 );
        print_warn('eximstats db: ');
        print_warning($size);
    }
}

sub check_eximstats_corrupt {
    my $mysql_error_log = shift;
    return if !-f $mysql_error_log;

    my $size           = ( stat($mysql_error_log) )[7];
    my $bytes_to_check = 20_971_520;                      # 20M limit of logs to check
    my $seek_position  = 0;
    my $log_data;
    my @logs;
    my $eximstats_is_crashed;

    if ( $size > $bytes_to_check ) {
        $seek_position = ( $size - $bytes_to_check );
    }

    if ( open my $file_fh, '<', $mysql_error_log ) {
        seek $file_fh, $seek_position, 0;
        read $file_fh, $log_data, $bytes_to_check;
        close $file_fh;
    }

    @logs = split /\n/, $log_data;
    undef $log_data;
    @logs = reverse @logs;

    for my $log_line (@logs) {

        # /usr/sbin/mysqld: Table './eximstats/smtp' is marked as crashed and should be repaired
        if ( $log_line =~ m{ /eximstats/ (.*) marked \s as \s crashed }xms ) {
            $eximstats_is_crashed = $log_line;
            last;
        }
    }

    if ($eximstats_is_crashed) {
        print_warn('eximstats: ');
        print_warning("latest crash: $eximstats_is_crashed");
    }
}

1;
