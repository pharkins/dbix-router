{
    datasources => [
        {
            name => 'Master1',
            dsn  => 'dbi:DBM:dbm_type=SDBM_File;lockfile=0;f_dir=/tmp/master1',
            user => undef,
            password => undef,
        },
        {
            name => 'Master2',
            dsn  => 'dbi:DBM:dbm_type=SDBM_File;lockfile=0;f_dir=/tmp/master2',
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
            dsn  => 'dbi:DBM:dbm_type=SDBM_File;lockfile=0;f_dir=/tmp/master2',
            user => undef,
            password => undef,
        },
        {
            name        => 'Random',
            class       => 'random',
            datasources => [ 'Master1', 'Slave1', ],
        },
        {
            name        => 'Repeater',
            class       => 'repeater',
            datasources => [ 'Master1', 'Master2', ],
        }
    ],
    rules => [
        {
            class      => 'regex',
            datasource => 'Random',
            match      => ['^ \s* SELECT \b '],
            not_match  => ['\b FOR \s+ UPDATE \b '],
        },
        {
            class      => 'default',
            datasource => 'Repeater',
        }
    ],

    fallback => 0,
}
