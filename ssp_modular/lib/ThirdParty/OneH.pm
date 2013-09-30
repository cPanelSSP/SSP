package ThirdParty::OneH;

use strict;
use warnings;
use diagnostics;
use Vars;
use PrintText;
use Cmd;

sub one_h {
    my $one_h = 0;
    my ( $hive_module, $guardian );

    if ( -d '/usr/local/1h' ) {
        $one_h = 1;
        if (@apache_modules_output) {
            for my $line (@apache_modules_output) {
                if ( $line =~ /hive/ ) {
                    $hive_module = 'loaded';
                }
                else {
                    $hive_module = 'not active';
                }
            }
        }
        if ( -x '/usr/local/1h/sbin/guardian' ) {
            for my $line (@process_list) {
                if ( $line =~ /Guardian/ ) {
                    $guardian = 'running';
                }
                else {
                    $guardian = 'not running';
                }
            }
        }
        else {
            $guardian = 'not running';
        }
    }

    if ( $one_h == 1 ) {
        print_3rdp('1H Software: ');
        print_3rdp2("/usr/local/1h exists. hive apache module: [ $hive_module ] Guardian process: [ $guardian ]");
    }
}

1;
