package DBIx::Router::DataSource::Group::random;

use warnings;
use strict;

use base qw(DBIx::Router::DataSource::Group);

sub choose_datasource {
    my ( $self, $request ) = @_;
    my $datasources = $self->datasources;
    my $random = $datasources->[rand @{$datasources}];
    return $random;
}

1;
__END__

=head1 NAME

DBIx::Router::DataSource::Group::random - Distribute requests randomly

=head1 SYNOPSIS

This DataSource will distribute requests randomly among a group of DSNs.  This is useful if you have replicated read-only slaves and want to distribute load between them.

    my $group =
        DBIx::Router::DataSource::Group::random->new( { name => 'my_group',
                                                datasources => \@group_sources, } );
    
    my $ds = $group->choose_datasource( $request );

=head1 METHODS

=head2 choose_datasource($request)

Picks a random DataSource from C<< $self->datasources >> and returns it.
