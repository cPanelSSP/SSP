package Warn::PureFTPd;

use strict;
use warnings;
use diagnostics;
use Cmd;
use PrintText;


sub check_pure_ftpd_conf_for_upload_script_and_dead {
    my ( $cpconf, $pureftpdconf ) = @_;

    return unless $cpconf->{'ftpserver'} && $cpconf->{'ftpserver'} eq 'pure-ftpd';

    if ( $pureftpdconf->{'CallUploadScript'} && $pureftpdconf->{'CallUploadScript'} eq 'yes' ) {
        if ( !-e '/var/run/pure-ftpd.upload.pipe' ) {
            print_warn("/etc/pure-ftpd.conf: ");
            print_warning("CallUploadScript set to yes, /var/run/pure-ftpd.upload.pipe is missing [might be broken ConfigServer's cxs ( http://configserver.com/cp/cxs.html )]");
        }
        else {
            my $out = run( 'lsof', '-n', '/var/run/pure-ftpd.upload.pipe' );
            if ( !$out ) {
                print_warn("/etc/pure-ftpd.conf: ");
                print_warning("CallUploadScript set to yes, and /var/run/pure-ftpd.upload.pipe does not seem to have anything listening on it. [might be broken ConfigServer's cxs ( http://configserver.com/cp/cxs.html )]");
            }
        }
    }
}

1;
