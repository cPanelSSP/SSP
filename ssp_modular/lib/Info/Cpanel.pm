package Info::Cpanel;

use strict;
use warnings;
use diagnostics;

use Exporter;
our @ISA = qw( Exporter );
our @EXPORT = qw(
    get_cpanel_version
);

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
