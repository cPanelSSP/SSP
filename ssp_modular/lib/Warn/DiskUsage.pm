package Warn::DiskUsage;

use strict;
use warnings;
use diagnostics;
use Cmd;
use PrintText;


sub check_disk_space {
    my @df = split /\n/, run('df');
    for my $line (@df) {
        if ( $line =~ m{ (9[8-9]|100)% \s+ (.*) }xms ) {
            my ( $usage, $partition ) = ( $1, $2 );
            unless ( $line =~ m{ /virtfs | /(dev|proc) \z }xms ) {
                print_warn('Disk space: ');
                print_warning("${usage}% usage on $partition");
            }
        }
    }
}

sub check_disk_inodes {
    my @df_i = split /\n/, run( 'df', '-i' );
    for my $line (@df_i) {
        if ( $line =~ m{ (9[8-9]|100)% \s+ (.*) }xms ) {
            my ( $usage, $partition ) = ( $1, $2 );
            unless ( $line =~ m{ /virtfs | /(dev|proc) \z }xms ) {
                print_warn('Disk inodes: ');
                print_warning("${usage}% inode usage on $partition");
            }
        }
    }
}

1;
