package DBIx::Router::DataSource::DSN;

use warnings;
use strict;

use Carp;
use base qw(DBIx::Router::DataSource);
use DBI::Gofer::Execute;

__PACKAGE__->mk_accessors(
    qw(
      dsn
      user
      password
      executor
      )
);

sub new {
    my ( $self, $args ) = @_;
    croak('Missing required parameter dsn') if not $args->{dsn};
    $args->{executor} = DBI::Gofer::Execute->new(
        {
            forced_connect_dsn => $args->{dsn},
            forced_connect_attributes =>
              { Username => $args->{username}, Password => $args->{password} },
        }
    );
    return $self->SUPER::new($args);
}

sub execute_request {
    my ( $self, $request, $transport ) = @_;

    # Store this for failover
    $transport->last_dsn($self);

    return $self->executor->execute_request($request);
}

1;
__END__

=head1 NAME

DBIx::Router::DataSource::DSN - Execute requests with a specified DSN

=head1 SYNOPSIS

This DataSource class is where most requests end up.  It holds a specific DSN that a combination of Rule and DataSource::Group objects will eventually map to.

    my $ds = DBIx::Router::DataSource::DSN->new({ name => 'fallback',
                                                  dsn  => $dsn,
                                                  user => $user,
                                                  password => $password, });
    
    my $result = $ds->execute_request( $request, $router );

=head1 METHODS

=head2 name

Accessor for name attribute.

=head2 user

Accessor for user attribute.

=head2 password

Accessor for password attribute.

=head2 dsn

Accessor for dsn attribute.

=head2 executor

Accessor for cached DBI::Gofer::Execute object.

=head2 execute_request($request, $router)

Execute request with the specified DSN, user, and password.  See DBIx::Router::DataSource.
