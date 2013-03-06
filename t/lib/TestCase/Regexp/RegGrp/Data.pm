package Stordoc::Regexp::RegGrp::Data;

use strict;
use warnings;

use Test::Class::Most parent => 'TestCase';

use Regexp::RegGrp::Data;

sub constructor_test : Tests() {
    my $mocked_data = Test::MockModule->new( 'Regexp::RegGrp::Data' );

    $mocked_data->mock( '_args_are_valid', sub { return 0; } );
    ok( ! Regexp::RegGrp::Data->new() );

    $mocked_data->unmock_all();

    my $data = Regexp::RegGrp::Data->new( { regexp => qr/Foo/ } );

    isa_ok( $data, 'Regexp::RegGrp::Data' );
    can_ok( $data, ( 'regexp', 'replacement', 'placeholder' ) );
}

sub test__adjust_regexp_attribute : Tests() {
    my $mocked_data = Test::MockModule->new( 'Regexp::RegGrp::Data' );

    $mocked_data->mock(
        'new',
        sub {
            my ( $class ) = @_;

            my $self = {};

            bless( $self, $class );

            return $self;
        }
    );

    my $data = Regexp::RegGrp::Data->new();

    $data->{_regexp} = qr/Foo/;
    $data->_adjust_regexp_attribute();
    is( $data->regexp(), ( $] < 5.013006 ) ? '(?-xism:Foo)' : '(?^:Foo)', 'Test regexp is a regexp object.' );

    $data->{_regexp} = 'Foo';
    $data->_adjust_regexp_attribute();
    is( $data->regexp(), '(?sm:Foo)', 'Test regexp is a scalar.' );

    $data->{_regexp} = qr/Foo/;
    $data->{_modifier} = 's';
    $data->_adjust_regexp_attribute();
    is( $data->regexp(), '(?s:Foo)', 'regexp is a regexp object and modifier is set.' );

    $data->{_regexp} = 'Foo';
    $data->{_modifier} = 's';
    $data->_adjust_regexp_attribute();
    is( $data->regexp(), '(?s:Foo)', 'Test regexp is a scalar and modifier is set.' );

    $mocked_data->unmock_all();
}

sub test__args_are_valid : Tests() {
    my $mocked_data = Test::MockModule->new( 'Regexp::RegGrp::Data' );

    $mocked_data->mock(
        'new',
        sub {
            my ( $class ) = @_;

            my $self = {};

            bless( $self, $class );

            return $self;
        }
    );

    my $data = Regexp::RegGrp::Data->new();

    warning_is( sub { $data->_args_are_valid() }, 'Args must be a hashref!', 'Check for hashref.' );
    warning_is( sub { $data->_args_are_valid( {} ) }, 'Value for key "regexp" must be given!', 'Test presence of key "regexp".' );
    warning_is( sub { $data->_args_are_valid( { regexp => [] } ) }, 'Value for key "regexp" must be a scalar or a regexp object!', 'Test "regexp" value.' );
    ok( $data->_args_are_valid( { regexp => 'Foo' } ),   'Test "regexp" value.' );
    ok( $data->_args_are_valid( { regexp => qr/Foo/ } ), 'Test "regexp" value.' );

    warning_is(
        sub { $data->_args_are_valid( { regexp => 'Foo', replacement => [] } ) },
        'Value for key "replacement" must be a scalar or a code reference!',
        'Test "replacement" value.'
    );
    ok( $data->_args_are_valid( { regexp => 'Foo', replacement => 'Bar' } ), 'Test "replacement" value.' );
    ok(
        $data->_args_are_valid(
            {
                regexp      => 'Foo',
                replacement => sub { return 'Bar'; }
            }
        ),
        'Test "replacement" value.'
    );

    warning_is(
        sub { $data->_args_are_valid( { regexp => 'Foo', placeholder => [] } ) },
        'Value for key "placeholder" must be a scalar or a code reference!',
        'Test "placeholder" value.'
    );
    ok( $data->_args_are_valid( { regexp => 'Foo', placeholder => 'Bar' } ), 'Test "placeholder" value.' );
    ok(
        $data->_args_are_valid(
            {
                regexp      => 'Foo',
                placeholder => sub { return 'Bar'; }
            }
        ),
        'Test "placeholder" value.'
    );

    warning_is(
        sub { $data->_args_are_valid( { regexp => 'Foo', modifier => [] } ) },
        'Value for key "modifier" must be a scalar!',
        'Test "modifier" value.'
    );
    ok( $data->_args_are_valid( { regexp => 'Foo', modifier => 'g' } ), 'Test "modifier" value.' );

    $mocked_data->unmock_all();
}

