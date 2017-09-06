package MySQL::Sandbox::Scripts;
use strict;
use warnings;
use MySQL::Sandbox;

require Exporter;

our @ISA = qw/Exporter/;

our @EXPORT_OK = qw( 
    scripts_in_code
    get_readme_master_slave 
    get_readme_circular 
    get_readme_multiple 
    get_readme_common 
    get_readme_common_replication
    );
our @EXPORT = @EXPORT_OK;

our $VERSION=q{3.2.14};

our @MANIFEST = (
'clear.sh',
'my.sandbox.cnf',
'sb_include.sh',
'start.sh',
'status.sh',
'msb.sh',
'restart.sh',
'stop.sh',
'send_kill.sh',
'load_grants.sh',
'use.sh',
'mycli.sh',
'mysqlsh.sh',
'proxy_start.sh',
'my.sh',
'change_paths.sh',
'change_ports.sh',
'USING',
'README',
'connection.json',
'default_connection.json',
'grants.mysql',
'grants_5_7_6.mysql',
'json_in_db.sh',
'show_binlog.sh',
'show_relaylog.sh',
'add_option.sh',
'# INSTALL FILES',
'sandbox_action.pl',
'test_replication.sh',
);

#my $SBINSTR_SH_TEXT =<<'SBINSTR_SH_TEXT';
#if [ -f "$SBINSTR" ] 
#then
#    echo "[`basename $0`] - `date "+%Y-%m-%d %H:%M:%S"` - $@" >> $SBINSTR
#fi
#SBINSTR_SH_TEXT

#sub sbinstr_sh_text {
#    return $MySQL::Sandbox::SBINSTR_SH_TEXT;
#}

sub manifest {
    return @MANIFEST;
}
my %parse_options_low_level_make_sandbox = (
    upper_directory        => {
                                value => $ENV{'SANDBOX_HOME'} || $ENV{'HOME'},       
                                parse => 'upper_directory=s',         
                                so    =>  10,
                                help  => [
                                            "The directory that will contain the sandbox. (default: \$SANDBOX_HOME ($ENV{SANDBOX_HOME}))"
                                         ]
                            },
 
    sandbox_directory     => {
                                value => 'msb',    
                                parse => 'd|sandbox_directory=s',      
                                so    =>  20,
                                export => 1,
                                help  => [
                                            'Where to install the sandbox, under upper-directory'
                                         ] 
                             },
    sandbox_port          => {
                                value => 3310,               
                                parse => 'P|sandbox_port=i',           
                                export => 1,
                                so    =>  30,
                                help  => [
                                            'The port number to use for the sandbox server.', 
                                            '(Default: 3310)',
                                         ]
                            },
    check_port            => {
                                value => 0,               
                                parse => 'check_port',           
                                export => 1,
                                so    =>  35,
                                help  => [
                                            'Check whether the provided port is free,', 
                                            'and determine the next available one if it is not.',
                                            '(Default: disabled)',
                                         ]
                            },
    no_check_port         => {
                                value => 0,               
                                parse => 'no_check_port',           
                                so    =>  36,
                                help  => [
                                            'Ignores requests of checking ports.', 
                                            'To be used by group sandbox scripts.',
                                            '(Default: disabled)',
                                         ]
                            },
    datadir_from          => {
                                value => 'script',          
                                parse => 'datadir_from=s' ,            
                                so    =>  40,
                                help  => [
                                            'Where to get datadir files from. Available options are',
                                            'archive   will be taken from the archived data',
                                            '          provided with the package. They include',
                                            '          default username and passwords',
                                            '          ( DEPRECATED )',
                                            'script    the script mysql_install_db is called, with',
                                            '          default users, no passwords.',
                                            'dir:name  will be copied from an existing mysql directory', 
                                            '(Default: script)',
                                         ]
                             },
    install_version       => {
                                value => '',              
                                parse => 'i|install_version=s',        
                                so    =>  50,
                                help  => [
                                            'Which version to install (3.23, 4.0, 4.1, 5.0 or 5.1) default: none'
                                         ]
                            },
   basedir               => {
                                value => '/usr/local/mysql', 
                                parse => 'b|basedir=s' ,               
                                export => 1,
                                so    =>  60,
                                help  => [
                                            'Base directory for MySQL (default: /usr/local/mysql)'
                                         ]
                            },
   tmpdir                => {
                                value => undef, 
                                parse => 'tmpdir=s' ,               
                                export => 1,
                                so    =>  65,
                                help  => [
                                            'Temporary directory for MySQL (default: Sandbox_directory/tmp)'
                                         ]
                            },

    my_file               => {
                                value => q{},                 
                                parse => 'm|my_file=s',                
                                so    =>  70,
                                export => 1,
                                help  => [
                                            'which sample my-{small|large|huge}.cnf file should be used',
                                            'for additional configuration',
                                            'You may enter either the label (small|large|huge) or a full',
                                            'file name. (default: none)',
                                         ]
                            },
    conf_file             => {
                                value => q{},                 
                                parse => 'f|conf_file=s',              
                                so    =>  80,
                                help  =>  [
                                            'Configuration file containing options like the ones',
                                            'you can give on the command line (without dashes)',
                                          ]
                            },
    operating_system_user => {
                                value => $ENV{'USER'},       
                                parse => 'U|operating_system_user=s',  
                                so    =>  90,
                                help  => [
                                            'Operating system user (for mysql installation)',
                                            "default: \$USER ($ENV{USER})",
                                         ]
                            },
    db_user               => {
                                value => $MySQL::Sandbox::default_users{'db_user'},
                                parse => 'u|db_user=s'  ,              
                                so    => 100,
                                export => 1,
                                help  => [
                                            'user for global access to mysql (Default: '
                                            .  $MySQL::Sandbox::default_users{'db_user'} . ')'
                                         ]
                            },
     remote_access        => {
                                value => $MySQL::Sandbox::default_users{'remote_access'},
                                parse => 'remote_access=s'  ,              
                                so    => 101,
                                export => 1,
                                help  => [
                                            'network access for mysql users (Default: '
                                            .  $MySQL::Sandbox::default_users{'remote_access'} . ')'
                                         ]
                            },
     bind_address        => {
                                value => '127.0.0.1',
                                parse => 'bind_address=s'  ,              
                                so    => 102,
                                export => 1,
                                help  => [
                                            'Bind address for mysql server (Default: 127.0.0.1'
                                         ]
                            },

    ro_user              => {
                                value => $MySQL::Sandbox::default_users{'ro_user'},
                                parse => 'ro_user=s'  ,              
                                so    => 103,
                                export => 1,
                                help  => [
                                            'user for read-only access to mysql (Default: ' 
                                            .  $MySQL::Sandbox::default_users{'ro_user'} . ')'
                                         ]
                            },

     rw_user              => {
                                value => $MySQL::Sandbox::default_users{'rw_user'},
                                parse => 'rw_user=s'  ,              
                                so    => 105,
                                export => 1,
                                help  => [
                                            'user for read-write access to mysql (Default: ' 
                                            .  $MySQL::Sandbox::default_users{'rw_user'} . ')'
                                         ]
                            },
      repl_user           => {
                                value => $MySQL::Sandbox::default_users{'repl_user'},
                                parse => 'repl_user=s'  ,              
                                so    => 106,
                                export => 1,
                                help  => [
                                            'user for replication access to mysql (Default: ' 
                                            .  $MySQL::Sandbox::default_users{'repl_user'} . ')'
                                         ]
                            },
     db_password           => {
                                value =>  $MySQL::Sandbox::default_users{'db_password'},      
                                parse => 'p|db_password=s'  ,              
                                so    => 110,
                                export => 1,
                                help  => [
                                            'password for global access to mysql (Default: '
                                            .  $MySQL::Sandbox::default_users{'db_password'} . ')'
                                         ]
                            },
      repl_password      => {
                                value =>  $MySQL::Sandbox::default_users{'repl_password'},      
                                parse => 'repl_password=s'  ,              
                                so    => 112,
                                export => 1,
                                help  => [
                                            'password for replication access to mysql (Default: '
                                            .  $MySQL::Sandbox::default_users{'repl_password'} . ')'
                                         ]
                            },
    my_clause             => {
                                value => '',      
                                parse => 'c|my_clause=s@', 
                                so    => 115,
                                export => 1,
                                help  => [
                                            'option to be inserted in a my.cnf file',
                                            'it may be used several times',
                                         ]
                            },
   init_options           => {
                                value => $ENV{INIT_OPTIONS} || '',      
                                parse => 'init_options=s', 
                                so    => 118,
                                export => 1,
                                help  => [
                                            'options to be used during initialization ',
                                            '(by either mysql_install_db or mysqld --initialize.)'
                                         ]
                            },
   init_my_cnf        => {
                                value => $ENV{INIT_MY_CNF} ||  '',      
                                parse => 'init_my_cnf', 
                                so    => 120,
                                export => 1,
                                help  => [
                                            'If set, it uses my.sandbox.cnf at initialization',
                                            'instead of --no-defaults.',
                                            'WARNING! it may lead to initialization failures'
                                         ]
                            },
   init_use_cnf        => {
                                value => $ENV{INIT_USE_CNF} ||  '',      
                                parse => 'init_use_cnf=s', 
                                so    => 122,
                                export => 1,
                                help  => [
                                            'Indicates an options file to load during initialization',
                                            'instead of --no-defaults.'
                                         ]
                            },
    master            => {
                                value => 0,      
                                parse => 'master', 
                                so    => 124,
                                export => 1,
                                help  => [
                                            'configures the server as a master (enables binlog and sets server ID)'
                                         ]
                            },
    slaveof           => {
                                value => undef,      
                                parse => 'slaveof=s', 
                                so    => 125,
                                export => 1,
                                help  => [
                                            'Configures the server as a slave of another sandbox ',
                                            'Requires options for CHANGE MASTER TO, (at least master_port).',
                                            'If options other than master_port are provided, they will override the defaults',
                                            'and it will be possible to set a slave for a non-sandbox server'
                                         ]
                            },
      high_performance      => {
                                value => 0,      
                                parse => 'high_performance', 
                                so    => 126,
                                export => 1,
                                help  => [
                                            'configures the server for high performance'
                                         ]
                            },
    gtid            => {
                                value => 0,      
                                parse => 'gtid', 
                                so    => 130,
                                export => 1,
                                help  => [
                                            'enables GTID for MySQL 5.6.10+'
                                         ]
                            },
#    general_log      => {
#                               value => 0,
#                               parse => 'gl|general_log'  ,              
#                               so    => 140,
#                               help  => [
#                                           'Enables the general log for MYSQL 5.1+',
#                                        ]
#                           },
     pre_start_exec      => {
                                value => '',      
                                parse => 'pre_start_exec=s', 
                                so    => 140,
                                export => 1,
                                help  => [
                                            'Shell command to execute after installation, before the server starts',
                                         ]
                           },
      pre_grants_exec      => {
                                value => '',      
                                parse => 'pre_grants_exec=s', 
                                so    => 150,
                                export => 1,
                                help  => [
                                            'Shell command to execute shortly after installation',
                                         ]
                           },
     post_grants_exec      => {
                                value => '',      
                                parse => 'post_grants_exec=s', 
                                so    => 152,
                                export => 1,
                                help  => [
                                            'Shell command to execute shortly after loading grants',
                                         ]
                           },
     pre_grants_sql      => {
                                value => '',      
                                parse => 'pre_grants_sql=s', 
                                so    => 155,
                                export => 1,
                                help  => [
                                            'SQL command to execute shortly after installation ',
                                         ]
                           },
    post_grants_sql      => {
                                value => '',      
                                parse => 'post_grants_sql=s', 
                                so    => 160,
                                export => 1,
                                help  => [
                                            'SQL command to execute shortly after loading grants ',
                                         ]
                            },
    pre_grants_file      => {
                                value => '',      
                                parse => 'pre_grants_file=s', 
                                so    => 170,
                                export => 1,
                                help  => [
                                            'SQL file to execute shortly after installation ',
                                         ]
                            },
    post_grants_file      => {
                                value => '',      
                                parse => 'post_grants_file=s', 
                                so    => 180,
                                export => 1,
                                help  => [
                                            'SQL file to execute shortly after loading grants ',
                                         ]
                            },
    load_plugin         => {
                                value => '',      
                                parse => 'load_plugin=s', 
                                so    => 190,
                                export => 1,
                                help  => [
                                            'Comma separated list of plugins to install ',
                                         ]
                            },
    plugin_mysqlx       => {
                                value => undef,      
                                parse => 'plugin_mysqlx', 
                                so    => 195,
                                export => 1,
                                help  => [
                                            'Installs MySQLx plugin with an automatic port for X-protocol',
                                         ]
                            },
    mysqlx_port       => {
                                value => 0,      
                                parse => 'mysqlx_port=i', 
                                so    => 196,
                                export => 1,
                                help  => [
                                            'Sets port for X-plugin (requires --plugin_mysqlx)',
                                         ]
                            },
    custom_mysqld => {
                                value => $ENV{'CUSTOM_MYSQLD'} || '' , 
                                parse => 'custom_mysqld=s', 
                                so    => 198,
                                export => 1,
                                help  => [
                                            'uses alternative mysqld ',
                                            '(must be in the same directory as the regular mysqld)'
                                         ]
                            },
     expose_dd_tables => {
                                value => $ENV{'EXPOSE_DD_TABLES'},      
                                parse => 'expose_dd_tables', 
                                so    => 197,
                                export => 1,
                                help  => [
                                            'Exposed MySQL 8.0.x data dictionary tables',
                                         ]
                            },
 
     prompt_prefix           => {
                                value => 'mysql',      
                                parse => 'prompt_prefix=s', 
                                so    => 200,
                                export => 1,
                                help  => [
                                            'prefix to use in CLI prompt (default: mysql)',
                                         ]
                            },

    prompt_body          => {
                                value => q/ [\h] {\u} (\d) > /,      
                                parse => 'prompt_body=s', 
                                so    => 210,
                                export => 1,
                                help  => [
                                            'options to use in CLI prompt (default:  [\h] {\u} (\d) > )',
                                         ]
                            },
    force                 => {
                                value => 0,                  
                                parse => 'force',                      
                                so    => 220,
                                export => 1,
                                help  => [
                                            'Use this option if you want to overwrite existing directories',
                                            'and files during the installation. (Default: disabled)', 
                                         ] 
                            },
    no_ver_after_name     => {
                                value => 0,                  
                                parse => 'no_ver_after_name',                  
                                so    => 230,
                                help  => [
                                            'Do not add version number after sandbox directory name (default: disabled)'
                                         ] 
                            },
    verbose               => {
                                value => 0,                  
                                parse => 'v|verbose',                  
                                so    => 240,
                                export => 1,
                                help  => [
                                            'Use this option to see installation progress (default: disabled)'
                                         ] 
                            },
   load_grants           => {
                                value => 0,                  
                                parse => 'load_grants',                  
                                so    => 250,
                                export => 1,
                                help  => [
                                            'Loads the predefined grants from a SQL file.',
                                            'Useful when installing from script.',
                                            '(default: disabled)'
                                         ] 
                            },
   no_load_grants         => {
                                value => 0,                  
                                parse => 'no_load_grants',                  
                                so    => 260,
                                help  => [
                                            'Does not loads the predefined grants from a SQL file.',
                                            '(default: disabled)'
                                         ] 
                            },

   no_run                 => {
                                value => 0,                  
                                parse => 'no_run',                  
                                so    => 270,
                                help  => [
                                            'Stops the server if started with "load_grants".',
                                            '(default: disabled)'
                                         ] 
                            },

#  
#  This option requires rewriting several installation steps
#  For now ( April 29, 2014) we are only supporting MySQL 5.7.4 without random password.
#  More support will come later
#
#    random_password       => {
#                                value => 0,                  
#                                parse => 'random_password',                  
#                                so    => 275,
#                                help  => [
#                                            'Enables random password generation with MySQL 5.7.4+'
#                                         ] 
#                            },
    interactive           => {
                                value => 0,                  
                                parse => 't|interactive',                  
                                so    => 280,
                                help  => [
                                            'Use this option to be guided through the installation process (default: disabled)'
                                         ] 
                            },
    more_options          => {
                                value => q{},                 
                                parse => undef,                        
                                so => 20},
    help                  => {
                                value => q{},                 
                                parse => 'help',                       
                                so => 25},
    no_confirm            => {
                                value => 0, 
                                parse => 'no_confirm',
                                export => 1,
                                so    => 290,
                                help  => [
                                            'suppress the confirmation request from user',
                                         ],
                            },
    no_show               => {
                                value => 0, 
                                parse => 'no_show',
                                so    => 300,
                                help  => [
                                            'does not show options or ask confirmation to the user',
                                         ],
                            },
    keep_uuid             => {
                                value => $ENV{KEEP_UUID} || $ENV{keep_uuid} || 0, 
                                parse => 'keep_uuid',
                                so    => 310,
                                help  => [
                                            'does not modify server UUID in MySQL 5.6+',
                                         ],
                            },
    history_dir             => {
                                value => $ENV{HISTORY_DIR} || $ENV{HISTORYDIR} || '', 
                                parse => 'history_dir=s',
                                so    => 320,
                                help  => [
                                            'Sets the history directory for mysql client to a given path',
                                         ],
                            },

);

