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
        },
        {
            name        => 'RoundRobin',
            class       => 'roundrobin',
            datasources => [ 'Master1', 'Slave1', ],
            failover    => 1,
            timeout     => 2,
        },
        {
            name   => 'Partitioned',
            class  => 'shard',
            type   => 'list',
            table  => 'fruit',
            column => 'dkey',
            shards => [
                { values => [ 1, 3, 5 ], datasource => 'Master1', },
                { values => [ 2, 4, 6 ], datasource => 'Master2', },
            ],
        },
    ],
    rules => [
        {
            class      => 'shard',
            datasource => 'Partitioned',
        },

        #         {
        #             class      => 'regex',
        #             datasource => 'RoundRobin',
        #             match      => ['^ \s* SELECT \b '],
        #             not_match  => ['\b FOR \s+ UPDATE \b '],
        #         },
        {
            class => 'parser',
            match => [
                {
                    structure => 'tables',
                    operator  => 'all',
                    tokens    => ['fruit']
                },
                {
                    structure => 'tables',
                    operator  => 'none',
                    tokens    => ['orders']
                },
                {
                    structure => 'command',
                    operator  => 'any',
                    tokens    => ['select']
                },
                {
                    structure => 'columns',
                    operator  => 'any',
                    tokens    => ['fruit.type']
                },
            ],
            datasource => 'RoundRobin',
        },
        {
            class      => 'readonly',
            datasource => 'RoundRobin',
        },
        {
            class      => 'not',
            rule       => { class => 'readonly', },
            datasource => 'Master1',
        },

        #      {
        #             class      => 'default',
        #             datasource => 'Master1',
        #         },
    ],

    fallback => 0,
}
