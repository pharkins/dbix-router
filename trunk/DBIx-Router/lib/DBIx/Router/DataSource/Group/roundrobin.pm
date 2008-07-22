package DBIx::Router::DataSource::Group::roundrobin;

use warnings;
use strict;

use base qw(DBIx::Router::DataSource::Group);

__PACKAGE__->mk_accessors(qw(last_index));

sub new {
    my ( $self, $args ) = @_;
    $args->{last_index} = -1;
    return $self->SUPER::new($args);
}

sub choose_datasource {
    my ( $self, $request ) = @_;

    my $datasources = $self->datasources;
    my $index       = $self->last_index;
    $index++;
    if ( $index > $#{$datasources} ) { $index = 0 }
    $self->last_index($index);

    return $datasources->[$index];
}

1;
__END__

=head1 NAME

DBIx::Router::DataSource::Group::roundrobin - Distribute requests in round-robin order

=head1 SYNOPSIS

This DataSource will distribute requests in round-robin among a group of DSNs.  This is useful if you have replicated read-only slaves and want to distribute load between them.

    my $group =
        DBIx::Router::DataSource::Group::random->new( { name => 'my_group',
                                                datasources => \@group_sources, } );
    
    my $ds = $group->choose_datasource( $request );

=head1 METHODS

=head2 choose_datasource($request)

Picks the next DataSource from C<< $self->datasources >> and returns it.  It will wrap around when it reaches the last one in the list.