my %parse_options_replication = (
    upper_directory        => {
                                value => $ENV{'SANDBOX_HOME'} || $ENV{'HOME'},       
                                parse => 'upper_directory=s',         
                                so    =>  10,
                                help  => [
                                            "The directory containing the sandbox. (default: \$SANDBOX_HOME ($ENV{SANDBOX_HOME}))"
                                         ]
                            },
    replication_directory  => {
                                value => undef,
                                parse => 'r|replication_directory=s',      
                                so    =>  20,
                                help  => [
                                            'Where to install the sandbox replication system, under upper-directory',
                                            'default: (rsandbox)'
                                         ] 
                             },
    server_version  => {
                                value => undef,    
                                parse => 'server_version=s',      
                                so    =>  30,
                                help  => [
                                            'which version to install'
                                         ] 
                             },
    sandbox_base_port      => {
                                value => undef,               
                                parse => 'sandbox_base_port=i',           
                                so    =>  40,
                                help  => [
                                            'The port number to use for the sandbox replication system.', 
                                            '(Default: 11000  + version )',
                                         ]
                            },
    check_base_port      => {
                                value => undef,               
                                parse => 'check_base_port',           
                                so    =>  45,
                                help  => [
                                            'Check that the ports are available ', 
                                            '(Default: disabled )',
                                         ]
                            },


    how_many_slaves      => {
                                value => 2,               
                                parse => 'how_many_nodes|how_many_slaves=i',           
                                so    =>  50,
                                help  => [
                                            'The number of slaves to create.', 
                                            '(Default: 2)',
                                         ]
                            },

    topology               => {
                                value => 'standard',                  
                                parse => 't|topology=s',                  
                                so    => 60,
                                help  => [
                                            'Sets a replication topology.',
                                            'Available: {standard|circular} (default: standard)'
                                         ] 
                            },
    circular               => {
                                value => 0,
                                parse => 'circular=i',                  
                                so    => 70,
                                help  => [
                                            'Sets circular replication with N nodes.',
                                            '(default: 0)'
                                         ] 
                            },


    master_master        => {
                                value => 0,                  
                                parse => 'master_master',                  
                                so    => 80,
                                help  => [
                                            'set exactly two nodes in circular replication'
                                         ] 
                            },
 
    repl_user           => {
                                value => $MySQL::Sandbox::default_users{'repl_user'},
                                parse => 'repl_user=s',                  
                                so    => 90,
                                help  => [
                                            'user with replication slave privileges.',
                                            '(default: '. $MySQL::Sandbox::default_users{'repl_user'} . ')'
                                         ] 
                            },
    master_ip           => {
                                value => '127.0.0.1',
                                parse => 'master_ip=s',
                                so    => 95,
                                help  => [
                                            'Which IP is used by slaves to connect to the master',
                                            '(default: 127.0.0.1)'
                                         ]
                            },

    repl_password           => {
                                value => $MySQL::Sandbox::default_users{'repl_password'},
                                parse => 'repl_password=s',                  
                                so    => 100,
                                help  => [
                                            'password for user with replication slave privileges.',
                                            '(default: '. $MySQL::Sandbox::default_users{'repl_password'} . ')'
                                         ] 
                            },
     remote_access        => {
                                value => $MySQL::Sandbox::default_users{'remote_access'},
                                parse => 'remote_access=s'  ,              
                                so    => 110,
                                help  => [
                                            'network access for mysql users (Default: '
                                            .  $MySQL::Sandbox::default_users{'remote_access'} . ')'
                                         ]
                            },
     master_options       => {
                                value => '',
                                parse => 'master_options=s'  ,              
                                so    => 120,
                                help  => [
                                            'Options passed to the master (Default: "" )'
                                         ]
                            },
     slave_options        => {
                                value => '',
                                parse => 'slave_options=s'  ,              
                                so    => 120,
                                help  => [
                                            'Options passed to each slave (Default: "" )'
                                         ]
                            },
     node_options        => {
                                value => '',
                                parse => 'node_options=s'  ,              
                                so    => 130,
                                help  => [
                                            'Options passed to each node (Default: "" )'
                                         ]
                            },
     one_slave_options      => {
                                value => '',
                                parse => 'one_slave_options=s@'  ,              
                                so    => 130,
                                help  => [
                                            'Options passed to a specific slave with the format "N:options"',
                                            '(Default: "" )'
                                         ]
                            },
     gtid      => {
                                value => 0,
                                parse => 'gtid'  ,              
                                so    => 140,
                                help  => [
                                            'Enables GTID for MYSQL 5.6.10+',
                                            '(Default: NO )'
                                         ]
                            },
#    general_log      => {
#                               value => 0,
#                               parse => 'gl|general_log'  ,              
#                               so    => 145,
#                               help  => [
#                                           'Enables the general log for MYSQL 5.1+',
#                                           '(Default: NO )'
#                                        ]
#                           },
   
  
    interactive           => {
                                value => 0,                  
                                parse => 'interactive',                  
                                so    => 210,
                                help  => [
                                            'Use this option to ask interactive user ',
                                            'confirmation for each node (default: disabled)'
                                         ] 
                            },
    verbose               => {
                                value => 0,                  
                                parse => 'v|verbose',                  
                                so    => 220,
                                help  => [
                                            'Use this option to see installation progress (default: disabled)'
                                         ] 
                            },
    help               => {
                                value => 0,                  
                                parse => 'help',                  
                                so    => 230,
                                help  => [
                                            'show this help (default: disabled)'
                                         ] 
                            },
);


