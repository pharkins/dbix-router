#!perl -T

use Test::More tests => 15;

BEGIN {
	use_ok( 'DBIx::Router' );
	use_ok( 'DBIx::Router::DataSource' );
	use_ok( 'DBIx::Router::Rule' );
    use_ok( 'DBIx::Router::Rule::default' );
    use_ok( 'DBIx::Router::Rule::not' );
    use_ok( 'DBIx::Router::Rule::parser' );
    use_ok( 'DBIx::Router::Rule::readonly' );
	use_ok( 'DBIx::Router::RuleList' );
	use_ok( 'DBIx::Router::DataSource::DSN' );
    use_ok( 'DBIx::Router::DataSource::PassThrough' );
	use_ok( 'DBIx::Router::DataSource::Group' );
    use_ok( 'DBIx::Router::DataSource::Group::random' );
    use_ok( 'DBIx::Router::DataSource::Group::repeater' );
    use_ok( 'DBIx::Router::DataSource::Group::roundrobin' );
    use_ok( 'DBIx::Router::DataSource::Group::shard' );
}

diag( "Testing DBIx::Router $DBIx::Router::VERSION, Perl $], $^X" );
