package DBIx::Router::DataSource::Group::shard;

use warnings;
use strict;

use base qw(DBIx::Router::DataSource::Group);
use Carp;

__PACKAGE__->mk_accessors(qw(shards type table column));

sub new {
    my ( $self, $args ) = @_;

    # If you can figure out what failover would mean for shards, feel free to
    # enlighten me.
    croak "Failover is not supported for shard" if $args->{failover};

    my @datasources = map { $_->{datasource} } @{ $args->{shards} };
    $args->{datasources} = \@datasources;

    return $self->SUPER::new($args);
}

sub choose_datasource {
    my ( $self, $request ) = @_;

    # parsed statement should be in meta, but fallback to parsing ourselves
    $request->meta->{parsed_stmts} ||=
      DBIx::Router::Rule::parser->_parse($request);
    if ( @{ $request->meta->{parsed_stmts} } > 1 ) {
        croak('Multiple statements in one query is not supported for shard');
    }

    my $shard_value =
      $self->_shard_value( $request->meta->{parsed_stmts}->[0], $request );
    my $partition_method = '_partition_by_' . $self->type;
    return $self->$partition_method( $shard_value, $request );
}

sub _shard_value {
    my ( $self, $stmt, $request ) = @_;

    # check the WHERE clause
    my $where = $stmt->where;
    if ($where) {

        # NOT IMPLEMENTED YET
    }

    # check for INSERT/UPDATE values
    my @columns = map { $_->table . '.' . $_->name } $stmt->columns;
    my @values = $stmt->row_values;

    my %column_value;
    @column_value{@columns} = @values;

    my $value = $column_value{ $self->table . '.' . $self->column };
    if ( ref $value eq 'SQL::Statement::Param' ) {
        my $param_num = $value->num;
        $value = $self->_value_for_param( $param_num, $request );
    }
    return $value;
}

sub _value_for_param {
    my ( $self, $param_num, $request ) = @_;

    my $call = pop @{ $request->sth_method_calls || [] }
      or croak "Can't find sth call for request: " . $request->summary_as_text;
    ( undef, my @args ) = @{$call};

    return $args[$param_num];
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

DBIx::Router::DataSource::Pool - The great new DBIx::Router::DataSource::Pool!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use DBIx::Router::DataSource::Pool;

    my $foo = DBIx::Router::DataSource::Pool->new();
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

Please report any bugs or feature requests to C<bug-dbix-router-datasource-pool at rt.cpan.org>, or through
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

1; # End of DBIx::Router::DataSource::Pool