my %parse_options_many = (
    upper_directory        => {
                                value => $ENV{'SANDBOX_HOME'} || $ENV{'HOME'},       
                                parse => 'upper_directory=s',         
                                so    =>  10,
                                help  => [
                                            "The directory containing the sandbox. (default: \$SANDBOX_HOME ($ENV{SANDBOX_HOME}))"
                                         ]
                            },
    group_directory  => {
                                value => undef,
                                parse => 'r|group_directory=s',      
                                so    =>  20,
                                help  => [
                                            'Where to install the sandbox group, under home-directory',
                                            'default: (multi_msb)'
                                         ] 
                             },
    server_version  => {
                                value => undef,    
                                parse => 'server_version=s',      
                                so    =>  30,
                                help  => [
                                            'which version to install'
                                         ] 
                             },
    sandbox_base_port      => {
                                value => undef,               
                                parse => 'sandbox_base_port=i',           
                                so    =>  40,
                                help  => [
                                            'The port number to use for the sandbox multiple system.', 
                                            '(Default: 7000  + version )',
                                         ]
                            },
    check_base_port      => {
                                value => undef,               
                                parse => 'check_base_port',           
                                so    =>  45,
                                help  => [
                                            'Check that the ports are available ', 
                                            '(Default: disabled )',
                                         ]
                            },

    how_many_nodes      => {
                                value => 3,               
                                parse => 'how_many_nodes=i',           
                                so    =>  50,
                                help  => [
                                            'The number of nodes to create.', 
                                            '(Default: 3)',
                                         ]
                            },
    master_master        => {
                                value => 0,                  
                                parse => 'master_master',                  
                                so    => 60,
                                help  => [
                                            'set exactly two nodes in circular replication'
                                         ] 
                            },
 
    circular             => {
                                value => 0,                  
                                parse => 'circular',                  
                                so    => 70,
                                help  => [
                                            'set the nodes in circular replication'
                                         ] 
                            },

    repl_user           => {
                                value => $MySQL::Sandbox::default_users{'repl_user'},
                                parse => 'repl_user=s',                  
                                so    => 80,
                                help  => [
                                            'user with replication slave privileges.',
                                            '(default: '. $MySQL::Sandbox::default_users{'repl_user'} . ')'
                                         ] 
                            },

    repl_password           => {
                                value => $MySQL::Sandbox::default_users{'repl_password'},
                                parse => 'repl_password=s',                  
                                so    => 90,
                                help  => [
                                            'password for user with replication slave privileges.',
                                            '(default: '. $MySQL::Sandbox::default_users{'repl_password'} . ')'
                                         ] 
                            },
     remote_access        => {
                                value => $MySQL::Sandbox::default_users{'remote_access'},
                                parse => 'remote_access=s'  ,              
                                so    => 100,
                                help  => [
                                            'network access for mysql users (Default: '
                                            .  $MySQL::Sandbox::default_users{'remote_access'} . ')'
                                         ]
                            },
 
     node_options        => {
                                value => '',
                                parse => 'node_options=s'  ,              
                                so    => 130,
                                help  => [
                                            'Options passed to each node (Default: "" )'
                                         ]
                            },
 
    one_node_options      => {
                                value => '',
                                parse => 'one_node_options=s@'  ,              
                                so    => 140,
                                help  => [
                                            'Options passed to a specific node with the format "N:options"',
                                            '(Default: "" )'
                                         ]
                            },
     gtid      => {
                                value => 0,
                                parse => 'gtid'  ,              
                                so    => 150,
                                help  => [
                                            'Enables GTID for MYSQL 5.6.10+',
                                            '(Default: NO )'
                                         ]
                            },
  

    interactive           => {
                                value => 0,                  
                                parse => 'interactive',                  
                                so    => 210,
                                help  => [
                                            'Use this option to ask interactive user ',
                                            'confirmation for each node (default: disabled)'
                                         ] 
                            },
    verbose               => {
                                value => 0,                  
                                parse => 'v|verbose',                  
                                so    => 220,
                                help  => [
                                            'Use this option to see installation progress (default: disabled)'
                                         ] 
                            },

    help               => {
                                value => 0,                  
                                parse => 'help',                  
                                so    => 230,
                                help  => [
                                            'show this help (default: disabled)'
                                         ] 
                            },
); 

my %parse_options_custom_many = (
    upper_directory        => {
                                value => $ENV{'SANDBOX_HOME'} || $ENV{'HOME'},       
                                parse => 'upper_directory=s',         
                                so    =>  10,
                                help  => [
                                            "The directory containing the sandbox. (default: \$SANDBOX_HOME ($ENV{SANDBOX_HOME}))"
                                         ]
                            },
    group_directory  => {
                                value => undef,
                                parse => 'r|group_directory=s',      
                                so    =>  20,
                                help  => [
                                            'Where to install the sandbox group, under home-directory',
                                            'default: (multi_msb)'
                                         ] 
                             },
    server_version  => {
                                value => undef,    
                                parse => 'server_version=s',      
                                so    =>  30,
                                help  => [
                                            'which version to install'
                                         ] 
                             },
    sandbox_base_port      => {
                                value => undef,               
                                parse => 'sandbox_base_port=i',           
                                so    =>  40,
                                help  => [
                                            'The port number to use for the sandbox custom system.', 
                                            '(Default: 5000  + version )',
                                         ]
                            },
    check_base_port      => {
                                value => undef,               
                                parse => 'check_base_port',           
                                so    =>  45,
                                help  => [
                                            'Check that the ports are available ', 
                                            '(Default: disabled )',
                                         ]
                            },
     node_options        => {
                                value => '',
                                parse => 'node_options=s'  ,              
                                so    => 130,
                                help  => [
                                            'Options passed to each node (Default: "" )'
                                         ]
                            },
 
    one_node_options      => {
                                value => '',
                                parse => 'one_node_options=s@'  ,              
                                so    => 140,
                                help  => [
                                            'Options passed to a specific node with the format "N:options"',
                                            '(Default: "" )'
                                         ]
                            },



    interactive           => {
                                value => 0,                  
                                parse => 'interactive',                  
                                so    => 210,
                                help  => [
                                            'Use this option to ask interactive user ',
                                            'confirmation for each node (default: disabled)'
                                         ] 
                            },
    verbose               => {
                                value => 0,                  
                                parse => 'v|verbose',                  
                                so    => 220,
                                help  => [
                                            'Use this option to see installation progress (default: disabled)'
                                         ] 
                            },
    help               => {
                                value => 0,                  
                                parse => 'help',                  
                                so    => 230,
                                help  => [
                                            'show this help (default: disabled)'
                                         ] 
                            },
); 

our %sbtool_supported_operations = (
    ports => 'lists ports used by the Sandbox',
    range => 'finds N consecutive ports not yet used by the Sandbox',
    info  => 'returns configuration options from a Sandbox',
    tree  => 'creates a replication tree',
    copy  => 'copies data from one Sandbox to another',
    move  => 'moves a Sandbox to a different location',
    port  => 'Changes a Sandbox port',
    delete => 'removes a sandbox completely',
    preserve => 'makes a sandbox permanent',
    unpreserve => 'makes a sandbox NOT permanent',
    plugin => 'adds plugin support to a sandbox (innodb,semisynch)',
);

our %sbtool_supported_formats = (
    text => 'plain text dump of requested information',
    perl => 'fully structured information in Perl code',
);

#our %sbtool_supported_plugins = (
#    innodb => 'innodb plugin (5.1)',
#    semisync => 'semi synchrounus replication (5.5)',
#    gearman => 'Gearman UDF',
#);

my %parse_options_sbtool = (
    operation => {
        so       => 10,
        parse    => 'o|operation=s',
        value    => undef,
        accepted => \%sbtool_supported_operations,
        help     => 'what task to perform',
    },
    source_dir => {
        so    => 20,
        parse => 's|source_dir=s',
        value => undef,
        help  => 'source directory for move, copy, delete',
    },
    dest_dir => {
        so    => 30,
        parse => 'd|dest_dir=s',
        value => undef,
        help  => 'destination directory for move,copy',
    },
    new_port  => {
        so    => 40,
        parse => 'n|new_port=s',
        value => undef,
        help  => 'new port while moving a sandbox',
    },
    only_used => {
        so    => 50,
        parse => 'u|only_used',
        value => 0,
        help  => 'for "ports" operation, shows only the used ones',
    },
    min_range => {
        so    => 60,
        parse => 'i|min_range=i',
        value => 5000,
        help  => 'minimum port when searching for available ranges',
    },
    max_range => {
        so    => 70,
        parse => 'x|max_range=i',
        value => 64000,
        help  => 'maximum port when searching for available ranges',
    },
    range_size => {
        so    => 80,
        parse => 'z|range_size=i',
        value => 10,
        help  => 'size of range when searching for available port range',
    },
    format => {
        so       => 90,
        parse    => 'f|format=s',
        value    => 'text',
        accepted => \%sbtool_supported_formats,
        help     => 'format for "ports" and "info"',
    },
    search_path => {
        so    => 100,
        parse => 'p|search_path=s',
        value => $ENV{SANDBOX_HOME},
        help  => 'search path for ports and info',
    },
    all_info => {
        so    => 110,
        parse => 'a|all_info',
        value => 0,
        help  => 'print more info for "ports" operation'
    },
    master_node => {
        so    => 115,
        parse => 'master_node=i',
        value => '1',
        help  => 'which node should be master (default: 1)',
    },
    tree_nodes => {
        so    => 120,
        parse => 'tree_nodes=s',
        value => '',
        help  => 'description of the tree (x-x x x-x x|x x x|x x)',
    },
    mid_nodes => {
        so    => 130,
        parse => 'mid_nodes=s',
        value => '',
        help  => 'description of the middle nodes (x x x)',
    },
    leaf_nodes => {
        so    => 140,
        parse => 'leaf_nodes=s',
        value => '',
        help  => 'description of the leaf nodes (x x|x x x|x x)',
    },
    tree_dir => {
        so    => 150,
        parse => 'tree_dir=s',
        value => '',
        help  => 'which directory contains the tree nodes',
    },
    verbose => {
        so    => 160,
        parse => 'v|verbose',
        value => 0,
        help  => 'prints more info on some operations'
    },
    plugin => {
        so       => 170,
        parse    => 'plugin=s',
        value    => undef,
        help     => 'install given plugin in sandbox',
    },
    plugin_file => {
        so       => 180,
        parse    => 'plugin_file=s',
        value    => undef,
        help     => 'plugin configuration file to use instead of default plugin.conf',
    },
    help => {
        so    => 999,
        parse => 'h|help',
        value => undef,
        help  => 'this screen',
    },
);

