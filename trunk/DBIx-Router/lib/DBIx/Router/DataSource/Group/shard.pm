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

DBIx::Router::DataSource::Group::shard - Distribute requests across sets of servers in a data-dependent way

=head1 SYNOPSIS

This class is going through major changes.  Please check back later.
