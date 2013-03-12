package Stordoc::Regexp::RegGrp;

use strict;
use warnings;

use Test::Class::Most parent => 'TestCase';

use Regexp::RegGrp;
use Regexp::RegGrp::Data;

sub test__adjust_restore_pattern_attribute : Tests() {
    my $mocked_reggrp = Test::MockModule->new( 'Regexp::RegGrp' );

    $mocked_reggrp->mock(
        'new',
        sub {
            my ( $class ) = @_;

            my $self = { _restore_pattern => undef };

            bless( $self, $class );

            return $self;
        }
    );

    my $reggrp = Regexp::RegGrp->new();



    $mocked_reggrp->unmock_all();
}

sub test__create_reggrp_objects : Tests() {
    my $mocked_reggrp = Test::MockModule->new( 'Regexp::RegGrp' );

    $mocked_reggrp->mock(
        'new',
        sub {
            my ( $class ) = @_;

            my $self = { _reggrps => [], _reggrp => [ {} ] };

            bless( $self, $class );

            return $self;
        }
    );

    my $reggrp = Regexp::RegGrp->new();

    my $ret;
    warnings_are( sub { $reggrp->_create_reggrp_objects(); }, [ 'Value for key "regexp" must be given!', 'RegGrp No 1 in arrayref is malformed!' ] );
    cmp_deeply( [ $reggrp->reggrp_array() ], [] );

    $reggrp->{_reggrp} = [ { regexp => qr/Foo/ } ];
    $reggrp->_create_reggrp_objects();

    cmp_deeply( [ $reggrp->reggrp_array() ], [ isa( 'Regexp::RegGrp::Data' ) ] );

    $mocked_reggrp->unmock_all();
}

sub test__create_reggrp_object : Tests() {
    my $mocked_reggrp = Test::MockModule->new( 'Regexp::RegGrp' );

    $mocked_reggrp->mock(
        'new',
        sub {
            my ( $class ) = @_;

            my $self = { _reggrps => [] };

            bless( $self, $class );

            return $self;
        }
    );

    my $reggrp = Regexp::RegGrp->new();

    my $ret;

    cmp_deeply( [ $reggrp->reggrp_array() ], [] );

    warning_is( sub { $ret = $reggrp->_create_reggrp_object( {} ) }, 'Value for key "regexp" must be given!' );
    is( $ret, 0 );

    cmp_deeply( [ $reggrp->reggrp_array() ], [] );

    is( $reggrp->_create_reggrp_object( { regexp => qr/Foo/ } ), 1 );

    cmp_deeply( [ $reggrp->reggrp_array() ], [ isa( 'Regexp::RegGrp::Data' ) ] );

    $mocked_reggrp->unmock_all();
}

sub test_replacements_methods : Tests() {
    my $mocked_reggrp = Test::MockModule->new( 'Regexp::RegGrp' );

    $mocked_reggrp->mock(
        'new',
        sub {
            my ( $class ) = @_;

            my $self = {};

            bless( $self, $class );

            return $self;
        }
    );

    my $reggrp = Regexp::RegGrp->new();

    is( $reggrp->replacements_count(), 0 );

    $reggrp->replacements_add( 'Foo' );
    is( $reggrp->replacements_count(), 1 );
    cmp_deeply( $reggrp->replacements_by_idx( 0 ), 'Foo' );

    $reggrp->replacements_add( 'Bar' );
    is( $reggrp->replacements_count(), 2 );
    cmp_deeply( $reggrp->replacements_by_idx( 1 ), 'Bar' );

    $reggrp->replacements_flush();
    is( $reggrp->replacements_count(), 0 );

    $mocked_reggrp->unmock_all();
}