# --- START SCRIPTS IN CODE ---

my %scripts_in_code = (
    'msb.sh' => <<'MSB_SCRIPT',
#!_BINBASH_    
__LICENSE__

ACCEPTED="{start|stop|restart|clear|send_kill|status}"
if [ "$1" == "" ]
then
        echo "argument required $ACCEPTED"
        exit 1
fi

SBDIR="_HOME_DIR_/_SANDBOXDIR_"
CMD=$1
shift

if [ -x "$SBDIR/$CMD" ]
then
    $SBDIR/$CMD "$@"
else
    echo "unrecognized command '$CMD'"
    echo "accepted: $ACCEPTED"
    exit 1 
fi

#case $CMD in
#      start)  $SBDIR/start "$@"   ;;
#    restart)  $SBDIR/restart "$@" ;;
#       stop)  $SBDIR/stop "$@"    ;;
#      clear)  $SBDIR/clear "$@"    ;;
#  send_kill)  $SBDIR/send_kill "$@"    ;;
#     status)  $SBDIR/status "$@"  ;;
#    *)  
#        echo "unrecognized command '$CMD'"
#        echo "accepted: $ACCEPTED"
#        exit 1 
#        ;;
#esac

MSB_SCRIPT

    'start.sh' => <<'START_SCRIPT',
#!_BINBASH_
__LICENSE__
BASEDIR='_BASEDIR_'
export LD_LIBRARY_PATH=$BASEDIR/lib:$BASEDIR/lib/mysql:$LD_LIBRARY_PATH
export DYLD_LIBRARY_PATH=$BASEDIR_/lib:$BASEDIR/lib/mysql:$DYLD_LIBRARY_PATH
MYSQLD_SAFE="bin/_MYSQLDSAFE_"
SBDIR="_HOME_DIR_/_SANDBOXDIR_"
PIDFILE="$SBDIR/data/mysql_sandbox_SERVERPORT_.pid"
CUSTOM_MYSQLD=_CUSTOM_MYSQLD_
if [ -n "$CUSTOM_MYSQLD" ]
then
    CUSTOM_MYSQLD="--mysqld=$CUSTOM_MYSQLD"
fi
__SBINSTR_SH__
if [ ! -f $BASEDIR/$MYSQLD_SAFE ]
then
    echo "mysqld_safe not found in $BASEDIR/bin/"
    exit 1
fi
MYSQLD_SAFE_OK=`sh -n $BASEDIR/$MYSQLD_SAFE 2>&1`
if [ "$MYSQLD_SAFE_OK" == "" ]
then
    if [ "$SBDEBUG" == "2" ] 
    then
        echo "$MYSQLD_SAFE OK"
    fi
else
    echo "$MYSQLD_SAFE has errors"
    echo "((( $MYSQLD_SAFE_OK )))"
    exit 1
fi

function is_running
{
    if [ -f $PIDFILE ]
    then
        MYPID=$(cat $PIDFILE)
        ps -p $MYPID | grep $MYPID
    fi
}

TIMEOUT=180
if [ -n "$(is_running)" ]
then
    echo "sandbox server already started (found pid file $PIDFILE)"
else
    if [ -f $PIDFILE ]
    then
        # Server is not running. Removing stale pid-file
        rm -f $PIDFILE
    fi
    CURDIR=`pwd`
    cd $BASEDIR
    if [ "$SBDEBUG" = "" ]
    then
        $MYSQLD_SAFE --defaults-file=$SBDIR/my.sandbox.cnf $CUSTOM_MYSQLD $@ > /dev/null 2>&1 &
    else
        $MYSQLD_SAFE --defaults-file=$SBDIR/my.sandbox.cnf $CUSTOM_MYSQLD $@ > "$SBDIR/start.log" 2>&1 &
    fi
    cd $CURDIR
    ATTEMPTS=1
    while [ ! -f $PIDFILE ] 
    do
        ATTEMPTS=$(( $ATTEMPTS + 1 ))
        echo -n "."
        if [ $ATTEMPTS = $TIMEOUT ]
        then
            break
        fi
        sleep 1
    done
fi

if [ -f $PIDFILE ]
then
    echo " sandbox server started"
    #if [ -f $SBDIR/needs_reload ]
    #then
    #    if [ -f $SBDIR/rescue_mysql_dump.sql ]
    #    then
    #        $SBDIR/use mysql < $SBDIR/rescue_mysql_dump.sql
    #    fi
    #    rm $SBDIR/needs_reload
    #fi
else
    echo " sandbox server not started yet"
    exit 1
fi

START_SCRIPT
    'sb_include.sh' => <<'SB_INCLUDE_SCRIPT',
if [ -r $HOME/.mylogin.cnf ]
then
    if [ -z "$IGNORE_MYLOGIN_CNF" ]
    then
        echo "MySQL Sandbox does not work with \$HOME/.mylogin.cnf,"
        echo "which is a file created by mysql_config_editor."
        echo "Either remove the file or make it not readable by the current user."
        echo "If you know what you are doing, you can skip this check by"
        echo "setting the variable IGNORE_MYLOGIN_CNF to a nonzero value."
        echo "Be aware that having \$HOME/.mylogin.cnf can disrupt MySQL-Sandbox."
        echo "Use it at your own risk.\n"
        exit 1
    fi
fi

SB_INCLUDE_SCRIPT

    'status.sh' => <<'STATUS_SCRIPT',
#!_BINBASH_
__LICENSE__
SBDIR="_HOME_DIR_/_SANDBOXDIR_"
PIDFILE="$SBDIR/data/mysql_sandbox_SERVERPORT_.pid"
__SBINSTR_SH__
source $SBDIR/sb_include
node_status=off
exit_code=1
if [ -f $PIDFILE ]
then
    MYPID=$(cat $PIDFILE)
    running=$(ps -p $MYPID | grep $MYPID)
    if [ -n "$running" ]
    then
        node_status=on
        exit_code=0
    fi
fi
echo "_SANDBOXDIR_ $node_status"
exit $exit_code

STATUS_SCRIPT

'restart.sh' => <<'RESTART_SCRIPT',
#!_BINBASH_
__LICENSE__

__SBINSTR_SH__
SBDIR="_HOME_DIR_/_SANDBOXDIR_"
$SBDIR/stop
$SBDIR/start $@

RESTART_SCRIPT
    'stop.sh' => <<'STOP_SCRIPT',
#!_BINBASH_
__LICENSE__
SBDIR="_HOME_DIR_/_SANDBOXDIR_"
source $SBDIR/sb_include
BASEDIR=_BASEDIR_
export LD_LIBRARY_PATH=$BASEDIR/lib:$BASEDIR/lib/mysql:$LD_LIBRARY_PATH
export DYLD_LIBRARY_PATH=$BASEDIR/lib:$BASEDIR/lib/mysql:$DYLD_LIBRARY_PATH
MYSQL_ADMIN="$BASEDIR/bin/mysqladmin"
PIDFILE="$SBDIR/data/mysql_sandbox_SERVERPORT_.pid"
__SBINSTR_SH__

function is_running
{
    if [ -f $PIDFILE ]
    then
        MYPID=$(cat $PIDFILE)
        ps -p $MYPID | grep $MYPID
    fi
}

if [ -n "$(is_running)" ]
then
    if [ -f $SBDIR/data/master.info ]
    then
        echo "stop slave" | $SBDIR/use -u root
    fi
    # echo "$MYSQL_ADMIN --defaults-file=$SBDIR/my.sandbox.cnf $MYCLIENT_OPTIONS shutdown"
    $MYSQL_ADMIN --defaults-file=$SBDIR/my.sandbox.cnf $MYCLIENT_OPTIONS shutdown
    sleep 1
else
    if [ -f $PIDFILE ]
    then
        rm -f $PIDFILE
    fi
fi

if [ -n "$(is_running)" ]
then
    # use the send_kill script if the server is not responsive
    $SBDIR/send_kill
fi
STOP_SCRIPT

    'send_kill.sh' => <<'KILL_SCRIPT',
#!_BINBASH_
__LICENSE__
SBDIR="_HOME_DIR_/_SANDBOXDIR_"
#source $SBDIR/sb_include
PIDFILE="$SBDIR/data/mysql_sandbox_SERVERPORT_.pid"
TIMEOUT=30
__SBINSTR_SH__

function is_running
{
    if [ -f $PIDFILE ]
    then
        MYPID=$(cat $PIDFILE)
        ps -p $MYPID | grep $MYPID
    fi
}


if [ -n "$(is_running)" ]
then
    MYPID=`cat $PIDFILE`
    echo "Attempting normal termination --- kill -15 $MYPID"
    kill -15 $MYPID
    # give it a chance to exit peacefully
    ATTEMPTS=1
    while [ -f $PIDFILE ]
    do
        ATTEMPTS=$(( $ATTEMPTS + 1 ))
        if [ $ATTEMPTS = $TIMEOUT ]
        then
            break
        fi
        sleep 1
    done
    if [ -f $PIDFILE ]
    then
        echo "SERVER UNRESPONSIVE --- kill -9 $MYPID"
        kill -9 $MYPID
        rm -f $PIDFILE
    fi
else
    # server not running - removing stale pid-file
    if [ -f $PIDFILE ]
    then
        rm -f $PIDFILE
    fi
fi

KILL_SCRIPT

'json_in_db.sh' => <<'JSON_IN_DB_SCRIPT',

#!_BINBASH_
__LICENSE__
SBDIR="_HOME_DIR_/_SANDBOXDIR_"
cd $SBDIR
./use -e 'drop table if exists test.connection_json'
./use -e 'create table test.connection_json(t longtext)'
./use -e '/*!50708 alter table test.connection_json modify t json */'
#./use -e "insert into test.connection_json values (load_file('$SBDIR/connection.json'))"
./use -e "insert into test.connection_json values ( /*!50708 convert( */ load_file('$SBDIR/connection.json') /*!50708 using UTF8 ) */ )"
if [ "$?" != "0" ]
then
    echo "error loading connection.json to the database"
    exit 1
fi
echo "connection.json saved to test.connection_json"

JSON_IN_DB_SCRIPT

    'use.sh' => <<'USE_SCRIPT',
#!_BINBASH_
__LICENSE__
export LD_LIBRARY_PATH=_BASEDIR_/lib:_BASEDIR_/lib/mysql:$LD_LIBRARY_PATH
export DYLD_LIBRARY_PATH=_BASEDIR_/lib:_BASEDIR_/lib/mysql:$DYLD_LIBRARY_PATH
SBDIR="_HOME_DIR_/_SANDBOXDIR_"
[ -n "$TEST_REPL_DELAY" -a -f $SBDIR/data/mysql-relay.index ] && sleep $TEST_REPL_DELAY
source $SBDIR/sb_include
BASEDIR=_BASEDIR_
[ -z "$MYSQL_EDITOR" ] && MYSQL_EDITOR="$BASEDIR/bin/mysql"
if [ ! -x $MYSQL_EDITOR ]
then
    if [ -x $SBDIR/$MYSQL_EDITOR ]
    then
        MYSQL_EDITOR=$SBDIR/$MYSQL_EDITOR
    else
        echo "MYSQL_EDITOR '$MYSQL_EDITOR' not found or not executable"
        exit 1
    fi
fi
HISTDIR=_HISTORY_DIR_
[ -z "$HISTDIR" ] && HISTDIR=$SBDIR
export MYSQL_HISTFILE="$HISTDIR/.mysql_history"
PIDFILE="$SBDIR/data/mysql_sandbox_SERVERPORT_.pid"
__SBINSTR_SH__
MY_CNF=$SBDIR/my.sandbox.cnf
MY_CNF_NO_PASSWORD=$SBDIR/my.sandbox_np.cnf
if [ -n "$NOPASSWORD" ]
then
    perl -ne 'print unless /^password/' < $MY_CNF > $MY_CNF_NO_PASSWORD
    MY_CNF=$MY_CNF_NO_PASSWORD
fi
if [ -f $PIDFILE ]
then
    $MYSQL_EDITOR --defaults-file=$MY_CNF $MYCLIENT_OPTIONS "$@"
#else
#    echo "PID file $PIDFILE not found "
fi
USE_SCRIPT

    'mycli.sh' => <<'MYCLI_SCRIPT',
#!_BINBASH_
__LICENSE__
export LD_LIBRARY_PATH=_BASEDIR_/lib:_BASEDIR_/lib/mysql:$LD_LIBRARY_PATH
export DYLD_LIBRARY_PATH=_BASEDIR_/lib:_BASEDIR_/lib/mysql:$DYLD_LIBRARY_PATH
SBDIR="_HOME_DIR_/_SANDBOXDIR_"
source $SBDIR/sb_include
BASEDIR=_BASEDIR_
mycli --user=_DBUSER_ \
    --pass=_DBPASSWORD_ \
    --port=_SERVERPORT_ \
    --socket=_GLOBALTMPDIR_/mysql_sandbox_SERVERPORT_.sock \
    --_MYSQL_PROMPT_ "$@"

MYCLI_SCRIPT


    'mysqlsh.sh' => <<'MYSQLSH_SCRIPT',
#!_BINBASH_
__LICENSE__
export LD_LIBRARY_PATH=_BASEDIR_/lib:_BASEDIR_/lib/mysql:$LD_LIBRARY_PATH
export DYLD_LIBRARY_PATH=_BASEDIR_/lib:_BASEDIR_/lib/mysql:$DYLD_LIBRARY_PATH
SBDIR="_HOME_DIR_/_SANDBOXDIR_"
source $SBDIR/sb_include
BASEDIR=_BASEDIR_
mode=$1
if [ -n "$mode" ]
then
    shift
else
    mode=--sql
fi
case $mode in
    --sql)
        mysqlsh \
            --sqlc \
            --user=_DBUSER_ \
            --password=_DBPASSWORD_ \
            --port=_SERVERPORT_  "$@"
            ;;
    --js)
        mysqlsh \
            --user=_DBUSER_ \
            --password=_DBPASSWORD_ \
            --port=_MYSQLXPORT_ "$@"
            ;;
   *)
       echo "Syntax: $0 [--js|--sql]"
       exit 1
