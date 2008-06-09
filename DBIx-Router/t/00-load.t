#!perl -T

use Test::More tests => 6;

BEGIN {
	use_ok( 'DBIx::Router' );
	use_ok( 'DBIx::Router::DataSource' );
	use_ok( 'DBIx::Router::Rule' );
	use_ok( 'DBIx::Router::RuleList' );
	use_ok( 'DBIx::Router::DataSource::Pool' );
	use_ok( 'DBIx::Router::DataSource::Handle' );
}

diag( "Testing DBIx::Router $DBIx::Router::VERSION, Perl $], $^X" );