sub test_reggrp_methods : Tests() {
    my $mocked_reggrp = Test::MockModule->new( 'Regexp::RegGrp' );

    $mocked_reggrp->mock(
        'new',
        sub {
            my ( $class ) = @_;

            my $self = { _reggrps => [] };

            bless( $self, $class );

            return $self;
        }
    );

    my $reggrp = Regexp::RegGrp->new();

    cmp_deeply( [ $reggrp->reggrp_array() ], [] );

    my $reggrp_a = Regexp::RegGrp::Data->new( { regexp => qr/Foo/ } );
    my $reggrp_b = Regexp::RegGrp::Data->new( { regexp => qr/Bar/ } );

    $reggrp->reggrp_add( $reggrp_a );
    cmp_deeply( [ $reggrp->reggrp_array() ], [$reggrp_a] );

    $reggrp->reggrp_add( $reggrp_b );
    cmp_deeply( [ $reggrp->reggrp_array() ], [ $reggrp_a, $reggrp_b ] );

    cmp_deeply( $reggrp->reggrp_by_idx( 0 ), $reggrp_a );
    cmp_deeply( $reggrp->reggrp_by_idx( 1 ), $reggrp_b );

    $mocked_reggrp->unmock_all();
}

sub test__args_are_valid : Tests() {
    my $mocked_reggrp = Test::MockModule->new( 'Regexp::RegGrp' );

    $mocked_reggrp->mock(
        'new',
        sub {
            my ( $class ) = @_;

            my $self = {};

            bless( $self, $class );

            return $self;
        }
    );

    my $reggrp = Regexp::RegGrp->new();

    my $ret;
    warning_is( sub { $ret = $reggrp->_args_are_valid() }, 'First argument must be a hashref!' );
    is( $ret, 0 );
    warning_is( sub { $ret = $reggrp->_args_are_valid( {} ) }, 'Key "reggrp" does not exist in input hashref!' );
    is( $ret, 0 );
    warning_is( sub { $ret = $reggrp->_args_are_valid( { reggrp => {} } ) }, 'Value for key "reggrp" must be an arrayref!' );
    is( $ret, 0 );
    is( $reggrp->_args_are_valid( { reggrp => [] } ), 1 );

    is( $reggrp->_args_are_valid( { reggrp => [], restore_pattern => undef } ), 1 );

    warning_is(
        sub { $ret = $reggrp->_args_are_valid( { reggrp => [], restore_pattern => [] } ) },
        'Value for key "restore_pattern" must be a scalar or regexp!',
        'Test "restore_pattern" value.'
    );
    is( $ret, 0 );
    is( $reggrp->_args_are_valid( { reggrp => [], restore_pattern => 'Bar' } ), 1, 'Test "restore_pattern" value.' );
    is(
        $reggrp->_args_are_valid(
            {
                reggrp          => [],
                restore_pattern => qr/Bar/,
            }
        ),
        1,
        'Test "restore_pattern" value.'
    );

    $mocked_reggrp->unmock_all();
}

sub io_test : Tests() {
    my $test_cases = _get_test_cases();

    foreach my $tc ( @{$test_cases} ) {
        my $reggrp = Regexp::RegGrp->new( { reggrp => $tc->{reggrp}, restore_pattern => $tc->{restore_pattern} } );
        my $input = $tc->{input_string};

        $reggrp->exec( \$input );

        if ( $tc->{test_restore} ) {
            $reggrp->restore_stored( \$input );
        }

        is( $input, $tc->{expected_output}, $tc->{description} . ' - void context' );

        $reggrp->replacements_flush();

        $input = $tc->{input_string};

        my $output = $reggrp->exec( \$input );

        if ( $tc->{test_restore} ) {
            $output = $reggrp->restore_stored( \$output );
        }

        is( $output, $tc->{expected_output}, $tc->{description} . ' - scalar context' );
    }
}