esac

MYSQLSH_SCRIPT


    'clear.sh' => <<'CLEAR_SCRIPT', 
#!_BINBASH_
__LICENSE__
SBDIR="_HOME_DIR_/_SANDBOXDIR_"
#source $SBDIR/sb_include
cd $SBDIR
PIDFILE="$SBDIR/data/mysql_sandbox_SERVERPORT_.pid"
__SBINSTR_SH__
#
# attempt to drop databases gracefully
#

function is_running
{
    if [ -f $PIDFILE ]
    then
        MYPID=$(cat $PIDFILE)
        ps -p $MYPID | grep $MYPID
    fi
}

if [ -n "$(is_running)" ]
then
    for D in `echo "show databases " | ./use -B -N | grep -v "^mysql$" | grep -iv "^information_schema$" | grep -iv "^performance_schema" | grep -ivw "^sys"` 
    do
        echo "set sql_mode=ansi_quotes;drop database \"$D\"" | ./use 
    done
    VERSION=`./use -N -B  -e 'select left(version(),3)'`
    #if [ `perl -le 'print $ARGV[0] ge "5.0" ? "1" : "0" ' "$VERSION"` = "1" ]
    #then
    #    ./use -e "truncate mysql.proc"
    #    ./use -e "truncate mysql.func"
    #fi
    is_slave=$(ls data | grep relay)
    if [ -n "$is_slave" ]
    then
        ./use -e "stop slave; reset slave;"
    fi
    if [ `perl -le 'print $ARGV[0] ge "5.1" ? "1" : "0" ' "$VERSION"` = "1" ]
    then
        for T in general_log slow_log plugin
        do
            exists_table=$(./use -e "show tables from mysql like '$T'")
            if [ -n "$exists_table" ]
            then
                ./use -e "truncate mysql.$T"
            fi
        done
    fi
fi

is_master=$(ls data | grep 'mysql-bin')
if [ -n "$is_master" ]
then
    ./use -e 'reset master'
fi

