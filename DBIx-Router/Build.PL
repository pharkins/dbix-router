use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'DBIx::Router',
    license             => 'perl',
    dist_author         => 'Perrin Harkins <perrin@elem.com>',
    dist_version_from   => 'lib/DBIx/Router.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'DBIx-Router-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
