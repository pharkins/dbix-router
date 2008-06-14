package DBIx::Router;

use warnings;
use strict;

use base qw(DBD::Gofer::Transport::Base);

use Carp;
use DBI 1.55;
use DBI::Gofer::Execute;
use Config::Any;
use Storable;

our $VERSION = '0.01';

__PACKAGE__->mk_accessors(
    qw(
      )
);

my $executor = DBI::Gofer::Execute->new();

sub transmit_request_by_transport {
    my ( $self, $request ) = @_;

    # ...
    # magic routing happens here
    # ...

    # We have to clone the request because the object gets reused but
    # execute_request damages it.  If we fix this, it should help performance
    # quite a bit.
    my $cloned_request = Storable::dclone($request);
    my $response       = $executor->execute_request($cloned_request);

    return $response;
}

# Experimental: faster, but skips features we may want
#*transmit_request = \*transmit_request_by_transport;

sub receive_response_by_transport {
    my $self = shift;

    # transmit_request_by_transport does all the work for this driver
    # so receive_response_by_transport should never be called
    croak "receive_response_by_transport should never be called";
}

1;

__END__

=head1 NAME

DBIx::Router - The great new DBIx::Router!

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use DBIx::Router;

    my $foo = DBIx::Router->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 function1

=head2 function2

=head1 AUTHOR

Perrin Harkins, C<< <perrin at elem.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dbix-router at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Router>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Router

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Router>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-Router>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Router>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-Router>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2008 Perrin Harkins, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
