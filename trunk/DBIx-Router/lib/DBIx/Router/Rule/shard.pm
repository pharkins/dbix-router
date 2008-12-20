package DBIx::Router::Rule::shard;

use warnings;
use strict;

use base qw(DBIx::Router::Rule::parser);
use SQL::Statement;
use Carp qw(croak);
use List::Util qw(first);

__PACKAGE__->mk_accessors(qw(shards type table column));

sub defer_datasource { 1; }

sub new {
    my ( $self, $args ) = @_;

    # only accept statements that match our sharding rules
    $args->{match} = [

        # limit to basic statements for now
        {
            structure => 'command',
            operator  => 'only',
            tokens    => [qw/select insert update/],
        },
        {
            structure => 'tables',
            operator  => 'only',
            tokens    => [ $args->{table} ],
        },
        {
            structure => 'columns',
            strict    => 1,
            operator  => 'all',
            tokens    => [ $args->{table} . '.' . $args->{column} ],
        },
    ];

    return $self->SUPER::new($args);
}

sub accept {
    my $self = shift;

    $self->SUPER::accept(@_) or return 0;

    # parsed statement should be in meta after parser::accept()
    my $request = shift @_;
    if ( @{ $request->meta->{parsed_stmts} } > 1 ) {
        warn 'Multiple statements in one query is not supported for shards: '
          . $request->summary_as_text;
        return 0;
    }

    warn 'parser accepted: ' . $request->summary_as_text;

    # also need to make sure we can get a value
    my $shard_value =
      $self->_shard_value( $request->meta->{parsed_stmts}->[0], $request );
    if ($shard_value) {

        # no need to do this twice
        $request->meta->{shard_value} = $shard_value;
        return 1;
    }

    return 0;
}

sub datasource {
    my ( $self, $request ) = @_;

    my $partition_method = '_partition_by_' . $self->type;

    # return a datasource name and let Router look up the object
    return $self->$partition_method( $request->meta->{shard_value}, $request );
}

sub _shard_value {
    my ( $self, $stmt, $request ) = @_;

    # check the WHERE clause
    my $where = $stmt->where;
    if ($where) {

        # NOT IMPLEMENTED YET
    }

    # check for INSERT/UPDATE values
    my @columns = $self->_normalize_columns($stmt);
    my @values  = $stmt->row_values;

    my %column_value;
    @column_value{@columns} = @values;

    my $column = lc( $self->table . '.' . $self->column );
    my $value  = $column_value{$column};

    if ( $value eq '?' ) {
        my $param_num = first { $columns[$_] eq $column } 0 .. $#values;
        $value = $self->_value_for_param( $param_num, $request );
    }
    return $value;
}

sub _value_for_param {
    my ( $self, $param_num, $request ) = @_;

    # we have to dig for it
    my $value;
    foreach my $method ( @{ $request->sth_method_calls } ) {
        my ( $name, @args ) = @{$method};
        if ( $name eq 'execute' ) {
            return $args[$param_num];
        }

        # bind_param counts from 1
        elsif ( $name eq 'bind_param' and $args[0] == ( $param_num + 1 ) ) {
            return $args[1];
        }
    }

    return undef;
}

sub _partition_by_list {
    my ( $self, $shard_value, $request ) = @_;

    foreach my $shard ( @{ $self->shards } ) {
        if ( grep { $_ eq $shard_value } @{ $shard->{values} } ) {
            return $shard->{datasource};
        }
    }
    croak "Couldn't map to shard for value '$shard_value' in request: "
      . $request->summary_as_text;
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
