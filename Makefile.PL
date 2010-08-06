use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'Regexp::RegGrp',
    'AUTHOR'        => 'Merten Falk <nevesenin@cpan.org>',
    'VERSION_FROM'  => 'lib/Regexp/RegGrp.pm',
    'ABSTRACT_FROM' => 'lib/Regexp/RegGrp.pm',
    (
        $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ('LICENSE'=> 'perl')
        : ()
    ),
    'PL_FILES'          => {},
    'PREREQ_PM'         => {
        'Test::More'    => 0,
    },
    'META_MERGE'        => {
        'resources'     => {
            'repository'    => 'http://github.com/nevesenin/regexp-reggrp-perl'
        }
    },
    'dist'  => {
        'COMPRESS'  => 'gzip -9f',
        'SUFFIX' => 'gz'
    },
    'clean' => {
        'FILES' => 'Regexp-RegGrp-*'
    },
);
