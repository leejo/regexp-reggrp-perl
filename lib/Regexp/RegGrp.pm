package Regexp::RegGrp;

use 5.008;
use warnings;
use strict;
use Carp;

BEGIN {
    if ( $] < 5.010000 ) {
        require re;
        re->import( 'eval' );
    }
}

use constant {
    ESCAPE_BRACKETS => qr~\(\?(-?[pmixs]+:|[:=!><])|\[[^\]]+\]~,
    ESCAPE_CHARS    => qr~\\.~,
    BRACKETS        => qr~\(~,
    BACK_REF        => qr~\\(\d+)~
};

# =========================================================================== #

our $VERSION = '0.01_03';

sub new {
    my ( $class, $in_ref )  = @_;
    my $self                = {};

    if ( ref( $in_ref ) ne 'HASH' ) {
        carp( 'First argument must be a hashref!' );
        return undef;
    }

    unless ( exists( $in_ref->{reggrp} ) ) {
            carp( 'Key "reggrp" does not exist in input hashref!' );
            return undef;
    }

    if ( ref( $in_ref->{reggrp} ) ne 'ARRAY' ) {
        carp( 'Value for key "reggrp" must be an arrayref!' );
        return undef;
    }

    if (
        ref( $in_ref->{restore_pattern} ) and
        ref( $in_ref->{restore_pattern} ) ne 'Regexp'
    ) {
        carp( 'Value for key "restore_pattern" must be a scalar or regexp!' );
        return undef;
    }

    my $no = 0;

    map {
        $no++;
        if (
            (
                ref( $_->{regexp} ) and
                ref( $_->{regexp} ) ne 'Regexp'
            ) or
            not length( $_->{regexp} ) or
            (
                ref( $_->{replacement} ) and
                ref( $_->{replacement} ) ne 'CODE'
            ) or
            (
                ref( $_->{store} ) and
                ref( $_->{store} ) ne 'CODE'
            )
        ) {
            carp( 'RegGrp No ' . $no . ' in arrayref is malformed!' );
            return undef;
        }

        push(
            @{$self->{reggrp}},
            {
                regexp      => $_->{regexp},
                replacement => defined( $_->{store} ) ? (
                    $in_ref->{restore_pattern} ? $_->{replacement} : sub {
                        return sprintf( "\x01%d\x01", $_[0]->{store_index} );
                    }
                ) : $_->{replacement},
                store       => $_->{store}
            }
        );
    } @{$in_ref->{reggrp}};

    my $restore_pattern         = $in_ref->{restore_pattern} || qr~\x01(\d+)\x01~;
    $self->{restore_pattern}    = qr/$restore_pattern/;

    $self->{store_data}         = [];

    my $offset  = 1;
    my $midx    = 0;

    # In perl versions < 5.10 hash %+ doesn't exist, so we have to initialize it
    $self->{re_str} = ( ( $] < 5.010000 ) ? '(?{ %+ = (); })' : '' ) . join(
        '|',
        map {
            my $re = $_->{regexp};
            # Count backref brackets
            $re =~ s/${\(ESCAPE_CHARS)}//g;
            $re =~ s/${\(ESCAPE_BRACKETS)}//g;
            my @nparen = $re =~ /${\(BRACKETS)}/g;
            $_->{regexp} = qr/$_->{regexp}/;

            $re = $_->{regexp};

            $re =~ s/${\(BACK_REF)}/sprintf( "\\%d", $offset + $1 )/eg;

            my $ret;

            if ( $] < 5.010000 ) {
                # In perl versions < 5.10 we need to fill %+ hash manually
                $ret = '(' . $re . ')' . '(?{ $+{\'_' . $midx++ . '\'} = $^N; })';
            }
            else {
                $ret = '(?\'_' . $midx++ . '\'' . $re . ')';
            }

            $offset += scalar( @nparen ) + 1;

            $ret;

        } @{$self->{reggrp}}
    );

    bless( $self, $class );

    return $self;
}

sub exec {
    my ( $self, $input, $opts ) = @_;

    if ( ref( $input ) ne 'SCALAR' ) {
        carp( 'First argument in Regexp::RegGrp->exec must be a scalarref!' );
        return undef;
    }

    $opts ||= {};

    if ( ref( $opts ) ne 'HASH' ) {
        carp( 'Second argument in Regexp::RegGrp->exec must be a hashref!' );
        return undef;
    }

    my $to_process  = \'';
    my $cont        = 'void';

    if ( defined( wantarray ) ) {
        my $tmp_input = ${$input};

        $to_process = \$tmp_input;
        $cont       = 'scalar';
    }
    else {
        $to_process = $input;
    }

    ${$to_process} =~ s/$self->{re_str}/$self->_process( { match_hash => \%+, opts => $opts } )/egsm;

    # Return a scalar if requested by context
    return ${$to_process} if ( $cont eq 'scalar' );
}

