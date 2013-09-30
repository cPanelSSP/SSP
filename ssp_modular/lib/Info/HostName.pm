package Info::HostName;

use strict;
use warnings;
use diagnostics;
use PrintText;


sub print_hostname {
    my $hostname = shift;

    print_info( 'Hostname: ' );
    if ( $hostname !~ /([\w-]+)\.([\w-]+)\.(\w+)/ ) {
        print_warning( "$hostname may not be a FQDN ( en.wikipedia.org/wiki/Fully_qualified_domain_name )" );
    }
    else {
        print_normal( $hostname );
    }
}

1;
