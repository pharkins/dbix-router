{
    datasources => [
        {
            name => 'Master1',
            dsn  => 'dbi:DBM:dbm_type=SDBM_File;lockfile=0;f_dir=/tmp/master1',
            user => undef,
            password => undef,
        },
        {
            name => 'Slave1',
            dsn  => 'dbi:DBM:dbm_type=SDBM_File;lockfile=0;f_dir=/tmp/master1',
            user => undef,
            password => undef,
        },
        {
            name => 'Slave2',
            dsn  => 'dbi:DBM:dbm_type=SDBM_File;lockfile=0;f_dir=/tmp/master1',
            user => undef,
            password => undef,
        },
        {
            name        => 'Random',
            class       => 'random',
            datasources => [ 'Slave1', 'Slave2', ],
        },
    ],
    rules => [
        {
            class      => 'readonly',
            datasource => 'Random',
        },
        {
            class      => 'default',
            datasource => 'Master1',
        },
    ],

    fallback => 0,
}
