package Warn::Tomcat;

use strict;
use warnings;
use diagnostics;
use PrintText;


sub check_for_tomcatoptions {
    my $tomcat_options = '/var/cpanel/tomcat.options';
    if ( -f $tomcat_options and !-z $tomcat_options ) {
        print_warn('Tomcat options: ');
        print_warning("$tomcat_options exists");
    }
}

# TODO: add sub that checks for Tomcat 5, prints unsupported message

1;
