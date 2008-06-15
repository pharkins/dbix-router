package DBIx::Router::DataSource::Group::roundrobin;

use warnings;
use strict;

use base qw(DBIx::Router::DataSource::Group);

__PACKAGE__->mk_accessors( qw(last_index) );

sub new {
    my ( $self, $args ) = @_;
    $args->{last_index} = -1;
    return $self->SUPER::new($args);
}

sub choose_datasource {
    my ( $self, $request ) = @_;

    my $datasources = $self->datasources;
    my $index = $self->last_index;
    $index++;
    if ($index > $#{$datasources}) { $index = 0 };
    $self->last_index($index);

    return $datasources->[$index];
}

1;
__END__

=head1 NAME

DBIx::Router::DataSource::Pool - The great new DBIx::Router::DataSource::Pool!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use DBIx::Router::DataSource::Pool;

    my $foo = DBIx::Router::DataSource::Pool->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 function1

=cut

sub function1 {
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

Perrin Harkins, C<< <perrin at elem.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dbix-router-datasource-pool at rt.cpan.org>, or through
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

1; # End of DBIx::Router::DataSource::Pool
