package Warn::MySQL;

use strict;
use warnings;
use diagnostics;
use Vars;
use Cmd;
use PrintText;


sub check_mysql_non_default_datadir {
    if ( $mysql_datadir !~ m{ /var/lib/mysql(/?) \z }xms ) {
        print_warn('MySQL non-default datadir: ');
        print_warning($mysql_datadir);
    }
}

sub check_mysqld_warnings_errors {
    foreach my $mysql_err ( grep ( m{\[(?:err)}i, split( /\n/, run_trap_stderr( 'mysqld', '-u', 'mysql', '--help' ) ) ) ) {
        if ( $mysql_err =~ m/open_files_limit=/ ) {
            print_warn('MySQL config missing newline: [see FB 64008]: ');
            print_warning($mysql_err);
        }
        else {
            print_warn('MySQL config errors: ');
            print_warning($mysql_err);
        }
    }
}

sub check_for_non_default_mysql_error_log_location {
    if ( $mysql_error_log and $mysql_error_log !~ m# \A /var/lib/mysql/${hostname}\.err \z #xms ) {
        print_warn('MySQL: ');
        print_warning("error log configured in /etc/my.cnf as $mysql_error_log");
    }
}

sub check_for_my_cnf_skip_name_resolve {
    my $skip_name_resolve = 0;

    my $my_cnf = '/etc/my.cnf';
    if ( open my $my_cnf_fh, '<', $my_cnf ) {
        while (<$my_cnf_fh>) {
            chomp( my $line = $_ );
            if ( $line =~ m{ \A skip_name_resolve }xms ) {
                $skip_name_resolve = 1;
                last;
            }
        }
        close $my_cnf;
    }

    if ( $skip_name_resolve == 1 ) {
        print_warn('/etc/my.cnf: ');
        print_warning('skip_name_resolve found. Seeing "Can\'t find any matching row"? That may be why');
    }
}

sub check_for_my_cnf_sql_mode {
    my $sql_mode = 0;

    my $my_cnf = '/etc/my.cnf';
    if ( open my $my_cnf_fh, '<', $my_cnf ) {
        while (<$my_cnf_fh>) {
            chomp( my $line = $_ );
            if ( $line =~ m{ \A sql[-_]mode }xms ) {
                $sql_mode = 1;
                last;
            }
        }
        close $my_cnf;
    }

    if ( $sql_mode == 1 ) {
        print_warn('/etc/my.cnf: ');
        print_warning('sql_mode or sql-mode found. Seeing "Field \'ssl_cipher\' doesn\'t have a default value"? That may be why');
    }
}

sub check_for_mysql_root_pass_with_single_quote {
    my $mycnf = '/root/.my.cnf';
    return if !-f $mycnf;

    my $has_single_quote = 0;

    open my $mycnf_fh, '<', $mycnf or return;
    while ( <$mycnf_fh> ) {
        chomp;
        if ( /^(?:[\s\t]?)+pass(?:[^"']+)?=(?:[\s\t]?)+(?:["']?)(.*)(?:["']+)$/ ) {
            if ( $1 =~ /'/ ) {
                $has_single_quote = 1;
                last;
            }
        }
    }
    close $mycnf_fh;

    if ( $has_single_quote && $has_single_quote == 1 ) {
        print_warn('mysql root user: ');
        print_warning('pass has single quote. This breaks mysql_upgrade! mysql.proc issues? See FB 73533');
    }
}

1;