sub regexp_tests : Tests() {
    my $regexp_tests = _get_regexp_tests();

    foreach my $test ( @$regexp_tests ) {
        my $data;

        if ( $test->{warning} ) {
            warning_is( sub { $data = Regexp::RegGrp::Data->new( $test->{input} ) }, $test->{warning}, 'Constructor failed!' );
        }
        else {
            $data = Regexp::RegGrp::Data->new( $test->{input} );

            ok( $data, 'Regexp::RegGrp::Data object successfuly created!' );
        }

        if ( $data ) {
            cmp_ok( $data->regexp(), 'eq', $test->{output}->{regexp}, 'Field "regexp" correctly set' . ( $test->{message} ? ' - ' . $test->{message} : '' ) );
        }
    }
}

sub replacement_tests : Tests() {
    my $replacement_tests = _get_replacement_tests();

    foreach my $test ( @$replacement_tests ) {
        my $data;

        if ( defined $test->{warning} ) {
            warning_is( sub { $data = Regexp::RegGrp::Data->new( $test->{input} ) }, $test->{warning}, 'Constructor failed!' );
        }
        else {
            $data = Regexp::RegGrp::Data->new( $test->{input} );

            ok( $data, 'Regexp::RegGrp::Data object successfuly created!' );
        }

        if ( $data ) {
            if ( ref( $data->replacement() ) eq 'CODE' ) {
                cmp_deeply(
                    $data->replacement()->(),
                    $test->{output}->{replacement},
                    'Field "replacement" correctly set' . ( $test->{message} ? ' - ' . $test->{message} : '' )
                );
            }
            else {
                cmp_deeply(
                    $data->replacement(),
                    $test->{output}->{replacement},
                    'Field "replacement" correctly set' . ( $test->{message} ? ' - ' . $test->{message} : '' )
                );
            }
        }
    }
}

sub placeholder_tests : Tests() {
    my $placeholder_tests = _get_placeholder_tests();

    foreach my $test ( @$placeholder_tests ) {
        my $data;

        if ( defined $test->{warning} ) {
            warning_is( sub { $data = Regexp::RegGrp::Data->new( $test->{input} ) }, $test->{warning}, 'Constructor failed!' );
        }
        else {
            $data = Regexp::RegGrp::Data->new( $test->{input} );

            ok( $data, 'Regexp::RegGrp::Data object successfuly created!' );
        }

        if ( $data ) {
            if ( ref( $data->placeholder() ) eq 'CODE' ) {
                my $args = { placeholder_index => 1 };
                cmp_deeply(
                    $data->placeholder()->( $args ),
                    $test->{output}->{placeholder},
                    'Field "placeholder" correctly set' . ( $test->{message} ? ' - ' . $test->{message} : '' )
                );
            }
            else {
                cmp_deeply(
                    $data->placeholder(),
                    $test->{output}->{placeholder},
                    'Field "placeholder" correctly set' . ( $test->{message} ? ' - ' . $test->{message} : '' )
                );
            }
        }
    }
}

sub modifier_tests : Tests() {
    my $modifier_tests = _get_modifier_tests();

    foreach my $test ( @$modifier_tests ) {
        my $data;

        if ( $test->{warning} ) {
            warning_is( sub { $data = Regexp::RegGrp::Data->new( $test->{input} ) }, $test->{warning}, 'Constructor failed!' );
        }
        else {
            $data = Regexp::RegGrp::Data->new( $test->{input} );

            ok( $data, 'Regexp::RegGrp::Data object successfuly created!' );
        }

        if ( $data ) {
            cmp_ok( $data->regexp(), 'eq', $test->{output}->{regexp}, 'Field "regexp" correctly set' . ( $test->{message} ? ' - ' . $test->{message} : '' ) );
        }
    }
}

sub _get_modifier_tests {
    return [
        {
            input => {
                regexp   => '(a)(.+?)(\1)',
                modifier => { regexp => qr/(a)(.+?)(\1)/ },
            },
            output  => undef,
            message => 'modifier is a hashref',
            warning => 'Value for key "modifier" must be a scalar!',
        },
        {
            input => {
                regexp   => '(a)(.+?)(\1)',
                modifier => \'xsm',
            },
            output  => undef,
            message => 'modifier is a scalarref',
            warning => 'Value for key "modifier" must be a scalar!',
        },
        {
            input   => { regexp => '(a)(.+?)(\1)', },
            output  => { regexp => '(?sm:(a)(.+?)(\1))' },
            message => 'modifier is undefined and regexp is a scalar'
        },
        {
            input  => { regexp => qr/(a)(.+?)(\1)/, },
            output => { regexp => ( $] < 5.013006 ) ? '(?-xism:(a)(.+?)(\1))' : '(?^:(a)(.+?)(\1))' },
            message => 'modifier is undefined and regexp is a regexp object'
        },
    ];
}

