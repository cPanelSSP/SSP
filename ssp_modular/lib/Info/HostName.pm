package Info::HostName;

use strict;
use warnings;
use diagnostics;
use PrintText;

use Exporter;
our @ISA = qw( Exporter );
our @EXPORT = qw( print_hostname );

sub print_hostname {
    my $hostname = shift;

    print_info( 'Hostname: ' );
    if ( $hostname !~ /([\w-]+)\.([\w-]+)\.(\w+)/ ) {
        print_warning( "$hostname is not a FQDN ( en.wikipedia.org/wiki/Fully_qualified_domain_name )" );
    }
    else {
        print_normal( $hostname );
    }
}

1;
