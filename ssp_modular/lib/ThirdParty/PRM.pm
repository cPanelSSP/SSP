package ThirdParty::PRM;

use strict;
use warnings;
use diagnostics;
use PrintText;
use Cmd;

use Exporter;
our @ISA = qw( Exporter );
our @EXPORT = qw( check_for_prm );

sub check_for_prm {
    if ( -e '/usr/local/prm' ) {
        print_3rdp('PRM: ');
        print_3rdp2('PRM exists at /usr/local/prm');
    }
}

1;