sub _get_test_cases : Tests() {
    return [
        {
            description     => 'Simple regexes without replacements',
            input_string    => 'abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz',
            expected_output => 'abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz',
            reggrp          => [ { regexp => qr/ab/ }, { regexp => qr/yz/ }, { regexp => qr/foo/ } ]
        },
        {
            description     => 'Simple regexes with scalar replacements',
            input_string    => 'abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz',
            expected_output => 'ABcdefghijklmnopqrstuvwxYZABcdefghijklmnopqrstuvwxYZ',
            reggrp          => [
                {
                    regexp      => qr/ab/,
                    replacement => 'AB'
                },
                {
                    regexp      => qr/yz/,
                    replacement => 'YZ'
                },
                {
                    regexp      => qr/foo/,
                    replacement => 'BAR'
                }
            ]
        },
        {
            description     => 'Simple regexes with sub replacements I',
            input_string    => 'abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz',
            expected_output => 'bacdefghijklmnopqrstuvwxyYZbacdefghijklmnopqrstuvwxyYZ',
            reggrp          => [
                {
                    regexp      => qr/(a)(.)/,
                    replacement => sub {
                        my $in_ref     = shift;
                        my $submatches = $in_ref->{submatches};
                        return sprintf( "%s%s", $submatches->[1], $submatches->[0] );
                        }
                },
                {
                    regexp      => qr/((y)z)/,
                    replacement => sub {
                        my $in_ref     = shift;
                        my $submatches = $in_ref->{submatches};
                        return sprintf( "%s%s", $submatches->[1], uc( $submatches->[0] ) );
                        }
                },
                {
                    regexp      => qr/f(oo)?/,
                    replacement => sub {
                        my $in_ref     = shift;
                        my $match      = $in_ref->{match};
                        my $submatches = $in_ref->{submatches};
                        return sprintf( "%s%s", $match, $submatches->[0] );
                        }
                }
            ]
        },
        {
            description     => 'Simple regexes with sub replacements II',
            input_string    => 'a1a2a0a1a0a2a3bcde',
            expected_output => 'a1a2a0a1a0a2a3bcde',
            reggrp          => [
                {
                    regexp      => qr/(a)(\d)/,
                    replacement => sub {
                        my $in_ref     = shift;
                        my $submatches = $in_ref->{submatches};

                        return sprintf( "%s%s", $submatches->[0], $submatches->[1] );
                        }
                }
            ]
        },
        {
            description     => 'Regexes with backreferences 1',
            input_string    => 'abcxyzabcxyz',
            expected_output => 'bcxyzaAbcxyz',
            reggrp          => [
                {
                    regexp      => qr/(a)(.+?)(\1)/,
                    replacement => sub {
                        my $in_ref     = shift;
                        my $submatches = $in_ref->{submatches};
                        return sprintf( "%s%s%s", $submatches->[1], $submatches->[0], uc( $submatches->[2] ) );
                        }
                },
                {
                    regexp      => qr/((y)z).+(\1)/,
                    replacement => sub {
                        my $in_ref     = shift;
                        my $submatches = $in_ref->{submatches};
                        return sprintf( "%s%s", $submatches->[0], uc( $submatches->[1] ) );
                        }
                },
                {
                    regexp      => qr/f(oo)?/,
                    replacement => sub {
                        my $in_ref     = shift;
                        my $match      = $in_ref->{match};
                        my $submatches = $in_ref->{submatches};
                        return sprintf( "%s%s", $match, $submatches->[0] );
                        }
                }
            ]
        },
        {
            description     => 'Regexes with backreferences 2',
            input_string    => 'abcxyzabcxyzabcxyz',
            expected_output => ( $] < 5.010000 ) ? 'bcxyzaAbcxyzabcxyz' : 'bcxyzaAbcxyzYyz',
            reggrp          => [
                {
                    regexp      => qr/(a)(.+?)(\1)/,
                    replacement => sub {
                        my $in_ref     = shift;
                        my $submatches = $in_ref->{submatches};
                        return sprintf( "%s%s%s", $submatches->[1], $submatches->[0], uc( $submatches->[2] ) );
                        }
                },
                {
                    regexp      => qr/((y)z)(.+)(\g{2})/,
                    replacement => sub {
                        my $in_ref     = shift;
                        my $submatches = $in_ref->{submatches};
                        return sprintf( "%s%s%s", $submatches->[0], uc( $submatches->[1] ), $submatches->[3] );
                        }
                },
                {
                    regexp      => qr/f(oo)?/,
                    replacement => sub {
                        my $in_ref     = shift;
                        my $match      = $in_ref->{match};
                        my $submatches = $in_ref->{submatches};
                        return sprintf( "%s%s", $match, $submatches->[0] );
                        }
                }
            ]
        },
        {
            description     => 'Store replacements',
            input_string    => 'abcxyzabcxyzabcxyz',
            expected_output => "\x01" . '0' . "\x01" . 'bcx' . "\x01" . '1' . "\x01" . 'z',
            reggrp          => [
                {
                    regexp      => qr/(a)(.+?)(\1)/,
                    replacement => sub {
                        my $in_ref     = shift;
                        my $submatches = $in_ref->{submatches};
                        return sprintf( "%s%s%s", $submatches->[1], $submatches->[0], uc( $submatches->[2] ) );
                    },
                    placeholder => sub { return sprintf( "\x01%d\x01", $_[0]->{placeholder_index} ); },
                },
                {
                    regexp      => qr/((y)z)(.+)(\2)/,
                    replacement => sub {
                        my $in_ref     = shift;
                        my $submatches = $in_ref->{submatches};
                        return sprintf( "%s%s%s", $submatches->[0], uc( $submatches->[1] ), $submatches->[3] );
                    },
                    placeholder => sub { return sprintf( "\x01%d\x01", $_[0]->{placeholder_index} ); },
                },
                {
                    regexp      => qr/f(oo)?/,
                    replacement => sub {
                        my $in_ref     = shift;
                        my $match      = $in_ref->{match};
                        my $submatches = $in_ref->{submatches};
                        return sprintf( "%s%s", $match, $submatches->[0] );
                        }
                }
            ]
        },
        {
            description     => 'Restore replacements',
            input_string    => 'abcxyzabcxyzabcxyz',
            expected_output => 'bcxyzaAbcxyzYyz',
            test_restore    => 1,
            reggrp          => [
                {
                    regexp      => qr/(a)(.+?)(\1)/,
                    replacement => sub {
                        my $in_ref     = shift;
                        my $submatches = $in_ref->{submatches};
                        return sprintf( "%s%s%s", $submatches->[1], $submatches->[0], uc( $submatches->[2] ) );
                    },
                    placeholder => sub { return sprintf( "\x01%d\x01", $_[0]->{placeholder_index} ); },
                },
                {
                    regexp      => qr/((y)z)(.+)(\2)/,
                    replacement => sub {
                        my $in_ref     = shift;
                        my $submatches = $in_ref->{submatches};
                        return sprintf( "%s%s%s", $submatches->[0], uc( $submatches->[1] ), $submatches->[3] );
                    },
                    placeholder => sub { return sprintf( "\x01%d\x01", $_[0]->{placeholder_index} ); },
                },
                {
                    regexp      => qr/f(oo)?/,
                    replacement => sub {
                        my $in_ref     = shift;
                        my $match      = $in_ref->{match};
                        my $submatches = $in_ref->{submatches};
                        return sprintf( "%s%s", $match, $submatches->[0] );
                        }
                }
            ]
        },
        {
            description     => 'Store replacements with custom pattern',
            input_string    => 'abcxyzabcxyzabcxyz',
            expected_output => '~~0~~bcx~~1~~z',
            restore_pattern => qr/~~(\d+)~~/,
            reggrp          => [
                {
                    regexp      => qr/(a)(.+?)(\1)/,
                    placeholder => sub {
                        my $in_ref            = shift;
                        my $placeholder_index = $in_ref->{placeholder_index};
                        return sprintf( "~~%d~~", $placeholder_index );
                    },
                    replacement => sub {
                        my $in_ref     = shift;
                        my $submatches = $in_ref->{submatches};
                        return sprintf( "%s%s%s", $submatches->[1], $submatches->[0], uc( $submatches->[2] ) );
                        }
                },
                {
                    regexp      => qr/((y)z)(.+)(\2)/,
                    placeholder => sub {
                        my $in_ref            = shift;
                        my $placeholder_index = $in_ref->{placeholder_index};
                        return sprintf( "~~%d~~", $placeholder_index );
                    },
                    replacement => sub {
                        my $in_ref     = shift;
                        my $submatches = $in_ref->{submatches};
                        return sprintf( "%s%s%s", $submatches->[0], uc( $submatches->[1] ), $submatches->[3] );
                        }
                },
                {
                    regexp      => qr/f(oo)?/,
                    replacement => sub {
                        my $in_ref     = shift;
                        my $match      = $in_ref->{match};
                        my $submatches = $in_ref->{submatches};
                        return sprintf( "%s%s", $match, $submatches->[0] );
                        }
                }
            ]
        },
        {
            description     => 'Restore replacements with custom pattern',
            input_string    => 'abcxyzabcxyzabcxyz',
            expected_output => 'bcxyzaAbcxyzYyz',
            restore_pattern => qr/~~(\d+)~~/,
            test_restore    => 1,
            reggrp          => [
                {
                    regexp      => qr/(a)(.+?)(\1)/,
                    placeholder => sub {
                        my $in_ref            = shift;
                        my $placeholder_index = $in_ref->{placeholder_index};
                        return sprintf( "~~%d~~", $placeholder_index );
                    },
                    replacement => sub {
                        my $in_ref     = shift;
                        my $submatches = $in_ref->{submatches};
                        return sprintf( "%s%s%s", $submatches->[1], $submatches->[0], uc( $submatches->[2] ) );
                        }
                },
                {
                    regexp      => qr/((y)z)(.+)(\2)/,
                    placeholder => sub {
                        my $in_ref            = shift;
                        my $placeholder_index = $in_ref->{placeholder_index};
                        return sprintf( "~~%d~~", $placeholder_index );
                    },
                    replacement => sub {
                        my $in_ref     = shift;
                        my $submatches = $in_ref->{submatches};
                        return sprintf( "%s%s%s", $submatches->[0], uc( $submatches->[1] ), $submatches->[3] );
                        }
                },
                {
                    regexp      => qr/f(oo)?/,
                    replacement => sub {
                        my $in_ref     = shift;
                        my $match      = $in_ref->{match};
                        my $submatches = $in_ref->{submatches};
                        return sprintf( "%s%s", $match, $submatches->[0] );
                        }
                }
            ]
        },
        {
            description     => 'Modifier test 1',
            input_string    => "   \n\n\n\t   \n  a \nb\n  c\n\n",
            expected_output => "\n\n\n\na\nb\nc\n\n",
            reggrp          => [
                {
                    regexp      => '^[^\S\n]*',
                    replacement => ''
                },
                {
                    regexp      => '[^\S\n]$',
                    replacement => ''
                },
                {
                    regexp      => 'B',
                    replacement => 'd'
                }
            ]
        },
        {
            description     => 'Modifier test 2',
            input_string    => "   \n\n\n\t   \n  a \n\n\nb\n  c\n\n",
            expected_output => "a \n\n\nd\n  c",
            reggrp          => [
                {
                    regexp      => '^\s*',
                    replacement => '',
                    modifier    => 's'
                },
                {
                    regexp      => '\s*$',
                    replacement => '',
                    modifier    => 's'
                },
                {
                    regexp      => 'B',
                    replacement => 'd',
                    modifier    => 'i'
                }
            ]
        },
        {
            description     => 'Zero-length submatch test',
            input_string    => "   \n\n\n\t   \n  a \n\n\nb\n  c\n\n",
            expected_output => "a \n\n\nx\nc",
            reggrp          => [
                {
                    regexp      => '^\s*',
                    replacement => '',
                    modifier    => 's'
                },
                {
                    regexp      => '^[^\S\n]*',
                    replacement => '',
                    modifier    => 'm'
                },
                {
                    regexp      => '\s*$',
                    replacement => '',
                    modifier    => 's'
                },
                {
                    regexp      => 'b',
                    replacement => 'x'
                }
            ]
        }
    ];
}

1;
