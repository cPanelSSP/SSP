package PrintText;

use strict;
use warnings;
use diagnostics;

use Exporter;
our @ISA = qw( Exporter );
our @EXPORT = qw(
        print_info
        print_info2
        print_warn
        print_warning
        print_warning_underline
        print_3rdp
        print_3rdp2
        print_start
        print_normal
        print_magenta       
);

use Term::ANSIColor qw( :constants );
$Term::ANSIColor::AUTORESET = 1;

sub print_info {
    my $text = shift;
    print BOLD YELLOW ON_BLACK "[INFO] * $text";
}

sub print_info2 {
    my $text = shift;
    print BOLD GREEN ON_BLACK "$text\n";
}

sub print_warn {
    my $text = shift;
    print BOLD RED ON_BLACK "[WARN] * $text";
}

sub print_warning {
    my $text = shift;
    print BOLD RED ON_BLACK "$text\n";
}

## for other imporant things (e.g., "You are in an LVE, do not restart services")
sub print_warning_underline {
    my $text = shift;
    print BOLD UNDERLINE "$text\n";
}

sub print_3rdp {
    my $text = shift;
    print BOLD GREEN ON_BLACK "[3RDP] * $text";
}

sub print_3rdp2 {
    my $text = shift;
    print BOLD GREEN ON_BLACK "$text\n";
}

## precedes informational items (e.g., "Hostname:")
sub print_start {
    my $text = shift;
    print BOLD YELLOW ON_BLACK $text;
}
## for informational items (e.g., the server's hostname)
sub print_normal {
    my $text = shift;
    print BOLD CYAN ON_BLACK "$text\n";
}

sub print_magenta {
    my $text = shift;
    print BOLD MAGENTA ON_BLACK "$text\n";
}

1;
