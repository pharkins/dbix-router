package DBIx::Router::Rule::parser;

use warnings;
use strict;

use base qw(DBIx::Router::Rule);
use SQL::Statement;
use Carp;

__PACKAGE__->mk_accessors(qw(match));

our %_extract_tokens = (
    command => sub { $_[0]->command },
    tables  => sub {
        my @tables = $_[0]->tables or return;
        map { $_->name } @tables;
    },
    columns => sub {
        my @columns = $_[0]->columns;

        # Sometimes we just get a '0' here...
        return if grep { not ref $_ } @columns;

        # And sometimes the columns have no table definition, but if there's
        # only one table we can infer.
        my @tables = $_[0]->tables;
        my $default_table = ( @tables == 1 ) ? $tables[0]->name : '';
        map {
            ( defined $_->table ? $_->table : $default_table ) . '.' . $_->name
        } @columns;
    },
);

our %_eval_operator = (
    all => sub {
        my ( $stmt_tokens, $match_tokens, $structure ) = @_;
        foreach my $match_token ( @{$match_tokens} ) {
            grep { $match_token =~ m/^$_$/i } @{$stmt_tokens} or return 0;
        }
        return 1;
    },
    any => sub {
        my ( $stmt_tokens, $match_tokens, $structure ) = @_;
        foreach my $stmt_token ( @{$stmt_tokens} ) {
            grep { $_ =~ m/^$stmt_token$/i } @{$match_tokens} and return 1;
        }
        return 0;
    },
    none => sub {
        my ( $stmt_tokens, $match_tokens, $structure ) = @_;
        foreach my $stmt_token ( @{$stmt_tokens} ) {
            grep { $_ =~ m/^$stmt_token$/i } @{$match_tokens} and return 0;
        }
        return 1;
    },
    only => sub {
        my ( $stmt_tokens, $match_tokens, $structure ) = @_;
        foreach my $stmt_token ( @{$stmt_tokens} ) {
            grep { $_ =~ m/^$stmt_token$/i } @{$match_tokens} or return 0;
        }
        return 1;
    },
);

sub new {
    my ( $self, $args ) = @_;

    croak "No matching rules specified" if not $args->{match};

    foreach my $match ( @{ $args->{match} } ) {
        croak "Unkown structure '$match->{structure}'"
          if not $_extract_tokens{ $match->{structure} };
        croak "Unkown operator '$match->{operator}'"
          if not $_eval_operator{ $match->{operator} };
    }

    return $self->SUPER::new($args);
}

sub accept {
    my ( $self, $request ) = @_;
    warn 'accept called';
    $request->meta->{parsed_stmts} ||= $self->_parse($request);
    return 0 if not @{ $request->meta->{parsed_stmts} };

    foreach my $stmt ( @{ $request->meta->{parsed_stmts} } ) {
        foreach my $match ( @{ $self->match } ) {
            if ( not $self->_evaluate_match( $stmt, $match ) ) { return 0; }
        }
    }

    return 1;
}

sub _parse {
    my ( $self, $request ) = @_;

    my @statements = $request->statements;
    my $parser     = SQL::Parser->new();
    $parser->{PrinteError} = 1;

    return [ map { SQL::Statement->new( $_, $parser ) } @statements ];
}

sub _evaluate_match {
    my ( $self, $stmt, $match ) = @_;

    my @stmt_tokens = $_extract_tokens{ $match->{structure} }->($stmt);

    # Change them to regexes
    foreach my $token (@stmt_tokens) {
        if ( $token =~ s/\*$// and not $match->{strict} ) {
            $token = quotemeta($token) . '[^.]+';
        }
        else {
            $token = quotemeta($token);
        }
    }

    return $_eval_operator{ $match->{operator} }
      ->( \@stmt_tokens, $match->{tokens}, $match->{structure} );
}

sub _normalize_columns {
    my $self = shift;
    return map { lc $_ } $_extract_tokens{columns}->(@_);
}

1;
__END__


=head1 NAME

DBIx::Router::Rule::parser - SQL routing based on statement parsing

=head1 SYNOPSIS

This module uses SQL::Statement to parse your SQL and route it to a data source based on the contents.

        # match all queries on the "fruit" table
        {
            class => 'parser',
            match => [
                {
                    structure => 'tables',
                    operator  => 'any',
                    tokens    => ['fruit']
                },
            ],
            datasource => 'RoundRobin',
        },
        
        # match all queries except those on the "orders" or "customers" tables
        {
            class => 'parser',
                {
                    structure => 'tables',
                    operator  => 'none',
                    tokens    => ['orders', 'customers']
                },
            ],
            datasource => 'RoundRobin',
        },
        
        # match all "INSERT" and "UPDATE" statements on the "fruit" table
        {
            class => 'parser',
            match => [
                {
                    structure => 'tables',
                    operator  => 'any',
                    tokens    => ['fruit']
                },
                {
                    structure => 'command',
                    operator  => 'any',
                    tokens    => ['insert', 'update']
                },
            ],
            datasource => 'Master1',
        },

        # match queries that only use the "customers" table
        {
            class => 'parser',
            match => [
                {
                    structure => 'tables',
                    operator  => 'only',
                    tokens    => ['customers']
                },
            ],
            datasource => 'RoundRobin',
        },

        # match queries that use the "type" column in the table "fruit"
        {
            class => 'parser',
            match => [
                {
                    structure => 'columns',
                    operator  => 'any',
                    tokens    => ['fruit.type']
                },
            ],
            datasource => 'RoundRobin',
        },

        # match queries that use both the "type" and "price" columns in the table "fruit"
        {
            class => 'parser',
            match => [
                {
                    structure => 'columns',
                    operator  => 'all',
                    tokens    => ['fruit.type', 'fruit.price']
                },
            ],
            datasource => 'RoundRobin',
        },


=head1 OPTIONS

The configuration for this rule is done in the standard DBIx::Router conf file.  It adds a C<match> section where the details of the routing are specified.  Anything that matches the rules described in this section will be routed to the datasource specified in the C<datasource> section. 

The C<match> section takes a list of configuration blocks.  If multiple blocks are specified, they will be combined with AND logic as a match requirement.  The blocks take these directives:

=head2 C<structure>

This controls which part of the SQL statement will be looked at.  It can be any of the following:

=over

=item * tables

Examine the names of tables used in the statement.

=item * command

Examine the command (e.g. "SELECT", "INSERT") used in the statement.

=item * columns

Examine the names of the columns used in the statement.

=back

=head2 C<tokens>

A list of words to match.  In the case of columns, these can use dotted table notation, e.g. C<table.column>.

=head2 C<operator>

Controls how the tokens need to compare to the structure for the rule to be considered a match.

=over

=item * any

If any of the tokens match the structure, the rule is a match.

=item * none

If none of the tokens match the stucture, the rule is a match.  (Negated form of C<any>.)

=item * all

If all of the given tokens match the structure, the rule is a match.

=item * only

If all of the structure matches the given token, the rule is a match, i.e. the structure must B<only> match the given tokens.
