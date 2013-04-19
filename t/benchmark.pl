#!/usr/bin/env perl

use strict;
use warnings;

use lib 'lib';

use Regexp::RegGrp;

use Benchmark qw(:all);

my $reggrp = Regexp::RegGrp->new(
    {
        reggrp => [
            {
                regexp      => qr/F.o/,
                replacement => 'Bar',
                placeholder => sub { return sprintf( "\x01%d\x01", $_[0]->{placeholder_index} ); }
            },
            {
                regexp      => qr/Blu/,
                replacement => 'Bla',
                placeholder => sub { return sprintf( "\x01%d\x01", $_[0]->{placeholder_index} ); }
            }
        ]
    }
);

cmpthese(
    # 1,
        1_000_000,
        {
            'old' => sub {
                my $input = 'Blah Foo Blubb';
                $reggrp->exec( \$input );
                $reggrp->restore_stored( \$input );
            },
            'new' => sub {
                my $input = 'Blah Foo Blubb';
                $reggrp->exec( \$input, {}, 1 );
                $reggrp->restore_stored( \$input );
            },
        }
    );

