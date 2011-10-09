package MySQL::Sandbox::Scripts;
use strict;
use warnings;
use MySQL::Sandbox;

require Exporter;

our @ISA = qw/Exporter/;

our @EXPORT_OK = qw( scripts_in_code);
our @EXPORT = @EXPORT_OK;

our $VERSION="3.0.19";

our @MANIFEST = (
'clear.sh',
'my.sandbox.cnf',
'start.sh',
'status.sh',
'msb.sh',
'restart.sh',
'stop.sh',
'send_kill.sh',
'load_grants.sh',
'use.sh',
'proxy_start.sh',
'my.sh',
'change_paths.sh',
'change_ports.sh',
'USING',
'grants.mysql',
'# INSTALL FILES',
'sandbox_action.pl',
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
##
# DEPRECATED and removed 
# (April fool's edition)
#    query_analyzer         => {
#                                value => 0,
#                                parse=> 'query_analyzer',
#                                so  => 5,
#                                help => ['solves your tuning problems at once']
#    },
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
                                help  => [
                                            'Where to install the sandbox, under upper-directory'
                                         ] 
                             },
    sandbox_port          => {
                                value => 3310,               
                                parse => 'P|sandbox_port=i',           
                                so    =>  30,
                                help  => [
                                            'The port number to use for the sandbox server.', 
                                            '(Default: 3310)',
                                         ]
                            },
    check_port            => {
                                value => 0,               
                                parse => 'check_port',           
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
                                so    =>  60,
                                help  => [
                                            'Base directory for MySQL (default: /usr/local/mysql)'
                                         ]
                            },
   tmpdir                => {
                                value => undef, 
                                parse => 'tmpdir=s' ,               
                                so    =>  65,
                                help  => [
                                            'Temporary directory for MySQL (default: Sandbox_directory/tmp)'
                                         ]
                            },

    my_file               => {
                                value => q{},                 
                                parse => 'm|my_file=s',                
                                so    =>  70,
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
                                help  => [
                                            'user for global access to mysql (Default: '
                                            .  $MySQL::Sandbox::default_users{'db_user'} . ')'
                                         ]
                            },
     remote_access        => {
                                value => $MySQL::Sandbox::default_users{'remote_access'},
                                parse => 'remote_access=s'  ,              
                                so    => 101,
                                help  => [
                                            'network access for mysql users (Default: '
                                            .  $MySQL::Sandbox::default_users{'remote_access'} . ')'
                                         ]
                            },
    ro_user              => {
                                value => $MySQL::Sandbox::default_users{'ro_user'},
                                parse => 'ro_user=s'  ,              
                                so    => 102,
                                help  => [
                                            'user for read-only access to mysql (Default: ' 
                                            .  $MySQL::Sandbox::default_users{'ro_user'} . ')'
                                         ]
                            },

     rw_user              => {
                                value => $MySQL::Sandbox::default_users{'rw_user'},
                                parse => 'rw_user=s'  ,              
                                so    => 104,
                                help  => [
                                            'user for read-write access to mysql (Default: ' 
                                            .  $MySQL::Sandbox::default_users{'rw_user'} . ')'
                                         ]
                            },
      repl_user           => {
                                value => $MySQL::Sandbox::default_users{'repl_user'},
                                parse => 'repl_user=s'  ,              
                                so    => 106,
                                help  => [
                                            'user for replication access to mysql (Default: ' 
                                            .  $MySQL::Sandbox::default_users{'repl_user'} . ')'
                                         ]
                            },
     db_password           => {
                                value =>  $MySQL::Sandbox::default_users{'db_password'},      
                                parse => 'p|db_password=s'  ,              
                                so    => 110,
                                help  => [
                                            'password for global access to mysql (Default: '
                                            .  $MySQL::Sandbox::default_users{'db_password'} . ')'
                                         ]
                            },
      repl_password      => {
                                value =>  $MySQL::Sandbox::default_users{'repl_password'},      
                                parse => 'repl_password=s'  ,              
                                so    => 112,
                                help  => [
                                            'password for replication access to mysql (Default: '
                                            .  $MySQL::Sandbox::default_users{'repl_password'} . ')'
                                         ]
                            },
    my_clause             => {
                                value => '',      
                                parse => 'c|my_clause=s@', 
                                so    => 120,
                                help  => [
                                            'option to be inserted in a my.cnf file',
                                            'it may be used several times',
                                         ]
                            },
    prompt_prefix           => {
                                value => 'mysql',      
                                parse => 'prompt_prefix=s', 
                                so    => 130,
                                help  => [
                                            'prefix to use in CLI prompt (default: mysql)',
                                         ]
                            },

    prompt_body          => {
                                value => q/ [\h] {\u} (\d) > /,      
                                parse => 'prompt_body=s', 
                                so    => 135,
                                help  => [
                                            'options to use in CLI prompt (default:  [\h] {\u} (\d) > )',
                                         ]
                            },
    force                 => {
                                value => 0,                  
                                parse => 'force',                      
                                so    => 140,
                                help  => [
                                            'Use this option if you want to overwrite existing directories',
                                            'and files during the installation. (Default: disabled)', 
                                         ] 
                            },
    no_ver_after_name     => {
                                value => 0,                  
                                parse => 'no_ver_after_name',                  
                                so    => 150,
                                help  => [
                                            'Do not add version number after sandbox directory name (default: disabled)'
                                         ] 
                            },
    verbose               => {
                                value => 0,                  
                                parse => 'v|verbose',                  
                                so    => 160,
                                help  => [
                                            'Use this option to see installation progress (default: disabled)'
                                         ] 
                            },
   load_grants           => {
                                value => 0,                  
                                parse => 'load_grants',                  
                                so    => 170,
                                help  => [
                                            'Loads the predefined grants from a SQL file.',
                                            'Useful when installing from script.',
                                            '(default: disabled)'
                                         ] 
                            },
   no_load_grants         => {
                                value => 0,                  
                                parse => 'no_load_grants',                  
                                so    => 175,
                                help  => [
                                            'Does not loads the predefined grants from a SQL file.',
                                            '(default: disabled)'
                                         ] 
                            },

   no_run                 => {
                                value => 0,                  
                                parse => 'no_run',                  
                                so    => 176,
                                help  => [
                                            'Stops the server if started with "load_grants".',
                                            '(default: disabled)'
                                         ] 
                            },

    interactive           => {
                                value => 0,                  
                                parse => 't|interactive',                  
                                so    => 180,
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
                                so    => 180,
                                help  => [
                                            'suppress the confirmation request from user',
                                         ],
                            },
    no_show               => {
                                value => 0, 
                                parse => 'no_show',
                                so    => 190,
                                help  => [
                                            'does not show options or ask confirmation to the user',
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
                                so    => 55,
                                help  => [
                                            'Sets a replication topology.',
                                            'Available: {standard|circular} (default: standard)'
                                         ] 
                            },
    circular               => {
                                value => 0,
                                parse => 'circular=i',                  
                                so    => 56,
                                help  => [
                                            'Sets circular replication with N nodes.',
                                            '(default: 0)'
                                         ] 
                            },


    master_master        => {
                                value => 0,                  
                                parse => 'master_master',                  
                                so    => 57,
                                help  => [
                                            'set exactly two nodes in circular replication'
                                         ] 
                            },
 
    repl_user           => {
                                value => $MySQL::Sandbox::default_users{'repl_user'},
                                parse => 'repl_user=s',                  
                                so    => 60,
                                help  => [
                                            'user with replication slave privileges.',
                                            '(default: '. $MySQL::Sandbox::default_users{'repl_user'} . ')'
                                         ] 
                            },

    repl_password           => {
                                value => $MySQL::Sandbox::default_users{'repl_password'},
                                parse => 'repl_password=s',                  
                                so    => 60,
                                help  => [
                                            'password for user with replication slave privileges.',
                                            '(default: '. $MySQL::Sandbox::default_users{'repl_password'} . ')'
                                         ] 
                            },
     remote_access        => {
                                value => $MySQL::Sandbox::default_users{'remote_access'},
                                parse => 'remote_access=s'  ,              
                                so    => 61,
                                help  => [
                                            'network access for mysql users (Default: '
                                            .  $MySQL::Sandbox::default_users{'remote_access'} . ')'
                                         ]
                            },
 
    interactive           => {
                                value => 0,                  
                                parse => 'interactive',                  
                                so    => 65,
                                help  => [
                                            'Use this option to ask interactive user ',
                                            'confirmation for each node (default: disabled)'
                                         ] 
                            },
    verbose               => {
                                value => 0,                  
                                parse => 'v|verbose',                  
                                so    => 60,
                                help  => [
                                            'Use this option to see installation progress (default: disabled)'
                                         ] 
                            },
    help               => {
                                value => 0,                  
                                parse => 'help',                  
                                so    => 70,
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
                                so    => 65,
                                help  => [
                                            'set exactly two nodes in circular replication'
                                         ] 
                            },
 
    circular             => {
                                value => 0,                  
                                parse => 'circular',                  
                                so    => 60,
                                help  => [
                                            'set the nodes in circular replication'
                                         ] 
                            },

    repl_user           => {
                                value => $MySQL::Sandbox::default_users{'repl_user'},
                                parse => 'repl_user=s',                  
                                so    => 60,
                                help  => [
                                            'user with replication slave privileges.',
                                            '(default: '. $MySQL::Sandbox::default_users{'repl_user'} . ')'
                                         ] 
                            },

    repl_password           => {
                                value => $MySQL::Sandbox::default_users{'repl_password'},
                                parse => 'repl_password=s',                  
                                so    => 60,
                                help  => [
                                            'password for user with replication slave privileges.',
                                            '(default: '. $MySQL::Sandbox::default_users{'repl_password'} . ')'
                                         ] 
                            },
     remote_access        => {
                                value => $MySQL::Sandbox::default_users{'remote_access'},
                                parse => 'remote_access=s'  ,              
                                so    => 61,
                                help  => [
                                            'network access for mysql users (Default: '
                                            .  $MySQL::Sandbox::default_users{'remote_access'} . ')'
                                         ]
                            },
 
    interactive           => {
                                value => 0,                  
                                parse => 'interactive',                  
                                so    => 65,
                                help  => [
                                            'Use this option to ask interactive user ',
                                            'confirmation for each node (default: disabled)'
                                         ] 
                            },
    verbose               => {
                                value => 0,                  
                                parse => 'v|verbose',                  
                                so    => 70,
                                help  => [
                                            'Use this option to see installation progress (default: disabled)'
                                         ] 
                            },

    help               => {
                                value => 0,                  
                                parse => 'help',                  
                                so    => 80,
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

    interactive           => {
                                value => 0,                  
                                parse => 'interactive',                  
                                so    => 65,
                                help  => [
                                            'Use this option to ask interactive user ',
                                            'confirmation for each node (default: disabled)'
                                         ] 
                            },
    verbose               => {
                                value => 0,                  
                                parse => 'v|verbose',                  
                                so    => 60,
                                help  => [
                                            'Use this option to see installation progress (default: disabled)'
                                         ] 
                            },
    help               => {
                                value => 0,                  
                                parse => 'help',                  
                                so    => 70,
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
MYSQLD_SAFE="$BASEDIR/bin/_MYSQLDSAFE_"
SBDIR="_HOME_DIR_/_SANDBOXDIR_"
PIDFILE="$SBDIR/data/mysql_sandbox_SERVERPORT_.pid"
__SBINSTR_SH__
if [ ! -f $MYSQLD_SAFE ]
then
    echo "mysqld_safe not found in $BASEDIR/bin/"
    exit 1
fi
MYSQLD_SAFE_OK=`sh -n $MYSQLD_SAFE 2>&1`
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
TIMEOUT=60
if [ -f $PIDFILE ]
then
    echo "sandbox server already started (found pid file $PIDFILE)"
else
    CURDIR=`pwd`
    cd $BASEDIR
    if [ "$SBDEBUG" = "" ]
    then
        $MYSQLD_SAFE --defaults-file=$SBDIR/my.sandbox.cnf $@ > /dev/null 2>&1 &
    else
        $MYSQLD_SAFE --defaults-file=$SBDIR/my.sandbox.cnf $@ > "$SBDIR/start.log" 2>&1 &
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
else
    echo " sandbox server not started yet"
    exit 1
fi

START_SCRIPT

    'status.sh' => <<'STATUS_SCRIPT',
#!_BINBASH_
__LICENSE__
SBDIR="_HOME_DIR_/_SANDBOXDIR_"
PIDFILE="$SBDIR/data/mysql_sandbox_SERVERPORT_.pid"
__SBINSTR_SH__

if [ -f $PIDFILE ]
then
    echo "_SANDBOXDIR_ on"
    exit 0
else
    echo "_SANDBOXDIR_ off"
    exit 1
fi

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
BASEDIR=_BASEDIR_
export LD_LIBRARY_PATH=$BASEDIR/lib:$BASEDIR/lib/mysql:$LD_LIBRARY_PATH
export DYLD_LIBRARY_PATH=$BASEDIR/lib:$BASEDIR/lib/mysql:$DYLD_LIBRARY_PATH
MYSQL_ADMIN="$BASEDIR/bin/mysqladmin"
PIDFILE="$SBDIR/data/mysql_sandbox_SERVERPORT_.pid"
__SBINSTR_SH__

if [ -f $PIDFILE ]
then
    if [ -f $SBDIR/data/master.info ]
    then
        echo "stop slave" | $SBDIR/use -u root
    fi
    # echo "$MYSQL_ADMIN --defaults-file=$SBDIR/my.sandbox.cnf $MYCLIENT_OPTIONS shutdown"
    $MYSQL_ADMIN --defaults-file=$SBDIR/my.sandbox.cnf $MYCLIENT_OPTIONS shutdown
    sleep 1
fi
if [ -f $PIDFILE ]
then
    # use the send_kill script if the server is not responsive
    $SBDIR/send_kill
fi
STOP_SCRIPT

    'send_kill.sh' => <<'KILL_SCRIPT',
#!_BINBASH_
__LICENSE__
SBDIR="_HOME_DIR_/_SANDBOXDIR_"
PIDFILE="$SBDIR/data/mysql_sandbox_SERVERPORT_.pid"
TIMEOUT=30
__SBINSTR_SH__
if [ -f $PIDFILE ]
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
fi

KILL_SCRIPT

    'use.sh' => <<'USE_SCRIPT',
#!_BINBASH_
__LICENSE__
export LD_LIBRARY_PATH=_BASEDIR_/lib:_BASEDIR_/lib/mysql:$LD_LIBRARY_PATH
export DYLD_LIBRARY_PATH=_BASEDIR_/lib:_BASEDIR_/lib/mysql:$DYLD_LIBRARY_PATH
SBDIR="_HOME_DIR_/_SANDBOXDIR_"
BASEDIR=_BASEDIR_
MYSQL="$BASEDIR/bin/mysql"
export MYSQL_HISTFILE="$SBDIR/.mysql_history"
PIDFILE="$SBDIR/data/mysql_sandbox_SERVERPORT_.pid"
__SBINSTR_SH__
if [ -f $PIDFILE ]
then
    $MYSQL --defaults-file=$SBDIR/my.sandbox.cnf $MYCLIENT_OPTIONS "$@"
#else
#    echo "PID file $PIDFILE not found "
fi
USE_SCRIPT

    'clear.sh' => <<'CLEAR_SCRIPT', 
#!_BINBASH_
__LICENSE__
SBDIR="_HOME_DIR_/_SANDBOXDIR_"
cd $SBDIR
PIDFILE="$SBDIR/data/mysql_sandbox_SERVERPORT_.pid"
__SBINSTR_SH__
#
# attempt to drop databases gracefully
#
if [ -f $PIDFILE ]
then
    for D in `echo "show databases " | ./use -B -N | grep -v "^mysql$" | grep -iv "^information_schema$" | grep -iv "^performance_schema"` 
    do
        echo "set sql_mode=ansi_quotes;drop database \"$D\"" | ./use 
    done
    VERSION=`./use -N -B  -e 'select left(version(),3)'`
    if [ `perl -le 'print $ARGV[0] ge "5.0" ? "1" : "0" ' "$VERSION"` = "1" ]
    then
        ./use -e "truncate mysql.proc"
        ./use -e "truncate mysql.func"
    fi
    if [ `perl -le 'print $ARGV[0] ge "5.1" ? "1" : "0" ' "$VERSION"` = "1" ]
    then
        for T in general_log slow_log plugin proc func
        do
            ./use -e "truncate mysql.$T"
        done
    fi
    #if [ `perl -le 'print $ARGV[0] ge "5.5" ? "1" : "0" ' "$VERSION"` = "1" ]
    #then
    #    for T in `./use -N -B -e 'show tables from performance_schema'`
    #    do
    #        ./use -e "truncate performance_schema.$T"
    #    done
    #fi
fi

./stop
#./send_kill
rm -f data/`hostname`*
rm -f data/log.0*
rm -f data/*.log
rm -f data/falcon*
rm -f data/mysql-bin*
rm -f data/*relay-bin*
rm -f data/ib*
rm -f data/*.info
rm -f data/*.err
rm -f data/*.err-old
# rm -rf data/test/*

#
# remove all databases if any
#
for D in `ls -d data/*/ | grep -w -v mysql | grep -iv performance_schema` 
do
    rm -rf $D
done
mkdir data/test

CLEAR_SCRIPT
    'my.sandbox.cnf'  => <<'MY_SANDBOX_SCRIPT',
__LICENSE__
[mysql]
_MYSQL_PROMPT_
#

[client]
user            = _DBUSER_
password        = _DBPASSWORD_
port            = _SERVERPORT_
socket          = /tmp/mysql_sandbox_SERVERPORT_.sock

[mysqld]
user                            = _OSUSER_
port                            = _SERVERPORT_
socket                          = /tmp/mysql_sandbox_SERVERPORT_.sock
basedir                         = _BASEDIR_
datadir                         = _HOME_DIR_/_SANDBOXDIR_/data
tmpdir                          = _TMPDIR_
pid-file                        = _HOME_DIR_/_SANDBOXDIR_/data/mysql_sandbox_SERVERPORT_.pid
#log-slow-queries               = _HOME_DIR_/_SANDBOXDIR_/data/msandbox-slow.log
#log                            = _HOME_DIR_/_SANDBOXDIR_/data/msandbox.log
_MORE_OPTIONS_

MY_SANDBOX_SCRIPT

    'USING' => <<USING_SCRIPT,
Created with MySQL Sandbox $VERSION
Currently using _INSTALL_VERSION_ with basedir _BASEDIR_

USING_SCRIPT

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

GRANTS_MYSQL

    'load_grants.sh' => << 'LOAD_GRANTS_SCRIPT',
#!_BINBASH_
__LICENSE__
SBDIR=_HOME_DIR_/_SANDBOXDIR_
echo "source $SBDIR/grants.mysql" | $SBDIR/use -u root --password= 
LOAD_GRANTS_SCRIPT

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
mysql_upgrade
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

__SBINSTR_SH__
OLD_PORT=_SERVERPORT_

if [ "$1" = "" ]
then
    echo "new port required"
    exit
else
    NEW_PORT=$1
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

);

# --- END SCRIPTS IN CODE ---

my $license_text = <<'LICENSE';
#    The MySQL Sandbox
#    Copyright (C) 2006-2010 Giuseppe Maxia
#    Contacts: http://datacharmer.org
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; version 2 of the License
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
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

1;
__END__
=head1 NAME

MySQL::Sandbox::Scripts - Script templates for MySQL Sandbox

=head1 PURPOSE

This package is a collection of data and scripts templates for MySQL::Sandbox.
It is not supposed to be used stand alone. It is an ancillary package.
For a reference manual, see L<MySQL::Sandbox>. For a cookbook, see L<MySQL::Sandbox::Recipes>.


=head1 COPYRIGHT

Version 3.0

Copyright (C) 2006-2010 Giuseppe Maxia

Home Page  http://launchpad.net/mysql-sandbox/

=head1 LEGAL NOTICE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2 of the License.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301
USA

