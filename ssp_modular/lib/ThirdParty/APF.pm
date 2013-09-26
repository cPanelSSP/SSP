package ThirdParty::APF;

use strict;
use warnings;
use diagnostics;
use PrintText;
use Cmd;

use Exporter;
our @ISA = qw( Exporter );
our @EXPORT = qw( check_for_apf );

sub check_for_apf {
    my $chkconfig_apf = run( 'chkconfig', '--list', 'apf' );
    if ( $chkconfig_apf and $chkconfig_apf =~ /3:on/ ) {
        print_3rdp('APF: ');
        print_3rdp2('installed, may be enabled.');
    }
}

1;
