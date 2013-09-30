package ThirdParty::PRM;

use strict;
use warnings;
use diagnostics;
use PrintText;
use Cmd;


sub prm {
    if ( -e '/usr/local/prm' ) {
        print_3rdp('PRM: ');
        print_3rdp2('PRM exists at /usr/local/prm');
    }
}

1;
