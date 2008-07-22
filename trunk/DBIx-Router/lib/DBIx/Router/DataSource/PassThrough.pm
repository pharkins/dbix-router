package DBIx::Router::DataSource::PassThrough;

use warnings;
use strict;

use Carp;
use base qw(DBIx::Router::DataSource);
use DBI::Gofer::Execute;

__PACKAGE__->mk_accessors(
    qw(
      executor
      )
);

sub new {
    my ( $self, $args ) = @_;
    $args->{executor} = DBI::Gofer::Execute->new();
    return $self->SUPER::new($args);
}

sub execute_request {
    my ( $self, $request ) = @_;
    return $self->executor->execute_request($request);
}

1;
__END__

=head1 NAME

DBIx::Router::DataSource::PassThrough - Execute requests without modifying them

=head1 SYNOPSIS

This DataSource class is for executing requests using the DSN originally specified in them.  It's mostly useful as a fallback.

    my $ds = DBIx::Router::DataSource::PassThrough->new({ name => 'fallback' });
    
    my $result = $ds->execute_request( $request, $router );
=head1 METHODS

=head2 name

Accessor for name attribute.

=head2 executor

Accessor for cached DBI::Gofer::Execute object.

=head2 execute_request($request, $router)

See DBIx::Router::DataSource.
