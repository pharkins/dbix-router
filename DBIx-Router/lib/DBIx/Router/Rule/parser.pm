package DBIx::Router::Rule::parser;

use warnings;
use strict;

use base qw(DBIx::Router::Rule);
use SQL::Statement;
use Carp;

__PACKAGE__->mk_accessors(qw(match));

our %_extract_tokens = (
    command => sub { $_[0]->command },
    tables  => sub {
        my @tables = $_[0]->tables or return;
        map { $_->name } @tables;
    },
    columns => sub {
        my @columns = $_[0]->columns;

        # Sometimes we just get a '0' here...
        return if grep { not ref $_ } @columns;

        # And sometimes the columns have no table definition, but if there's
        # only one table we can infer.
        my @tables = $_[0]->tables;
        my $default_table = ( @tables == 1 ) ? $tables[0]->name : '';
        map {
            ( defined $_->table ? $_->table : $default_table ) . '.' . $_->name
        } @columns;
    },
);

our %_eval_operator = (
    all => sub {
        my ( $stmt_tokens, $match_tokens, $structure ) = @_;
        foreach my $match_token ( @{$match_tokens} ) {
            grep { $match_token =~ m/^$_$/i } @{$stmt_tokens} or return 0;
        }
        return 1;
    },
    any => sub {
        my ( $stmt_tokens, $match_tokens, $structure ) = @_;
        foreach my $stmt_token ( @{$stmt_tokens} ) {
            grep { $_ =~ m/^$stmt_token$/i } @{$match_tokens} and return 1;
        }
        return 0;
    },
    none => sub {
        my ( $stmt_tokens, $match_tokens, $structure ) = @_;
        foreach my $stmt_token ( @{$stmt_tokens} ) {
            grep { $_ =~ m/^$stmt_token$/i } @{$match_tokens} and return 0;
        }
        return 1;
    },
    only => sub {
        my ( $stmt_tokens, $match_tokens, $structure ) = @_;
        foreach my $stmt_token ( @{$stmt_tokens} ) {
            grep { $_ =~ m/^$stmt_token$/i } @{$match_tokens} or return 0;
        }
        return 1;
    },
);

sub new {
    my ( $self, $args ) = @_;

    croak "No matching rules specified" if not $args->{match};

    foreach my $match ( @{ $args->{match} } ) {
        croak "Unkown structure '$match->{structure}'"
          if not $_extract_tokens{ $match->{structure} };
        croak "Unkown operator '$match->{operator}'"
          if not $_eval_operator{ $match->{operator} };
    }

    return $self->SUPER::new($args);
}

sub accept {
    my ( $self, $request ) = @_;

    $request->meta->{parsed_stmts} ||= $self->_parse($request);
    return 0 if not @{ $request->meta->{parsed_stmts} };

    foreach my $stmt ( @{ $request->meta->{parsed_stmts} } ) {
        foreach my $match ( @{ $self->match } ) {
            if ( not $self->_evaluate_match( $stmt, $match ) ) { return 0; }
        }
    }

    return 1;
}

sub _parse {
    my ( $self, $request ) = @_;

    my @statements = $request->statements;
    my $parser     = SQL::Parser->new();
    $parser->{PrinteError} = 1;

    return [ map { SQL::Statement->new( $_, $parser ) } @statements ];
}

sub _evaluate_match {
    my ( $self, $stmt, $match ) = @_;

    my @stmt_tokens = $_extract_tokens{ $match->{structure} }->($stmt);

    # Change them to regexes
    foreach my $token (@stmt_tokens) {
        if ( $token =~ s/\*$// ) {
            $token = quotemeta($token) . '[^.]+';
        }
        else {
            $token = quotemeta($token);
        }
    }

    return $_eval_operator{ $match->{operator} }
      ->( \@stmt_tokens, $match->{tokens}, $match->{structure} );
}

1;
__END__


=head1 NAME

DBIx::Router::Rule - The great new DBIx::Router::Rule!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use DBIx::Router::Rule;

    my $foo = DBIx::Router::Rule->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 function1

=cut

sub function1 {
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

Perrin Harkins, C<< <perrin at elem.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dbix-router-rule at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Router>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Router


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Router>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-Router>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Router>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-Router>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Perrin Harkins, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of DBIx::Router::Rule