./stop
#./send_kill
rm -f data/`hostname`*
rm -f data/log.0*
rm -f data/*.log
rm -f data/falcon*
rm -f data/mysql-bin*
rm -f data/*relay-bin*
rm -f data/ib_*
rm -f data/*.info
rm -f data/*.err
rm -f data/*.err-old
#if [ `perl -le 'print $ARGV[0] ge "5.6" ? "1" : "0" ' "$VERSION"` = "1" ]
#then
#    rm -f data/mysql/slave_*
#    rm -f data/mysql/innodb_*
#    touch needs_reload
#fi
# rm -rf data/test/*

#
# remove all databases if any (up to 8.0)
#
if [ `perl -le 'print $ARGV[0] lt "8.0" ? "1" : "0" ' "$VERSION"` = "1" ]
then
    for D in `ls -d data/*/ | grep -w -v mysql | grep -iv performance_schema | grep -ivw sys` 
    do
        rm -rf $D
    done
    mkdir data/test
fi

CLEAR_SCRIPT
    'my.sandbox.cnf'  => <<'MY_SANDBOX_SCRIPT',
__LICENSE__
[mysql]
_MYSQL_PROMPT_
#

[client]
user               = _DBUSER_
password           = _DBPASSWORD_
port               = _SERVERPORT_
socket             = _GLOBALTMPDIR_/mysql_sandbox_SERVERPORT_.sock

[mysqld]
user               = _OSUSER_
port               = _SERVERPORT_
socket             = _GLOBALTMPDIR_/mysql_sandbox_SERVERPORT_.sock
basedir            = _BASEDIR_
datadir            = _HOME_DIR_/_SANDBOXDIR_/data
tmpdir             = _TMPDIR_
lower_case_table_names = _LOWER_CASE_TABLE_NAMES_
pid-file           = _HOME_DIR_/_SANDBOXDIR_/data/mysql_sandbox_SERVERPORT_.pid
bind-address       = _BIND_ADDRESS_
# _SLOW_QUERY_LOG_
# _GENERAL_LOG_
_MORE_OPTIONS_

MY_SANDBOX_SCRIPT

    'USING' => <<USING_SCRIPT,
Created with MySQL Sandbox _MSB_VERSION_
Currently using _INSTALL_VERSION_ with basedir _BASEDIR_

USING_SCRIPT

    'README' => 
        MySQL::Sandbox::credits() 
        . "\n" .  <<README_SCRIPT,
This is a sandbox for MySQL _INSTALL_VERSION_ (from _BASEDIR_)
Created using MySQL Sandbox _MSB_VERSION_

Default user: "_DBUSER_" (password: "_DBPASSWORD_")
For more connection options, see connection.json
    and default_connection.json.

You can connect to the database with ./use

Simple administrative tasks can be performed using:
./start   [options] : starts the server
./restart [options] : restarts the server
./stop              : stops the server
./status            : tells if the server is running
./clear             : stops the server and removes all contents (WARNING!: dangerous)
./send_kill         : stops an unresponsive server
./my sqldump        : calls mysqldump (notice the space after './my')
./my sqladmin       : calls mysqladmin (notice the space after './my')
./my sqlbinlog      : calls mysqlbinlog (notice the space after './my')
./msb {start restart stop status} : all-purpose start/stop/status/restart command

The full manual is available using:
perldoc MySQL::Sandbox

A task-oriented user manual is also available:
perldoc MySQL::Sandbox::Recipes

README_SCRIPT


    'grants.mysql'  => <<'GRANTS_MYSQL',

use mysql;
set password=password('_DBPASSWORD_');
grant all on *.* to _DBUSER_@'_REMOTE_ACCESS_' identified by '_DBPASSWORD_';
grant all on *.* to _DBUSER_@'localhost' identified by '_DBPASSWORD_';
grant SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,INDEX,ALTER,
    SHOW DATABASES,CREATE TEMPORARY TABLES,LOCK TABLES, EXECUTE 
    on *.* to _DBUSERRW_@'localhost' identified by '_DBPASSWORD_';
grant SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,INDEX,ALTER,
    SHOW DATABASES,CREATE TEMPORARY TABLES,LOCK TABLES, EXECUTE 
    on *.* to _DBUSERRW_@'_REMOTE_ACCESS_' identified by '_DBPASSWORD_';
grant SELECT,EXECUTE on *.* to _DBUSERRO_@'_REMOTE_ACCESS_' identified by '_DBPASSWORD_';
grant SELECT,EXECUTE on *.* to _DBUSERRO_@'localhost' identified by '_DBPASSWORD_';
grant REPLICATION SLAVE on *.* to _DBUSERREPL_@'_REMOTE_ACCESS_' identified by '_DB_REPL_PASSWORD_';
delete from user where password='';
delete from db where user='';
flush privileges;
create database if not exists test;

GRANTS_MYSQL


    'grants_5_7_6.mysql'  => <<'GRANTS_MYSQL_5_7_6',

use mysql;
set password='_DBPASSWORD_';
-- delete from tables_priv;
-- delete from columns_priv;
-- delete from db;
delete from user where user not in ('root', 'mysql.sys', 'mysqlxsys');

flush privileges;

create user _DBUSER_@'_REMOTE_ACCESS_' identified by '_DBPASSWORD_';
grant all on *.* to _DBUSER_@'_REMOTE_ACCESS_' ;

create user _DBUSER_@'localhost' identified by '_DBPASSWORD_';
grant all on *.* to _DBUSER_@'localhost';

create user _DBUSERRW_@'localhost' identified by '_DBPASSWORD_';
grant SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,INDEX,ALTER,
    SHOW DATABASES,CREATE TEMPORARY TABLES,LOCK TABLES, EXECUTE 
    on *.* to _DBUSERRW_@'localhost';

create user _DBUSERRW_@'_REMOTE_ACCESS_' identified by '_DBPASSWORD_';
grant SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,INDEX,ALTER,
    SHOW DATABASES,CREATE TEMPORARY TABLES,LOCK TABLES, EXECUTE 
    on *.* to _DBUSERRW_@'_REMOTE_ACCESS_';

create user _DBUSERRO_@'_REMOTE_ACCESS_' identified by '_DBPASSWORD_';
create user _DBUSERRO_@'localhost' identified by '_DBPASSWORD_';
create user _DBUSERREPL_@'_REMOTE_ACCESS_' identified by '_DB_REPL_PASSWORD_';
grant SELECT,EXECUTE on *.* to _DBUSERRO_@'_REMOTE_ACCESS_';
grant SELECT,EXECUTE on *.* to _DBUSERRO_@'localhost';
grant REPLICATION SLAVE on *.* to _DBUSERREPL_@'_REMOTE_ACCESS_';
create schema if not exists test;

GRANTS_MYSQL_5_7_6

    'load_grants.sh' => << 'LOAD_GRANTS_SCRIPT',
#!_BINBASH_
__LICENSE__
SBDIR=_HOME_DIR_/_SANDBOXDIR_
source $SBDIR/sb_include
BASEDIR='_BASEDIR_'
export LD_LIBRARY_PATH=$BASEDIR/lib:$BASEDIR/lib/mysql:$LD_LIBRARY_PATH
export DYLD_LIBRARY_PATH=$BASEDIR_/lib:$BASEDIR/lib/mysql:$DYLD_LIBRARY_PATH
CLI_VERSION=`$BASEDIR/bin/mysql --no-defaults --version | sed 's/^.*mysql[ ]*Ver.*\([0-9]\{1\}\.[0-9]\{1,2\}\.[0-9]\{1,2\}\).*$/\1/'`
CLI_MAJOR=$(echo $CLI_VERSION | tr '.' ' ' | awk '{print $1}')
CLI_MINOR=$(echo $CLI_VERSION | tr '.' ' ' | awk '{print $2}')
if [ $CLI_MAJOR -eq 5 -a $CLI_MINOR -lt 6 ] || [ $CLI_MAJOR -lt 5 ]
then
    MYSQL="$BASEDIR/bin/mysql --no-defaults --socket=_GLOBALTMPDIR_/mysql_sandbox_SERVERPORT_.sock --port=_SERVERPORT_"
else
    MYSQL="$BASEDIR/bin/mysql --no-defaults --login-path=# --socket=_GLOBALTMPDIR_/mysql_sandbox_SERVERPORT_.sock --port=_SERVERPORT_"
fi
# START UGLY WORKAROUND for grants syntax changes in 5.7.6
VERSION=`$MYSQL -u root --skip-password -BN -e 'select version()' | perl -ne 'print $1 if /(\d+\.\d+\.\d+)/'`
MAJOR=$(echo $VERSION | tr '.' ' ' | awk '{print $1}')
MINOR=$(echo $VERSION | tr '.' ' ' | awk '{print $2}')
REV=$(echo $VERSION | tr '.' ' ' | awk '{print $3}')
if [ "$MAJOR" == "5" -a "$MINOR" == "7" -a "$REV" == "8" ]
then
    # workaround for Bug#77732.
    echo "grant SELECT on performance_schema.global_variables to _DBUSERREPL_@'_REMOTE_ACCESS_';" >> $SBDIR/grants_5_7_6.mysql
    echo "grant SELECT on performance_schema.session_variables to _DBUSERREPL_@'_REMOTE_ACCESS_';" >> $SBDIR/grants_5_7_6.mysql
fi
if [ "$MAJOR" == "5" -a "$MINOR" == "7" -a $REV -gt 5 ]
then
    cp $SBDIR/grants_5_7_6.mysql $SBDIR/grants.mysql
fi
if [ "$MAJOR" == "8" ]
then
    cp $SBDIR/grants_5_7_6.mysql $SBDIR/grants.mysql
fi
# END UGLY WORKAROUND
VERBOSE_SQL=''
[ -n "$SBDEBUG" ] && VERBOSE_SQL=-v
$MYSQL -u root --skip-password $VERBOSE_SQL < $SBDIR/grants.mysql 2
# echo "source $SBDIR/grants.mysql" | $SBDIR/use -u root --password= 
# $SBDIR/my sqldump _EVENTS_OPTIONS_ mysql > $SBDIR/rescue_mysql_dump.sql
LOAD_GRANTS_SCRIPT

    'default_connection.json' => <<'END_DEFAULT_CONNECTION_JSON',
{
    "host":     "127.0.0.1",
    "port":     "_SERVERPORT_",
    "socket":   "_GLOBALTMPDIR_/mysql_sandbox_SERVERPORT_.sock",
    "username": "_DBUSER_@_REMOTE_ACCESS_",
    "password": "_DBPASSWORD_"
}

END_DEFAULT_CONNECTION_JSON

    'connection.json' => <<'END_CONNECTION_JSON',
{
    "origin": {
        "mysql_sandbox_version" : "_MSB_VERSION_",
        "mysql_version":    "_INSTALL_VERSION_",
        "binaries":         "_BASEDIR_"
    },
    "connection": {
        "host":             "127.0.0.1",
        "port":             "_SERVERPORT_",
        "socket":           "_GLOBALTMPDIR_/mysql_sandbox_SERVERPORT_.sock",
        "bind_address":     "_BIND_ADDRESS_"
    },
    "users": {
       "admin": {
            "username":     "root@localhost",
            "password":     "_DBPASSWORD_",
            "privileges":   "all, with grant option"
        },
       "all_privileges": {
            "username":     "_DBUSER_@_REMOTE_ACCESS_",
            "password":     "_DBPASSWORD_",
            "privileges":   "all, no grant option"
        },
        "read_write": {
            "username":     "_DBUSERRW_@_REMOTE_ACCESS_",
            "password":     "_DBPASSWORD_",
            "privileges":   "SELECT,INSERT,UPDATE,DELETE,CREATE,DROP,INDEX,ALTER,SHOW DATABASES,CREATE TEMPORARY TABLES,LOCK TABLES, EXECUTE"
        },
        "read_only": {
            "username":     "_DBUSERRO_@_REMOTE_ACCESS_",
            "password":     "_DBPASSWORD_",
            "privileges":   "SELECT,EXECUTE"
        },
        "replication": {
            "username":     "_DBUSERREPL_@_REMOTE_ACCESS_",
            "password":     "_DB_REPL_PASSWORD_",
            "privileges":   "REPLICATION SLAVE"
        }
    },
    "samples": {
        "php": {
            "mysqli" : "$mysqli = new mysqli('127.0.0.1', '_DBUSER_', '_DBPASSWORD_', 'test', '_SERVERPORT_');",
            "pdo"    : "$dbh = new PDO('mysql:host=127.0.0.1;port=5531', '_DBUSER_', '_DBPASSWORD_');"
        },
        "perl" : {
            "dbi" : "$dbh=DBI->connect( 'DBI:mysql:host=127.0.0.1;port=_SERVERPORT_', '_DBUSER_', '_DBPASSWORD_')"
        },
        "python" : {
            "mysql.connector" : "cnx = mysql.connector.connect(user='_DBUSER_', password='_DBPASSWORD_', host='127.0.0.1', port=_SERVERPORT_, database='test')"
        },
        "java" : {
            "DriverManager" : "con=DriverManager.getConnection(\\\"jdbc:mysql://127.0.0.1:_SERVERPORT_/test\\\", \\\"_DBUSER_\\\", \\\"_DBPASSWORD_\\\")"            
        },
        "ruby" : {
            "mysql" : "connection = Mysql.new '127.0.0.1', '_DBUSER_', '_DBPASSWORD_', 'test', _SERVERPORT_"
        },
        "shell" : {
            "generic": "_BASEDIR_/bin/mysql -h 127.0.0.1 -P _SERVERPORT_ -u _DBUSER_ -p_DBPASSWORD_"
        }
    }
}
END_CONNECTION_JSON

    'my.sh'    => <<'MY_SCRIPT',
#!_BINBASH_
__LICENSE__

if [ "$1" = "" ]
then
    echo "syntax my sql{dump|binlog|admin} arguments"
    exit
fi
__SBINSTR_SH__

SBDIR=_HOME_DIR_/_SANDBOXDIR_
source $SBDIR/sb_include
BASEDIR=_BASEDIR_
export LD_LIBRARY_PATH=$BASEDIR/lib:$BASEDIR/lib/mysql:$LD_LIBRARY_PATH
export DYLD_LIBRARY_PATH=$BASEDIR/lib:$BASEDIR/lib/mysql:$DYLD_LIBRARY_PATH
MYSQL=$BASEDIR/bin/mysql

SUFFIX=$1
shift

MYSQLCMD="$BASEDIR/bin/my$SUFFIX"

NODEFAULT=(myisam_ftdump
myisamlog
mysql_config
mysql_convert_table_format
mysql_find_rows
mysql_fix_extensions
mysql_fix_privilege_tables
mysql_secure_installation
mysql_setpermission
mysql_tzinfo_to_sql
mysql_config_editor
mysql_waitpid
mysql_zap
mysqlaccess
mysqlbinlog
mysqlbug
mysqldumpslow
mysqlhotcopy
mysqltest
mysqltest_embedded)

DEFAULTSFILE="--defaults-file=$SBDIR/my.sandbox.cnf"

for NAME in ${NODEFAULT[@]}
do
    if [ "my$SUFFIX" = "$NAME" ]
    then
        DEFAULTSFILE=""
        break
    fi
done

if [ -f $MYSQLCMD ]
then
    $MYSQLCMD $DEFAULTSFILE "$@"
else
    echo "$MYSQLCMD not found "
fi

MY_SCRIPT
    'proxy_start.sh'    => <<'PROXY_START_SCRIPT',
#!_BINBASH_
__LICENSE__

PROXY_BIN=/usr/local/sbin/mysql-proxy
HOST='127.0.0.1'

$PROXY_BIN --proxy-backend-addresses=$HOST:_SERVERPORT_ "$@"

PROXY_START_SCRIPT

'change_ports.sh' => <<'CHANGE_PORTS_SCRIPT',
#!_BINBASH_
__LICENSE__

cd $(dirname $0)
__SBINSTR_SH__
OLD_PORT=_SERVERPORT_

if [ "$1" = "" ]
then
    echo "New port required as argument."
    exit
else
    ONLY_DIGITS_REGEX="^[[:digit:]]+$"
    if [[ $1 =~ ${ONLY_DIGITS_REGEX} ]]
    then
        if [[ $1 -ge 1 ]] && [[ $1 -le 65535 ]]
        then
            NEW_PORT=$1
        else
            echo "New port must be a valid port number in the 1-65535 range."
            exit
        fi
    else
        echo "New port must contain only digits (unsigned integer)."
        exit
    fi
fi

if [ $OLD_PORT = $NEW_PORT ]
then
    echo Old port and new port must be different.
    exit
fi

PERL_SCRIPT1='BEGIN{$old=shift;$new=shift};'
PERL_SCRIPT2='s/sandbox$old/sandbox$new/g;'
PERL_SCRIPT3='s/\b$old\b/$new/' 
PERL_SCRIPT="$PERL_SCRIPT1 $PERL_SCRIPT2 $PERL_SCRIPT3"

SCRIPTS1="start stop send_kill clear status restart my.sandbox.cnf "
SCRIPTS2="load_grants my use $0"
SCRIPTS="$SCRIPTS1 $SCRIPTS2"
for SCRIPT in $SCRIPTS
do
    perl -i.port.bak -pe "$PERL_SCRIPT" $OLD_PORT $NEW_PORT $SCRIPT
done
echo "($PWD) The old scripts have been saved as filename.port.bak"

CHANGE_PORTS_SCRIPT

    'change_paths.sh' => <<'CHANGE_PATHS_SCRIPT',
#!_BINBASH_
__LICENSE__
if [ "$1" = "" ]
then
    OLD_SB_LOCATION=_HOME_DIR_/_SANDBOXDIR_
else
    OLD_SB_LOCATION=$1
fi

__SBINSTR_SH__
if [ "$2" = "" ]
then
    NEW_SB_LOCATION=$PWD
else
    NEW_SB_LOCATION=$2
fi

if [ $OLD_SB_LOCATION = $NEW_SB_LOCATION ]
then
    echo Old location and new location must be different.
    echo Move the sandbox to the new location and then run this script.
    exit
fi

if [ ! -d "$NEW_SB_LOCATION" ]
then
    echo "new location must be a directory"
    exit
fi

PERL_SCRIPT1='BEGIN{$old=shift;$new=shift};'
PERL_SCRIPT2='s/$old/$new/g' 
PERL_SCRIPT="$PERL_SCRIPT1 $PERL_SCRIPT2"

SCRIPTS1="start stop send_kill clear status restart my.sandbox.cnf "
SCRIPTS2="load_grants my use $0"
SCRIPTS="$SCRIPTS1 $SCRIPTS2"

for SCRIPT in $SCRIPTS
do
    perl -i.bak -pe "$PERL_SCRIPT" $OLD_SB_LOCATION $NEW_SB_LOCATION $SCRIPT
done
echo "($PWD) The old scripts have been saved as filename.path.bak"
CHANGE_PATHS_SCRIPT
    'sandbox_action.pl' => <<'SANDBOX_ACTION_SCRIPT',
#!_BINPERL_
__LICENSE__
use strict;
use warnings;
use MySQL::Sandbox qw(sbinstr);

my $DEBUG = $MySQL::Sandbox::DEBUG;

my $action_list = 'use|start|stop|status|clear|restart|send_kill';
my $action = shift
    or die "action required {$action_list}\n";
$action =~/^($action_list)$/ 
    or die "action must be one of {$action_list}\n";
my $sandboxdir = $0;
sbinstr($action);
$sandboxdir =~ s{[^/]+$}{};
$sandboxdir =~ s{/$}{};
my $command = $ARGV[0];
if ($action eq 'use' and !$command) {
    die "action 'use' requires a command\n";
}

my @dirs = glob("$sandboxdir/*");

for my $dir (@dirs) {
    if (-d $dir) {
        if ($action eq "use") {
            if ( -x "$dir/use_all" ) {
                print "executing -- $dir/use_all $command\n" if $DEBUG;
                system(qq($dir/use_all "$command"));
            }           
            elsif ( -x "$dir/use" ) {
                print "executing -- $dir/use $command\n" if $DEBUG;
                system(qq(echo "$command" | $dir/use));
            }           
        } 
        elsif ( -x "$dir/${action}_all") {
            print "-- executing  $dir/${action}_all\n" if $DEBUG;
            system("$dir/${action}_all", @ARGV)
        }
        elsif ( -x "$dir/$action") {
            print "-- executing  $dir/$action\n" if $DEBUG;
            system("$dir/$action", @ARGV)
        }
    }
}

SANDBOX_ACTION_SCRIPT
    'plugin.conf' => <<'PLUGIN_CONF',
#
# Plugin configuration file
# To use this template, see 
# sbtool -o plugin 
#
$plugin_definition = 
{
innodb =>    {
    minimum_version => '5.1.45',
    all_servers => 
        {
        operation_sequence => [qw(stop options_file start sql_commands )],
        options_file => 
            [
            'ignore_builtin_innodb',
            'plugin-load='
             .'innodb=ha_innodb_plugin.so;'
             .'innodb_trx=ha_innodb_plugin.so;'
             .'innodb_locks=ha_innodb_plugin.so;'
             .'innodb_lock_waits=ha_innodb_plugin.so;'
             .'innodb_cmp=ha_innodb_plugin.so;'
             .'innodb_cmp_reset=ha_innodb_plugin.so;'
             .'innodb_cmpmem=ha_innodb_plugin.so;'
             .'innodb_cmpmem_reset=ha_innodb_plugin.so',
            'default-storage-engine=InnoDB',
            'innodb_file_per_table=1',
            'innodb_file_format=barracuda',
            'innodb_strict_mode=1',
            ],
        sql_commands => 
            [
                'select @@innodb_version;',
            ],
        startup_file => [ ],
        },
    },
semisynch => {
    minimum_version => '5.5.2',

    master => 
        {
            operation_sequence => [qw(stop options_file start sql_commands )],
            options_file => 
                [
                'plugin-load=rpl_semi_sync_master=semisync_master.so',
                'rpl_semi_sync_master_enabled=1'
                ],
            sql_commands => 
                [
                    'select @@rpl_semi_sync_master_enabled;'
                ],
            startup_file => []
        },
    slave => 
        {
            operation_sequence => [qw(stop options_file start sql_commands )],
            options_file => 
                [
                'plugin-load=rpl_semi_sync_slave=semisync_slave.so',
                'rpl_semi_sync_slave_enabled=1'
                ],
            sql_commands => 
                [
                    'select @@rpl_semi_sync_slave_enabled;'
                ],
            startup_file => []
        },
    },
gearman =>    {
    minimum_version => '5.0',
    all_servers => 
        {
        operation_sequence => [qw(start sql_commands options_file 
                                startup_file restart )],
        options_file => 
            [
            'init-file=startup.sql'
            ],
        sql_commands => 
            [
            'CREATE FUNCTION gman_do RETURNS STRING
                SONAME "libgearman_mysql_udf.so";',
            'CREATE FUNCTION gman_do_high RETURNS STRING
                SONAME "libgearman_mysql_udf.so";',
            'CREATE FUNCTION gman_do_low RETURNS STRING
                SONAME "libgearman_mysql_udf.so";',
            'CREATE FUNCTION gman_do_background RETURNS STRING
                SONAME "libgearman_mysql_udf.so";',
            'CREATE FUNCTION gman_do_high_background RETURNS STRING
                SONAME "libgearman_mysql_udf.so";',
            'CREATE FUNCTION gman_do_low_background RETURNS STRING
                SONAME "libgearman_mysql_udf.so";',
            'CREATE AGGREGATE FUNCTION gman_sum RETURNS INTEGER
                SONAME "libgearman_mysql_udf.so";',
            'CREATE FUNCTION gman_servers_set RETURNS STRING
                SONAME "libgearman_mysql_udf.so";',                
            ],
        startup_file => 
            [ 
            'set @a := (select gman_servers_set("127.0.0.1"));',
            'use test ;',
            'create table if not exists startup (msg text, ts timestamp);',
            'insert into startup (msg) values (@a);',
            ]
        },
    },
};

PLUGIN_CONF

    'test_replication.sh' => <<'TEST_REPLICATION',
#!_BINBASH_
__LICENSE__
if [ -x ./m ]
then
    MASTER=./m
elif [ -x ./n1 ]
then
    MASTER=./n1
else
    echo "# No master found"
    exit 1
fi
$MASTER -e 'create schema if not exists test'
$MASTER test -e 'drop table if exists t1'
$MASTER test -e 'create table t1 (i int not null primary key, msg varchar(50), d date, t time, dt datetime, ts timestamp)'
#$MASTER test -e "insert into t1 values (1, 'test sandbox 1', '2015-07-16', '11:23:40','2015-07-17 12:34:50', null)"
#$MASTER test -e "insert into t1 values (2, 'test sandbox 2', '2015-07-17', '11:23:41','2015-07-17 12:34:51', null)"
for N in $(seq -f '%02.0f' 1 20)
do
    #echo "$MASTER test -e \"insert into t1 values ($N, 'test sandbox $N', '2015-07-$N', '11:23:$N','2015-07-17 12:34:$N', null)\""
    $MASTER test -e "insert into t1 values ($N, 'test sandbox $N', '2015-07-$N', '11:23:$N','2015-07-17 12:34:$N', null)"
done
sleep 0.5
MASTER_RECS=$($MASTER -BN -e 'select count(*) from test.t1')

master_status=master_status$$
slave_status=slave_status$$
$MASTER -e 'show master status\G' > $master_status
master_binlog=$(grep 'File:' $master_status | awk '{print $2}' )
master_pos=$(grep 'Position:' $master_status | awk '{print $2}' )
echo "# Master log: $master_binlog - Position: $master_pos - Rows: $MASTER_RECS"
rm -f $master_status

FAILED=0
PASSED=0

function ok_equal
{
    fact="$1"
    expected="$2"
    msg="$3"
    if [ "$fact" == "$expected" ]
    then
        echo -n "ok"
        PASSED=$(($PASSED+1))
    else
        echo -n "not ok - (expected: <$expected> found: <$fact>) "
        FAILED=$(($FAILED+1))
    fi
    echo " - $msg"
}

function test_summary
{
    TESTS=$(($PASSED+$FAILED))
    if [ -n "$TAP_TEST" ]
    then
        echo "1..$TESTS"
    else
        PERCENT_PASSED=$(($PASSED/$TESTS*100))
        PERCENT_FAILED=$(($FAILED/$TESTS*100))
        printf "# TESTS : %5d\n" $TESTS
        printf "# FAILED: %5d (%5.1f%%)\n" $FAILED $PERCENT_FAILED
        printf "# PASSED: %5d (%5.1f%%)\n" $PASSED $PERCENT_PASSED
    fi
    exit_code=0
    if [ "$FAILED" != "0" ]
    then
        exit_code=1
    fi
    echo "# exit code: $exit_code"
    exit $exit_code
}

for SLAVE_N in 1 2 3 4 5 6 7 8 9
do
    N=$(($SLAVE_N+1)) 
    unset SLAVE
    if [ -x ./s$SLAVE_N ]
    then
        SLAVE=./s$SLAVE_N
    elif [ -x ./n$N ]
    then
        SLAVE=./n$N
    fi
    if [ -n "$SLAVE" ]
    then
        echo "# Testing slave #$SLAVE_N"
        if [ -f set_circular_replication.sh ]
        then
            sleep 3
        else
            S_READY=$($SLAVE -BN -e "select master_pos_wait('$master_binlog', $master_pos,60)")
            # master_pos_wait can return 0 or a positive number for successful replication
            # Any result that is not NULL or -1 is acceptable
            if [ "$S_READY" != "-1" -a "$S_READY" != "NULL" ]
            then
                S_READY=0
            fi
            ok_equal $S_READY 0 "Slave #$SLAVE_N acknowledged reception of transactions from master" 
        fi
        $SLAVE -e 'show slave status\G' > $slave_status
        IO_RUNNING=$(grep -w Slave_IO_Running $slave_status | awk '{print $2}')
        ok_equal $IO_RUNNING Yes "Slave #$SLAVE_N IO thread is running"
        SQL_RUNNING=$(grep -w Slave_IO_Running $slave_status | awk '{print $2}')
        ok_equal $SQL_RUNNING Yes "Slave #$SLAVE_N SQL thread is running"
        rm -f $slave_status 

        [ $FAILED == 0 ] || exit 1

        T1_EXISTS=$($SLAVE -BN -e 'show tables from test like "t1"')
        ok_equal $T1_EXISTS t1 "Table t1 found on slave #$SLAVE_N"
        T1_RECS=$($SLAVE -BN -e 'select count(*) from test.t1')
        ok_equal $T1_RECS $MASTER_RECS "Table t1 has $MASTER_RECS rows on #$SLAVE_N"
    fi
done
test_summary

TEST_REPLICATION

    'show_binlog.sh' => <<'SHOW_BINLOG',
#!_BINBASH_
__LICENSE__

curdir="_HOME_DIR_/_SANDBOXDIR_"
cd $curdir

if [ ! -d ./data ]
then
    echo "$curdir/data not found"
    exit 1
fi

# Checks if the output is a terminal or a pipe
if [  -t 1 ]
then
    echo "###################### WARNING ####################################"
    echo "# You are not using a pager."
    echo "# The output of this script can be quite large."
    echo "# Please pipe this script with a pager, such as 'less' or 'vim -'"
    echo "# ENTER 'q' to exit or simply RETURN to continue without a pager"
    read answer
    if [ "$answer" == "q" ]
    then
        exit
    fi
fi

pattern=$1
[ -z "$pattern" ] && pattern='[0-9]*'
if [ "$pattern" == "-h" -o "$pattern" == "--help" -o "$pattern" == "-help" -o "$pattern" == "help" ]
then
    echo "# Usage: $0 [BINLOG_PATTERN] "
    echo "# Where BINLOG_PATTERN is a number, or part of a number used after 'mysql-bin'"
    echo "# (The default is '[0-9]*]')"
    echo "# examples:" 
    echo "#          ./show_binlog 000001 | less "
    echo "#          ./show_binlog 000012 | vim - "
    echo "#          ./show_binlog  | grep -i 'CREATE TABLE'"
    exit 0
fi
# set -x
last_binlog=$(ls -lotr data/mysql-bin.$pattern | tail -n 1 | awk '{print $NF}')

if [ -z "$last_binlog" ]
then
    echo "No binlog found in $curdir/data"
    exit 1
fi

(printf "#\n# Showing $last_binlog\n#\n" ; ./my sqlbinlog --verbose $last_binlog ) 

SHOW_BINLOG

    'show_relaylog.sh' => <<'SHOW_RELAYLOG',
#!_BINBASH_
__LICENSE__

curdir="_HOME_DIR_/_SANDBOXDIR_"
cd $curdir

if [ ! -d ./data ]
then
    echo "$curdir/data not found"
    exit 1
fi

# Checks if the output is a terminal or a pipe
if [  -t 1 ]
then
    echo "###################### WARNING ####################################"
    echo "# You are not using a pager."
    echo "# The output of this script can be quite large."
    echo "# Please pipe this script with a pager, such as 'less' or 'vim -'"
    echo "# ENTER 'q' to exit or simply RETURN to continue without a pager"
    read answer
    if [ "$answer" == "q" ]
    then
        exit
    fi
fi

relay_basename=$1
[ -z "$relay_basename" ] && relay_basename='mysql-relay'
pattern=$2
[ -z "$pattern" ] && pattern='[0-9]*'
if [ "$pattern" == "-h" -o "$pattern" == "--help" -o "$pattern" == "-help" -o "$pattern" == "help" ]
then
    echo "# Usage: $0 [ relay-base-name [BINLOG_PATTERN]] "
    echo "# Where relay-basename is the initial part of the relay ('$relay_basename')"
    echo "# and BINLOG_PATTERN is a number, or part of a number used after '$relay_basename'"
    echo "# (The default is '[0-9]*]')"
    echo "# examples:" 
    echo "#          ./show_relaylog relay-log-alpha 000001 | less "
    echo "#          ./show_relaylog relay-log 000012 | vim - "
    echo "#          ./show_relaylog  | grep -i 'CREATE TABLE'"
    exit 0
fi
# set -x
last_relaylog=$(ls -lotr data/$relay_basename.$pattern | tail -n 1 | awk '{print $NF}')

if [ -z "$last_relaylog" ]
then
    echo "No relay log found in $curdir/data"
    exit 1
fi

(printf "#\n# Showing $last_relaylog\n#\n" ; ./my sqlbinlog --verbose $last_relaylog ) 

SHOW_RELAYLOG

    'add_option.sh' => <<'ADD_OPTION',
#!_BINBASH_
__LICENSE__

curdir="_HOME_DIR_/_SANDBOXDIR_"
cd $curdir

if [ -z "$*" ]
then
    echo "# Syntax $0 options-for-my.cnf [more options] "
    exit
fi

CHANGED=''
for OPTION in $@
do
    option_exists=$(grep $OPTION ./my.sandbox.cnf)
    if [ -z "$option_exists" ]
    then
        echo "$OPTION" >> my.sandbox.cnf
        echo "# option '$OPTION' added to configuration file"
        CHANGED=1
    else
        echo "# option '$OPTION' already exists configuration file"
    fi
done

if [ -n "$CHANGED" ]
then
    ./restart
fi

ADD_OPTION

);

# --- END SCRIPTS IN CODE ---

my $license_text = <<'LICENSE';
#    The MySQL Sandbox
#    Copyright (C) 2006-2017 Giuseppe Maxia
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#                                                                             
#        http://www.apache.org/licenses/LICENSE-2.0
#                                                                             
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

LICENSE

sub license_text {
    return $license_text;
}

sub parse_options_low_level_make_sandbox {
    return \%parse_options_low_level_make_sandbox;
}

sub parse_options_replication {
    return \%parse_options_replication;
}

sub parse_options_many {
    return \%parse_options_many;
}

sub parse_options_sbtool {
    return \%parse_options_sbtool;
}

sub parse_options_custom_many {
    return \%parse_options_custom_many;
}

sub scripts_in_code {
    return \%scripts_in_code;
}

my $readme_multiple = <<'END_README_MULTIPLE';
This is a composite sandbox. Each node is independent, without any replication relationship to the others

To operate each node, use
./n1 [options]   # (= ./node1/use [options])
./n2 [options]   # (= ./node2/use [options])
...
./nN [options]   # (= ./nodeN/use [options])

END_README_MULTIPLE

my $readme_circular = <<'END_README_CIRCULAR';
This is a composite sandbox, where each node is both a master and a slave (in circular replication)

To operate each node, use
./n1 [options]   # (= ./node1/use [options])
./n2 [options]   # (= ./node2/use [options])
...
./nN [options]   # (= ./nodeN/use [options])

END_README_CIRCULAR


my $readme_master_slave = <<'END_README_MASTER_SLAVE';
This is a composite replication sandbox, having one master and many slaves.

To operate the master, use
./m [options]    # (= ./master/use)

To operate the slaves, use 
./s1 [options]   # (= ./node1/use [options])
./s2 [options]   # (= ./node2/use [options])
...
./sN [options]   # (= ./nodeN/use [options])

END_README_MASTER_SLAVE

my $readme_common_replication = <<'END_README_COMMON_REPLICATION';

./to check the status of all slaves, use:
./check_slaves

END_README_COMMON_REPLICATION

my $readme_common = <<'END_README_COMMON';
To run a SQL command in all servers, use:
./use_all {query}

To connect to this sandbox, use the information stored inside 
    'connection.json' or 'default_connection.json'.

Simple administrative tasks can be performed using:
./start_all  [options]  : starts all servers
./stop_all              : stops all servers
./status_all            : tells the status of all servers
./clear_all             : stops andremoves the contents from all servers (WARNING: dangerous)
./restart_all [options] : restarts all servers

More information is available inside the README file within each directory below.

The full manual is available using:
perldoc MySQL::Sandbox

A task-oriented user guide is also available:
perldoc MySQL::Sandbox::Recipes

END_README_COMMON

sub get_readme_common_replication {
    return $readme_common_replication;
}

sub get_readme_common {
    return $readme_common;
}

sub get_readme_multiple {
    return MySQL::Sandbox::credits() . "\n" . $readme_multiple;
}
sub get_readme_circular {
    return MySQL::Sandbox::credits() . "\n" . $readme_circular;
}

sub get_readme_master_slave {
    return MySQL::Sandbox::credits() . "\n" . $readme_master_slave;
}

1;
__END__
=head1 NAME

MySQL::Sandbox::Scripts - Script templates for MySQL Sandbox

=head1 PURPOSE

This package is a collection of data and scripts templates for MySQL::Sandbox.
It is not supposed to be used stand alone. It is an ancillary package.
For a reference manual, see L<MySQL::Sandbox>. For a cookbook, see L<MySQL::Sandbox::Recipes>.


=head1 COPYRIGHT

Version 3.1

Copyright (C) 2006-2017 Giuseppe Maxia

Home Page  https://github.com/datacharmer

=head1 LEGAL NOTICE

   Copyright 2006-2017 Giuseppe Maxia

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

