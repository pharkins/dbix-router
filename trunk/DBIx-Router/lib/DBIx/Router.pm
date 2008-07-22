package DBIx::Router;

use warnings;
use strict;

use base qw(DBD::Gofer::Transport::Base);

use Carp;
use DBI 1.55;
use DBI::Gofer::Execute;
use Config::Any;
use Storable;
use DBIx::Router::DataSource::DSN;
use DBIx::Router::DataSource::Group;
use DBIx::Router::DataSource::PassThrough;
use DBIx::Router::RuleList;
use DBIx::Router::Rule::default;

our $VERSION = '0.01';

__PACKAGE__->mk_accessors(
    qw(
      go_conf
      conf
      rule_list
      datasources
      last_group
      last_dsn
      )
);

my $executor = DBI::Gofer::Execute->new();

sub new {
    my ( $class, $args ) = @_;
    my $self = $class->SUPER::new($args);
    $self->_init_conf($args);
    return $self;
}

sub _init_conf {
    my ( $self, $args ) = @_;

    my $conf_file = $ENV{DBIX_ROUTER_CONF} || $args->{go_conf};
    croak('No config file specified') if not $conf_file;

    # I wish Config::Any had a simpler API for loading a single file...
    my $files =
      Config::Any->load_files( { files => [$conf_file], use_ext => 1, } );
    my ($conf) = values %{ $files->[0] };
    $conf = Storable::dclone($conf);    # work around Config::Any caching

    croak("Config file '$conf_file' failed to load") if ( ref $conf ne 'HASH' );

    # init datasources
    my %datasources;
    foreach my $ds_args ( @{ $conf->{datasources} } ) {
        if ( exists $datasources{ $ds_args->{name} } ) {
            croak("Duplicate definition for datasource '$ds_args->{name}'");
        }

        my $datasource;

        my $class = delete $ds_args->{class};
        if ( not $class or $class =~ m/^dsn$/i ) {
            $datasource = DBIx::Router::DataSource::DSN->new($ds_args);
        }
        else {
            if ( $class !~ m/::/ ) {

                # He's one of ours
                $class = 'DBIx::Router::DataSource::Group::' . $class;
            }
            $self->_load_class($class)
              or croak("Failed to load datasource class '$class': $@");

            my @group_sources;
            foreach my $group_source ( @{ $ds_args->{datasources} } ) {
                my $ds_obj = $datasources{$group_source}
                  or croak( "Can't find datasource '$group_source' "
                      . "configured for group '$ds_args->{name}'. "
                      . "Make sure you define it before referencing it by name."
                  );
                push @group_sources, $ds_obj;
            }
            $datasource =
              $class->new( { %{$ds_args}, datasources => \@group_sources } );
        }

        $datasources{ $ds_args->{name} } = $datasource;
    }

    # init rules
    my @rules;
    foreach my $rule_args ( @{ $conf->{rules} } ) {

        my $class = delete $rule_args->{class};
        if ( $class !~ m/::/ ) {
            $class = 'DBIx::Router::Rule::' . $class;
        }
        $self->_load_class($class)
          or croak("Failed to load rule class '$class': $@");

        my $datasource = $datasources{ $rule_args->{datasource} }
          or croak( "Can't find datasource '$rule_args->{datasource}' "
              . "configured for rule '$rule_args->{class}'" );

        my $rule = $class->new( { %{$rule_args}, datasource => $datasource } );
        push @rules, $rule;
    }

    if ( defined $conf->{fallback} ? $conf->{fallback} : 1 ) {
        my $passthrough = DBIx::Router::DataSource::PassThrough->new(
            { name => 'passthrough' } );
        my $fallback =
          DBIx::Router::Rule::default->new( { datasource => $passthrough } );
        push @rules, $fallback;
    }

    my $rule_list = DBIx::Router::RuleList->new( { rules => \@rules } );

    $self->conf($conf);
    $self->datasources( \%datasources );
    $self->rule_list($rule_list);
}

# Ripped from DBD::Gofer
sub _load_class {    # return true or false+$@
    my ( $self, $class ) = @_;
    ( my $pm = $class ) =~ s{::}{/}g;
    $pm .= ".pm";
    return 1 if eval { require $pm };

    # shouldn't be needed (perl bug?) and assigning undef isn't enough
    delete $INC{$pm};
    undef;           # error in $@
}

sub transmit_request_by_transport {
    my ( $self, $request ) = @_;

    # We have to clone the request because the object gets reused but
    # execute_request damages it.  If we fix this, it should help performance
    # quite a bit.
    my $cloned_request = Storable::dclone($request);

    # Reset these to clear leftover values from a failover request
    # There's a bug here
    #$self->go_timeout(undef);
    #$self->go_retry_limit(0);
    #$self->go_retry_hook(undef);

    # "And then, a miracle occurs"
    my $rule_list  = $self->rule_list;
    my $datasource = $rule_list->map_request($cloned_request);
    return $datasource->execute_request( $cloned_request, $self );
}

sub receive_response_by_transport {
    my $self = shift;

    # transmit_request_by_transport does all the work for this driver
    # so receive_response_by_transport should never be called
    croak "receive_response_by_transport should never be called";
}

sub retry_hook {
    my ( $request, $response, $self ) = @_;

    # We retry if it's a network error
    # Add a call to user-specified retry_method here for additional reasons
    my $retry = 0;
    if ( $response->errstr =~ /DBD::Gofer .* timed-out/imxs ) {

        # We currently only retry read-only statements. Should offer a way
        # to let users live dangerously if they really want to.
        my $idempotent = $request->is_idempotent;
        $retry = 1 if $idempotent;

        # Remove the failed datasource. It stays out until you restart.
        my $group       = $self->last_group;
        my $dsn_name    = $self->last_dsn->name;
        my $datasources = $group->datasources;

        warn "Failure on datasource '$dsn_name' in group '"
          . $group->name
          . "'. Removing from further requests.\n";

        # Just comparing by name here. Probably could do better.
        my @good_datasources = grep { $_->name ne $dsn_name } @{$datasources};

        if ( not scalar @good_datasources ) {

            # No more left! Can't retry, and removing the last one will just
            # cause mayhem.
            return 0;
        }

        # Really should remove it from any other groups too, but that will mean
        # building in more relationship tracking.
        $group->datasources( \@good_datasources );
    }

    return $retry;
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