sub _process {
    my ( $self, $in_ref ) = @_;

    my %match_hash  = %{$in_ref->{match_hash}};
    my $opts        = $in_ref->{opts};

    my $match_key   = ( keys( %match_hash ) )[0];
    my ( $midx )    = $match_key =~ /^_(\d+)$/;
    my $match       = $match_hash{$match_key};

    my @submatches = $match =~ /$self->{reggrp}->[$midx]->{regexp}/;
    map { $_ ||= ''; } @submatches;

    my $ret = $match;

    if (
        defined( $self->{reggrp}->[$midx]->{replacement} ) and
        not ref( $self->{reggrp}->[$midx]->{replacement} )
    ) {
        $ret = $self->{reggrp}->[$midx]->{replacement};
    }
    else {
        if ( ref( $self->{reggrp}->[$midx]->{replacement} ) eq 'CODE' ) {
            $ret = $self->{reggrp}->[$midx]->{replacement}->(
                {
                    match       => $match,
                    submatches  => \@submatches,
                    opts        => $opts,
                    store_index => scalar( @{$self->{store_data}} )
                }
            );
        }
    }

    if (
        defined( $self->{reggrp}->[$midx]->{store} ) and
        defined( $self->{restore_pattern} )
    ) {
        my $store = $match;
        if ( not ref( $self->{reggrp}->[$midx]->{store} ) ) {
            $store = $self->{reggrp}->[$midx]->{store};
        }
        elsif ( ref( $self->{reggrp}->[$midx]->{store} ) eq 'CODE' ) {
            $store = $self->{reggrp}->[$midx]->{store}->(
                {
                    match       => $match,
                    submatches  => \@submatches,
                    opts        => $opts
                }
            );
        }

        push( @{$self->{store_data}}, $store );
    }

    return $ret;
};

sub restore_stored {
    my ( $self, $input ) = @_;

    if ( ref( $input ) ne 'SCALAR' ) {
        carp( 'First argument in Regexp::RegGrp->restore must be a scalarref!' );
        return undef;
    }

    my $to_process  = \'';
    my $cont        = 'void';

    if ( defined( wantarray ) ) {
        my $tmp_input = ${$input};

        $to_process = \$tmp_input;
        $cont       = 'scalar';
    }
    else {
        $to_process = $input;
    }

    # Here is a while loop, because there could be recursive replacements
    while ( ${$to_process} =~ /$self->{restore_pattern}/ ) {
        ${$to_process} =~ s/$self->{restore_pattern}/$self->{store_data}->[$1]/egsm;
    }

    $self->flush_stored();

    # Return a scalar if requested by context
    return ${$to_process} if ( $cont eq 'scalar' );
}

sub flush_stored {
    my $self = shift;

    $self->{store_data} = [];
}

1;

__END__

=head1 NAME

Regexp::RegGrp - Groups a regular expressions collection

=head1 VERSION

Version 0.01_03

=head1 DESCRIPTION

Groups regular expressions to one regular expression

=head1 SYNOPSIS

    use Regexp::RegGrp;

    my $reggrp = Regexp::RegGrp->new( [ { regexp => '%name%', replacement => 'John Doe' }, { regexp => '%company%', replacement => 'ACME' } ] );

    $reggrp->exec( \$scalar );

To return a scalar without changing the input simply use (e.g. example 2):

    my $ret = $reggrp->exec( \$scalar );

The first argument must be a scalarref.

=head1 EXAMPLES

=over 4

=item Example 1

Common usage.

    #!/usr/bin/perl

    use strict;
    use warnings;

    use Regexp::RegGrp;

    my $reggrp = Regexp::RegGrp->new( [ { regexp => '%name%', replacement => 'John Doe' }, { regexp => '%company%', replacement => 'ACME' } ] );

    open( INFILE, 'unprocessed.txt' );
    open( OUTFILE, '>processed.txt' );

    my $txt = join( '', <INFILE> );

    $reggrp->exec( \$txt );

    print OUTFILE $txt;
    close(INFILE);
    close(OUTFILE);

=item Example 2

A scalar is requested by the context. The input will remain unchanged.

    #!/usr/bin/perl

    use strict;
    use warnings;

    use Regexp::RegGrp;

    my $reggrp = Regexp::RegGrp->new( [ { regexp => '%name%', replacement => 'John Doe' }, { regexp => '%company%', replacement => 'ACME' } ] );

    open( INFILE, 'unprocessed.txt' );
    open( OUTFILE, '>processed.txt' );

    my $unprocessed = join( '', <INFILE> );

    my $processed = $reggrp->exec( \$unprocessed );

    print OUTFILE $processed;
    close(INFILE);
    close(OUTFILE);

=back

=head1 AUTHOR

Merten Falk, C<< <nevesenin at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-javascript-packer at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Regexp-RegGrp>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

perldoc Regexp::RegGrp


=head1 COPYRIGHT & LICENSE

Copyright 2010 Merten Falk, all rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut