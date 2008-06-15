{
    datasources => [
        {
            name     => Test1,
            dsn      => 'dbi:DBM:dbm_type=SDBM_File;lockfile=0',
            user     => undef,
            password => undef,
        },
        {
            name     => Test2,
            dsn      => 'dbi:DBM:dbm_type=SDBM_File;lockfile=0',
            user     => undef,
            password => undef,
        },

    ],
    rules => [
        {
            class      => 'regex',
            datasource => 'Test1',
            match      => ['^ \s* SELECT \b '],
            not_match  => ['\b FOR \s+ UPDATE \b '],
        },
        {
            class      => 'default',
            datasource => 'Test2',
        }
    ],
}
