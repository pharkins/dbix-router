package DBIx::Router::RuleList;

use warnings;
use strict;

use Carp;
use base qw(DBI::Util::_accessor);

__PACKAGE__->mk_accessors(
    qw(
      rules
      )
);

sub new {
    my ( $self, $args ) = @_;
    croak("Missing required parameter 'rules'") if not $args->{rules};
    return $self->SUPER::new($args);
}

sub map_request {
    my ( $self, $request ) = @_;

    foreach my $rule ( @{ $self->rules } ) {
        if ( $rule->accept($request) ) {
            return $rule->datasource;
        }
    }

    croak( 'Unable to map request: ' . $request->summary_as_text );
}

1;
__END__

=head1 NAME

DBIx::Router::RuleList - Apply a list of Rules in a specified order

=head1 SYNOPSIS

    my $rule_list = DBIx::Router::RuleList->new( { rules => \@rules } );
    
    my $datasource = $rule_list->map_request($request);

=head1 METHODS

=head2 new({ rules => \@rules })

Constructor, requires rules parameter which is an arrayref of Rule objects.

=head2 rules

Accessor for rules arrayref.

=head2 map_request($request)

This is passed a request and tries each Rule in order until it finds one that will accept the request.  When it finds one, it returns that Rule's datasource.  If none is found, it will throw an exception.  Normally a RuleList would either have a default rule at the end or use the C<passthrough> option.