sub _get_placeholder_tests {
    return [
        {
            input   => { regexp      => '(a)(.+?)(\1)', },
            output  => { placeholder => undef },
            message => 'store is undefined'
        },
        {
            input => {
                regexp      => '(a)(.+?)(\1)',
                placeholder => '',
            },
            output  => { placeholder => '' },
            message => 'store is empty'
        },
        {
            input => {
                regexp      => '(a)(.+?)(\1)',
                placeholder => { regexp => qr/(a)(.+?)(\1)/ },
            },
            output  => undef,
            message => 'store is a hashref',
            warning => 'Value for key "placeholder" must be a scalar or a code reference!',
        },
        {
            input => {
                regexp      => '(a)(.+?)(\1)',
                placeholder => [qr/(a)(.+?)(\1)/],
            },
            output  => undef,
            message => 'store is an arrayref',
            warning => 'Value for key "placeholder" must be a scalar or a code reference!',
        },
        {
            input => {
                regexp      => qr/(a)(.+?)(\1)/,
                placeholder => sub { return 'foo'; }
            },
            output  => { placeholder => 'foo' },
            message => 'store is a coderef'
        },
        {
            input => {
                regexp      => '(a)(.+?)(\1)',
                placeholder => 'bar'
            },
            output  => { placeholder => 'bar' },
            message => 'store is a scalar'
        }
    ];
}

sub _get_replacement_tests {
    return [
        {
            input   => { regexp      => '(a)(.+?)(\1)', },
            output  => { replacement => undef },
            message => 'empty replacement',
        },
        {
            input => {
                regexp      => '(a)(.+?)(\1)',
                replacement => ['foo'],
            },
            output  => undef,
            message => 'replacement is an arrayref',
            warning => 'Value for key "replacement" must be a scalar or a code reference!',
        },
        {
            input => {
                regexp      => '(a)(.+?)(\1)',
                replacement => { bar => 'foo' },
            },
            output  => undef,
            message => 'replacement is a hashref',
            warning => 'Value for key "replacement" must be a scalar or a code reference!',
        },
        {
            input => {
                regexp      => '(a)(.+?)(\1)',
                replacement => 'foo'
            },
            output  => { replacement => 'foo' },
            message => 'replacement is a scalar'
        },
        {
            input => {
                regexp      => '(a)(.+?)(\1)',
                replacement => sub { return 'foo'; }
            },
            output  => { replacement => 'foo' },
            message => 'replacement is a coderef'
        },
        {
            input => {
                regexp      => '(a)(.+?)(\1)',
                replacement => sub { return 'foo'; },
            },
            output  => { replacement => 'foo' },
            message => 'replacement is a coderef and store and restore_pattern are set'
        },
    ];
}

sub _get_regexp_tests {
    return [
        {
            input   => { regexp => '', },
            output  => undef,
            message => 'empty regexp',
            warning => 'Value for key "regexp" must be given!',
        },
        {
            input   => { regexp => { regexp => qr/(a)(.+?)(\1)/ }, },
            output  => undef,
            message => 'regexp is a hashref',
            warning => 'Value for key "regexp" must be a scalar or a regexp object!',
        },
        {
            input   => { regexp => [qr/(a)(.+?)(\1)/], },
            output  => undef,
            message => 'regexp is an arrayref',
            warning => 'Value for key "regexp" must be a scalar or a regexp object!',
        },
        {
            input  => { regexp => qr/(a)(.+?)(\1)/, },
            output => { regexp => ( $] < 5.013006 ) ? '(?-xism:(a)(.+?)(\1))' : '(?^:(a)(.+?)(\1))' },
            message => 'regexp is a regexp object'
        },
        {
            input   => { regexp => '(a)(.+?)(\1)', },
            output  => { regexp => '(?sm:(a)(.+?)(\1))' },
            message => 'regexp is a scalar'
        },
        {
            input => {
                regexp   => qr/(a)(.+?)(\1)/,
                modifier => 's'
            },
            output  => { regexp => '(?s:(a)(.+?)(\1))' },
            message => 'regexp is a regexp object and modifier is set'
        },
        {
            input => {
                regexp   => '(a)(.+?)(\1)',
                modifier => 's'
            },
            output  => { regexp => '(?s:(a)(.+?)(\1))' },
            message => 'regexp is a scalar and modifier is set'
        },
    ];
}

1;
