package ProcessList;

use strict;
use warnings;
use Cmd;

use Exporter;
our @ISA = qw( Exporter );
our @EXPORT = qw( @process_list );

our @process_list = split /\n/, run( 'ps', 'axwwwf', '-o', 'user,cmd' );

1;
