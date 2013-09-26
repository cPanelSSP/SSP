package Warn::PostgreSQL;

use strict;
use warnings;
use diagnostics;
use PrintText;

use Exporter;
our @ISA = qw( Exporter );
our @EXPORT = qw(
    check_for_empty_postgres_config
    check_for_custom_postgres_repo
);

sub check_for_empty_postgres_config {
    my $postgres_config = '/var/lib/pgsql/data/pg_hba.conf';
    if ( -f $postgres_config and -z $postgres_config ) {
        print_warn('Postgres config: ');
        print_warning("$postgres_config is empty (install via WHM >> Postgres Config)");
    }
}

sub check_for_custom_postgres_repo {
    my $yum_repos_dir = '/etc/yum.repos.d/';
    my @dir_contents;
    my $has_postgres_repo = 0;

    return if !-d $yum_repos_dir;

    opendir( my $dir_fh, $yum_repos_dir );
    @dir_contents = grep { !/^\.\.?$/ } readdir $dir_fh;
    closedir $dir_fh;

    for my $repos (@dir_contents) {
        if ( $repos =~ m{ \A pgdg-(\d+)-centos\.repo }xms ) {
            $has_postgres_repo = 1;
            last;
        }
    }

    if ( $has_postgres_repo == 1 ) {
        print_warn('PostgreSQL: ');
        print_warning('custom Postgres repo (pgdg-*) found in /etc/yum.repos.d/ . See tickets 3690445, 3568781');
    }
}

1;
