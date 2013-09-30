package Warn::ImageMagick;

use strict;
use warnings;
use diagnostics;
use PrintText;


sub check_for_multiple_imagemagick_installs {
    if ( -x '/usr/bin/convert' and !-l '/usr/bin/convert' ) {
        if ( -x '/usr/local/bin/convert' and !-l '/usr/local/bin/convert' ) {
            print_warn('ImageMagick: ');
            print_warning('multiple "convert" binaries found [/usr/bin/convert] [/usr/local/bin/convert]');
        }
    }
}

1;
