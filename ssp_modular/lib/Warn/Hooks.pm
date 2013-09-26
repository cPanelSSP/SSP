package Warn::Hooks;

use strict;
use warnings;
use diagnostics;
use Cmd;
use PrintText;
use File::Find;

use Exporter;
our @ISA = qw( Exporter );
our @EXPORT = qw(
    check_for_custom_event_handler
    check_for_hooks_in_scripts_directory
    check_for_usr_local_cpanel_hooks
    check_for_hooks_from_var_cpanel_hooks_yaml
);

my @usr_local_cpanel_hooks;

sub check_for_custom_event_handler {
    if ( -f '/usr/local/cpanel/Cpanel/CustomEventHandler.pm' ) {
        print_warn('Hooks: ');
        print_warning('/usr/local/cpanel/Cpanel/CustomEventHandler.pm exists!');
    }
}

sub check_for_hooks_in_scripts_directory {
    # default CloudLinux, cPGs hooks that can be ignored
    my %hooks_ignore = qw(
      e5e13640299ec439fb4c7f79a054e42b    /scripts/posteasyapache
      16d94b5426681a977e2beedd0ad871e9    /scripts/posteasyapache
      42a624c843f34085f1532b0b4e17fe8c    /scripts/postmodifyacct
      22cf7db1c069fd9672cd9dad3a3d371d    /scripts/postupcp
      57f8ea2d494e299827cc365c86a357ac    /scripts/postupcp
      e464adf0531fea2af4fe57361d9a43fb    /scripts/postupcp
      941772daaa48999f1d5ae5fe2f881e36    /scripts/postupcp
      4988be925a6f50ec505618a7cec702e2    /scripts/postkillacct
      a4df04a6440073fe40363cfd241b1fe7    /scripts/postwwwacct
      03a0dc919c892bde254c52cefe4d0673    /scripts/postwwwacct
      2401d6260dac6215596be1652b394200    /scripts/postwwwacct
      677da3bdd8fbd16d4b8917a9fe0f6f89    /scripts/postwwwacct
      44caf075fc0f9847ede43de5dd563edc    /scripts/prekillacct
      86f9b53c81a8f2fd77a8626ddd3b2c71    /scripts/prekillacct
      46fee9faf2d5f83cbcda17ce0178a465    /scripts/prekillacct
      677da3bdd8fbd16d4b8917a9fe0f6f89    /scripts/prekillacct

    );

    my @hooks;
    if ( -d '/scripts' ) {
        opendir( my $scripts_fh, '/scripts' );
        @hooks = grep { /^(pre|post)/ } readdir $scripts_fh;
        closedir $scripts_fh;
    }

    # these exist by default
    @hooks = grep { !/postsuexecinstall/ && !/post_sync_cleanup/ } @hooks;

    # CloudLinux stuff
    @hooks = grep { !/postwwwacct\.l\.v\.e-manager\.bak/ } @hooks;

    my $hooks_output;
    if (@hooks) {
        for my $hook (@hooks) {
            $hook = '/scripts/' . $hook;
            chomp( my $checksum = run( 'md5sum', $hook ) );
            $checksum =~ s/\s.*//g;
            next if exists $hooks_ignore{$checksum};

            if ( !-z $hook ) {
                $hooks_output .= " $hook ";
            }
        }
    }

    if ($hooks_output) {
        print_warn('Hooks: ');
        print_warning($hooks_output);
    }
}

sub check_for_usr_local_cpanel_hooks {
    my $hooks;
    my $dir = '/usr/local/cpanel/hooks';
    find( \&find_usr_local_cpanel_hooks, $dir );

    # default CloudLinux hooks that can be ignored
    my %hooks_ignore = qw(
      677da3bdd8fbd16d4b8917a9fe0f6f89    /usr/local/cpanel/hooks/addondomain/addaddondomain
      677da3bdd8fbd16d4b8917a9fe0f6f89    /usr/local/cpanel/hooks/addondomain/deladdondomain
      677da3bdd8fbd16d4b8917a9fe0f6f89    /usr/local/cpanel/hooks/subdomain/addsubdomain
      677da3bdd8fbd16d4b8917a9fe0f6f89    /usr/local/cpanel/hooks/subdomain/delsubdomain
    );

    if (@usr_local_cpanel_hooks) {
        for my $hook (@usr_local_cpanel_hooks) {
            my $tmp_hook = '/usr/local/cpanel/hooks/' . $hook;
            if ( -f $tmp_hook and !-z $tmp_hook ) {
                chomp( my $checksum = run( 'md5sum', $tmp_hook ) );
                $checksum =~ s/\s.*//g;
                next if exists $hooks_ignore{$checksum};
                $hooks .= "$hook ";
            }
        }
    }

    if ($hooks) {
        print_warn("$dir: ");
        print_warning($hooks);
    }
}

sub find_usr_local_cpanel_hooks {
    my $file = $File::Find::name;
    if ( -f $file and $file !~ m{ ( README | \.example ) \z }xms ) {
        $file =~ s#/usr/local/cpanel/hooks/##;
        push @usr_local_cpanel_hooks, $file;
    }
}

sub check_for_hooks_from_var_cpanel_hooks_yaml {
    my $hooks_yaml = '/var/cpanel/hooks.yaml';
    my ( @hooks_tmp, @hooks );

    if ( open my $file_fh, '<', $hooks_yaml ) {
        while (<$file_fh>) {
            if (/hook: (.*)/) {
                # Ignore default Attracta hooks
                next if ( $1 =~ m{ \A ( /usr/local/cpanel/3rdparty/attracta/scripts/pkgacct-restore | /usr/local/cpanel/Cpanel/ThirdParty/Attracta/Hooks/pkgacct-restore ) \z }xms );
                push @hooks_tmp, "$1 ";
            }
        }
        close $file_fh;
    }

    for my $hook (@hooks_tmp) {
        if ( -e $hook and !-z $hook ) {
            push @hooks, $hook;
        }
    }

    if ( scalar @hooks == 1 ) {
        print_warn('Hooks in /var/cpanel/hooks.yaml: ');
        print_warning(@hooks);
    }
    elsif ( scalar @hooks > 1 ) {
        print_warn("Hooks in /var/cpanel/hooks.yaml:\n");
        for my $hook (@hooks) {
            print_magenta("\t \\_ $hook");
        }
    }
}

1;
