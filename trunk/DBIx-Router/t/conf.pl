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

        #         {
        #             class      => 'readonly',
        #             datasource => 'Test1',
        #         },
        {
            class      => 'default',
            datasource => 'Test2',
        }
    ],
}
