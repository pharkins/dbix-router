package DBIx::Router::DataSource;

use warnings;
use strict;

use base qw(DBI::Util::_accessor);
use Carp;

__PACKAGE__->mk_accessors(
    qw(
      name
      )
);

# Implemented by subclasses
sub execute_request {
    croak('DBIx::Router::DataSource::execute_request should never be called');
}

1;
__END__

=head1 NAME

DBIx::Router::DataSource - Base class for data sources

=head1 SYNOPSIS

This is a base class that all DataSource classes must inherit from.

    use base qw(DBIx::Router::DataSource);
    
    $self->name('my_data_source');

=head1 METHODS

=head2 name

Accessor for name attribute.

=head2 execute_request($request, $router)

This is a virtual method that all subclasses must implement.  It is passed a request which it then executes.  The second parameter is a reference to the DBIx::Router instance, used to get the current conf if the DataSource class wants to check config parameters.
