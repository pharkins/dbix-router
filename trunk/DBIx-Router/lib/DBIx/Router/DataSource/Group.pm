package DBIx::Router::DataSource::Group;

use warnings;
use strict;

use base qw(DBIx::Router::DataSource);
use Carp;

__PACKAGE__->mk_accessors(
    qw(
      datasources
      failover
      timeout
      retry_hook
      )
);

sub new {
    my ( $self, $args ) = @_;
    croak('Missing required parameter datasources') if not $args->{datasources};
    return $self->SUPER::new($args);
}

sub execute_request {
    my ( $self, $request, $transport ) = @_;
    my $datasource = $self->choose_datasource($request);

    if ( $self->failover ) {
        $transport->go_timeout( $self->timeout );
        $transport->go_retry_limit(99);    # let retry hook decide if we go on
        $transport->go_retry_hook( \&DBIx::Router::retry_hook );
        $transport->last_group($self);
    }

    return $datasource->execute_request($request, $transport);
}

sub choose_datasource {
    croak( __PACKAGE__ . '::choose_datasource should never be called' );
}

1;
__END__

=head1 NAME

DBIx::Router::DataSource::Group - Handle a request using a group of DSNs

=head1 SYNOPSIS

This is the base class for DataSource groups.  Subclasses will decide which DSNs they want to use to execute a given request.  This is different from Rule classes which decide whether to handle a request at all.

    my $ds =
        DBIx::Router::DataSource::Group->new( { name        => 'my_group',
                                                datasources => \@group_sources, } );
    
    my $result = $ds->execute_request( $request, $router );

=head1 METHODS

=head2 name

Accessor for name attribute.

=head2 datasources

Accessor for arrayref of DataSource objects.

=head2 failover

If set to true, this group will attempt to do failover between DataSources.

=head2 timeout

Accessor for timeout attribute.  This is the time in seconds that Gofer will wait before considering the request failed.  This is only used when failover is active.

=head2 execute_request($request, $router)

Choose a DataSource to use and execute the request with it.  See DBIx::Router::DataSource.

=head2 choose_datasource($request)

This is a virtual method that child classes implement to decide which DataSource to use for a given request.
