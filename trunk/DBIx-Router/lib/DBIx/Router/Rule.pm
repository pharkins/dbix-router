package DBIx::Router::Rule;

use warnings;
use strict;

use Carp;
use base qw(DBI::Util::_accessor);

__PACKAGE__->mk_accessors(
    qw(
      datasource
      )
);

sub new {
    my ( $self, $args ) = @_;
    croak('Missing required parameter datasource') if not $args->{datasource};
    return $self->SUPER::new($args);
}

# This is implemented by subclasses
sub accept {
    croak('DBIx::Router::Rule::accept should never be called');
}

1;
__END__

=head1 NAME

DBIx::Router::Rule - Base class for rules

=head1 SYNOPSIS

This is a base class that all Rule classes must inherit from.

    use base qw(DBIx::Router::Rule);
    
    my $datasource_obj = $self->datasource;

=head1 METHODS

=head2 new({ datasource => $datasource_obj })

Constructor, requires datasource parameter.

=head2 datasource

Accessor for DataSource object.

=head2 accept

This is a virtual method that all subclasses must implement.  It is passed a request and determines whether or not the request matches this rule, returning true or false.
