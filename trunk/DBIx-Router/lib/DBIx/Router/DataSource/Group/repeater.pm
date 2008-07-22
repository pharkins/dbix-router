package DBIx::Router::DataSource::Group::repeater;

use warnings;
use strict;

use base qw(DBIx::Router::DataSource::Group);
use Storable;

sub execute_request {
    my ( $self, $request, $transport ) = @_;

    my $datasources = $self->datasources;
    my $response;

    # Should we try to check if the responses all match?
    foreach my $datasource ( @{$datasources} ) {

        # Need to clone here because $request gets mangled
        $response =
          $datasource->execute_request( Storable::dclone($request),
            $transport );
    }

    return $response;
}

1;
__END__

=head1 NAME

DBIx::Router::DataSource::Group::repeater - Repeat requests on ALL of a group of DSNs

=head1 SYNOPSIS

This DataSource will repeat requests on all of a group of DSNs.  This can be used as a cheesy replication system for simple scenarios.  Be warned, the requests are run sequentially, so the amount of time needed is multiplied by the number of datasources.

    my $group =
        DBIx::Router::DataSource::Group::random->new( { name => 'my_group',
                                                datasources => \@group_sources, } );
    
    my $ds = $group->choose_datasource( $request );

=head1 METHODS

=head2 execute_request($request, $router)

Overrides parent to execute the given request on all of the datasources.
