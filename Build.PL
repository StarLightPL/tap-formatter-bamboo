use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'TAP::Formatter::Bamboo',
    license             => 'perl',
    dist_author         => q{Piotr Piątkowski <pp@idea7.pl>},
    dist_version_from   => 'lib/TAP/Formatter/Bamboo.pm',
    release_status      => 'stable',
    configure_requires => {
        'Module::Build' => 0,
    },
    build_requires => {
        'Test::More'  => 0,
        'File::Slurp' => 0,
        'File::Temp'  => 0,
        'Test::XML'   => 0,
    },
    requires => {
        'Moose'            => 2.0000,
        'MooseX::NonMoose' => 0.20,
        'TAP::Harness'     => 3.20,
        'Encode'           => 2.42,
        'XML::LibXML'      => 2.0000,
    },
    add_to_cleanup     => [ 'TAP-Formatter-Bamboo-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
