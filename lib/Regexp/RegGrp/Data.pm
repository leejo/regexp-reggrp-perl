package Regexp::RegGrp::Data;

use 5.008009;
use warnings;
use strict;
use Carp;

our @ACCESSORS = ( 'regexp', 'replacement', 'placeholder' );

##########################################################################################

sub new {
    my ( $class, $args ) = @_;

    $args ||= {};

    my $self = {};

    bless( $self, $class );

    return unless ( $self->_args_are_valid( $args ) );

    $self->{_regexp}      = $args->{regexp};
    $self->{_replacement} = $args->{replacement};
    $self->{_placeholder} = $args->{placeholder};
    $self->{_modifier}    = $args->{modifier};

    $self->_adjust_regexp_attribute();

    foreach my $field ( @ACCESSORS ) {
        $self->_mk_accessor( $field );
    }

    return $self;
}

sub _adjust_regexp_attribute {
    my ( $self ) = @_;

    if ( defined( $self->{_modifier} ) || !ref( $self->{_regexp} ) ) {
        my $modifier = defined( $self->{_modifier} ) ? $self->{_modifier} : 'sm';

        $self->{_regexp} =~ s/^\(\?[\^dlupimsx-]+:(.*)\)$/$1/si;
        $self->{_regexp} = sprintf( '(?%s:%s)', $modifier, $self->{_regexp} );
    }
}

sub _args_are_valid {
    my ( $self, $args ) = @_;

    unless ( ref( $args ) eq 'HASH' ) {
        carp( 'Args must be a hashref!' );

        return 0;
    }

    unless ( exists( $args->{regexp} ) && $args->{regexp} ) {
        carp( 'Value for key "regexp" must be given!' );
        return 0;
    }

    if (    ref( $args->{regexp} )
        and ref( $args->{regexp} ) ne 'Regexp' )
    {
        carp( 'Value for key "regexp" must be a scalar or a regexp object!' );
        return 0;
    }

    foreach my $accessor ( 'replacement', 'placeholder' ) {
        if (   exists( $args->{$accessor} )
            && ref( $args->{$accessor} )
            && ref( $args->{$accessor} ) ne 'CODE' )
        {
            carp( 'Value for key "' . $accessor . '" must be a scalar or a code reference!' );
            return 0;
        }
    }

    if ( exists( $args->{modifier} ) && ref( $args->{modifier} ) ) {
        carp( 'Value for key "modifier" must be a scalar!' );
        return 0;
    }

    return 1;
}

sub _mk_accessor {
    my ( $self, $var ) = @_;

    no strict 'refs';    ## no critic

    return if ( defined *{ __PACKAGE__ . '::' . $var }{CODE} );

    *{ __PACKAGE__ . '::' . $var } = sub {
        return $_[0]->{ '_' . $var };
    };
}

1;
